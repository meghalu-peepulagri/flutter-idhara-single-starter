import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widgets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_bottom_sheets.dart';

class ScheduleForm extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onBack;

  // Optional initial values for edit mode
  final int? initialStartHour;
  final int? initialStartMinute;
  final int? initialEndHour;
  final int? initialEndMinute;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool? initialCyclicMode;
  final int? initialCyclicOnMinutes;
  final int? initialCyclicOffMinutes;
  final bool? initialPowerLossRecovery;
  final List<int>? initialSelectedDays;

  const ScheduleForm({
    super.key,
    required this.onSave,
    required this.onBack,
    this.initialStartHour,
    this.initialStartMinute,
    this.initialEndHour,
    this.initialEndMinute,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCyclicMode,
    this.initialCyclicOnMinutes,
    this.initialCyclicOffMinutes,
    this.initialPowerLossRecovery,
    this.initialSelectedDays,
  });

  @override
  State<ScheduleForm> createState() => ScheduleFormState();
}

class ScheduleFormState extends State<ScheduleForm> {
  late DateTime startDate;
  late DateTime endDate;

  late int startHour;
  late int startMinute;
  late int endHour;
  late int endMinute;

  late bool cyclicMode;
  late int cyclicOnMinutes;
  late int cyclicOffMinutes;
  late bool powerLossRecovery;
  late Set<int> selectedDays; // 1=Mon ... 7=Sun

  late final ValueNotifier<bool> _cyclicController;
  late final ValueNotifier<bool> _powerLossController;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    startDate = widget.initialStartDate ?? today;
    endDate = widget.initialEndDate ?? today;
    startHour = widget.initialStartHour ?? 0;
    startMinute = widget.initialStartMinute ?? 0;
    endHour = widget.initialEndHour ?? 0;
    endMinute = widget.initialEndMinute ?? 0;
    cyclicMode = widget.initialCyclicMode ?? false;
    cyclicOnMinutes = widget.initialCyclicOnMinutes ?? 20;
    cyclicOffMinutes = widget.initialCyclicOffMinutes ?? 15;
    powerLossRecovery = widget.initialPowerLossRecovery ?? false;
    selectedDays = widget.initialSelectedDays?.toSet() ?? {};
    _cyclicController = ValueNotifier(cyclicMode);
    _powerLossController = ValueNotifier(powerLossRecovery);
  }

  @override
  void dispose() {
    _cyclicController.dispose();
    _powerLossController.dispose();
    super.dispose();
  }

  int get _activeDays => endDate.difference(startDate).inDays.abs() + 1;

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  int get durationMinutes {
    int s = startHour * 60 + startMinute;
    int e = endHour * 60 + endMinute;
    if (e <= s) e += 1440;
    return e - s;
  }

  String get durationText {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  void _onTimePicked(TimeOfDay t, bool isStart) => setState(() {
        if (isStart) {
          startHour = t.hour;
          startMinute = t.minute;
          // Reset end time to 00:00 whenever start time changes
          endHour = 0;
          endMinute = 0;
        } else {
          endHour = t.hour;
          endMinute = t.minute;
        }
      });

  void _openTimePicker(bool isStart) => showTimeBottomSheet(
        context,
        isStart ? startTime : endTime,
        (picked) => _onTimePicked(picked, isStart),
        minTime: isStart ? null : startTime,
      );

  Future<void> _openCalendarDialog() async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        firstDate: todayNorm,
        lastDate: DateTime(todayNorm.year + 2),
        selectedDayHighlightColor: const Color(0xFF004E7E),
        selectedRangeHighlightColor: const Color(0xFFEBF3FE),
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        todayTextStyle: const TextStyle(
          color: Color(0xFF004E7E),
          fontWeight: FontWeight.w600,
        ),
        dayTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w400,
        ),
        disabledDayTextStyle: const TextStyle(color: Color(0xFFB0B8C4)),
        weekdayLabelTextStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        controlsTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        lastMonthIcon:
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF004E7E)),
        nextMonthIcon:
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF004E7E)),
        okButtonTextStyle: const TextStyle(
          color: Color(0xFF004E7E),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        cancelButtonTextStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      dialogSize: const Size(340, 350),
      value: [startDate, endDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results != null && results.isNotEmpty && mounted) {
      setState(() {
        startDate = results[0] ?? startDate;
        endDate = results.length > 1 ? (results[1] ?? startDate) : startDate;
      });
    }
  }

  void _toggleDay(int dayNum) {
    setState(() {
      if (selectedDays.contains(dayNum)) {
        selectedDays.remove(dayNum);
      } else {
        selectedDays.add(dayNum);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateCard(),
                const SizedBox(height: 24),
                scheduleSectionLabel('Schedule Timing'),
                const SizedBox(height: 10),
                _buildTimingCard(),
                const SizedBox(height: 24),
                ScheduleCyclicCard(
                  cyclicMode: cyclicMode,
                  cyclicOnMinutes: cyclicOnMinutes,
                  cyclicOffMinutes: cyclicOffMinutes,
                  cyclicController: _cyclicController,
                  onCyclicChanged: (v) => setState(() {
                    cyclicMode = v;
                    _cyclicController.value = v;
                    if (v) {
                      powerLossRecovery = false;
                      _powerLossController.value = false;
                    }
                  }),
                  onOnDecrement: () => setState(() {
                    if (cyclicOnMinutes > 5) cyclicOnMinutes -= 5;
                  }),
                  onOnIncrement: () => setState(() {
                    if (cyclicOnMinutes < 120) cyclicOnMinutes += 5;
                  }),
                  onOffDecrement: () => setState(() {
                    if (cyclicOffMinutes > 5) cyclicOffMinutes -= 5;
                  }),
                  onOffIncrement: () => setState(() {
                    if (cyclicOffMinutes < 120) cyclicOffMinutes += 5;
                  }),
                ),
                const SizedBox(height: 12),
                buildScheduleToggle(
                  icon: Icons.power_rounded,
                  title: 'Power Loss Recovery',
                  subtitle: 'Auto-resume after power restored',
                  controller: _powerLossController,
                  enabled: !cyclicMode,
                  onChanged: (v) => setState(() {
                    powerLossRecovery = v;
                    _powerLossController.value = v;
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        ScheduleFormBottomBar(onBack: widget.onBack, onSave: widget.onSave),
      ],
    );
  }

  // ── Date Card ───────────────────────────────────────────────────────────────

  Widget _buildDateCard() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Date Range" + calendar icon
          Row(
            children: [
              Text(
                'Date Range',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004E7E),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openCalendarDialog,
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: Color(0xFF004E7E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Start → End date boxes
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openCalendarDialog,
                  child: _buildDateBox('Start', startDate),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Color(0xFF94A3B8)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _openCalendarDialog,
                  child: _buildDateBox('End', endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Range row
          Row(
            children: [
              Text(
                'Range',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_activeDays ${_activeDays == 1 ? 'day' : 'days'} active',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004E7E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Day chips — manually tappable
          Row(
            children: List.generate(7, (i) {
              final dayNum = i + 1; // 1=Mon...7=Sun
              final isActive = selectedDays.contains(dayNum);
              return Expanded(
                child: GestureDetector(
                  onTap: () => _toggleDay(dayNum),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFEBF3FE)
                            : Colors.transparent,
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF3686AF)
                              : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          dayLabels[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF004E7E)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String label, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _fmtDate(date),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timing Card ─────────────────────────────────────────────────────────────

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      _buildTimePicker('START', startHour, startMinute, true)),
              Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                  child: _buildTimePicker('END', endHour, endMinute, false)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF3FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: Color(0xFF004E7E)),
                const SizedBox(width: 6),
                Text('Duration: $durationText',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, int hour, int minute, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _openTimePicker(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(hour.toString().padLeft(2, '0'),
                    style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(':',
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A))),
            ),
            GestureDetector(
              onTap: () => _openTimePicker(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(minute.toString().padLeft(2, '0'),
                    style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
