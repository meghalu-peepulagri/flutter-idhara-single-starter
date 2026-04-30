import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/mqtt_utils.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart'
    as motor_model;
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class MotorScheduleController extends GetxController {
  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;
  StreamSubscription<Map<String, dynamic>>? _scheduleActionAckSubscription;
  StreamSubscription<Map<String, dynamic>>? _scheduleLiveDataSubscription;
  StreamSubscription<String>? _scheduleAckTimeoutSubscription;

  var schedules = <Record>[].obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  var page = 1.obs;
  var limit = 10.obs;
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var isHasMoreLoading = false.obs;
  var isInitialLoading = true.obs;
  var totalRecords = 0.obs;
  var selectedFilter = ''.obs; // '' means All
  late final Rx<DateTime> selectedDate;

  final scrollController = ScrollController();

  // Persists colored dots across widget remounts (keyed by date, value = set of status colors)
  final Map<DateTime, Set<Color>> dateBars = {};

  // Track pending actions: scheduleId -> cmd (1=stop, 2=restart, 3=delete)
  final _pendingActions = <int, int>{};

  // Completers for delete (cmd=3): resolved when ACK arrives
  final _deleteCompleters = <int, Completer<bool>>{};

  // Completers for stop/restart (cmd=1/2): resolved after ACK + post API
  final _toggleCompleters = <int, Completer<bool>>{};

  // Bulk completers: key = sorted scheduleIds joined by comma
  final _bulkDeleteCompleters = <String, Completer<bool>>{};
  final _bulkToggleCompleters = <String, Completer<bool>>{};

  // Completer for republish — resolved when create-ACK arrives after republish.
  Completer<bool>? _republishCompleter;

  // Called after a non-republish schedule-create ACK refresh completes.
  // ScheduleManagePageState sets this to refresh its own list without waiting.
  VoidCallback? onScheduleAckRefreshed;

  // Bulk metadata: bulkKey → {scheduleId: objectId}, bulkKey → cmd
  final _bulkObjectIds = <String, Map<int, int>>{};
  final _bulkCmds = <String, int>{};

  /// Converts a DateTime to YYMMDD int format (e.g. 2026-03-17 → 260317)
  static int dateToYYMMDD(DateTime d) =>
      (d.year % 100) * 10000 + d.month * 100 + d.day;

  String _bulkKey(List<int> scheduleIds) =>
      (List<int>.from(scheduleIds)..sort()).join(',');

  @override
  void onInit() {
    super.onInit();
    final today = DateTime.now();
    selectedDate = DateTime(today.year, today.month, today.day).obs;
    scrollController.addListener(_onScroll);
    fetchSchedules();
    _listenScheduleAck();
    _listenScheduleActionAck();
    _listenScheduleLiveData();
    _listenScheduleAckTimeout();
    ever(Get.find<AnalyticsController>().selectedTabIndex, (int index) {
      if (index == 1) fetchSchedules();
    });
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMoreSchedules();
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _scheduleAckSubscription?.cancel();
    _scheduleActionAckSubscription?.cancel();
    _scheduleLiveDataSubscription?.cancel();
    _scheduleAckTimeoutSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchSchedules({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
      page.value = 1;
    } else {
      isLoading.value = true;
      page.value = 1;
    }
    try {
      final response = await _scheduleRepo.getScheduleList(
        page.value,
        limit.value,
        scheduleStatus:
            selectedFilter.value.isNotEmpty ? selectedFilter.value : null,
        scheduleStartDate: dateToYYMMDD(selectedDate.value),
      );
      schedules.value = response?.data?.records ?? [];

      final pagination = response?.data?.paginationInfo;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? 1;
      totalRecords.value = pagination?.totalRecords ?? schedules.length;
    } catch (_) {
      // silently fail
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isInitialLoading.value = false;
      isHasMoreLoading.value = false;
    }
  }

  Future<void> loadMoreSchedules() async {
    if (isHasMoreLoading.value) return;
    if (currentPage.value >= totalPages.value) return;

    isHasMoreLoading.value = true;
    page.value = currentPage.value + 1;
    try {
      final response = await _scheduleRepo.getScheduleList(
        page.value,
        limit.value,
        scheduleStatus:
            selectedFilter.value.isNotEmpty ? selectedFilter.value : null,
        scheduleStartDate: dateToYYMMDD(selectedDate.value),
      );
      schedules.addAll(response?.data?.records ?? []);

      final pagination = response?.data?.paginationInfo;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? totalPages.value;
      totalRecords.value = pagination?.totalRecords ?? totalRecords.value;
    } catch (_) {
      // silently fail
    } finally {
      isHasMoreLoading.value = false;
    }
  }

  Future<void> fetchacknowledgement(List<int> ids) async {
    try {
      await _scheduleRepo.scheduleAcknowledgement(ids);
    } catch (_) {
      // silently fail
    }
  }

  // --- Schedule Actions (T:24): stop/resume/delete ---

  /// Publish schedule action: cmd 1=stop, 2=resume, 3=delete
  /// ids in payload = 2^(scheduleId - 1)
  Future<void> publishScheduleAction(Record record, int cmd) async {
    final id = _resolveIdentifier();
    if (id.isEmpty) return;
    final scheduleId = record.scheduleId ?? 0;
    _pendingActions[scheduleId] = cmd;
    try {
      await _mqttService.publishScheduleActionCommand(
        identifier: id,
        scheduleId: scheduleId,
        cmd: cmd,
      );
    } catch (e) {
      _pendingActions.remove(scheduleId);
      _deleteCompleters.remove(scheduleId)?.complete(false);
      _toggleCompleters.remove(scheduleId)?.complete(false);
      geterrorSnackBar('Failed to send command: $e');
    }
  }

  /// Delete: publish MQTT cmd:3, wait for ACK + API, then return.
  /// Dialog stays loading until this resolves.
  Future<bool> deleteSchedule(Record record) async {
    final scheduleId = record.scheduleId ?? 0;
    // Guard: skip if this schedule already has an in-flight action from any path.
    if (_pendingActions.containsKey(scheduleId)) return false;
    final completer = Completer<bool>();
    _deleteCompleters[scheduleId] = completer;
    await publishScheduleAction(record, 3);
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _deleteCompleters.remove(scheduleId);
        _pendingActions.remove(scheduleId);
        geterrorSnackBar('No response from device');
        // fetchSchedules();
        return false;
      },
    );
  }

  /// Stop/Restart: publish MQTT cmd:1 (stop) or cmd:2 (restart),
  /// wait for ACK, then call stop/restart API.
  /// Returns true on success, false on failure.
  Future<bool> toggleSchedule(Record record, bool enabled) async {
    final scheduleId = record.scheduleId ?? 0;
    // Guard: skip if this schedule already has an in-flight action from any path.
    if (_pendingActions.containsKey(scheduleId)) return false;
    final completer = Completer<bool>();
    _toggleCompleters[scheduleId] = completer;
    await publishScheduleAction(record, enabled ? 2 : 1);
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _toggleCompleters.remove(scheduleId);
        _pendingActions.remove(scheduleId);
        geterrorSnackBar('No response from device');
        // fetchSchedules();
        return false;
      },
    );
  }

  /// Publish a single MQTT T:24 for multiple schedules (combined bitmask).
  Future<void> _publishBulkScheduleAction(List<Record> records, int cmd) async {
    final id = _resolveIdentifier();
    if (id.isEmpty) return;
    final scheduleIds =
        records.map((r) => r.scheduleId ?? 0).where((sid) => sid > 0).toList();
    if (scheduleIds.isEmpty) return;
    for (final sid in scheduleIds) {
      _pendingActions[sid] = cmd;
    }
    try {
      await _mqttService.publishBulkScheduleActionCommand(
        identifier: id,
        scheduleIds: scheduleIds,
        cmd: cmd,
      );
    } catch (e) {
      for (final sid in scheduleIds) {
        _pendingActions.remove(sid);
      }
      rethrow;
    }
  }

  /// Bulk delete: send a single MQTT cmd:3 for all records, wait for ACK,
  /// then call DELETE /motor-schedules/bulk API.
  Future<bool> deleteBulkSchedules(List<Record> records) async {
    final scheduleIds =
        records.map((r) => r.scheduleId ?? 0).where((sid) => sid > 0).toList();
    if (scheduleIds.isEmpty) return false;
    // Guard: skip if any of these schedules already has an in-flight action.
    if (scheduleIds.any((sid) => _pendingActions.containsKey(sid)))
      return false;

    final key = _bulkKey(scheduleIds);
    final completer = Completer<bool>();
    _bulkDeleteCompleters[key] = completer;
    _bulkObjectIds[key] = {
      for (final r in records)
        if (r.scheduleId != null && r.id != null) r.scheduleId!: r.id!
    };
    _bulkCmds[key] = 3;

    try {
      await _publishBulkScheduleAction(records, 3);
    } catch (e) {
      _bulkDeleteCompleters.remove(key);
      _bulkObjectIds.remove(key);
      _bulkCmds.remove(key);
      geterrorSnackBar('Failed to send command: $e');
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _bulkDeleteCompleters.remove(key);
        _bulkObjectIds.remove(key);
        _bulkCmds.remove(key);
        for (final sid in scheduleIds) _pendingActions.remove(sid);
        geterrorSnackBar('No response from device');
        return false;
      },
    );
  }

  /// Bulk stop/restart: send a single MQTT cmd:1/2 for all records, wait for
  /// ACK, then call POST /motor-schedules/bulk/stop|restart API.
  Future<bool> toggleBulkSchedules(List<Record> records, bool enabled) async {
    final scheduleIds =
        records.map((r) => r.scheduleId ?? 0).where((sid) => sid > 0).toList();
    if (scheduleIds.isEmpty) return false;
    // Guard: skip if any of these schedules already has an in-flight action.
    if (scheduleIds.any((sid) => _pendingActions.containsKey(sid)))
      return false;

    final cmd = enabled ? 2 : 1;
    final key = _bulkKey(scheduleIds);
    final completer = Completer<bool>();
    _bulkToggleCompleters[key] = completer;
    _bulkObjectIds[key] = {
      for (final r in records)
        if (r.scheduleId != null && r.id != null) r.scheduleId!: r.id!
    };
    _bulkCmds[key] = cmd;

    try {
      await _publishBulkScheduleAction(records, cmd);
    } catch (e) {
      _bulkToggleCompleters.remove(key);
      _bulkObjectIds.remove(key);
      _bulkCmds.remove(key);
      geterrorSnackBar('Failed to send command: $e');
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _bulkToggleCompleters.remove(key);
        _bulkObjectIds.remove(key);
        _bulkCmds.remove(key);
        for (final sid in scheduleIds) _pendingActions.remove(sid);
        geterrorSnackBar('No response from device');
        return false;
      },
    );
  }

  /// Cancel an in-flight schedule action (stop / restart / delete).
  /// Called when the user taps Cancel in the confirmation dialog while we're
  /// still waiting on the device ACK. Stops the MQTT retry loop and resolves
  /// the awaiting completer with `false` so the dialog's future returns
  /// immediately and the dialog can be dismissed.
  void cancelPendingScheduleAction(int scheduleId) {
    // 1. Stop MQTT retry loop for this device identifier.
    final id = _resolveIdentifier();
    if (id.isNotEmpty) {
      _mqttService.cancelScheduleActionRetries(id);
    }

    // 2. Drop the pending action so any late ACK is treated as unrelated.
    _pendingActions.remove(scheduleId);

    // 3. Resolve any awaiting completer with `false`. Guard isCompleted in
    //    case the ACK landed in the same frame as the cancel tap.
    final delete = _deleteCompleters.remove(scheduleId);
    if (delete != null && !delete.isCompleted) delete.complete(false);
    final toggle = _toggleCompleters.remove(scheduleId);
    if (toggle != null && !toggle.isCompleted) toggle.complete(false);
  }

  void _listenScheduleActionAck() {
    _scheduleActionAckSubscription?.cancel();
    _scheduleActionAckSubscription =
        _mqttService.scheduleActionAckStream.listen((ack) async {
      int scheduleId = 0;
      try {
        final currentId = _resolveIdentifier();
        final ackId = (ack['topic'] ?? '').toString();
        if (currentId.isNotEmpty && ackId != currentId) return;

        final status = ack['status'] as int? ?? 0;
        scheduleId = ack['id'] as int? ?? 0;
        final ackedIds =
            (ack['ids'] as List?)?.whereType<int>().toList() ?? <int>[];
        final receivedAckCmd = ack['ack'] as int?;

        // ── BULK PATH ──────────────────────────────────────────────────────
        if (ackedIds.isNotEmpty) {
          final key = _bulkKey(ackedIds);
          final hasBulkDelete = _bulkDeleteCompleters.containsKey(key);
          final hasBulkToggle = _bulkToggleCompleters.containsKey(key);

          if (hasBulkDelete || hasBulkToggle) {
            for (final sid in ackedIds) {
              _pendingActions.remove(sid);
            }
            final objectIdMap = _bulkObjectIds.remove(key) ?? {};
            final cmd = _bulkCmds.remove(key) ?? receivedAckCmd ?? 0;
            final objectIds = objectIdMap.values.toList();

            if (status == 1) {
              if (cmd == 3) {
                try {
                  await _scheduleRepo.bulkDeleteSchedules(objectIds);
                  getsuccessSnackBar('Schedules deleted successfully');
                  _bulkDeleteCompleters.remove(key)?.complete(true);
                } catch (_) {
                  geterrorSnackBar('Failed to delete schedules');
                  _bulkDeleteCompleters.remove(key)?.complete(false);
                }
              } else if (cmd == 1 || cmd == 2) {
                try {
                  if (cmd == 1) {
                    await _scheduleRepo.bulkStopSchedules(objectIds);
                  } else {
                    await _scheduleRepo.bulkRestartSchedules(objectIds);
                  }
                  getsuccessSnackBar(
                      cmd == 1 ? 'Schedules stopped' : 'Schedules restarted');
                  _bulkToggleCompleters.remove(key)?.complete(true);
                } catch (_) {
                  geterrorSnackBar('Failed to update schedules');
                  _bulkToggleCompleters.remove(key)?.complete(false);
                }
              }
            } else {
              geterrorSnackBar('Schedule action failed');
              _bulkDeleteCompleters.remove(key)?.complete(false);
              _bulkToggleCompleters.remove(key)?.complete(false);
            }
            fetchSchedules();
            return;
          }
        }

        // ── SINGLE PATH (existing) ─────────────────────────────────────────
        final cmd = _pendingActions[scheduleId];
        if (cmd == null) return;

        if (receivedAckCmd != null && receivedAckCmd != cmd) {
          debugPrint('⚠️ Ignored ACK: expected $cmd but got $receivedAckCmd');
          return;
        }

        _pendingActions.remove(scheduleId);

        if (status == 1) {
          if (cmd == 3) {
            // ── DELETE: call delete API, complete completer ──
            await _deleteScheduleAfterAck(scheduleId);
            _deleteCompleters.remove(scheduleId)?.complete(true);
          } else if (cmd == 1 || cmd == 2) {
            // ── STOP / RESTART: call post API, complete completer ──
            final record =
                schedules.firstWhereOrNull((r) => r.scheduleId == scheduleId);
            if (record != null) {
              await SharedPreference.setscheduleid(record.id ?? 0);
            }
            try {
              final response = await _scheduleRepo.scheduleStopAndRestart(cmd);
              if (response != null) {
                getsuccessSnackBar(
                    cmd == 1 ? 'Schedule stopped' : 'Schedule restarted');
                _toggleCompleters.remove(scheduleId)?.complete(true);
              } else {
                geterrorSnackBar('Failed to update schedule status');
                _toggleCompleters.remove(scheduleId)?.complete(false);
              }
            } catch (_) {
              geterrorSnackBar('Failed to update schedule status');
              _toggleCompleters.remove(scheduleId)?.complete(false);
            }
            fetchSchedules();
          } else {
            fetchSchedules();
          }
        } else {
          // ── ACK FAILURE ──
          geterrorSnackBar('Schedule action failed');
          _deleteCompleters.remove(scheduleId)?.complete(false);
          _toggleCompleters.remove(scheduleId)?.complete(false);
          fetchSchedules();
        }
      } catch (e) {
        // Safety net: always resolve completers so dialogs never get stuck
        _deleteCompleters.remove(scheduleId)?.complete(false);
        _toggleCompleters.remove(scheduleId)?.complete(false);
        fetchSchedules();
      }
    });
  }

  Future<void> _deleteScheduleAfterAck(int scheduleId) async {
    final record =
        schedules.firstWhereOrNull((r) => r.scheduleId == scheduleId);
    if (record != null) {
      SharedPreference.setscheduleid(record.id ?? 0);
      schedules.remove(record);
    }
    getsuccessSnackBar('Schedule deleted successfully');
    try {
      await _scheduleRepo.scheduleDelete();
    } catch (_) {
      // silently fail
    }
    // Start fetching with loading — runs in background while dialog closes
    unawaited(fetchSchedules());
  }

  // --- Navigation ---

  motor_model.Motor _buildMotorFromDetails() {
    final details = Get.find<AnalyticsController>().motorDetails.value;
    return motor_model.Motor(
      id: details?.id,
      name: details?.name,
      aliasName: details?.aliasName,
      starter: details?.starter != null
          ? motor_model.Starter(
              id: details!.starter!.id,
              name: details.starter!.name,
              macAddress: details.starter!.macAddress,
              pcbNumber: details.starter!.pcbNumber,
              starterNumber: details.starter!.starterNumber,
              deviceAllocation: details.starter!.deviceAllocation,
            )
          : null,
    );
  }

  Future<void> navigateToCreateSchedule() async {
    await Get.toNamed(
      Routes.schedule,
      arguments: {'motor': _buildMotorFromDetails()},
    );
    fetchSchedules();
  }

  Future<void> navigateToEditSchedule(Record record) async {
    await Get.toNamed(
      Routes.schedule,
      arguments: {
        'motor': _buildMotorFromDetails(),
        'record': record,
      },
    );
    fetchSchedules();
  }

  Future<void> navigateToScheduleManage() async {
    await Get.toNamed(Routes.scheduleManage);
    fetchSchedules();
  }

  /// Republish a T:3 MQTT command for the given schedule records.
  /// Used by Schedule Manage page to re-send PENDING schedules to the device.
  /// Always uses idx=2 (motor already has schedules).
  Future<bool> republishSchedules(List<Record> records) async {
    if (records.isEmpty) return false;
    final id = _resolveIdentifier();
    if (id.isEmpty) {
      geterrorSnackBar('Device identifier not found');
      return false;
    }
    try {
      final items = records.map((r) {
        final sid = r.scheduleId ?? 0;
        final startHHMM = _timeStrToHHMM(r.startTime);
        final endHHMM = _timeStrToHHMM(r.endTime);
        final sd = r.scheduleStartDate ?? 0;
        final ed = r.scheduleEndDate ?? sd;
        final isCyclic = r.scheduleType == ScheduleType.CYCLIC;
        return <String, dynamic>{
          'id': sid,
          'sd': sd,
          'ed': ed,
          'st': startHHMM,
          'et': endHHMM,
          'st_ep': _yymmddHhmmToEpoch(sd, startHHMM),
          'ed_ep': _yymmddHhmmToEpoch(ed, endHHMM),
          'en': 1,
          if (isCyclic) ...{
            'cy': 1,
            'on': (r.cycleOnMinutes as num?)?.toInt() ?? 20,
            'off': (r.cycleOffMinutes as num?)?.toInt() ?? 15,
            'pwr_rec': 0,
          } else ...{
            'pwr_rec': (r.powerLossRecovery == true) ? 1 : 0,
          },
        };
      }).toList()
        ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

      final completer = Completer<bool>();
      _republishCompleter = completer;

      await _mqttService.publishMultipleSchedulesCommand(
        identifier: id,
        items: items,
        idx: 2,
      );

      // Wait for device ACK (T:33) — resolved in _listenScheduleAck
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _republishCompleter = null;
          geterrorSnackBar('No response from device');
          return false;
        },
      );
    } catch (e) {
      _republishCompleter = null;
      geterrorSnackBar('Failed to republish: $e');
      return false;
    }
  }

  static int _timeStrToHHMM(String? time) {
    if (time == null || time.isEmpty) return 0;
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length < 2) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m =
          int.tryParse(parts[1].substring(0, parts[1].length.clamp(0, 2))) ?? 0;
      return h * 100 + m;
    }
    return int.tryParse(time) ?? 0;
  }

  static int _yymmddHhmmToEpoch(int yymmdd, int hhmm) {
    if (yymmdd == 0) return 0;
    final yy = yymmdd ~/ 10000;
    final mm = (yymmdd % 10000) ~/ 100;
    final dd = yymmdd % 100;
    final h = hhmm ~/ 100;
    final m = hhmm % 100;
    return DateTime(2000 + yy, mm, dd, h, m).millisecondsSinceEpoch ~/ 1000;
  }

  String _resolveIdentifier() {
    final starter = Get.find<AnalyticsController>().motorDetails.value?.starter;
    final deviceAlloc = starter?.deviceAllocation ?? 'false';
    final pcb = starter?.pcbNumber?.trim() ?? '';
    final mac = starter?.macAddress?.trim() ?? '';
    return getMotorIdentifier(deviceAlloc, pcb, mac);
  }

  // --- MQTT live schedule updates (sch field from T:35 / T:41) ---

  /// Convert integer time (e.g. 700 or 1430) to "HH:MM" string.
  static String _intToTimeStr(int t) {
    final h = t ~/ 100;
    final m = t % 100;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Fired by MqttService when a schedule-create publish (T:23) exhausts
  /// retries with no device ACK. Show the user a clear snackbar so they
  /// know the create didn't reach the device, and unblock any in-flight
  /// republish dialog awaiting completion.
  void _listenScheduleAckTimeout() {
    _scheduleAckTimeoutSubscription?.cancel();
    _scheduleAckTimeoutSubscription =
        _mqttService.scheduleAckTimeoutStream.listen((timedOutIdentifier) {
      // Filter to this controller's motor — the stream is broadcast across
      // motors and we don't want a snackbar for an unrelated device.
      final currentId = _resolveIdentifier();
      if (currentId.isNotEmpty && timedOutIdentifier != currentId) return;

      geterrorSnackBar('No response from device');

      // If a republish flow was awaiting an ACK, resolve it with false so
      // the loading dialog closes cleanly.
      if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
        _republishCompleter!.complete(false);
        _republishCompleter = null;
      }
    });
  }

  void _listenScheduleLiveData() {
    _scheduleLiveDataSubscription?.cancel();
    _scheduleLiveDataSubscription =
        _mqttService.scheduleLiveDataStream.listen((data) {
      final scheduleId = data['scheduleId'] as int?;
      if (scheduleId == null) return;

      final idx = schedules.indexWhere((r) => r.scheduleId == scheduleId);
      if (idx == -1) return;

      final stRaw = data['startTime'] as int?;
      final etRaw = data['endTime'] as int?;
      final runtime = data['runtime'] as int?;

      // copyWith creates a NEW Record instance so Flutter's widget diff detects
      // a real object change and guarantees ScheduleCard.build() is called.
      schedules[idx] = schedules[idx].copyWith(
        runtimeMinutes: runtime,
        startTime: stRaw != null ? _intToTimeStr(stRaw) : null,
        endTime: etRaw != null ? _intToTimeStr(etRaw) : null,
      );
    });
  }

  // --- Schedule Create ACK (T:33) ---

  void _listenScheduleAck() {
    _scheduleAckSubscription?.cancel();
    _scheduleAckSubscription =
        _mqttService.scheduleAckStream.listen((ack) async {
      final currentId = _resolveIdentifier();
      final ackId = (ack['topic'] ?? '').toString();
      debugPrint('📥 Schedule ACK received: $ack (currentId=$currentId)');
      if (currentId.isNotEmpty && ackId != currentId) {
        debugPrint('↪️ Schedule ACK ignored — identifier mismatch');
        return;
      }

      final d = ack['D'] as int? ?? 0;
      if (d != 1) {
        debugPrint('↪️ Schedule ACK failed — D=$d');
        return;
      }

      // Decode which scheduleIds were ACK'd from the bitmask.
      // Each entry in schedule_ids is a scheduleId (record.scheduleId).
      // We map them to their database object IDs (record.id) for the API call.
      final ackedScheduleIds =
          (ack['schedule_ids'] as List?)?.whereType<int>().toList() ?? <int>[];

      debugPrint('ACK scheduleIds: $ackedScheduleIds');

      // Collect object IDs of matching records; fall back to all if list is empty
      final objectIds = ackedScheduleIds.isNotEmpty
          ? schedules
              .where((r) =>
                  r.scheduleId != null &&
                  ackedScheduleIds.contains(r.scheduleId))
              .map((r) => r.id)
              .whereType<int>()
              .toList()
          : schedules.map((r) => r.id).whereType<int>().toList();

      debugPrint('📤 Sending acknowledgement for objectIds: $objectIds');

      // Sequential: ack endpoint first, then list refresh.
      try {
        await fetchacknowledgement(objectIds);
      } catch (e) {
        debugPrint('⚠️ fetchacknowledgement failed: $e');
      }
      try {
        await fetchSchedules();
        debugPrint('✅ fetchSchedules completed after schedule ACK');
      } catch (e) {
        debugPrint('⚠️ fetchSchedules failed after ACK: $e');
      }

      // Republish path: resolve the completer so the dialog closes and
      // republishSelectedSchedules can refresh the manage page list.
      if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
        getsuccessSnackBar('Schedules acknowledged by device');
        _republishCompleter!.complete(true);
        _republishCompleter = null;
      } else {
        // Normal create ACK: notify manage page (if open) to refresh its list.
        onScheduleAckRefreshed?.call();
      }
    });
  }
}
