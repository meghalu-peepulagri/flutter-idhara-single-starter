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

  /// Returns 1 if the motor has no schedules yet (first-time create),
  /// or 2 if it already has at least one schedule.
  int _mqttIdx() {
    if (Get.isRegistered<MotorScheduleController>()) {
      final existing = Get.find<MotorScheduleController>().schedules;
      if (existing.isNotEmpty) return 2;
    }
    return 1;
  }

  /// Returns [count] scheduleIds for new schedules.
  /// Gaps in the existing ID sequence are filled first (ascending), then
  /// continues from maxExistingId + 1.
  /// Example: existing=[1,3], count=2 → [2, 4]
  /// Example: existing=[1,2,3], count=2 → [4, 5]
  /// Example: existing=[], count=3 → [1, 2, 3]
  List<int> _computeScheduleIds(int count) {
    final existing = <int>{};
    if (Get.isRegistered<MotorScheduleController>()) {
      for (final s in Get.find<MotorScheduleController>().schedules) {
        if (s.scheduleId != null && s.scheduleId! > 0) {
          existing.add(s.scheduleId!);
        }
      }
    }

    if (existing.isEmpty) {
      return List.generate(count, (i) => i + 1);
    }

    final maxId = existing.reduce((a, b) => a > b ? a : b);

    // Collect gaps: IDs from 1..maxId that are missing
    final gaps = [
      for (int i = 1; i <= maxId; i++)
        if (!existing.contains(i)) i,
    ];

    final result = <int>[];
    // Fill gaps first
    for (final gap in gaps) {
      if (result.length == count) break;
      result.add(gap);
    }
    // Then increment from maxId + 1
    var next = maxId + 1;
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
  ///   `null`           → success (MQTT ACK + backend POST both ok) →
  ///                      dialog pops, caller navigates to the schedule list.
  ///   `''`             → no MQTT ACK within ~23s (or MQTT publish error)
  ///                      → dialog switches to its retry view. Backend POST
  ///                      is NOT called in this branch.
  ///   `'message'`      → backend POST returned an error → dialog shows
  ///                      inline banner.
  ///
  /// Order of operations: MQTT publish → wait for T:33 ACK → only on success
  /// hit POST /motor-schedules. This guarantees we never persist a schedule
  /// that the device hasn't acknowledged.
  Future<String?> _createSchedule() async {
    final form = _formKey.currentState!;
    final scheduleId = _computeScheduleIds(1).first;

    // Decide whether the device should be told first. Schedules with a
    // start date >2 days out skip MQTT entirely (no ACK to wait for) and
    // go straight to backend persistence.
    final id = _resolveIdentifier();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startNorm = DateTime(
        form.startDate.year, form.startDate.month, form.startDate.day);
    final daysDiff = startNorm.difference(todayNorm).inDays;
    final shouldPublishMqtt = id.isNotEmpty && daysDiff <= 2;

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
      } catch (e) {
        _ackCompleter = null;
        _expectedAckScheduleIds = <int>{};
        geterrorSnackBar('MQTT failed: $e');
        return '';
      }

      final ackOk = await _ackCompleter!.future.timeout(
        const Duration(seconds: 23),
        onTimeout: () => false,
      );
      _ackCompleter = null;
      _expectedAckScheduleIds = <int>{};

      // No ACK / device-error → DO NOT hit the backend. The dialog will
      // show its Retry view; tapping Retry re-runs this whole flow.
      if (!ackOk) return '';
    }

    // ACK ok (or MQTT skipped) → persist on backend.
    final dto = _buildDto(form, scheduleId: scheduleId);
    final response = await _scheduleController.createSchedule(dtos: [dto]);
    if (response == null) {
      return _scheduleController.message ?? '';
    }

    SharedPreference.setscheduleid(response.data?.id ?? 0);

    // PATCH /motor-schedules/bulk/ack with the freshly created object id so
    // the backend marks this schedule as device-acknowledged. Best-effort —
    // we already have the device's ACK, so a transient PATCH failure
    // shouldn't block the success flow.
    final newObjectId = response.data?.id;
    if (newObjectId != null) {
      try {
        await _scheduleRepo.scheduleAcknowledgement([newObjectId]);
      } catch (_) {
        // silently fail
      }
    }

    getsuccessSnackBar(response.message ?? 'Schedule created successfully');
    _scheduleSaved = true;
    return null;
  }

  Future<bool> _updateSchedule() async {
    final form = _formKey.currentState!;
    final id = _resolveIdentifier();

    // Step 1: Publish MQTT T:23 — dialog stays loading while we await ACK
    _ackCompleter = Completer<bool>();
    final isCyclic = form.cyclicMode;
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
    } catch (e) {
      _ackCompleter = null;
      geterrorSnackBar('MQTT failed: $e');
      return false;
    }

    // Step 2: Wait for T:54 ACK — dialog still loading (30s timeout)
    final ackSuccess = await _ackCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _ackCompleter = null;
        return false;
      },
    );
    _ackCompleter = null;

    if (!ackSuccess) {
      // No page-level snackbar / navigation here. The dialog now owns its
      // own waiting → failed → retry / cancel state machine, so popping a
      // route from this function would also pop the schedule page off the
      // stack (jumping the user to the schedule list) — which is what
      // happened when the user tapped Cancel during retry. Just return
      // false so the dialog can show its Retry view (or stay closed if
      // the user already cancelled).
      return false;
    }

    // Step 3: ACK success → show snackbar instantly, run PATCH API in
    // background AND refresh the schedules list once the PATCH commits.
    // We chain `.then()` instead of `unawaited(...)` so that the list fetch
    // fires AFTER the backend has persisted the edit — otherwise a delayed
    // ACK (~2s) pops the page before PATCH commits and the GET returns
    // stale data.
    SharedPreference.setscheduleid(_editRecord?.id ?? 0);
    final dto = _buildDto(form, scheduleId: _editRecord?.scheduleId ?? 1);
    getsuccessSnackBar('Schedule updated successfully');
    _scheduleSaved = true;
    _scheduleController.updateSchedule(dto: dto).then((_) {
      if (Get.isRegistered<MotorScheduleController>()) {
        Get.find<MotorScheduleController>().fetchSchedules();
      }
    });
    return true; // dialog closes immediately after ACK, no wait for API
  }

  /// Build a single MQTT schedule item (shape matches the m1[] entries the
  /// device expects). Dates come from the shared multi-form state; time,
  /// cyclic and power-recovery come from the individual child form.
  Map<String, dynamic> _buildMqttScheduleItem({
    required int scheduleId,
    required DateTime startDate,
    required DateTime endDate,
    required ScheduleFormState form,
    required int enabled,
  }) {
    final isCyclic = form.cyclicMode;

    final stEpoch = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          form.startHour,
          form.startMinute,
        ).millisecondsSinceEpoch ~/
        1000;

    final edEpoch = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          form.endHour,
          form.endMinute,
        ).millisecondsSinceEpoch ~/
        1000;

    return {
      'id': scheduleId,
      'sd': _dateToYYMMDD(startDate),
      'ed': _dateToYYMMDD(endDate),
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

  CreateScheduleDto _buildDtoForMulti({
    required ScheduleFormState form,
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> selectedDays,
    required int scheduleId,
  }) {
    final isCyclic = form.cyclicMode;
    final durationMinutes = () {
      final start = DateTime(startDate.year, startDate.month, startDate.day,
          form.startHour, form.startMinute);
      final end = DateTime(endDate.year, endDate.month, endDate.day,
          form.endHour, form.endMinute);
      final endAdjusted = end.isBefore(start) || end.isAtSameMomentAs(start)
          ? end.add(const Duration(days: 1))
          : end;
      return endAdjusted.difference(start).inMinutes;
    }();
    return CreateScheduleDto(
      motorId: SharedPreference.getMotorId(),
      starterId: SharedPreference.getStarterId(),
      scheduleType: isCyclic ? 'CYCLIC' : 'TIME_BASED',
      startTime: _formatTimeHHMM(form.startHour, form.startMinute),
      endTime: isCyclic ? null : _formatTimeHHMM(form.endHour, form.endMinute),
      scheduleStartDate: _dateToYYMMDD(startDate),
      scheduleEndDate: _dateToYYMMDD(endDate),
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

  /// Create all schedules sequentially via the existing single-create API,
  /// collect their scheduleIds, then publish ONE T:3 MQTT command with all
  /// items in ascending-id order.
  /// Same return contract and ordering as [_createSchedule]: MQTT publish +
  /// ACK first, then backend POST (only on success). On ACK timeout we
  /// return `''` so the dialog shows Retry; the backend is not touched.
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

    final scheduleIds = _computeScheduleIds(forms.length);

    final id = _resolveIdentifier();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startNorm =
        DateTime(sharedStart.year, sharedStart.month, sharedStart.day);
    final daysDiff = startNorm.difference(todayNorm).inDays;
    final shouldPublishMqtt = id.isNotEmpty && daysDiff <= 2;

    if (shouldPublishMqtt) {
      final items = <Map<String, dynamic>>[];
      for (int i = 0; i < forms.length; i++) {
        items.add(_buildMqttScheduleItem(
          scheduleId: scheduleIds[i],
          startDate: sharedStart,
          endDate: sharedEnd,
          form: forms[i],
          enabled: 1,
        ));
      }
      if (Get.isRegistered<MotorScheduleController>()) {
        Get.find<MotorScheduleController>().trackPendingSchedulePublish(
              items: items,
              identifier: id,
              idx: _mqttIdx(),
            );
      }

      _expectedAckScheduleIds = scheduleIds.toSet();
      _ackCompleter = Completer<bool>();

      try {
        await _mqttService.publishMultipleSchedulesCommand(
          identifier: id,
          items: items,
          idx: _mqttIdx(),
          trackExpectedAcks: items.length > 1,
        );
      } catch (e) {
        _ackCompleter = null;
        _expectedAckScheduleIds = <int>{};
        geterrorSnackBar('MQTT failed: $e');
        return '';
      }

      final ackOk = await _ackCompleter!.future.timeout(
        const Duration(seconds: 23),
        onTimeout: () => false,
      );
      _ackCompleter = null;
      _expectedAckScheduleIds = <int>{};

      // No ACK → don't persist on backend. Dialog will show Retry.
      if (!ackOk) return '';
    }

    // ACK ok (or MQTT skipped) → persist on backend.
    final dtos = List.generate(
      forms.length,
      (i) => _buildDtoForMulti(
        form: forms[i],
        startDate: sharedStart,
        endDate: sharedEnd,
        selectedDays: sharedDays,
        scheduleId: scheduleIds[i],
      ),
    );

    final response = await _scheduleController.createSchedule(dtos: dtos);
    if (response == null) {
      return _scheduleController.message ?? '';
    }
    if (response.data?.id != null) {
      SharedPreference.setscheduleid(response.data!.id!);
    }

    // PATCH /motor-schedules/bulk/ack for every record we just created.
    // The POST response only carries a single Data, so for multi-create we
    // refresh MotorScheduleController.schedules and collect every backend
    // object id whose scheduleId is in [scheduleIds].
    final ackIds = <int>{};
    if (response.data?.id != null) ackIds.add(response.data!.id!);
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
    if (ackIds.isNotEmpty) {
      try {
        await _scheduleRepo.scheduleAcknowledgement(ackIds.toList());
      } catch (_) {
        // silently fail — schedules are already created on backend
      }
    }

    getsuccessSnackBar(response.message ?? 'Schedules created successfully');
    _scheduleSaved = true;
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
      // Edit reuses the multi-style dialog (date range row + schedule card)
      // so the layout matches the create flow but reads as an update.
      // Count how many times each picked weekday occurs in the date range
      // so the chip badges show "2", "3" etc. (same as create-multi).
      final dayCounts = <int, int>{};
      final totalDays =
          form.endDate.difference(form.startDate).inDays.abs() + 1;
      for (int i = 0; i < totalDays; i++) {
        final d = form.startDate.add(Duration(days: i));
        final wd = d.weekday == 7 ? 0 : d.weekday; // 0=Sun..6=Sat
        if (form.selectedDays.contains(wd)) {
          dayCounts[wd] = (dayCounts[wd] ?? 0) + 1;
        }
      }

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
        selectedDays: form.selectedDays.toList(),
        dayCounts: dayCounts,
        onConfirm: () async {
          final ok = await _updateSchedule();
          if (ok) return null;
          // Edit currently distinguishes failures via _scheduleController.message;
          // an empty string is the no-ack case the dialog now treats as Retry.
          return _scheduleController.message ?? '';
        },
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
