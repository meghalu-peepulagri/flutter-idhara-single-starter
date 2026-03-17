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
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_card.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_dialogs.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  GlobalKey<ScheduleFormState> _formKey = GlobalKey<ScheduleFormState>();
  final _mqttService = MqttService();
  late final ScheduleController _scheduleController;
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSub;
  Completer<bool>? _ackCompleter;
  Motor? motor;
  Record? _editRecord;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _scheduleController = Get.put(ScheduleController());
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      motor = args['motor'] as Motor?;
      _editRecord = args['record'] as Record?;
      _isEditMode = _editRecord != null;
    }
    if (_isEditMode) {
      _scheduleAckSub = _mqttService.scheduleAckStream.listen((ack) {
        if (!mounted) return;
        final currentId = _resolveIdentifier();
        final ackId = (ack['topic'] ?? '').toString();
        if (currentId.isNotEmpty && ackId != currentId) return;
        final d = ack['D'] as int? ?? 0;
        if (_ackCompleter != null && !_ackCompleter!.isCompleted) {
          _ackCompleter!.complete(d == 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _scheduleAckSub?.cancel();
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

  bool _scheduleSaved = false;

  String _formatDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _dateToYYMMDD(DateTime d) =>
      (d.year % 100) * 10000 + d.month * 100 + d.day;

  DateTime? _yymmddToDate(int? v) {
    if (v == null) return null;
    final yy = v ~/ 10000;
    final mm = (v % 10000) ~/ 100;
    final dd = v % 100;
    return DateTime(2000 + yy, mm, dd);
  }

  // Bitwise: Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64
  static const _bitwiseMap = {
    7: 1, // Sunday
    1: 2, // Monday
    2: 4, // Tuesday
    3: 8, // Wednesday
    4: 16, // Thursday
    5: 32, // Friday
    6: 64, // Saturday
  };

  int _computeBitwiseDays(List<int> daysOfWeek) =>
      daysOfWeek.fold(0, (acc, d) => acc | (_bitwiseMap[d] ?? 0));

  CreateScheduleDto _buildDto(ScheduleFormState form) {
    final isCyclic = form.cyclicMode;
    return CreateScheduleDto(
      motorId: SharedPreference.getMotorId(),
      starterId: SharedPreference.getStarterId(),
      scheduleType: isCyclic ? 'CYCLIC' : 'TIME_BASED',
      startTime: formatTime24h(form.startTime),
      endTime: isCyclic ? null : formatTime24h(form.endTime),
      scheduleDate: _formatDateStr(form.startDate),
      scheduleStartDate: _formatDateStr(form.startDate),
      scheduleEndDate: _formatDateStr(form.endDate),
      cycleOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
      cycleOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
      daysOfWeek: form.selectedDays.toList()..sort(),
      bitwiseDays: _computeBitwiseDays(form.selectedDays.toList()),
      runtimeMinutes: form.durationMinutes,
      powerLossRecovery: isCyclic ? false : form.powerLossRecovery,
      repeat: 0,
      enabled: true,
    );
  }

  Future<bool> _createSchedule() async {
    final form = _formKey.currentState!;
    final dto = _buildDto(form);

    final response = await _scheduleController.createSchedule(dto: dto);
    if (response == null) {
      geterrorSnackBar(
          _scheduleController.message ?? 'Failed to create schedule');
      return false;
    }

    SharedPreference.setscheduleid(response.data?.id ?? 0);
    getsuccessSnackBar(response.message ?? 'Schedule created successfully');

    final id = _resolveIdentifier();
    if (id.isNotEmpty) {
      final today = DateTime.now();
      final todayNorm = DateTime(today.year, today.month, today.day);
      final startNorm = DateTime(
          form.startDate.year, form.startDate.month, form.startDate.day);
      final daysDiff = startNorm.difference(todayNorm).inDays;
      // Inclusive count: today→startDate. Publish only if within 3 days (diff ≤ 2).
      final shouldPublishMqtt = daysDiff <= 2;

      print(
          '[MQTT CHECK] today=$todayNorm | startDate=$startNorm | daysDiff=$daysDiff | inclusiveCount=${daysDiff + 1} | shouldPublishMqtt=$shouldPublishMqtt');

      if (shouldPublishMqtt) {
        final isCyclic = form.cyclicMode;
        try {
          await _mqttService.publishScheduleCommand(
            identifier: id,
            scheduleId: response.data?.scheduleId ?? 1,
            startTimeHHMM: form.startHour * 100 + form.startMinute,
            endTimeHHMM: form.endHour * 100 + form.endMinute,
            startDateYYMMDD: _dateToYYMMDD(form.startDate),
            endDateYYMMDD: _dateToYYMMDD(form.endDate),
            isCyclic: isCyclic,
            cyclicOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
            cyclicOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
            powerRecovery: (isCyclic ? false : form.powerLossRecovery) ? 1 : 0,
            enabled: 1,
          );
        } catch (e) {
          geterrorSnackBar('Saved but MQTT failed: $e');
        }
      }
    }

    _scheduleSaved = true;
    return true;
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
      geterrorSnackBar('No response from device. Please try again.');
      return false; // stops dialog loading, keeps dialog open
    }

    // Step 3: ACK success → call PATCH API
    SharedPreference.setscheduleid(_editRecord?.id ?? 0);
    final dto = _buildDto(form);
    final response = await _scheduleController.updateSchedule(dto: dto);
    if (response == null) {
      geterrorSnackBar(
          _scheduleController.message ?? 'Failed to update schedule');
      return false;
    }

    getsuccessSnackBar(response.message ?? 'Schedule updated successfully');
    _scheduleSaved = true;
    return true; // dialog closes, _onSaveTapped navigates back
  }

  void _onSaveTapped() async {
    final form = _formKey.currentState;
    if (form == null) return;
    _scheduleSaved = false;
    final isCyclic = form.cyclicMode;
    await showScheduleConfirmDialog(
      context: context,
      typeLabel: isCyclic ? 'Cyclic' : 'Time Based',
      startTime: formatTime24h(form.startTime),
      endTime: formatTime24h(form.endTime),
      duration: form.durationText,
      powerRecovery: form.powerLossRecovery ? 'ON' : 'OFF',
      onConfirm: _isEditMode ? _updateSchedule : _createSchedule,
    );
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
                    child: ScheduleForm(
                      key: _formKey,
                      onSave: _onSaveTapped,
                      onBack: () => Get.back(),
                      initialStartHour: record != null ? sh : null,
                      initialStartMinute: record != null ? sm : null,
                      initialEndHour: record != null ? eh : null,
                      initialEndMinute: record != null ? em : null,
                      initialStartDate:
                          _yymmddToDate(record?.scheduleStartDate),
                      initialEndDate: _yymmddToDate(record?.scheduleEndDate),
                      initialCyclicMode: record != null ? isCyclic : null,
                      initialCyclicOnMinutes: record != null
                          ? (record.cycleOnMinutes as num?)?.toInt()
                          : null,
                      initialCyclicOffMinutes: record != null
                          ? (record.cycleOffMinutes as num?)?.toInt()
                          : null,
                      initialPowerLossRecovery: record?.powerLossRecovery,
                      initialSelectedDays: record?.daysOfWeek,
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
