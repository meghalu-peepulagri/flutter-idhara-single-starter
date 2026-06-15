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
  StreamSubscription<String>? _scheduleAckTimeoutSub;
  Completer<bool>? _ackCompleter;
  Set<int> _expectedAckScheduleIds = <int>{};
  Motor? motor;
  Record? _editRecord;
  bool _isEditMode = false;
  int _existingScheduleCount = 0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _scheduleController = Get.put(ScheduleController());
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      motor = args['motor'] as Motor?;
      _editRecord = args['record'] as Record?;
      _isEditMode = _editRecord != null;
      _existingScheduleCount = (args['existingScheduleCount'] as int?) ?? 0;
      _selectedDate = args['selectedDate'] as DateTime?;
    }
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

      final ackedScheduleIds =
          (ack['schedule_ids'] as List?)?.whereType<int>().toList() ?? <int>[];
      final ackCode = ack['ack_code'] as int? ?? (ack['D'] as int? ?? 0);

      final expected = _isEditMode
          ? <int>{_editRecord?.scheduleId ?? 0}
          : _expectedAckScheduleIds;
      final isSuccess = ackCode == 1 &&
          (ackedScheduleIds.isEmpty || ackedScheduleIds.any(expected.contains));

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

  static const _bitwiseMap = {
    0: 1,
    1: 2,
    2: 4,
    3: 8,
    4: 16,
    5: 32,
    6: 64,
  };

  int _computeBitwiseDays(List<int> daysOfWeek) =>
      daysOfWeek.fold(0, (acc, d) => acc | (_bitwiseMap[d] ?? 0));

  Future<List<int>> _computeScheduleIds(int count) async {
    const reusableStatuses = <String>{};

    final occupied = <int>{};
    var maxSeenId = 0;
    try {
      final response = await _scheduleRepo.getScheduleList(1, 1000);
      final records = response?.data?.records ?? <Record>[];
      for (final s in records) {
        final sid = s.scheduleId;
        if (sid == null || sid <= 0) continue;
        if (sid > maxSeenId) maxSeenId = sid;
        final status = (s.scheduleStatus ?? '').toUpperCase();
        if (reusableStatuses.contains(status)) continue;
        occupied.add(sid);
      }
    } catch (_) {
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
      return List.generate(count, (i) => i + 1);
    }

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

  /// Device slot ids for the MQTT `id`: the lowest FREE slots in 1..15 only.
  /// Every existing schedule holds its slot regardless of status — only a
  /// deleted schedule (gone from the list) frees its slot for reuse. Never
  /// goes past 15.
  Future<List<int>> _computeDeviceScheduleIds(int count) async {
    const maxSlots = 15;
    final occupied = <int>{};
    void absorb(Iterable<Record> records) {
      for (final s in records) {
        final sid = s.deviceScheduleId;
        if (sid == null || sid < 1 || sid > maxSlots) continue;
        occupied.add(sid);
      }
    }

    // Read occupancy from BOTH the backend list and the controller's loaded
    // list — if one is paginated / stale / for another motor, the other still
    // covers the live slots so we never re-hand-out an occupied id.
    try {
      final response = await _scheduleRepo.getScheduleList(1, 1000);
      absorb(response?.data?.records ?? <Record>[]);
    } catch (_) {}
    if (Get.isRegistered<MotorScheduleController>()) {
      absorb(Get.find<MotorScheduleController>().schedules);
    }

    final result = <int>[];
    for (int slot = 1; slot <= maxSlots && result.length < count; slot++) {
      if (!occupied.contains(slot)) {
        result.add(slot);
        occupied.add(slot);
      }
    }
    // Device full (every 1..15 slot live) — fill the rest with the lowest
    // slots NOT already in this payload, so ids stay unique and within 1..15
    // (never duplicated, never past 15).
    for (int slot = 1; slot <= maxSlots && result.length < count; slot++) {
      if (!result.contains(slot)) result.add(slot);
    }
    return result;
  }

  CreateScheduleDto _buildDto(ScheduleFormState form,
      {required int scheduleId}) {
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

  Future<String?> _createSchedule() async {
    final form = _formKey.currentState!;

    final scheduleId = (await _computeScheduleIds(1)).first;
    final dto = _buildDto(form, scheduleId: scheduleId);
    final response = await _scheduleController.createSchedule(dtos: [dto]);
    if (response == null) {
      return _scheduleController.message ?? '';
    }
    SharedPreference.setscheduleid(response.data?.id ?? 0);
    _scheduleSaved = true;

    if (Get.isRegistered<MotorScheduleController>()) {
      try {
        await Get.find<MotorScheduleController>().fetchSchedules(silent: true);
      } catch (_) {}
    }

    getsuccessSnackBar('Schedule created successfully');
    return null;
  }

  Future<String?> _updateSchedule() async {
    final form = _formKey.currentState!;
    final id = _resolveIdentifier();

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
        idx: 2,
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
      return 'No response from device';
    }

    SharedPreference.setscheduleid(_editRecord?.id ?? 0);
    final dto = _buildDto(form, scheduleId: _editRecord?.scheduleId ?? 1);
    final response = await _scheduleController.updateSchedule(dto: dto);
    if (response == null) {
      return _scheduleController.message ?? '';
    }
    _scheduleSaved = true;

    if (Get.isRegistered<MotorScheduleController>()) {
      Get.find<MotorScheduleController>().fetchSchedules();
    }

    getsuccessSnackBar('Schedule updated successfully');
    return null;
  }

  List<DateTime> _filteredDates(DateTime start, DateTime end, Set<int> days) {
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

  CreateScheduleDto _buildDtoForFilteredDate({
    required ScheduleFormState form,
    required DateTime date,
    required Set<int> selectedDays,
    required int scheduleId,
    required int deviceScheduleId,
    DateTime? endDate,
  }) {
    final isCyclic = form.cyclicMode;
    final endD = endDate ?? date;
    final durationMinutes = endDate == null
        ? (() {
            final startMin = form.startHour * 60 + form.startMinute;
            var endMin = form.endHour * 60 + form.endMinute;
            if (endMin == startMin) return 0;
            if (endMin < startMin) endMin += 1440;
            return endMin - startMin;
          })()
        : (() {
            final s = DateTime(date.year, date.month, date.day, form.startHour,
                form.startMinute);
            var e = DateTime(
                endD.year, endD.month, endD.day, form.endHour, form.endMinute);
            if (!e.isAfter(s)) e = e.add(const Duration(days: 1));
            return e.difference(s).inMinutes;
          })();
    final dateCode = _dateToYYMMDD(date);
    final endDateCode = _dateToYYMMDD(endD);
    return CreateScheduleDto(
      motorId: SharedPreference.getMotorId(),
      starterId: SharedPreference.getStarterId(),
      scheduleType: isCyclic ? 'CYCLIC' : 'TIME_BASED',
      startTime: _formatTimeHHMM(form.startHour, form.startMinute),
      endTime: isCyclic ? null : _formatTimeHHMM(form.endHour, form.endMinute),
      scheduleStartDate: dateCode,
      scheduleEndDate: endDateCode,
      cycleOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
      cycleOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
      daysOfWeek: selectedDays.toList()..sort(),
      bitwiseDays: _computeBitwiseDays(selectedDays.toList()),
      runtimeMinutes: durationMinutes,
      powerLossRecovery: isCyclic ? false : form.powerLossRecovery,
      repeat: 0,
      enabled: true,
      scheduleId: scheduleId,
      deviceScheduleId: deviceScheduleId,
    );
  }

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
    final payloadDays = multi.isMultiDay ? sharedDays : <int>{};

    final filteredDates = multi.isMultiDay
        ? _filteredDates(sharedStart, sharedEnd, sharedDays)
        : <DateTime>[
            DateTime(sharedStart.year, sharedStart.month, sharedStart.day),
          ];
    if (filteredDates.isEmpty) {
      return 'No matching dates in the selected range';
    }

    final totalRows = forms.length * filteredDates.length;
    final scheduleIds = await _computeScheduleIds(totalRows);
    // Device slots — separate 1..15 ids, not the schedule_id. Still sent in
    // the POST body (device_schedule_id); no MQTT publish here.
    final deviceScheduleIds = await _computeDeviceScheduleIds(totalRows);
    final dtos = <CreateScheduleDto>[];
    var idIdx = 0;
    for (final d in filteredDates) {
      for (int i = 0; i < forms.length; i++) {
        dtos.add(_buildDtoForFilteredDate(
          form: forms[i],
          date: d,
          selectedDays: payloadDays,
          scheduleId: scheduleIds[idIdx],
          deviceScheduleId: deviceScheduleIds[idIdx],
          endDate: multi.isMultiDay ? null : sharedEnd,
        ));
        idIdx++;
      }
    }

    final response = await _scheduleController.createSchedule(dtos: dtos);
    if (response == null) {
      return _scheduleController.message ?? '';
    }

    if (response.data?.id != null) {
      SharedPreference.setscheduleid(response.data!.id!);
    }

    _scheduleSaved = true;

    // Refresh the list so the newly-created schedules appear.
    if (Get.isRegistered<MotorScheduleController>()) {
      try {
        await Get.find<MotorScheduleController>().fetchSchedules(silent: true);
      } catch (_) {}
    }

    getsuccessSnackBar('Schedules created successfully');
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
        duration: f.multiDaySpanText,
        powerRecovery: f.powerLossRecovery ? 'ON' : 'OFF',
        isCyclic: f.cyclicMode,
        cyclicOnMinutes: f.cyclicOnMinutes,
        cyclicOffMinutes: f.cyclicOffMinutes,
      );
    }).toList();

    final dayCounts = <int, int>{};
    final totalDays =
        multi.endDate.difference(multi.startDate).inDays.abs() + 1;
    for (int i = 0; i < totalDays; i++) {
      final d = multi.startDate.add(Duration(days: i));
      final wd = d.weekday == 7 ? 0 : d.weekday;
      if (multi.selectedDays.contains(wd)) {
        dayCounts[wd] = (dayCounts[wd] ?? 0) + 1;
      }
    }

    await showMultiScheduleConfirmDialog(
      context: context,
      startDate: _formatDateStr(multi.startDate),
      endDate: _formatDateStr(multi.endDate),
      schedules: items,
      selectedDays: multi.isMultiDay ? multi.selectedDays.toList() : <int>[],
      dayCounts: multi.isMultiDay ? dayCounts : <int, int>{},
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
                            initialDate: _selectedDate,
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
