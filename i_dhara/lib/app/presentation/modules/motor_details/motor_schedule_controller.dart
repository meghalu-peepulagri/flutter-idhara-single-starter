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

  // Failed schedules are terminal device-side and don't occupy a slot,
  // so they're excluded from the per-date cap. Use this everywhere the
  // "schedules currently using a slot" count is needed (FAB cap, create
  // page initial count).
  int get activeScheduleCount => schedules
      .where((r) => (r.scheduleStatus ?? '').toLowerCase() != 'failed')
      .length;
  late final Rx<DateTime> selectedDate;

  final scrollController = ScrollController();

  // Persists colored dots across widget remounts (keyed by date, value = set of status colors)
  final Map<DateTime, Set<Color>> dateBars = {};

  // Track pending actions: scheduleId -> cmd (1=stop, 2=restart, 3=delete)
  final _pendingActions = <int, int>{};

  // Completers for delete (cmd=3): resolved when ACK arrives
  final _deleteCompleters = <int, Completer<bool>>{};

  // scheduleId → backend object id captured when deleteSchedule is invoked.
  // _deleteScheduleAfterAck reads from this instead of the local `schedules`
  // list, which is scoped to selectedDate and resolves to the wrong record
  // when the manage page deletes a row on a different date.
  final _pendingDeleteObjectIds = <int, int>{};

  // Completers for stop/restart (cmd=1/2): resolved after ACK + post API
  final _toggleCompleters = <int, Completer<bool>>{};

  // Bulk completers: key = sorted scheduleIds joined by comma
  final _bulkDeleteCompleters = <String, Completer<bool>>{};
  final _bulkToggleCompleters = <String, Completer<bool>>{};

  // Completer for republish — resolved when create-ACK arrives after republish.
  Completer<bool>? _republishCompleter;

  // ScheduleIds we expect ACKs for from the in-flight publish. Compared
  // against the device's ACK bitmask to compute partial / full success for
  // the bottom result snackbar. Cleared after the toast fires.
  List<int> _expectedScheduleIds = [];

  // Maps the MQTT id we published (device slot, 1..15) → the unique
  // schedule_id of that row. The device ACKs the device slot, so we translate
  // it back to schedule_id before matching records (slots get reused, but
  // schedule_id is unique). Set on every publish / republish round.
  final Map<int, int> _slotToScheduleId = {};

  // Called after a non-republish schedule-create ACK refresh completes.
  // ScheduleManagePageState sets this to refresh its own list without waiting.
  VoidCallback? onScheduleAckRefreshed;

  // Bulk metadata: bulkKey → {scheduleId: objectId}, bulkKey → cmd
  final _bulkObjectIds = <String, Map<int, int>>{};
  final _bulkCmds = <String, int>{};

  // ScheduleIds the device most recently ACK'd via T:33. Manage controller
  // reads this through [lastAckedScheduleIds] after `republishSchedules`
  // returns and patches only the subset that actually landed on the device
  // — not the full payload we sent. The device may accept some entries and
  // reject others (e.g. payload bitmask 28 with ACK bitmask 24 means
  // schedule 3 was rejected); patching rejected entries to SCHEDULED on
  // the backend would lie about device state. Reset at the start of each
  // republish so a stale value from a prior round can't leak into the next.
  List<int> _lastAckedScheduleIds = [];
  List<int> get lastAckedScheduleIds =>
      List<int>.unmodifiable(_lastAckedScheduleIds);

  /// Converts a DateTime to YYMMDD int format (e.g. 2026-03-17 → 260317)
  static int dateToYYMMDD(DateTime d) =>
      (d.year % 100) * 10000 + d.month * 100 + d.day;

  String _bulkKey(List<int> scheduleIds) =>
      (List<int>.from(scheduleIds)..sort()).join(',');

  /// The device addresses each schedule by its SLOT (1..15) — the
  /// `device_schedule_id` — which is what the T:24 bitmask and the
  /// device ACKs use. The backend `schedule_id` grows monotonically and
  /// diverges from the slot once any schedule is deleted and its slot is
  /// reused. Every device-facing action (stop/restart/delete) must key off
  /// the slot, not `schedule_id`, or the bitmask points at the wrong slot
  /// (e.g. schedule_id 3 / slot 2 sent bit 4 instead of 2). Falls back to
  /// `scheduleId` for legacy rows that predate `device_schedule_id`.
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
    // `silent` = pull data in the background without flipping isLoading /
    // isRefreshing — used right after a T:33 ACK so the schedule tab does
    // NOT swap the list out for AppLottieLoading. The Obx on `schedules`
    // already redraws the cards when the new data lands.
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
      geterrorSnackBar('Failed to send command: $e');
    }
  }

  /// API-only delete for PENDING / FAILED rows. The device never
  /// accepted these schedules, so there's no slot to clear over MQTT —
  /// just drop the backend record and remove it from the local list.
  /// Returns true on a successful API response.
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

  /// API-only bulk delete for a set of PENDING / FAILED rows. Mirrors
  /// [deleteScheduleApiOnly] but goes through the bulk endpoint so a
  /// multi-row clear is a single network round-trip.
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

  /// Delete: publish MQTT cmd:3, wait for ACK + API, then return.
  /// Dialog stays loading until this resolves.
  Future<bool> deleteSchedule(Record record) async {
    final scheduleId = _deviceSlot(record);
    // Guard: skip if this schedule already has an in-flight action from any path.
    if (_pendingActions.containsKey(scheduleId)) return false;
    final completer = Completer<bool>();
    _deleteCompleters[scheduleId] = completer;
    _pendingDeleteObjectIds[scheduleId] = record.id ?? 0;
    await publishScheduleAction(record, 3);
    return completer.future.timeout(
      // Matches MQTT retry cycle (10s + 10s + 3s) so the dialog only closes
      // once the retry loop has fully exhausted.
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

  /// Stop/Restart: publish MQTT cmd:1 (stop) or cmd:2 (restart),
  /// wait for ACK, then call stop/restart API.
  /// Returns true on success, false on failure.
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

  /// Publish a single MQTT T:24 for multiple schedules (combined bitmask).
  /// Always opts into expected-id tracking so partial T:54 ACKs trigger
  /// the 5/5/3 retry cycle and the final-result toast. The bulk completer
  /// is resolved by [_listenScheduleActionFinalResult], not by individual
  /// ACK arrivals.
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

  /// Bulk delete: send a single MQTT cmd:3 for all records, wait for ACK,
  /// then call DELETE /motor-schedules/bulk API.
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
      geterrorSnackBar('Failed to send command: $e');
      return false;
    }

    return completer.future.timeout(
      // 5s buffer over the MQTT retry cycle (10 + 10 + 3 = 23s). MQTT
      // emits its final result at exactly T=23s; matching the timeout to
      // that boundary races with the listener — Dart runs the
      // synchronous onTimeout before the streamed listener microtask, so
      // _bulkObjectIds gets cleared and the bulkDeleteSchedules call for
      // the partially-acked subset is skipped. The buffer keeps the
      // listener in front of the timeout in the partial case.
      const Duration(seconds: 28),
      onTimeout: () {
        _bulkDeleteCompleters.remove(key);
        // Intentionally do NOT remove _bulkObjectIds[key] or _bulkCmds[key].
        // _listenScheduleActionFinalResult is the source of truth for the
        // bulk delete API call and needs the scheduleId→objectId map +
        // cmd to drive it; it cleans them up itself when its event lands.
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
      geterrorSnackBar('Failed to send command: $e');
      return false;
    }

    return completer.future.timeout(
      // 5s buffer over the MQTT retry cycle (10 + 10 + 3 = 23s). See
      // deleteBulkSchedules above for the full reasoning — short version:
      // at exactly 23s the controller's onTimeout cleared _bulkObjectIds
      // before _listenScheduleActionFinalResult could read it, so the
      // bulkStopSchedules / bulkRestartSchedules call for the partially
      // acked subset was skipped.
      const Duration(seconds: 28),
      onTimeout: () {
        _bulkToggleCompleters.remove(key);
        // Keep _bulkObjectIds[key] and _bulkCmds[key] — the listener owns
        // their cleanup once the MQTT final-result event arrives. See
        // deleteBulkSchedules for the rationale.
        for (final sid in scheduleIds) _pendingActions.remove(sid);
        geterrorSnackBar('No response from device');
        return false;
      },
    );
  }

  /// Cancel ALL in-flight schedule operations on this motor (bulk
  /// stop/restart/delete + republish + any pending single action).
  ///
  /// Called when the user taps Cancel on the bulk confirmation dialog while
  /// the MQTT retry loop is still in-flight. Without this, the controller's
  /// `.timeout()` on the awaiting completer would fire 23s later and show
  /// the stale "No response from device" snackbar — even though the user
  /// already dismissed the dialog. Steps:
  ///   1. Cancel both T:23 (create / republish) and T:24 (action) retries
  ///      in MqttService so `scheduleAckTimeoutController` never emits.
  ///   2. Resolve every awaiting completer with `false` so the controller's
  ///      `.timeout()` short-circuits and no snackbar is rendered.
  ///   3. Drop tracked state (`_pendingActions`, bulk maps,
  ///      `_expectedScheduleIds`) so any late ACK that does arrive can't
  ///      re-trigger a toast or API call.
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

  /// Cancel an in-flight schedule action (stop / restart / delete).
  /// Called when the user taps Cancel in the confirmation dialog while we're
  /// still waiting on the device ACK. Stops the MQTT retry loop and resolves
  /// the awaiting completer with `false` so the dialog's future returns
  /// immediately and the dialog can be dismissed.
  void cancelPendingScheduleAction(Record record) {
    // Pending maps are keyed by the device SLOT the action was published
    // with, not the backend schedule_id.
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

        // Bulk actions are now driven by [_listenScheduleActionFinalResult]
        // — that handler waits for the MQTT layer to emit a single result
        // (full coverage or retry exhaustion) and runs the API + completer
        // + partial toast there. Skip bulk traffic here so we don't fire
        // a single-action top snackbar on partial bulk ACKs (e.g. 1 of 2
        // acked) — those previously slipped through because their bulk
        // key didn't match the partial ackedIds set.
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

        // Unexpected mismatch — receivedAckCmd is neither the expected cmd
        // nor a known error code. Likely a stale ACK from a different
        // command; ignore so we don't fail the in-flight operation.
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
            // `scheduleId` here is the device SLOT the ACK named, so match
            // records by their slot, not the backend schedule_id.
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
            // Reconcile in the background — no isLoading flip, so the
            // schedule list area doesn't flash to the lottie loader after
            // the user already saw the action confirmation.
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
    // Use the objectId captured when deleteSchedule(record) was invoked.
    // Looking it up from the local `schedules` list by scheduleId is
    // unsafe — that list is scoped to selectedDate, so a delete coming
    // from the manage page for a different date can resolve to the
    // wrong record (the DELETE API would then target the wrong row, or
    // fall back to a stale SharedPreference value).
    final objectId = _pendingDeleteObjectIds.remove(scheduleId) ?? 0;
    // `scheduleId` here is the device SLOT — match the local row by slot.
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
    // Pass how many schedules already cover the selected date so the create
    // page can cap "+ Add Schedule" at the remaining slot count.
    // Failed schedules don't occupy a device slot, so exclude them — the
    // user gets that many extra chances to add a fresh schedule.
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

  /// Republish a T:3 MQTT command for the given schedule records.
  /// Used by Schedule Manage page to re-send PENDING schedules to the device.
  /// `idx` = 1 only when the device has NO accepted schedules yet (every
  /// schedule for this motor is still PENDING). If even one schedule has
  /// already been placed on the device (SCHEDULED / RUNNING / STOPPED /
  /// COMPLETED), the caller must pass `idx: 2` so the device appends to
  /// its existing slots instead of overwriting them.
  Future<bool> republishSchedules(List<Record> records, {int idx = 2}) async {
    if (records.isEmpty) return false;
    // MQTT republish removed. The records already exist on the backend and the
    // device sync is handled server-side, so nothing is published from here.
    _lastAckedScheduleIds = [];
    return true;
  }

  /// Resync via the backend `/motor-schedules/bulk/republish` API — the same
  /// endpoint the manage page's bulk resync uses. Sends the records' object
  /// ids; the backend publishes to the device. Returns true once the POST
  /// completes so the card's confirm dialog closes.
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

  /// Compares the in-flight expected scheduleIds against the device's acked
  /// list and, 3s after retries finish, surfaces a bottom snackbar summarising
  /// success / partial / failure counts. Empty `ackedScheduleIds` means the
  /// retry loop exhausted with no ACK at all.
  void _showScheduleResultAfterDelay(List<int> ackedScheduleIds) {
    if (_expectedScheduleIds.isEmpty) return;
    final expected = List<int>.from(_expectedScheduleIds);
    _expectedScheduleIds = [];
    // Single-record republish doesn't need the X-of-Y counts toast —
    // the top "Schedules acknowledged by device" snackbar already
    // conveys success for one row, and the toast just doubles up the
    // visual noise. Keep the toast for multi-record publishes where
    // the per-row breakdown is actually useful.
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
        _showScheduleResultAfterDelay(<int>[]);
      }
      // Multi-create timeout is handled by _listenScheduleFinalResult — the
      // MQTT service routes tracked publishes through the final-result
      // stream instead of this timeout stream.
    });
  }

  void _listenScheduleLiveData() {
    _scheduleLiveDataSubscription?.cancel();
    _scheduleLiveDataSubscription =
        _mqttService.scheduleLiveDataStream.listen((data) {
      final scheduleId = data['scheduleId'] as int?;
      if (scheduleId == null) return;

      // The live-data `sch.id` is the DEVICE slot (device_schedule_id),
      // not the backend schedule_id — match the row by its device slot.
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
        // Device-side error — surface the specific message and stop here.
        // For tracked multi-create, _listenScheduleFinalResult will still
        // render the bottom counts toast; for republish, resolve the
        // completer so the loading dialog closes.
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

      // The device ACKs the MQTT id it received (the device slot, 1..15 —
      // reused across creates). Translate each slot back to the UNIQUE
      // schedule_id of the row we published with it, so we match the right
      // record (never an old one that happens to share a low schedule_id).
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

      // ── Republish path (manage page) ──────────────────────────────────
      // When a republish is in flight, the manage controller owns the
      // PATCH. scheduleId is a per-date device SLOT index (1..N), not a
      // globally unique key — so filtering motor's local list (scoped
      // to selectedDate) by `ackedScheduleIds.contains(r.scheduleId)`
      // would match records on a DIFFERENT date than the one actually
      // resynced.
      //
      // Concrete bug this prevents: manage page resyncs dates 27/28/29
      // with slots 6/8/9; device ACKs bitmask 416 → [6, 8, 9]; motor's
      // selectedDate happens to be 30; motor's local list for date 30
      // also has PENDING rows on slots 6/8/9 — those wrong-date rows
      // would otherwise be PATCHed to SCHEDULED here, even though the
      // device only accepted the date-27/28/29 entries.
      //
      // Manage controller already patches the right rows by backend
      // object id (which IS globally unique). We just refresh motor's
      // list silently so any rows that DID belong to the resync round
      // (i.e. rows on selectedDate that were part of the published
      // batch) pick up the new status from the backend.
      final isRepublishInFlight =
          _republishCompleter != null && !_republishCompleter!.isCompleted;
      if (isRepublishInFlight) {
        try {
          await fetchSchedules(silent: true);
        } catch (_) {}

        if (_republishCompleter != null && !_republishCompleter!.isCompleted) {
          // Skip the controller-side snackbar — the manage page
          // fires 'Schedules resynced successfully' from its
          // dialog `.then()` after the dialog closes, and that's
          // the single top message we want on republish success.
          // Bottom count toast (`_showScheduleResultAfterDelay`
          // → `showScheduleResultSnackBar`) is untouched.
          _republishCompleter!.complete(true);
          _republishCompleter = null;
          _showScheduleResultAfterDelay(ackedScheduleIds);
        }
        return;
      }

      // ── Create / republish ACK path ──────────────────────────────────
      // No backend acknowledgement PATCH (/bulk/ack) from the app — create
      // and republish (resync) no longer forward the device ACK to the
      // backend. We just refresh the list silently so any status the
      // backend updated server-side is picked up. (Delete / stop / restart
      // use the separate T:24 action-ack listener and are unaffected.)
      // silent: true → no isLoading flip → list stays put, no lottie reload.
      try {
        await fetchSchedules(silent: true);
      } catch (_) {}

      onScheduleAckRefreshed?.call();
    });
  }

  /// Listens for the per-session final-result event the MQTT service emits
  /// for tracked multi-schedule publishes. Fires once at full coverage or
  /// when retries exhaust. Skips single-create (expected.length <= 1) per
  /// product requirement: only multi-schedule create surfaces the toast.
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

  /// Final-result handler for bulk T:24 actions (delete / stop / resume).
  /// Fires once per bulk publish at full coverage or retry exhaustion.
  /// Drives the API call (only for the actually-acked records), resolves the
  /// awaiting bulk completer, and surfaces the partial / full result toast
  /// when more than one schedule was involved. Single-schedule actions
  /// don't track expected ids, so they never reach this listener and never
  /// show the toast.
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

      // Silent reconcile — the manage page drives its own list refresh
      // via onScheduleAckRefreshed; we just need our motor-tab list to
      // catch up without flashing the lottie loader.
      fetchSchedules(silent: true);
    });
  }
}
