import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/mqtt_utils.dart';
import 'package:i_dhara/app/core/utils/schedule_utils/schedule_utils.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_card.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_dialogs.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  GlobalKey<ScheduleFormState> _formKey = GlobalKey<ScheduleFormState>();
  GlobalKey<MultiScheduleFormState> _multiFormKey =
      GlobalKey<MultiScheduleFormState>();
  final _mqttService = MqttService();
  final _scheduleRepo = ScheduleRepositoryImpl();
  late final ScheduleController _scheduleController;
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSub;
  // MQTT exhausts its retry loop (5s + 5s + 3s ≈ 13s) before our 30s
  // completer would otherwise fire — listen to the timeout stream so we
  // can resolve the completer as soon as that happens and close the dialog.
  StreamSubscription<String>? _scheduleAckTimeoutSub;
  Completer<bool>? _ackCompleter;
  // ScheduleIds the create / edit flow most recently published. The ACK
  // listener uses this to decide whether an inbound T:33 corresponds to
  // our pending publish (so the create dialog's countdown can resolve
  // the moment the device acknowledges any of them).
  Set<int> _expectedAckScheduleIds = <int>{};
  Motor? motor;
  Record? _editRecord;
  bool _isEditMode = false;
  // Schedules already created for the selected date — caps the number of new
  // entries the multi-create form allows. Default 0 means "no existing
  // schedules", giving the form the full 4-slot allowance.
  int _existingScheduleCount = 0;

  @override
  void initState() {
    super.initState();
    _scheduleController = Get.put(ScheduleController());
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      motor = args['motor'] as Motor?;
      _editRecord = args['record'] as Record?;
      _isEditMode = _editRecord != null;
      _existingScheduleCount =
          (args['existingScheduleCount'] as int?) ?? 0;
    }
    // ACK listeners are wired for BOTH create and edit modes — the create
    // confirm dialog now stays open during the 23s ACK window, so it needs
    // the same plumbing the edit flow already used.
    _scheduleAckTimeoutSub =
        _mqttService.scheduleAckTimeoutStream.listen((timedOutId) {
      if (!mounted) return;
      final currentId = _resolveIdentifier();
      if (currentId.isNotEmpty && timedOutId != currentId) return;
      if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
        _ackCompleter!.complete(false);
      }
    });
    _scheduleAckSub = _mqttService.scheduleAckStream.listen((ack) {
      if (!mounted) return;
      final currentId = _resolveIdentifier();
      final ackId = (ack['topic'] ?? '').toString();
      if (currentId.isNotEmpty && ackId != currentId) return;

      final ackedScheduleIds = (ack['schedule_ids'] as List?)
              ?.whereType<int>()
              .toList() ??
          <int>[];
      final ackCode = ack['ack_code'] as int? ?? (ack['D'] as int? ?? 0);

      // Edit uses the editing record's id; create uses the scheduleIds we
      // just published (single OR multi). The "no list" legacy case is also
      // accepted as a success.
      final expected = _isEditMode
          ? <int>{_editRecord?.scheduleId ?? 0}
          : _expectedAckScheduleIds;
      final isSuccess = ackCode == 1 &&
          (ackedScheduleIds.isEmpty ||
              ackedScheduleIds.any(expected.contains));

      if (isSuccess && _ackCompleter != null && !_ackCompleter!.isCompleted) {
        _ackCompleter!.complete(true);
      } else if (ackCode != 1 &&
          _ackCompleter != null &&
          !_ackCompleter!.isCompleted) {
        _ackCompleter!.complete(false);
      }
    });
  }

  @override
  void dispose() {
    _scheduleAckSub?.cancel();
    _scheduleAckTimeoutSub?.cancel();
    if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
      _ackCompleter!.complete(false);
    }
    super.dispose();
  }

  String _resolveIdentifier() {
    final deviceAlloc = motor?.starter?.deviceAllocation ?? 'false';
    final pcb = motor?.starter?.pcbNumber?.trim() ?? '';
    final mac = motor?.starter?.macAddress?.trim() ?? '';
    return getMotorIdentifier(deviceAlloc, pcb, mac);
  }

  /// Aborts whatever publish is currently waiting for an ACK. Wired into
  /// the create / edit confirm dialogs as `onCancelWhileWaiting` so the
  /// user can cancel mid-countdown:
  ///   1. Stops the MQTT T:23 retry loop in the service so no late ACK or
  ///      "No response from device" snackbar arrives after the user gave up.
  ///   2. Resolves [_ackCompleter] with `false` so the awaiting future
  ///      short-circuits — the create flow returns early, the backend POST
  ///      is skipped, and `_scheduleSaved` stays false (no nav back).
  void _cancelInFlightCreate() {
    final id = _resolveIdentifier();
    if (id.isNotEmpty) {
      _mqttService.cancelScheduleCreateRetries(id);
    }
    if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
      _ackCompleter!.complete(false);
    }
    _ackCompleter = null;
    _expectedAckScheduleIds = <int>{};
  }

  bool _scheduleSaved = false;

  String _formatDateStr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  int _dateToYYMMDD(DateTime d) =>
      (d.year % 100) * 10000 + d.month * 100 + d.day;

  String _formatTimeHHMM(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}';

  DateTime? _yymmddToDate(int? v) {
    if (v == null) return null;
    final yy = v ~/ 10000;
    final mm = (v % 10000) ~/ 100;
    final dd = v % 100;
    return DateTime(2000 + yy, mm, dd);
  }

  // Bitwise: Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64
  static const _bitwiseMap = {
    0: 1, // Sunday
    1: 2, // Monday
    2: 4, // Tuesday
    3: 8, // Wednesday
    4: 16, // Thursday
    5: 32, // Friday
    6: 64, // Saturday
  };

  int _computeBitwiseDays(List<int> daysOfWeek) =>
      daysOfWeek.fold(0, (acc, d) => acc | (_bitwiseMap[d] ?? 0));

  /// Returns the `idx` value sent in the T:3 publish:
  ///   • `1` ⇒ first-time create — the device has nothing to append to.
  ///   • `2` ⇒ append — the device already has at least one accepted slot.
  ///
  /// PENDING and FAILED rows live only in the app database; the device never
  /// acknowledged them. Sending `idx: 2` in that case makes the device think
  /// it should append to existing slots that don't exist, and it rejects the
  /// payload with a mismatch ACK. So `idx: 2` is gated on at least one schedule
  /// being in a status the device has accepted (SCHEDULED / RUNNING / STOPPED /
  /// COMPLETED / PARTIAL).
  int _mqttIdx() {
    if (!Get.isRegistered<MotorScheduleController>()) return 1;
    final existing = Get.find<MotorScheduleController>().schedules;
    final hasDeviceAccepted = existing.any((r) {
      final s = (r.scheduleStatus ?? '').toLowerCase();
      if (s.isEmpty) return false;
      return s != 'pending' && s != 'failed';
    });
    return hasDeviceAccepted ? 2 : 1;
  }

  /// Returns [count] scheduleIds for new schedules.
  ///
  /// "Occupied" slots are existing schedules whose status is **not** in
  /// the reusable set (`FAILED`, `MISSED`, `COMPLETED`). Those three
  /// statuses free their slot up — a freshly-created schedule can take
  /// over the same id, which is what the user expects when a missed /
  /// failed / finished run is replaced by a new one.
  ///
  /// Allocation order:
  ///   1. Fill free slots inside `[1..maxId]` ascending (gaps + reusable
  ///      ids from the statuses above).
  ///   2. Once those are exhausted, continue from `maxId + 1`.
  ///
  /// Examples (with no reusable statuses):
  ///   existing = [1, 3],     count = 2 → [2, 4]
  ///   existing = [1, 2, 3],  count = 2 → [4, 5]
  ///   existing = [],         count = 3 → [1, 2, 3]
  ///
  /// Examples with reusable statuses (id 2 is FAILED, id 3 is MISSED):
  ///   existing = [1, 2(failed), 3(missed), 4(scheduled)], count = 2 → [2, 3]
  ///   existing = [1(scheduled), 2(completed)],            count = 3 → [2, 3, 4]
  Future<List<int>> _computeScheduleIds(int count) async {
    // Statuses whose slots are considered free for re-allocation. PENDING
    // is intentionally not in here — it means the device hasn't acked the
    // schedule yet, but its id is still in-flight and shouldn't be reused.
    const reusableStatuses = {'FAILED', 'MISSED', 'COMPLETED'};

    // Pull every existing schedule for this motor — no date filter — so we
    // see ids across all dates. The in-memory MotorScheduleController list
    // is filtered to a single selectedDate, which made the previous
    // synchronous version miss ids from other dates (e.g. user creates on
    // 14/15 → ids 1..4, opens create for 16 → controller list looked
    // empty → started back at 1).
    final occupied = <int>{};
    var maxSeenId = 0;
    try {
      // High limit (1000) is enough for a motor's lifetime schedule
      // history; if a motor ever exceeds this we'll need pagination here.
      final response = await _scheduleRepo.getScheduleList(1, 1000);
      final records = response?.data?.records ?? <Record>[];
      for (final s in records) {
        final sid = s.scheduleId;
        if (sid == null || sid <= 0) continue;
        if (sid > maxSeenId) maxSeenId = sid;
        final status = (s.scheduleStatus ?? '').toUpperCase();
        if (reusableStatuses.contains(status)) continue; // free slot
        occupied.add(sid);
      }
    } catch (_) {
      // Network failure → fall back to whatever the controller has cached
      // so we don't block the create flow.
      if (Get.isRegistered<MotorScheduleController>()) {
        for (final s in Get.find<MotorScheduleController>().schedules) {
          final sid = s.scheduleId;
          if (sid == null || sid <= 0) continue;
          if (sid > maxSeenId) maxSeenId = sid;
          final status = (s.scheduleStatus ?? '').toUpperCase();
          if (reusableStatuses.contains(status)) continue;
          occupied.add(sid);
        }
      }
    }

    if (maxSeenId == 0) {
      // No prior schedules at all — start from id 1.
      return List.generate(count, (i) => i + 1);
    }

    // Free slots inside [1..maxSeenId]: gap ids plus reusable-status ids.
    final freeSlots = [
      for (int i = 1; i <= maxSeenId; i++)
        if (!occupied.contains(i)) i,
    ];

    final result = <int>[];
    for (final free in freeSlots) {
      if (result.length == count) break;
      result.add(free);
    }
    var next = maxSeenId + 1;
    while (result.length < count) {
      result.add(next++);
    }
    return result;
  }

  CreateScheduleDto _buildDto(ScheduleFormState form, {required int scheduleId}) {
    final isCyclic = form.cyclicMode;
    return CreateScheduleDto(
      motorId: SharedPreference.getMotorId(),
      starterId: SharedPreference.getStarterId(),
      scheduleType: isCyclic ? 'CYCLIC' : 'TIME_BASED',
      startTime: _formatTimeHHMM(form.startHour, form.startMinute),
      endTime: isCyclic ? null : _formatTimeHHMM(form.endHour, form.endMinute),
      scheduleStartDate: _dateToYYMMDD(form.startDate),
      scheduleEndDate: _dateToYYMMDD(form.endDate),
      cycleOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
      cycleOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
      daysOfWeek: form.selectedDays.toList()..sort(),
      bitwiseDays: _computeBitwiseDays(form.selectedDays.toList()),
      runtimeMinutes: form.durationMinutes,
      powerLossRecovery: isCyclic ? false : form.powerLossRecovery,
      repeat: 0,
      enabled: true,
      scheduleId: scheduleId,
    );
  }

  /// Returns:
  ///   `null`           → backend POST committed. Dialog pops and the
  ///                      caller navigates to the schedule list regardless
  ///                      of whether the device ACKed. Rows without an ACK
  ///                      stay in 'pending' status — visible in the list.
  ///   `'message'`      → backend POST rejected → dialog shows inline
  ///                      banner; no navigation.
  ///
  /// Order of operations: POST /motor-schedules → MQTT T:23 publish →
  /// wait for T:33 ACK → PATCH /motor-schedules/bulk/ack. MQTT and the
  /// ack PATCH are best-effort; only the POST gates success.
  Future<String?> _createSchedule() async {
    final form = _formKey.currentState!;

    // Step 1: POST. This is the only step that can fail the operation.
    final scheduleId = (await _computeScheduleIds(1)).first;
    final dto = _buildDto(form, scheduleId: scheduleId);
    final response = await _scheduleController.createSchedule(dtos: [dto]);
    if (response == null) {
      return _scheduleController.message ?? '';
    }
    final newObjectId = response.data?.id;
    SharedPreference.setscheduleid(newObjectId ?? 0);
    // Row committed — guarantee the parent navigates on close.
    _scheduleSaved = true;

    // Step 2: MQTT publish + wait for T:33 ACK (best-effort). >2 day-out
    // schedules skip MQTT — device gets told closer to run date.
    final id = _resolveIdentifier();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startNorm = DateTime(
        form.startDate.year, form.startDate.month, form.startDate.day);
    final daysDiff = startNorm.difference(todayNorm).inDays;
    final shouldPublishMqtt = id.isNotEmpty && daysDiff <= 2;

    var ackOk = !shouldPublishMqtt;
    if (shouldPublishMqtt) {
      _expectedAckScheduleIds = <int>{scheduleId};
      _ackCompleter = Completer<bool>();

      final isCyclic = form.cyclicMode;
      try {
        await _mqttService.publishScheduleCommand(
          identifier: id,
          scheduleId: scheduleId,
          startTimeHHMM: form.startHour * 100 + form.startMinute,
          endTimeHHMM: form.endHour * 100 + form.endMinute,
          startDateYYMMDD: _dateToYYMMDD(form.startDate),
          endDateYYMMDD: _dateToYYMMDD(form.endDate),
          isCyclic: isCyclic,
          cyclicOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
          cyclicOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
          powerRecovery: (isCyclic ? false : form.powerLossRecovery) ? 1 : 0,
          enabled: 1,
          idx: _mqttIdx(),
        );
        ackOk = await _ackCompleter!.future.timeout(
          const Duration(seconds: 23),
          onTimeout: () => false,
        );
      } catch (_) {
        ackOk = false;
      }
      _ackCompleter = null;
      _expectedAckScheduleIds = <int>{};
    }

    // Step 3: Acknowledgement API — only when the device actually ACKed.
    // Without an ACK the row stays 'pending' on the backend.
    if (ackOk && newObjectId != null) {
      try {
        await _scheduleRepo.scheduleAcknowledgement([newObjectId]);
      } catch (_) {
        // silently fail
      }
    }

    // Only celebrate when the device confirmed (or MQTT was skipped for a
    // far-out schedule). On ACK failure the row is on backend in 'pending'
    // status — the user sees that in the list, no snackbar needed.
    if (ackOk) {
      getsuccessSnackBar('Schedule created successfully');
    }
    return null;
  }

  /// Return contract: `null` → device ACKed AND PATCH committed.
  /// `'message'` → ACK timed out / failed OR backend rejected the
  /// PATCH. The dialog renders the returned string as an inline
  /// banner and stays open so the user can retry.
  ///
  /// Order: MQTT T:23 publish → wait T:54 ACK → PATCH /motor-schedules.
  /// The backend is only touched once the device confirms the change,
  /// so a missing ACK leaves the row unchanged on both sides.
  Future<String?> _updateSchedule() async {
    final form = _formKey.currentState!;
    final id = _resolveIdentifier();

    // Step 1: Publish MQTT T:23 and wait for the device ACK. We do
    // this BEFORE the PATCH so a silent device leaves the backend
    // record untouched — the previous order (PATCH first) updated the
    // app DB even when the device never received the command, which
    // is exactly what the user reported as "auto-updating".
    _ackCompleter = Completer<bool>();
    final isCyclic = form.cyclicMode;
    var ackOk = false;
    try {
      await _mqttService.publishScheduleCommand(
        identifier: id,
        scheduleId: _editRecord?.scheduleId ?? 1,
        startTimeHHMM: form.startHour * 100 + form.startMinute,
        endTimeHHMM: form.endHour * 100 + form.endMinute,
        startDateYYMMDD: _dateToYYMMDD(form.startDate),
        endDateYYMMDD: _dateToYYMMDD(form.endDate),
        isCyclic: isCyclic,
        cyclicOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
        cyclicOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
        powerRecovery: (isCyclic ? false : form.powerLossRecovery) ? 1 : 0,
        enabled: 1,
        isEdit: true,
        idx: 2, // editing means motor already has schedules
      );
      ackOk = await _ackCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
    } catch (_) {
      ackOk = false;
    }
    _ackCompleter = null;

    if (!ackOk) {
      // No device ACK → abort. PATCH is intentionally skipped so the
      // backend record stays consistent with whatever the device is
      // still holding. The dialog shows the returned banner so the
      // user can retry.
      return 'No response from device';
    }

    // Step 2: PATCH /motor-schedules — runs only after the device
    // accepted the new payload. scheduleupdate() builds the PATCH URL
    // from SharedPreference's scheduleid, so prime it from
    // _editRecord.id before the call; otherwise the request hits
    // /motor-schedules/0 or a stale id from the last create / edit.
    SharedPreference.setscheduleid(_editRecord?.id ?? 0);
    final dto = _buildDto(form, scheduleId: _editRecord?.scheduleId ?? 1);
    final response = await _scheduleController.updateSchedule(dto: dto);
    if (response == null) {
      return _scheduleController.message ?? '';
    }
    _scheduleSaved = true;

    // Refresh the list so the user sees the updated row.
    if (Get.isRegistered<MotorScheduleController>()) {
      Get.find<MotorScheduleController>().fetchSchedules();
    }

    getsuccessSnackBar('Schedule updated successfully');
    return null;
  }

  /// Build a single MQTT schedule item for one filtered date. The device
  /// sees `sd == ed == date` and an end-epoch that rolls into the next day
  /// when the slot crosses midnight (so cyclic / overnight windows stay
  /// contiguous).
  Map<String, dynamic> _buildMqttScheduleItem({
    required int scheduleId,
    required DateTime date,
    required ScheduleFormState form,
    required int enabled,
  }) {
    final isCyclic = form.cyclicMode;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      form.startHour,
      form.startMinute,
    );
    var end = DateTime(
      date.year,
      date.month,
      date.day,
      form.endHour,
      form.endMinute,
    );
    // end ≤ start ⇒ the slot wraps midnight; push the end into the next day
    // so st_ep < ed_ep and the device sees a coherent window.
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final stEpoch = start.millisecondsSinceEpoch ~/ 1000;
    final edEpoch = end.millisecondsSinceEpoch ~/ 1000;
    final dateCode = _dateToYYMMDD(date);

    return {
      'id': scheduleId,
      'sd': dateCode,
      'ed': dateCode,
      'st': form.startHour * 100 + form.startMinute,
      'et': form.endHour * 100 + form.endMinute,
      'st_ep': stEpoch,
      'ed_ep': edEpoch,
      'en': enabled,
      if (isCyclic) ...{
        'cy': 1,
        'on': form.cyclicOnMinutes,
        'off': form.cyclicOffMinutes,
        'pwr_rec': 0,
      } else ...{
        'pwr_rec': form.powerLossRecovery ? 1 : 0,
      },
    };
  }

  /// Expand a `startDate..endDate` range against `selectedDays` into the
  /// concrete dates the schedule should actually run on. Empty `days` means
  /// "every date in range"; otherwise only weekdays present in `days` are
  /// kept (Sun=0 .. Sat=6, matching the form's day-index convention).
  List<DateTime> _filteredDates(
      DateTime start, DateTime end, Set<int> days) {
    final out = <DateTime>[];
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final span = e.difference(s).inDays.abs() + 1;
    for (int i = 0; i < span; i++) {
      final d = s.add(Duration(days: i));
      final di = d.weekday == 7 ? 0 : d.weekday;
      if (days.isEmpty || days.contains(di)) out.add(d);
    }
    return out;
  }

  /// Builds the backend DTO for one (slot × filtered date) record. Each
  /// row stores `schedule_start_date == schedule_end_date == that date`,
  /// so the range "14 → 23" with one slot produces 10 separate rows
  /// (14/14, 15/15, …, 23/23). Lines up 1:1 with the per-date MQTT
  /// messages.
  CreateScheduleDto _buildDtoForFilteredDate({
    required ScheduleFormState form,
    required DateTime date,
    required Set<int> selectedDays,
    required int scheduleId,
  }) {
    final isCyclic = form.cyclicMode;
    // Per-date runtime (end − start with overnight wrap rolling end into
    // the next day so the minutes stay positive).
    final durationMinutes = () {
      final startMin = form.startHour * 60 + form.startMinute;
      var endMin = form.endHour * 60 + form.endMinute;
      if (endMin == startMin) return 0;
      if (endMin < startMin) endMin += 1440;
      return endMin - startMin;
    }();
    final dateCode = _dateToYYMMDD(date);
    return CreateScheduleDto(
      motorId: SharedPreference.getMotorId(),
      starterId: SharedPreference.getStarterId(),
      scheduleType: isCyclic ? 'CYCLIC' : 'TIME_BASED',
      startTime: _formatTimeHHMM(form.startHour, form.startMinute),
      endTime: isCyclic ? null : _formatTimeHHMM(form.endHour, form.endMinute),
      scheduleStartDate: dateCode,
      scheduleEndDate: dateCode,
      cycleOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
      cycleOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
      daysOfWeek: selectedDays.toList()..sort(),
      bitwiseDays: _computeBitwiseDays(selectedDays.toList()),
      runtimeMinutes: durationMinutes,
      powerLossRecovery: isCyclic ? false : form.powerLossRecovery,
      repeat: 0,
      enabled: true,
      scheduleId: scheduleId,
    );
  }

  /// Same return contract as [_createSchedule]: `null` → success (rows
  /// committed), `'message'` → backend rejected. ACK failure does not
  /// fail the call — the dialog closes and the caller navigates.
  Future<String?> _createMultipleSchedules() async {
    final multi = _multiFormKey.currentState;
    if (multi == null) return '';

    final forms = multi.scheduleStates;
    if (forms.isEmpty) {
      geterrorSnackBar('No schedules to publish');
      return '';
    }
    if (forms.length != multi.scheduleCount) {
      geterrorSnackBar('Please expand all schedules before publishing');
      return '';
    }

    final sharedStart = multi.startDate;
    final sharedEnd = multi.endDate;
    final sharedDays = multi.selectedDays;

    // Expand the picked range × selectedDays into the concrete dates we'll
    // act on. The backend POST and the MQTT publish both work from this
    // same list so the two stay in sync (every backend row matches a
    // device-side per-date run).
    final filteredDates =
        _filteredDates(sharedStart, sharedEnd, sharedDays);
    if (filteredDates.isEmpty) {
      // Nothing to create — happens only if the user picks a day-of-week
      // filter that excludes the entire range. Surface the validation as
      // a backend-style rejection message so the dialog handles it.
      return 'No matching dates in the selected range';
    }

    // Step 1: POST one row per (slot × filtered date). Schedule IDs are
    // unique across the whole batch (1..N_slots × N_dates) so each backend
    // record gets its own identifier and the device's per-date MQTT
    // messages can address them individually.
    final totalRows = forms.length * filteredDates.length;
    final scheduleIds = await _computeScheduleIds(totalRows);
    final dtos = <CreateScheduleDto>[];
    var idIdx = 0;
    for (final d in filteredDates) {
      for (int i = 0; i < forms.length; i++) {
        dtos.add(_buildDtoForFilteredDate(
          form: forms[i],
          date: d,
          selectedDays: sharedDays,
          scheduleId: scheduleIds[idIdx++],
        ));
      }
    }

    final response = await _scheduleController.createSchedule(dtos: dtos);
    if (response == null) {
      return _scheduleController.message ?? '';
    }

    final ackIds = <int>{};
    if (response.data?.id != null) {
      SharedPreference.setscheduleid(response.data!.id!);
      ackIds.add(response.data!.id!);
    }

    // POST response only carries a single Data, so refresh and collect
    // every backend object id whose scheduleId is in our set.
    if (Get.isRegistered<MotorScheduleController>()) {
      final ctrl = Get.find<MotorScheduleController>();
      try {
        await ctrl.fetchSchedules(silent: true);
        for (final r in ctrl.schedules) {
          if (r.scheduleId != null &&
              scheduleIds.contains(r.scheduleId) &&
              r.id != null) {
            ackIds.add(r.id!);
          }
        }
      } catch (_) {
        // silently fail — fall back to whatever ackIds we already have
      }
    }

    // Rows committed — guarantee navigation on close.
    _scheduleSaved = true;

    // Step 2: MQTT publish + wait for ACK (best-effort).
    //
    // Build one MQTT message per (slot × filtered date), each carrying
    // `sd == ed == that filtered date` and the unique scheduleId that
    // was just POSTed to the backend. publishSchedulesBatched chunks
    // these into groups of 8 with `D.last` as the chunk index and the
    // service's retry timer fires 10s/10s/3s if the device doesn't ACK.
    //
    // The 2-day cutoff is applied PER DATE — dates within 2 days of
    // today are published over MQTT, the rest sit as 'pending' on the
    // backend (they'll be re-published closer to their run date by the
    // sync flow). Backend POST already covers every filtered date, so
    // far-out rows still exist; only the device-side notification is
    // deferred.
    final id = _resolveIdentifier();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Per-date eligibility — keep the same `scheduleIds` allocation
    // order as the DTOs above so each MQTT m1 entry's `id` matches its
    // backend record's `schedule_id`. We collect a flat list of every
    // m1 entry (across dates and slots) and then chunk it into MQTT
    // messages of up to 8 entries each. This way the device sees a
    // single payload for small ranges (range 14→15, 2 slots → 4
    // entries → 1 message with m1[4]) instead of a separate publish
    // per date.
    final allMqttItems = <Map<String, dynamic>>[];
    for (int dIdx = 0; dIdx < filteredDates.length; dIdx++) {
      final d = filteredDates[dIdx];
      final diffDays = d.difference(todayNorm).inDays;
      if (diffDays > 2) continue; // > 2 days out → backend only, no MQTT
      for (int i = 0; i < forms.length; i++) {
        allMqttItems.add(_buildMqttScheduleItem(
          scheduleId: scheduleIds[dIdx * forms.length + i],
          date: d,
          form: forms[i],
          enabled: 1,
        ));
      }
    }

    // Chunk the flat list into MQTT messages of up to 8 m1 entries each.
    // dateMessages[i] is the m1[] of the i-th MQTT message.
    const entriesPerMessage = 8;
    final dateMessages = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < allMqttItems.length; i += entriesPerMessage) {
      final end = (i + entriesPerMessage < allMqttItems.length)
          ? i + entriesPerMessage
          : allMqttItems.length;
      dateMessages.add(allMqttItems.sublist(i, end));
    }

    final shouldPublishMqtt = id.isNotEmpty && dateMessages.isNotEmpty;
    var ackOk = !shouldPublishMqtt;
    if (shouldPublishMqtt) {
      // publishSchedulesBatched sends each MQTT message sequentially (one
      // per batch via batchSize=1), so the per-message retry cycle
      // (10s/10s/3s) stays intact and `D.last` reflects "is this the
      // last payload" — 1 for the only/final message, 0 otherwise.
      // Any successful T:33 short-circuits the retries for that message.
      if (Get.isRegistered<MotorScheduleController>() &&
          allMqttItems.isNotEmpty) {
        Get.find<MotorScheduleController>().trackPendingSchedulePublish(
              items: allMqttItems,
              identifier: id,
              idx: _mqttIdx(),
            );
      }

      _expectedAckScheduleIds = scheduleIds.toSet();

      try {
        ackOk = await _mqttService.publishSchedulesBatched(
          identifier: id,
          dateMessages: dateMessages,
          idx: _mqttIdx(),
        );
      } catch (_) {
        ackOk = false;
      }
      _expectedAckScheduleIds = <int>{};
    }

    // Step 3: Acknowledgement API — only when the device actually ACKed.
    if (ackOk && ackIds.isNotEmpty) {
      try {
        await _scheduleRepo.scheduleAcknowledgement(ackIds.toList());
      } catch (_) {
        // silently fail — schedules are already on backend
      }
    }

    if (ackOk) {
      getsuccessSnackBar('Schedules created successfully');
    }
    return null;
  }

  void _onMultiSaveTapped() async {
    final multi = _multiFormKey.currentState;
    if (multi == null) return;
    final forms = multi.scheduleStates;
    if (forms.isEmpty) {
      geterrorSnackBar('No schedules to publish');
      return;
    }
    if (forms.length != multi.scheduleCount) {
      geterrorSnackBar('Please expand all schedules before publishing');
      return;
    }

    _scheduleSaved = false;
    final items = forms.map((f) {
      return MultiScheduleDialogItem(
        typeLabel: f.cyclicMode ? 'Cyclic' : 'Time Based',
        startTime: formatTime24h(f.startTime),
        endTime: formatTime24h(f.endTime),
        duration: f.durationText,
        powerRecovery: f.powerLossRecovery ? 'ON' : 'OFF',
        isCyclic: f.cyclicMode,
        cyclicOnMinutes: f.cyclicOnMinutes,
        cyclicOffMinutes: f.cyclicOffMinutes,
      );
    }).toList();

    // Count how many times each picked weekday occurs in the date range
    // (e.g. a 14-day range → each day appears twice). The dialog uses these
    // counts to show a small badge on top of the day chip.
    final dayCounts = <int, int>{};
    final totalDays =
        multi.endDate.difference(multi.startDate).inDays.abs() + 1;
    for (int i = 0; i < totalDays; i++) {
      final d = multi.startDate.add(Duration(days: i));
      final wd = d.weekday == 7 ? 0 : d.weekday; // 0=Sun..6=Sat
      if (multi.selectedDays.contains(wd)) {
        dayCounts[wd] = (dayCounts[wd] ?? 0) + 1;
      }
    }

    await showMultiScheduleConfirmDialog(
      context: context,
      startDate: _formatDateStr(multi.startDate),
      endDate: _formatDateStr(multi.endDate),
      schedules: items,
      selectedDays: multi.selectedDays.toList(),
      dayCounts: dayCounts,
      onConfirm: _createMultipleSchedules,
      onCancelWhileWaiting: _cancelInFlightCreate,
    );
    if (_scheduleSaved && mounted) Navigator.of(context).pop(true);
  }

  void _onSaveTapped() async {
    final form = _formKey.currentState;
    if (form == null) return;
    _scheduleSaved = false;
    final isCyclic = form.cyclicMode;

    if (_isEditMode) {
      // Edit reuses the multi-style dialog but collapses the range
      // view: per-date storage means each record covers exactly one
      // day, so we surface a single date pill via the dialog's
      // start==end collapse. No weekday chip is shown — the form
      // already lets the user see and change the date directly.
      await showMultiScheduleConfirmDialog(
        context: context,
        title: 'Edit Schedule',
        description: 'Are you sure you want to update this schedule?',
        startDate: _formatDateStr(form.startDate),
        endDate: _formatDateStr(form.endDate),
        schedules: [
          MultiScheduleDialogItem(
            typeLabel: isCyclic ? 'Cyclic' : 'Time Based',
            startTime: formatTime24h(form.startTime),
            endTime: formatTime24h(form.endTime),
            duration: form.durationText,
            powerRecovery: form.powerLossRecovery ? 'ON' : 'OFF',
            isCyclic: isCyclic,
            cyclicOnMinutes: form.cyclicOnMinutes,
            cyclicOffMinutes: form.cyclicOffMinutes,
          ),
        ],
        onConfirm: _updateSchedule,
        onCancelWhileWaiting: _cancelInFlightCreate,
      );
    } else {
      await showScheduleConfirmDialog(
        context: context,
        typeLabel: isCyclic ? 'Cyclic' : 'Time Based',
        startDate: _formatDateStr(form.startDate),
        endDate: _formatDateStr(form.endDate),
        startTime: formatTime24h(form.startTime),
        endTime: formatTime24h(form.endTime),
        duration: form.durationText,
        powerRecovery: form.powerLossRecovery ? 'ON' : 'OFF',
        isCyclic: isCyclic,
        cyclicOnMinutes: form.cyclicOnMinutes,
        cyclicOffMinutes: form.cyclicOffMinutes,
        onConfirm: _createSchedule,
        onCancelWhileWaiting: _cancelInFlightCreate,
      );
    }
    if (_scheduleSaved && mounted) Navigator.of(context).pop(true);
  }

  (int, int) _parseTime(String? time) {
    if (time == null) return (0, 0);
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length < 2) return (0, 0);
      return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    } else if (time.length >= 3) {
      // "HHMM" or "HMM" — last 2 digits are minutes
      final m = int.tryParse(time.substring(time.length - 2)) ?? 0;
      final h = int.tryParse(time.substring(0, time.length - 2)) ?? 0;
      return (h, m);
    }
    return (0, 0);
  }

  Future<void> _onPullToRefresh() async {
    await _scheduleController.refreshCreateSchedulePage();
    if (!mounted) return;
    setState(() {
      _formKey = GlobalKey<ScheduleFormState>();
      _multiFormKey = GlobalKey<MultiScheduleFormState>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = motor?.aliasName ?? motor?.name ?? 'Motor';
    final displayName = name.length > 20 ? '${name.substring(0, 20)}...' : name;

    final record = _editRecord;
    // cyclic=true + repeat=true  → scheduleType='CYCLIC'
    // cyclic=true + repeat=false → scheduleType='TIME_BASED' but cycleOnMinutes is set
    final isCyclic = record?.scheduleType == ScheduleType.CYCLIC ||
        record?.cycleOnMinutes != null;
    final (sh, sm) = _parseTime(record?.startTime);
    final (eh, em) = _parseTime(record?.endTime);

    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(displayName),
            Expanded(
              child: Obx(
                () => Skeletonizer(
                  enabled: _scheduleController.isRefreshing.value,
                  child: RefreshIndicator(
                    onRefresh: _onPullToRefresh,
                    child: _isEditMode
                        ? ScheduleForm(
                            key: _formKey,
                            onSave: _onSaveTapped,
                            onBack: () => Get.back(),
                            isEditMode: true,
                            initialStartHour: record != null ? sh : null,
                            initialStartMinute: record != null ? sm : null,
                            initialEndHour: record != null ? eh : null,
                            initialEndMinute: record != null ? em : null,
                            initialStartDate:
                                _yymmddToDate(record?.scheduleStartDate),
                            initialEndDate:
                                _yymmddToDate(record?.scheduleEndDate),
                            initialCyclicMode: record != null ? isCyclic : null,
                            initialCyclicOnMinutes: record != null
                                ? (record.cycleOnMinutes as num?)?.toInt()
                                : null,
                            initialCyclicOffMinutes: record != null
                                ? (record.cycleOffMinutes as num?)?.toInt()
                                : null,
                            initialPowerLossRecovery: record?.powerLossRecovery,
                            initialSelectedDays: record?.daysOfWeek,
                          )
                        : MultiScheduleForm(
                            key: _multiFormKey,
                            onSave: _onMultiSaveTapped,
                            onBack: () => Get.back(),
                            existingScheduleCount: _existingScheduleCount,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName) {
    return Container(
      color: const Color(0xFFEBF3FE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              _isEditMode ? 'Edit Schedule' : 'Create Schedule',
              style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004E7E)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF004E7E), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
