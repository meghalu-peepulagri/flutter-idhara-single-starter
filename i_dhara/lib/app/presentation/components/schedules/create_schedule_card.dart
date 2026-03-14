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
  });

  @override
  State<ScheduleForm> createState() => ScheduleFormState();
}

class ScheduleFormState extends State<ScheduleForm> {
  late DateTime startDate;
  late DateTime endDate;
  bool _selectingStart = true;
  late final ScrollController _dateScrollController;

  late int startHour;
  late int startMinute;
  late int endHour;
  late int endMinute;

  late bool cyclicMode;
  late int cyclicOnMinutes;
  late int cyclicOffMinutes;
  late bool powerLossRecovery;

  late final ValueNotifier<bool> _cyclicController;
  late final ValueNotifier<bool> _powerLossController;

  static const int _dateRangeDays = 90;

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
    _cyclicController = ValueNotifier(cyclicMode);
    _powerLossController = ValueNotifier(powerLossRecovery);

    // Scroll to start date position after frame
    final startOffset = _daysBetween(today, startDate);
    _dateScrollController = ScrollController(
      initialScrollOffset: (startOffset * 62.0).clamp(0, double.infinity),
    );
  }

  @override
  void dispose() {
    _cyclicController.dispose();
    _powerLossController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  int _daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays.clamp(0, _dateRangeDays);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

  void _onDateTap(DateTime date) {
    setState(() {
      if (_selectingStart) {
        startDate = date;
        if (endDate.isBefore(date)) endDate = date;
        _selectingStart = false;
      } else {
        if (!date.isBefore(startDate)) {
          endDate = date;
        } else {
          startDate = date;
          endDate = date;
        }
        _selectingStart = true;
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
                scheduleSectionLabel('Schedule Dates'),
                const SizedBox(height: 10),
                _buildDateRangePicker(),
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

  // ── Date Range Picker ───────────────────────────────────────────────────────

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start / End date header cards
        Row(
          children: [
            Expanded(child: _buildDateHeaderCard(isStart: true)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 10),
            Expanded(child: _buildDateHeaderCard(isStart: false)),
          ],
        ),
        const SizedBox(height: 12),
        // Selection hint
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _selectingStart ? 'Tap a date to set start' : 'Tap a date to set end',
              key: ValueKey(_selectingStart),
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Horizontal date scroll
        _buildHorizontalDateScroll(),
      ],
    );
  }

  Widget _buildDateHeaderCard({required bool isStart}) {
    final date = isStart ? startDate : endDate;
    final isActive = _selectingStart == isStart;
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];

    return GestureDetector(
      onTap: () => setState(() => _selectingStart = isStart),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : const Color(0xFFE5E7EB),
            width: isActive ? 0 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF004E7E).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStart ? 'START DATE' : 'END DATE',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF94A3B8),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day} $monthName ${date.year}',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayName,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDateScroll() {
    final today = DateTime.now();
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final days = ['Su','Mo','Tu','We','Th','Fr','Sa'];

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          controller: _dateScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: _dateRangeDays,
          itemBuilder: (ctx, i) {
            final date = today.add(Duration(days: i));
            final isStart = _isSameDay(date, startDate);
            final isEnd = _isSameDay(date, endDate);
            final inRange = !date.isBefore(startDate) &&
                !date.isAfter(endDate) &&
                !isStart &&
                !isEnd;
            final isSelected = isStart || isEnd;
            final dayLabel = days[date.weekday % 7];
            final monthLabel = months[date.month - 1];
            final isToday = _isSameDay(date, today);

            return GestureDetector(
              onTap: () => _onDateTap(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 54,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : inRange
                          ? const Color(0xFFEBF3FE)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(
                          color: const Color(0xFF3686AF).withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : inRange
                                ? const Color(0xFF004E7E)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${date.day}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : inRange
                                ? const Color(0xFF004E7E)
                                : isToday
                                    ? const Color(0xFF3686AF)
                                    : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.75)
                            : inRange
                                ? const Color(0xFF3686AF)
                                : const Color(0xFFB0B8C4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
