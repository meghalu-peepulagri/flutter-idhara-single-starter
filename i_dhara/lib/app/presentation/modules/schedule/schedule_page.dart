import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/schedule_utils/schedule_utils.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_card.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_dialogs.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _formKey = GlobalKey<ScheduleFormState>();
  final _mqttService = MqttService();
  late final ScheduleController _scheduleController;
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSub;
  Motor? motor;

  @override
  void initState() {
    super.initState();
    _scheduleController = Get.put(ScheduleController());
    final args = Get.arguments;
    if (args is Map<String, dynamic>) motor = args['motor'] as Motor?;
    _scheduleAckSub = _mqttService.scheduleAckStream.listen((ack) {
      if (!mounted) return;
      final id = _resolveIdentifier();
      final ackId = (ack['topic'] ?? '').toString();
      if (id.isNotEmpty && ackId != id) return;
      (ack['status'] as int? ?? 0) == 1
          ? getsuccessSnackBar('Schedule updated successfully')
          : geterrorSnackBar('Schedule update failed');
    });
  }

  @override
  void dispose() {
    _scheduleAckSub?.cancel();
    super.dispose();
  }

  String _resolveIdentifier() {
    final mac = motor?.starter?.macAddress?.trim() ?? '';
    return mac.isNotEmpty ? mac : (motor?.starter?.pcbNumber?.trim() ?? '');
  }

  bool _scheduleCreated = false;

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Called by dialog onConfirm — POST API first, then MQTT on success
  Future<bool> _createSchedule() async {
    final form = _formKey.currentState!;
    final isCyclic = form.cyclicMode;

    final dto = CreateScheduleDto(
      motorId: SharedPreference.getMotorId(),
      starterId: SharedPreference.getStarterId(),
      scheduleType: (isCyclic && form.repeatWeekly) ? 'CYCLIC' : 'TIME_BASED',
      startTime: formatTime24h(form.startTime),
      endTime: isCyclic ? null : formatTime24h(form.endTime),
      scheduleDate: isCyclic ? _todayDate() : null,
      scheduleStartDate: null,
      scheduleEndDate: null,
      cycleOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
      cycleOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
      daysOfWeek: form.selectedDays.toList()..sort(),
      bitwiseDays: buildDaysBitmask(form.selectedDays),
      runtimeMinutes: form.durationMinutes,
      powerLossRecovery: form.powerLossRecovery,
      repeat: form.repeatWeekly ? 1 : 0,
      enabled: true,
    );

    final response = await _scheduleController.createSchedule(dto: dto);
    if (response == null) {
      geterrorSnackBar(
          _scheduleController.message ?? 'Failed to create schedule');
      return false; // keep dialog open
    }

    SharedPreference.setscheduleid(response.data?.id ?? 0);
    getsuccessSnackBar(response.message ?? 'Schedule created successfully');

    // Publish MQTT only after API success
    final id = _resolveIdentifier();
    if (id.isNotEmpty) {
      try {
        await _mqttService.publishScheduleCommand(
          identifier: id,
          scheduleType: (isCyclic && form.repeatWeekly) ? 2 : 1,
          scheduleId: response.data?.scheduleId ?? 1,
          startTime: formatTime24h(form.startTime),
          endTime: formatTime24h(form.endTime),
          durationMinutes: form.durationMinutes,
          cyclicOnMinutes: isCyclic ? form.cyclicOnMinutes : null,
          cyclicOffMinutes: isCyclic ? form.cyclicOffMinutes : null,
          repeat: form.repeatWeekly ? 1 : 0,
          daysBitmask: buildDaysBitmask(form.selectedDays),
          powerRecovery: form.powerLossRecovery ? 1 : 0,
          enabled: 1,
        );
      } catch (e) {
        geterrorSnackBar('Saved but MQTT failed: $e');
      }
    }

    _scheduleCreated = true;
    return true; // dialog closes itself, then _onSaveTapped navigates
  }

  void _onSaveTapped() async {
    final form = _formKey.currentState;
    if (form == null) return;
    _scheduleCreated = false;
    final isCyclic = form.cyclicMode;
    await showScheduleConfirmDialog(
      context: context,
      typeLabel: (isCyclic && form.repeatWeekly)
          ? 'Cyclic'
          : isCyclic
              ? 'Time Based'
              : 'Time Based',
      startTime: formatTime24h(form.startTime),
      endTime: formatTime24h(form.endTime),
      duration: form.durationText,
      powerRecovery: form.powerLossRecovery ? 'ON' : 'OFF',
      onConfirm: _createSchedule,
    );
    // Navigate back to motor details after dialog closes on success
    if (_scheduleCreated && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final name = motor?.aliasName ?? motor?.name ?? 'Motor';
    final displayName = name.length > 20 ? '${name.substring(0, 20)}...' : name;

    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(displayName),
            Expanded(
              child: ScheduleForm(
                key: _formKey,
                onSave: _onSaveTapped,
                onBack: () => Get.back(),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Schedule',
                    style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004E7E))),
                // const SizedBox(height: 2),
                // Text(displayName,
                //     style: GoogleFonts.dmSans(
                //         fontSize: 12,
                //         fontWeight: FontWeight.w400,
                //         color: const Color(0xFF57636C))),
              ],
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
