import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_utils.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_widgets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_bottom_sheets.dart';

class ScheduleCreateForm extends StatefulWidget {
  final bool isScheduleEnabled;
  final ValueChanged<bool> onScheduleEnabledChanged;
  final VoidCallback onPublish;
  final VoidCallback onBack;

  const ScheduleCreateForm({
    super.key,
    required this.isScheduleEnabled,
    required this.onScheduleEnabledChanged,
    required this.onPublish,
    required this.onBack,
  });

  @override
  State<ScheduleCreateForm> createState() => ScheduleCreateFormState();
}

class ScheduleCreateFormState extends State<ScheduleCreateForm>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // OneTime state
  final Set<int> oneTimeSelectedDays = {};
  TimeOfDay oneTimeStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay oneTimeEndTime = const TimeOfDay(hour: 0, minute: 0);
  int oneTimeDurationHours = 0;
  int oneTimeDurationMinutes = 0;

  // Cyclic state
  final Set<int> cyclicSelectedDays = {};
  TimeOfDay cyclicStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay cyclicEndTime = const TimeOfDay(hour: 0, minute: 0);
  int cyclicDurationHours = 0;
  int cyclicDurationMinutes = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  bool get isOneTimeTab => tabController.index == 0;

  Set<int> get selectedDays =>
      isOneTimeTab ? oneTimeSelectedDays : cyclicSelectedDays;
  TimeOfDay get startTime => isOneTimeTab ? oneTimeStartTime : cyclicStartTime;
  TimeOfDay get endTime => isOneTimeTab ? oneTimeEndTime : cyclicEndTime;
  int get durationHours =>
      isOneTimeTab ? oneTimeDurationHours : cyclicDurationHours;
  int get durationMinutes =>
      isOneTimeTab ? oneTimeDurationMinutes : cyclicDurationMinutes;

  void resetForm() {
    setState(() {
      oneTimeSelectedDays.clear();
      oneTimeStartTime = const TimeOfDay(hour: 0, minute: 0);
      oneTimeEndTime = const TimeOfDay(hour: 0, minute: 0);
      oneTimeDurationHours = 0;
      oneTimeDurationMinutes = 0;
      cyclicSelectedDays.clear();
      cyclicStartTime = const TimeOfDay(hour: 0, minute: 0);
      cyclicEndTime = const TimeOfDay(hour: 0, minute: 0);
      cyclicDurationHours = 0;
      cyclicDurationMinutes = 0;
      tabController.index = 0;
    });
  }

  // ─── Auto-calc setters ───────────────────────────────────
  void _setOneTimeStartTime(TimeOfDay t) => setState(() {
        oneTimeStartTime = t;
        oneTimeEndTime =
            calcEndTime(t, oneTimeDurationHours, oneTimeDurationMinutes);
      });

  void _setOneTimeEndTime(TimeOfDay t) => setState(() {
        oneTimeEndTime = t;
        int s = oneTimeStartTime.hour * 60 + oneTimeStartTime.minute;
        int e = t.hour * 60 + t.minute;
        if (e <= s) e += 1440;
        oneTimeDurationHours = (e - s) ~/ 60;
        oneTimeDurationMinutes = (e - s) % 60;
      });

  void _setOneTimeDuration(int h, int m) => setState(() {
        oneTimeDurationHours = h;
        oneTimeDurationMinutes = m;
        oneTimeEndTime = calcEndTime(oneTimeStartTime, h, m);
      });

  void _setCyclicStartTime(TimeOfDay t) => setState(() {
        cyclicStartTime = t;
        cyclicEndTime =
            calcEndTime(t, cyclicDurationHours, cyclicDurationMinutes);
      });

  void _setCyclicEndTime(TimeOfDay t) => setState(() {
        cyclicEndTime = t;
        int s = cyclicStartTime.hour * 60 + cyclicStartTime.minute;
        int e = t.hour * 60 + t.minute;
        if (e <= s) e += 1440;
        cyclicDurationHours = (e - s) ~/ 60;
        cyclicDurationMinutes = (e - s) % 60;
      });

  void _setCyclicDuration(int h, int m) => setState(() {
        cyclicDurationHours = h;
        cyclicDurationMinutes = m;
        cyclicEndTime = calcEndTime(cyclicStartTime, h, m);
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildTabBar(),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildOneTimeForm(context),
              _buildCyclicForm(context),
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
        controller: tabController,
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

  Widget _buildOneTimeForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          buildSectionLabel('Select Days'),
          const SizedBox(height: 8),
          buildDaySelector(
            oneTimeSelectedDays,
            (days) => setState(() => oneTimeSelectedDays
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
              time: oneTimeStartTime,
              icon: Icons.play_circle_outline_rounded,
              onTap: () => showTimeBottomSheet(
                  context, oneTimeStartTime, _setOneTimeStartTime),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: buildTimeCard(
              label: 'End Time',
              time: oneTimeEndTime,
              icon: Icons.stop_circle_outlined,
              onTap: () => showTimeBottomSheet(
                  context, oneTimeEndTime, _setOneTimeEndTime),
            )),
          ]),
          const SizedBox(height: 16),
          buildDurationCard(
            oneTimeDurationHours,
            oneTimeDurationMinutes,
            onTap: () => showDurationBottomSheet(context, oneTimeDurationHours,
                oneTimeDurationMinutes, _setOneTimeDuration),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCyclicForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          buildSectionLabel('Select Days'),
          const SizedBox(height: 8),
          buildDaySelector(
            cyclicSelectedDays,
            (days) => setState(() => cyclicSelectedDays
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
              time: cyclicStartTime,
              icon: Icons.play_circle_outline_rounded,
              onTap: () => showTimeBottomSheet(
                  context, cyclicStartTime, _setCyclicStartTime),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: buildTimeCard(
              label: 'End Time',
              time: cyclicEndTime,
              icon: Icons.stop_circle_outlined,
              onTap: () => showTimeBottomSheet(
                  context, cyclicEndTime, _setCyclicEndTime),
            )),
          ]),
          const SizedBox(height: 16),
          buildDurationCard(
            cyclicDurationHours,
            cyclicDurationMinutes,
            onTap: () => showDurationBottomSheet(context, cyclicDurationHours,
                cyclicDurationMinutes, _setCyclicDuration),
          ),
          const SizedBox(height: 12),
          buildRepeatInfoCard(cyclicSelectedDays),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
        mainAxisSize: MainAxisSize.max,
        children: [
          // buildPowerToggleRow(
          //   widget.isScheduleEnabled,
          //   () => widget.onScheduleEnabledChanged(!widget.isScheduleEnabled),
          // ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Cancel button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF004E7E)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.onBack,
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Create button
              Expanded(
                child: buildCreateScheduleButton(widget.onPublish),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
