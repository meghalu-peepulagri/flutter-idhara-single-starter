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
    final newObjectId = response.data?.id;
    SharedPreference.setscheduleid(newObjectId ?? 0);
    _scheduleSaved = true;

    final id = _resolveIdentifier();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final startNorm =
        DateTime(form.startDate.year, form.startDate.month, form.startDate.day);
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

    if (ackOk && newObjectId != null) {
      try {
        await _scheduleRepo.scheduleAcknowledgement([newObjectId],
            slotMap: {newObjectId: scheduleId});
      } catch (_) {}
    }

    if (ackOk) {
      getsuccessSnackBar('Schedule created successfully');
    }
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

  Map<String, dynamic> _buildMqttScheduleItem({
    required int scheduleId,
    required DateTime date,
    required ScheduleFormState form,
    required int enabled,
    DateTime? endDate,
  }) {
    final isCyclic = form.cyclicMode;
    final endD = endDate ?? date;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      form.startHour,
      form.startMinute,
    );
    var end = DateTime(
      endD.year,
      endD.month,
      endD.day,
      form.endHour,
      form.endMinute,
    );
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final stEpoch = start.millisecondsSinceEpoch ~/ 1000;
    final edEpoch = end.millisecondsSinceEpoch ~/ 1000;
    final dateCode = _dateToYYMMDD(date);
    final endDateCode = _dateToYYMMDD(endD);

    return {
      'id': scheduleId,
      'sd': dateCode,
      'ed': endDateCode,
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
    final dtos = <CreateScheduleDto>[];
    var idIdx = 0;
    for (final d in filteredDates) {
      for (int i = 0; i < forms.length; i++) {
        dtos.add(_buildDtoForFilteredDate(
          form: forms[i],
          date: d,
          selectedDays: payloadDays,
          scheduleId: scheduleIds[idIdx++],
          endDate: multi.isMultiDay ? null : sharedEnd,
        ));
      }
    }

    final response = await _scheduleController.createSchedule(dtos: dtos);
    if (response == null) {
      return _scheduleController.message ?? '';
    }

    final ackIds = <int>{};
    final slotMap = <int, int>{};
    if (response.data?.id != null) {
      SharedPreference.setscheduleid(response.data!.id!);
      ackIds.add(response.data!.id!);
      if (response.data!.scheduleId != null) {
        slotMap[response.data!.id!] = response.data!.scheduleId!;
      }
    }

    final createdRows = <String>{};
    var rowIdx = 0;
    for (final d in filteredDates) {
      final dc = _dateToYYMMDD(d);
      for (int i = 0; i < forms.length; i++) {
        createdRows.add('$dc:${scheduleIds[rowIdx++]}');
      }
    }

    if (Get.isRegistered<MotorScheduleController>()) {
      final ctrl = Get.find<MotorScheduleController>();
      try {
        await ctrl.fetchSchedules(silent: true);
        for (final r in ctrl.schedules) {
          if (r.id != null &&
              r.scheduleId != null &&
              createdRows.contains('${r.scheduleStartDate}:${r.scheduleId}')) {
            ackIds.add(r.id!);
            slotMap[r.id!] = r.scheduleId!;
          }
        }
      } catch (_) {}
    }

    _scheduleSaved = true;

    final id = _resolveIdentifier();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final allMqttItems = <Map<String, dynamic>>[];
    for (int dIdx = 0; dIdx < filteredDates.length; dIdx++) {
      final d = filteredDates[dIdx];
      final diffDays = d.difference(todayNorm).inDays;
      if (diffDays > 2) continue;
      for (int i = 0; i < forms.length; i++) {
        allMqttItems.add(_buildMqttScheduleItem(
          scheduleId: scheduleIds[dIdx * forms.length + i],
          date: d,
          form: forms[i],
          enabled: 1,
          endDate: multi.isMultiDay ? null : sharedEnd,
        ));
      }
    }

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

    if (ackOk && ackIds.isNotEmpty) {
      try {
        await _scheduleRepo.scheduleAcknowledgement(ackIds.toList(),
            slotMap: slotMap);
      } catch (_) {}
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
