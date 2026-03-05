import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_utils.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_widgets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_bottom_sheets.dart';

class MotorScheduleTab extends StatefulWidget {
  final MotorDetails? motorDetails;
  const MotorScheduleTab({super.key, this.motorDetails});

  @override
  State<MotorScheduleTab> createState() => _MotorScheduleTabState();
}

class _MotorScheduleTabState extends State<MotorScheduleTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;
  bool _isScheduleEnabled = false;

  // OneTime state
  final Set<int> _oneTimeSelectedDays = {};
  TimeOfDay _oneTimeStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _oneTimeEndTime = const TimeOfDay(hour: 0, minute: 0);
  int _oneTimeDurationHours = 0;
  int _oneTimeDurationMinutes = 0;
  final int _oneTimeScheduleId = 1;

  // Cyclic state
  final Set<int> _cyclicSelectedDays = {};
  TimeOfDay _cyclicStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _cyclicEndTime = const TimeOfDay(hour: 0, minute: 0);
  int _cyclicDurationHours = 0;
  int _cyclicDurationMinutes = 0;
  final int _cyclicScheduleId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listenScheduleAck();
  }

  @override
  void dispose() {
    _scheduleAckSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ─── OneTime auto-calc setters ───────────────────────────
  void _setOneTimeStartTime(TimeOfDay t) {
    setState(() {
      _oneTimeStartTime = t;
      _oneTimeEndTime =
          calcEndTime(t, _oneTimeDurationHours, _oneTimeDurationMinutes);
    });
  }

  void _setOneTimeEndTime(TimeOfDay t) {
    setState(() {
      _oneTimeEndTime = t;
      int startMin = _oneTimeStartTime.hour * 60 + _oneTimeStartTime.minute;
      int endMin = t.hour * 60 + t.minute;
      if (endMin <= startMin) endMin += 24 * 60;
      final diff = endMin - startMin;
      _oneTimeDurationHours = diff ~/ 60;
      _oneTimeDurationMinutes = diff % 60;
    });
  }

  void _setOneTimeDuration(int h, int m) {
    setState(() {
      _oneTimeDurationHours = h;
      _oneTimeDurationMinutes = m;
      _oneTimeEndTime = calcEndTime(_oneTimeStartTime, h, m);
    });
  }

  // ─── Cyclic auto-calc setters ────────────────────────────
  void _setCyclicStartTime(TimeOfDay t) {
    setState(() {
      _cyclicStartTime = t;
      _cyclicEndTime =
          calcEndTime(t, _cyclicDurationHours, _cyclicDurationMinutes);
    });
  }

  void _setCyclicEndTime(TimeOfDay t) {
    setState(() {
      _cyclicEndTime = t;
      int startMin = _cyclicStartTime.hour * 60 + _cyclicStartTime.minute;
      int endMin = t.hour * 60 + t.minute;
      if (endMin <= startMin) endMin += 24 * 60;
      final diff = endMin - startMin;
      _cyclicDurationHours = diff ~/ 60;
      _cyclicDurationMinutes = diff % 60;
    });
  }

  void _setCyclicDuration(int h, int m) {
    setState(() {
      _cyclicDurationHours = h;
      _cyclicDurationMinutes = m;
      _cyclicEndTime = calcEndTime(_cyclicStartTime, h, m);
    });
  }

  String _resolveIdentifier() {
    final starter = widget.motorDetails?.starter;
    final mac = starter?.macAddress?.trim() ?? '';
    if (mac.isNotEmpty) return mac;
    final pcb = starter?.pcbNumber?.trim() ?? '';
    return pcb;
  }

  void _listenScheduleAck() {
    _scheduleAckSubscription = _mqttService.scheduleAckStream.listen((ack) {
      if (!mounted) return;

      final currentIdentifier = _resolveIdentifier();
      final ackIdentifier = (ack['topic'] ?? '').toString();
      if (currentIdentifier.isNotEmpty && ackIdentifier != currentIdentifier) {
        return;
      }

      final status = ack['status'] as int? ?? 0;
      if (status == 1) {
        getsuccessSnackBar('Schedule updated successfully');
      } else {
        geterrorSnackBar('Schedule update failed');
      }
    });
  }

  Future<void> _publishSchedule() async {
    final isOneTimeTab = _tabController.index == 0;
    final selectedDays =
        isOneTimeTab ? _oneTimeSelectedDays : _cyclicSelectedDays;
    final startTime = isOneTimeTab ? _oneTimeStartTime : _cyclicStartTime;
    final endTime = isOneTimeTab ? _oneTimeEndTime : _cyclicEndTime;
    final durationHours =
        isOneTimeTab ? _oneTimeDurationHours : _cyclicDurationHours;
    final durationMinutes =
        isOneTimeTab ? _oneTimeDurationMinutes : _cyclicDurationMinutes;
    final scheduleId = isOneTimeTab ? _oneTimeScheduleId : _cyclicScheduleId;

    final identifier = _resolveIdentifier();
    if (identifier.isEmpty) {
      geterrorSnackBar('Motor identifier not found (MAC/PCB).');
      return;
    }

    final payloadDays = buildDaysBitmask(selectedDays);

    try {
      await _mqttService.publishScheduleCommand(
        identifier: identifier,
        scheduleType: isOneTimeTab ? 1 : 2,
        scheduleId: scheduleId,
        startTime: formatTime24h(startTime),
        endTime: formatTime24h(endTime),
        durationMinutes: durationToMinutes(durationHours, durationMinutes),
        repeat: isOneTimeTab ? 0 : 1,
        daysBitmask: payloadDays,
        powerRecovery: _isScheduleEnabled ? 1 : 0,
        enabled: _isScheduleEnabled ? 1 : 0,
      );
    } catch (e) {
      geterrorSnackBar('Failed to publish schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildTabBar(),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOneTimeTab(context),
              _buildCyclicTab(context),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF57636C),
        labelStyle:
            GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [Tab(text: 'One Time'), Tab(text: 'Cyclic')],
      ),
    );
  }

  Widget _buildOneTimeTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          buildSectionLabel('Select Days'),
          const SizedBox(height: 8),
          buildDaySelector(
            _oneTimeSelectedDays,
            (days) => setState(() => _oneTimeSelectedDays
              ..clear()
              ..addAll(days)),
          ),
          const SizedBox(height: 16),
          buildSectionLabel('Set Time'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: buildTimeCard(
              label: 'Start Time',
              time: _oneTimeStartTime,
              icon: Icons.play_circle_outline_rounded,
              onTap: () => showTimeBottomSheet(
                  context, _oneTimeStartTime, _setOneTimeStartTime),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: buildTimeCard(
              label: 'End Time',
              time: _oneTimeEndTime,
              icon: Icons.stop_circle_outlined,
              onTap: () => showTimeBottomSheet(
                  context, _oneTimeEndTime, _setOneTimeEndTime),
            )),
          ]),
          const SizedBox(height: 16),
          buildDurationCard(
            _oneTimeDurationHours,
            _oneTimeDurationMinutes,
            onTap: () => showDurationBottomSheet(context, _oneTimeDurationHours,
                _oneTimeDurationMinutes, _setOneTimeDuration),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCyclicTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          buildSectionLabel('Select Days'),
          const SizedBox(height: 8),
          buildDaySelector(
            _cyclicSelectedDays,
            (days) => setState(() => _cyclicSelectedDays
              ..clear()
              ..addAll(days)),
          ),
          const SizedBox(height: 16),
          buildSectionLabel('Set Time'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: buildTimeCard(
              label: 'Start Time',
              time: _cyclicStartTime,
              icon: Icons.play_circle_outline_rounded,
              onTap: () => showTimeBottomSheet(
                  context, _cyclicStartTime, _setCyclicStartTime),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: buildTimeCard(
              label: 'End Time',
              time: _cyclicEndTime,
              icon: Icons.stop_circle_outlined,
              onTap: () => showTimeBottomSheet(
                  context, _cyclicEndTime, _setCyclicEndTime),
            )),
          ]),
          const SizedBox(height: 16),
          buildDurationCard(
            _cyclicDurationHours,
            _cyclicDurationMinutes,
            onTap: () => showDurationBottomSheet(context, _cyclicDurationHours,
                _cyclicDurationMinutes, _setCyclicDuration),
          ),
          const SizedBox(height: 12),
          buildRepeatInfoCard(_cyclicSelectedDays),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildPowerToggleRow(
            _isScheduleEnabled,
            () => setState(() => _isScheduleEnabled = !_isScheduleEnabled),
          ),
          const SizedBox(height: 12),
          buildCreateScheduleButton(_publishSchedule),
        ],
      ),
    );
  }
}
