import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'schedule_utils.dart';
import 'schedule_widgets.dart';
import 'schedule_bottom_sheets.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Motor? motor;
  bool _isScheduleEnabled = false;

  // OneTime state
  final Set<int> _oneTimeSelectedDays = {};
  TimeOfDay _oneTimeStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _oneTimeEndTime = const TimeOfDay(hour: 0, minute: 0);
  int _oneTimeDurationHours = 0;
  int _oneTimeDurationMinutes = 0;

  // Cyclic state
  final Set<int> _cyclicSelectedDays = {};
  TimeOfDay _cyclicStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _cyclicEndTime = const TimeOfDay(hour: 0, minute: 0);
  int _cyclicDurationHours = 0;
  int _cyclicDurationMinutes = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      motor = args['motor'] as Motor?;
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final motorName = motor?.aliasName ?? motor?.name ?? 'Motor';
    String displayName = motorName;
    if (displayName.length > 16) {
      displayName = '${displayName.substring(0, 16)}...';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(displayName),
            const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text('Schedule',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF004E7E),
                    )),
                const SizedBox(height: 2),
                Text(displayName,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF57636C),
                    )),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child:
                    Icon(Icons.arrow_back, color: Color(0xFF004E7E), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
      ),
    );
  }

  Widget _buildOneTimeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const SectionLabel(label: 'Select Days'),
          const SizedBox(height: 8),
          DaySelector(
            selectedDays: _oneTimeSelectedDays,
            onChanged: (days) => setState(() => _oneTimeSelectedDays
              ..clear()
              ..addAll(days)),
          ),
          const SizedBox(height: 16),
          const SectionLabel(label: 'Set Time'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TimeCard(
              label: 'Start Time',
              time: _oneTimeStartTime,
              icon: Icons.play_circle_outline_rounded,
              onTap: () => showTimeBottomSheet(
                  context, _oneTimeStartTime, _setOneTimeStartTime),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: TimeCard(
              label: 'End Time',
              time: _oneTimeEndTime,
              icon: Icons.stop_circle_outlined,
              onTap: () => showTimeBottomSheet(
                  context, _oneTimeEndTime, _setOneTimeEndTime),
            )),
          ]),
          const SizedBox(height: 16),
          DurationCard(
            durationH: _oneTimeDurationHours,
            durationM: _oneTimeDurationMinutes,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const SectionLabel(label: 'Select Days'),
          const SizedBox(height: 8),
          DaySelector(
            selectedDays: _cyclicSelectedDays,
            onChanged: (days) => setState(() => _cyclicSelectedDays
              ..clear()
              ..addAll(days)),
          ),
          const SizedBox(height: 16),
          const SectionLabel(label: 'Set Time'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TimeCard(
              label: 'Start Time',
              time: _cyclicStartTime,
              icon: Icons.play_circle_outline_rounded,
              onTap: () => showTimeBottomSheet(
                  context, _cyclicStartTime, _setCyclicStartTime),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: TimeCard(
              label: 'End Time',
              time: _cyclicEndTime,
              icon: Icons.stop_circle_outlined,
              onTap: () => showTimeBottomSheet(
                  context, _cyclicEndTime, _setCyclicEndTime),
            )),
          ]),
          const SizedBox(height: 16),
          DurationCard(
            durationH: _cyclicDurationHours,
            durationM: _cyclicDurationMinutes,
            onTap: () => showDurationBottomSheet(context, _cyclicDurationHours,
                _cyclicDurationMinutes, _setCyclicDuration),
          ),
          const SizedBox(height: 12),
          RepeatInfoCard(selectedDays: _cyclicSelectedDays),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
          PowerToggleRow(
            isEnabled: _isScheduleEnabled,
            onToggle: () =>
                setState(() => _isScheduleEnabled = !_isScheduleEnabled),
          ),
          const SizedBox(height: 12),
          CreateScheduleButton(
            onTap: () {
              // TODO: Implement schedule creation logic
            },
          ),
        ],
      ),
    );
  }
}
