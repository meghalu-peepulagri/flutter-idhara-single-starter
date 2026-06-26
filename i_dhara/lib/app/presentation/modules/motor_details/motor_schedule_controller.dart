import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/mqtt_utils.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/schedule_result_snackbar.dart';
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
  static const int kMaxSchedulesPerDate = 4;

  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;
  StreamSubscription<Map<String, dynamic>>? _scheduleActionAckSubscription;
  StreamSubscription<Map<String, dynamic>>? _scheduleLiveDataSubscription;
  StreamSubscription<String>? _scheduleAckTimeoutSubscription;
  StreamSubscription<Map<String, dynamic>>? _scheduleFinalResultSubscription;
  StreamSubscription<Map<String, dynamic>>?
      _scheduleActionFinalResultSubscription;

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

  int get activeScheduleCount => schedules
      .where((r) => (r.scheduleStatus ?? '').toLowerCase() != 'failed')
      .length;
  late final Rx<DateTime> selectedDate;

  final scrollController = ScrollController();

  final Map<DateTime, Set<Color>> dateBars = {};

  final _pendingActions = <int, int>{};

  // Completers for delete (cmd=3): resolved when ACK arrives
  final _deleteCompleters = <int, Completer<bool>>{};

  final _pendingDeleteObjectIds = <int, int>{};

  // Completers for stop/restart (cmd=1/2): resolved after ACK + post API
  final _toggleCompleters = <int, Completer<bool>>{};

  // Bulk completers: key = sorted scheduleIds joined by comma
  final _bulkDeleteCompleters = <String, Completer<bool>>{};
  final _bulkToggleCompleters = <String, Completer<bool>>{};

  // Completer for republish — resolved when create-ACK arrives after republish.
  Completer<bool>? _republishCompleter;

  final _lastScheduleStatus = <int, int>{};

  List<int> _expectedScheduleIds = [];

  final Map<int, int> _slotToScheduleId = {};

  VoidCallback? onScheduleAckRefreshed;

  // Bulk metadata: bulkKey → {scheduleId: objectId}, bulkKey → cmd
  final _bulkObjectIds = <String, Map<int, int>>{};
  final _bulkCmds = <String, int>{};

  List<int> _lastAckedScheduleIds = [];
  List<int> get lastAckedScheduleIds =>
      List<int>.unmodifiable(_lastAckedScheduleIds);

  /// Converts a DateTime to YYMMDD int format (e.g. 2026-03-17 → 260317)
  static int dateToYYMMDD(DateTime d) =>
      (d.year % 100) * 10000 + d.month * 100 + d.day;

  String _bulkKey(List<int> scheduleIds) =>
      (List<int>.from(scheduleIds)..sort()).join(',');

  int _deviceSlot(Record r) => r.deviceScheduleId ?? r.scheduleId ?? 0;

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
    _listenScheduleFinalResult();
    _listenScheduleActionFinalResult();
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
    _scheduleFinalResultSubscription?.cancel();
    _scheduleActionFinalResultSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchSchedules({
    bool isRefresh = false,
    bool silent = false,
  }) async {
    if (!silent) {
      if (isRefresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
    }
    page.value = 1;
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
      if (!silent) {
        isLoading.value = false;
        isRefreshing.value = false;
        isInitialLoading.value = false;
      }
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

  Future<void> fetchacknowledgement(List<int> ids,
      {Map<int, int>? slotMap}) async {
    try {
      await _scheduleRepo.scheduleAcknowledgement(ids, slotMap: slotMap);
    } catch (_) {
      // silently fail
    }
  }

  // --- Schedule Actions (T:24): stop/resume/delete ---

  /// Publish schedule action: cmd 1=stop, 2=resume, 3=delete
  /// ids in payload = 2^(deviceSlot - 1)
  Future<void> publishScheduleAction(Record record, int cmd) async {
    final id = _resolveIdentifier();
    if (id.isEmpty) return;
    final scheduleId = _deviceSlot(record);
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
      debugPrint('Schedule action publish failed: $e');
      geterrorSnackBar('No response from device');
    }
  }

  Future<bool> deleteScheduleApiOnly(Record record) async {
    final objectId = record.id ?? 0;
    if (objectId <= 0) return false;
    try {
      await SharedPreference.setscheduleid(objectId);
      final res = await _scheduleRepo.scheduleDelete();
      if (res == null) {
        geterrorSnackBar('Failed to delete schedule');
        return false;
      }
      schedules.removeWhere((r) => r.id == objectId);
      getsuccessSnackBar('Schedule deleted successfully');
      unawaited(fetchSchedules(silent: true));
      return true;
    } catch (_) {
      geterrorSnackBar('Failed to delete schedule');
      return false;
    }
  }

  Future<bool> deleteBulkSchedulesApiOnly(List<Record> records) async {
    final objectIds = records.map((r) => r.id).whereType<int>().toList();
    if (objectIds.isEmpty) return false;
    try {
      final ok = await _scheduleRepo.bulkDeleteSchedules(objectIds);
      if (!ok) {
        geterrorSnackBar('Failed to delete schedules');
        return false;
      }
      schedules.removeWhere((r) => r.id != null && objectIds.contains(r.id));
      final n = objectIds.length;
      getsuccessSnackBar('$n schedule${n > 1 ? 's' : ''} deleted');
      unawaited(fetchSchedules(silent: true));
      return true;
    } catch (_) {
      geterrorSnackBar('Failed to delete schedules');
      return false;
    }
  }

  Future<bool> deleteSchedule(Record record) async {
    final scheduleId = _deviceSlot(record);
    // Guard: skip if this schedule already has an in-flight action from any path.
    if (_pendingActions.containsKey(scheduleId)) return false;
    final completer = Completer<bool>();
    _deleteCompleters[scheduleId] = completer;
    _pendingDeleteObjectIds[scheduleId] = record.id ?? 0;
    await publishScheduleAction(record, 3);
    return completer.future.timeout(
      const Duration(seconds: 23),
      onTimeout: () {
        _deleteCompleters.remove(scheduleId);
        _pendingDeleteObjectIds.remove(scheduleId);
        _pendingActions.remove(scheduleId);
        geterrorSnackBar('No response from device');
        // fetchSchedules();
        return false;
      },
    );
  }

  Future<bool> toggleSchedule(Record record, bool enabled) async {
    final scheduleId = _deviceSlot(record);
    // Guard: skip if this schedule already has an in-flight action from any path.
    if (_pendingActions.containsKey(scheduleId)) return false;
    final completer = Completer<bool>();
    _toggleCompleters[scheduleId] = completer;
    await publishScheduleAction(record, enabled ? 2 : 1);
    return completer.future.timeout(
      // Matches MQTT retry cycle (10s + 10s + 3s).
      const Duration(seconds: 23),
      onTimeout: () {
        _toggleCompleters.remove(scheduleId);
        _pendingActions.remove(scheduleId);
        geterrorSnackBar('No response from device');
        // fetchSchedules();
        return false;
      },
    );
  }

  Future<void> _publishBulkScheduleAction(List<Record> records, int cmd) async {
    final id = _resolveIdentifier();
    if (id.isEmpty) return;
    final scheduleIds =
        records.map(_deviceSlot).where((sid) => sid > 0).toList();
    if (scheduleIds.isEmpty) return;
    for (final sid in scheduleIds) {
      _pendingActions[sid] = cmd;
    }
    try {
      await _mqttService.publishBulkScheduleActionCommand(
        identifier: id,
        scheduleIds: scheduleIds,
        cmd: cmd,
        trackExpectedAcks: true,
      );
    } catch (e) {
      for (final sid in scheduleIds) {
        _pendingActions.remove(sid);
      }
      rethrow;
    }
  }

  Future<bool> deleteBulkSchedules(List<Record> records) async {
    final scheduleIds =
        records.map(_deviceSlot).where((sid) => sid > 0).toList();
    if (scheduleIds.isEmpty) return false;
    // Guard: skip if any of these schedules already has an in-flight action.
    if (scheduleIds.any((sid) => _pendingActions.containsKey(sid)))
      return false;

    final key = _bulkKey(scheduleIds);
    final completer = Completer<bool>();
    _bulkDeleteCompleters[key] = completer;
    _bulkObjectIds[key] = {
      for (final r in records)
        if (_deviceSlot(r) > 0 && r.id != null) _deviceSlot(r): r.id!
    };
    _bulkCmds[key] = 3;

    try {
      await _publishBulkScheduleAction(records, 3);
    } catch (e) {
      _bulkDeleteCompleters.remove(key);
      _bulkObjectIds.remove(key);
      _bulkCmds.remove(key);
      debugPrint('Bulk delete publish failed: $e');
      geterrorSnackBar('No response from device');
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 28),
      onTimeout: () {
        _bulkDeleteCompleters.remove(key);
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
        records.map(_deviceSlot).where((sid) => sid > 0).toList();
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
        if (_deviceSlot(r) > 0 && r.id != null) _deviceSlot(r): r.id!
    };
    _bulkCmds[key] = cmd;

    try {
      await _publishBulkScheduleAction(records, cmd);
    } catch (e) {
      _bulkToggleCompleters.remove(key);
      _bulkObjectIds.remove(key);
      _bulkCmds.remove(key);
      debugPrint('Bulk stop/restart publish failed: $e');
      geterrorSnackBar('No response from device');
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 28),
      onTimeout: () {
        _bulkToggleCompleters.remove(key);
        for (final sid in scheduleIds) _pendingActions.remove(sid);
        geterrorSnackBar('No response from device');
        return false;
      },
    );
  }

  void cancelInFlightScheduleOperation() {
    final id = _resolveIdentifier();
    if (id.isNotEmpty) {
      _mqttService.cancelScheduleActionRetries(id);
      _mqttService.cancelScheduleCreateRetries(id);
    }

    if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
      _republishCompleter!.complete(false);
    }
    _republishCompleter = null;

    for (final c in _bulkDeleteCompleters.values.toList()) {
      if (!c.isCompleted) c.complete(false);
    }
    _bulkDeleteCompleters.clear();

    for (final c in _bulkToggleCompleters.values.toList()) {
      if (!c.isCompleted) c.complete(false);
    }
    _bulkToggleCompleters.clear();

    for (final c in _deleteCompleters.values.toList()) {
      if (!c.isCompleted) c.complete(false);
    }
    _deleteCompleters.clear();

    for (final c in _toggleCompleters.values.toList()) {
      if (!c.isCompleted) c.complete(false);
    }
    _toggleCompleters.clear();

    _pendingActions.clear();
    _bulkObjectIds.clear();
    _bulkCmds.clear();
    _expectedScheduleIds = [];
  }

  void cancelPendingScheduleAction(Record record) {
    final scheduleId = _deviceSlot(record);
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
    _pendingDeleteObjectIds.remove(scheduleId);
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

        scheduleId = ack['id'] as int? ?? 0;
        final ackedIds =
            (ack['ids'] as List?)?.whereType<int>().toList() ?? <int>[];
        final receivedAckCmd = ack['ack'] as int?;

        final isPartOfBulk = ackedIds.length > 1 ||
            _bulkObjectIds.values
                .any((objMap) => ackedIds.any(objMap.containsKey));
        if (isPartOfBulk) return;

        // ── SINGLE PATH ────────────────────────────────────────────────────
        final cmd = _pendingActions[scheduleId];
        if (cmd == null) return;

        // Success when ack code matches the cmd we sent (1/2/3).
        final isSuccess = receivedAckCmd != null && receivedAckCmd == cmd;
        final errorMsg = receivedAckCmd != null
            ? MqttService.scheduleActionAckErrorMessage(receivedAckCmd)
            : null;

        if (!isSuccess && errorMsg == null) {
          debugPrint(
              '⚠️ Ignored unexpected schedule action ACK: ack=$receivedAckCmd cmd=$cmd');
          return;
        }

        _pendingActions.remove(scheduleId);

        if (isSuccess) {
          if (cmd == 3) {
            // ── DELETE: call delete API, complete completer ──
            await _deleteScheduleAfterAck(scheduleId);
            _deleteCompleters.remove(scheduleId)?.complete(true);
          } else if (cmd == 1 || cmd == 2) {
            // ── STOP / RESTART: call post API, complete completer ──
            final record =
                schedules.firstWhereOrNull((r) => _deviceSlot(r) == scheduleId);
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

            fetchSchedules(silent: true);
          } else {
            fetchSchedules(silent: true);
          }
        } else {
          // ── ACK FAILURE — show device-specific message ──
          geterrorSnackBar(errorMsg!);
          _deleteCompleters.remove(scheduleId)?.complete(false);
          _toggleCompleters.remove(scheduleId)?.complete(false);
          fetchSchedules(silent: true);
        }
      } catch (e) {
        // Safety net: always resolve completers so dialogs never get stuck
        _deleteCompleters.remove(scheduleId)?.complete(false);
        _toggleCompleters.remove(scheduleId)?.complete(false);
        fetchSchedules(silent: true);
      }
    });
  }

  Future<void> _deleteScheduleAfterAck(int scheduleId) async {
    final objectId = _pendingDeleteObjectIds.remove(scheduleId) ?? 0;
    final record =
        schedules.firstWhereOrNull((r) => _deviceSlot(r) == scheduleId);
    if (record != null) {
      schedules.remove(record);
    }
    if (objectId > 0) {
      SharedPreference.setscheduleid(objectId);
      getsuccessSnackBar('Schedule deleted successfully');
      try {
        await _scheduleRepo.scheduleDelete();
      } catch (_) {
        // silently fail
      }
    }
    // Reconcile in the background — silent so the list area doesn't
    // flash to the lottie loader; the row is already removed locally.
    unawaited(fetchSchedules(silent: true));
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
    final existingCount = activeScheduleCount;
    await Get.toNamed(
      Routes.schedule,
      arguments: {
        'motor': _buildMotorFromDetails(),
        'existingScheduleCount': existingCount,
        'selectedDate': selectedDate.value,
      },
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

  Future<bool> republishSchedules(List<Record> records, {int idx = 2}) async {
    if (records.isEmpty) return false;
    _lastAckedScheduleIds = [];
    return true;
  }

  Future<bool> republishSchedulesViaApi(List<Record> records) async {
    final ids = records
        .map((r) => r.id)
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
    if (ids.isEmpty) return false;
    final result = await _scheduleRepo.bulkRepublishSchedules(ids);

    // Device offline (ids landed in `failed`, nothing republished) → show the
    // backend message in an error snackbar.
    if (result != null && result.hasFailed && !result.hasRepublished) {
      geterrorSnackBar(
        (result.message != null && result.message!.isNotEmpty)
            ? result.message!
            : 'Device is offline. Schedules will be delivered on the next heartbeat.',
      );
    }

    try {
      await fetchSchedules(silent: true);
    } catch (_) {}
    return true;
  }

  void _showScheduleResultAfterDelay(List<int> ackedScheduleIds) {
    if (_expectedScheduleIds.isEmpty) return;
    final expected = List<int>.from(_expectedScheduleIds);
    _expectedScheduleIds = [];

    if (expected.length <= 1) return;
    final ackedSet = ackedScheduleIds.toSet();

    Future.delayed(const Duration(seconds: 3), () {
      final successCount = expected.where(ackedSet.contains).length;
      final failedCount = expected.length - successCount;
      showScheduleResultSnackBar(
        total: expected.length,
        successCount: successCount,
        failedCount: failedCount,
      );
    });
  }

  String _resolveIdentifier() {
    final starter = Get.find<AnalyticsController>().motorDetails.value?.starter;
    final deviceAlloc = starter?.deviceAllocation ?? 'false';
    final pcb = starter?.pcbNumber?.trim() ?? '';
    final mac = starter?.macAddress?.trim() ?? '';
    return getMotorIdentifier(deviceAlloc, pcb, mac);
  }

  // --- MQTT live schedule updates (sch field from T:35 / T:41) ---

  static String _epochToTimeStr(int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

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
        _showScheduleResultAfterDelay(<int>[]);
      }
    });
  }

  void _listenScheduleLiveData() {
    _scheduleLiveDataSubscription?.cancel();
    _scheduleLiveDataSubscription =
        _mqttService.scheduleLiveDataStream.listen((data) {
      final scheduleId = data['scheduleId'] as int?;
      if (scheduleId == null) return;

      final ss = data['scheduleStatus'] as int?;
      if (ss != null && _lastScheduleStatus[scheduleId] != ss) {
        _lastScheduleStatus[scheduleId] = ss;
        final msg = switch (ss) {
          0 => 'Schedule window expired',
          _ => null,
        };
        if (msg != null) getsuccessSnackBar(msg);
      }

      final idx = schedules.indexWhere((r) => _deviceSlot(r) == scheduleId);
      if (idx == -1) return;

      final stEpoch = data['startEpoch'] as int?;
      final etEpoch = data['endEpoch'] as int?;
      final runtime = data['runtime'] as int?;

      schedules[idx] = schedules[idx].copyWith(
        actualRunTime: runtime,
        actualStartTime:
            (stEpoch != null && stEpoch > 0) ? _epochToTimeStr(stEpoch) : null,
        actualEndTime:
            (etEpoch != null && etEpoch > 0) ? _epochToTimeStr(etEpoch) : null,
        deviceScheduleStatus: ss,
      );
      schedules.refresh();
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

      final ackCode = ack['ack_code'] as int? ?? (ack['D'] as int? ?? 0);
      if (ackCode != 1) {
        final msg = MqttService.scheduleAckErrorMessage(ackCode);
        if (msg != null) geterrorSnackBar(msg);
        debugPrint('↪️ Schedule ACK failed — ack=$ackCode');
        if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
          _republishCompleter!.complete(false);
          _republishCompleter = null;
          _showScheduleResultAfterDelay(<int>[]);
        }
        return;
      }

      final ackedDeviceSlots =
          (ack['schedule_ids'] as List?)?.whereType<int>().toList() ?? <int>[];
      final ackedScheduleIds = _slotToScheduleId.isEmpty
          ? ackedDeviceSlots
          : ackedDeviceSlots
              .map((slot) => _slotToScheduleId[slot])
              .whereType<int>()
              .toList();

      debugPrint(
          'ACK device slots: $ackedDeviceSlots -> scheduleIds: $ackedScheduleIds');

      // Cache the exact set the device confirmed so the manage controller
      // can patch only those records (not the full payload it sent).
      _lastAckedScheduleIds = List<int>.from(ackedScheduleIds);

      // Strict: only acknowledge the exact scheduleIds the device named.
      // Never fall back to "all schedules" — that wrongly flips earlier
      // PENDING schedules to scheduled when the user later creates a new one
      // and the device only ACKs that single new id.
      if (ackedScheduleIds.isEmpty) {
        debugPrint('⚠️ ACK has no schedule_ids — skipping acknowledgement');
        if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
          _republishCompleter!.complete(false);
          _republishCompleter = null;
        }
        return;
      }

      final isRepublishInFlight =
          _republishCompleter != null && !_republishCompleter!.isCompleted;
      if (isRepublishInFlight) {
        try {
          await fetchSchedules(silent: true);
        } catch (_) {}

        if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
          _republishCompleter!.complete(true);
          _republishCompleter = null;
          _showScheduleResultAfterDelay(ackedScheduleIds);
        }
        return;
      }

      try {
        await fetchSchedules(silent: true);
      } catch (_) {}

      onScheduleAckRefreshed?.call();
    });
  }

  void _listenScheduleFinalResult() {
    _scheduleFinalResultSubscription?.cancel();
    _scheduleFinalResultSubscription =
        _mqttService.scheduleFinalResultStream.listen((result) {
      final currentId = _resolveIdentifier();
      final ackId = (result['topic'] ?? '').toString();
      if (currentId.isNotEmpty && ackId != currentId) return;

      final expected =
          (result['expected'] as List?)?.whereType<int>().toList() ?? <int>[];
      final acked =
          (result['acked'] as List?)?.whereType<int>().toList() ?? <int>[];

      // Clear any stale tracking from the create-flow priming so a later
      // ACK can't re-fire the toast helper.
      _expectedScheduleIds = [];

      // Single-schedule create: device-level ACK already drives the inline
      // success/error UI. No bottom toast.
      if (expected.length <= 1) return;

      final ackedSet = acked.toSet();
      final successCount = expected.where(ackedSet.contains).length;
      final failedCount = expected.length - successCount;
      showScheduleResultSnackBar(
        total: expected.length,
        successCount: successCount,
        failedCount: failedCount,
      );
    });
  }

  void _listenScheduleActionFinalResult() {
    _scheduleActionFinalResultSubscription?.cancel();
    _scheduleActionFinalResultSubscription =
        _mqttService.scheduleActionFinalResultStream.listen((result) async {
      final currentId = _resolveIdentifier();
      final ackId = (result['topic'] ?? '').toString();
      if (currentId.isNotEmpty && ackId != currentId) return;

      final expected =
          (result['expected'] as List?)?.whereType<int>().toList() ?? <int>[];
      final acked =
          (result['acked'] as List?)?.whereType<int>().toList() ?? <int>[];
      final cmd = result['cmd'] as int?;
      final ackCode = result['ack_code'] as int?;
      if (expected.isEmpty || cmd == null) return;

      // Cleanup pendingActions for every expected id, regardless of ack.
      for (final sid in expected) {
        _pendingActions.remove(sid);
      }

      final key = _bulkKey(expected);
      final ackedSet = acked.toSet();
      final isFullSuccess = expected.every(ackedSet.contains);

      // Map only the acked scheduleIds to their object ids for the API call.
      final objectIdMap = _bulkObjectIds.remove(key) ?? {};
      _bulkCmds.remove(key);
      final ackedObjectIds = <int>[
        for (final entry in objectIdMap.entries)
          if (ackedSet.contains(entry.key)) entry.value,
      ];

      // Run the API for whatever the device confirmed, even on partial.
      if (ackedObjectIds.isNotEmpty) {
        try {
          if (cmd == 3) {
            await _scheduleRepo.bulkDeleteSchedules(ackedObjectIds);
          } else if (cmd == 1) {
            await _scheduleRepo.bulkStopSchedules(ackedObjectIds);
          } else if (cmd == 2) {
            await _scheduleRepo.bulkRestartSchedules(ackedObjectIds);
          }
        } catch (_) {
          // silently fail — the toast / completer below still reflect device truth
        }
      }

      // Toast only for genuine bulk operations (>1 schedule). Singles fall
      // through their own ACK listener and never reach this handler.
      if (expected.length > 1) {
        final successCount = expected.where(ackedSet.contains).length;
        final failedCount = expected.length - successCount;
        showScheduleResultSnackBar(
          total: expected.length,
          successCount: successCount,
          failedCount: failedCount,
        );
      } else if (!isFullSuccess && ackCode != null) {
        // expected.length == 1 (bulk wrapper around a single schedule) and
        // device returned an error — surface its specific message.
        final msg = MqttService.scheduleActionAckErrorMessage(ackCode);
        if (msg != null) geterrorSnackBar(msg);
      }

      // Resolve whichever bulk completer was awaiting this key.
      _bulkDeleteCompleters.remove(key)?.complete(isFullSuccess);
      _bulkToggleCompleters.remove(key)?.complete(isFullSuccess);

      fetchSchedules(silent: true);
    });
  }
}
