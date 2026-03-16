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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

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

  Future<void> _openCalendarDialog() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CalendarRangeDialog(
        initialStart: startDate,
        initialEnd: endDate,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        startDate = result.start;
        endDate = result.end;
      });
    }
  }

  // Returns set of weekday numbers (1=Mon...7=Sun) covered by the date range
  Set<int> _activeDayNumbers() {
    final active = <int>{};
    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays >= 7) return {1, 2, 3, 4, 5, 6, 7};
    for (int i = 0; i < totalDays; i++) {
      active.add(startDate.add(Duration(days: i)).weekday);
    }
    return active;
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
    final activeDays = _activeDayNumbers();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Icon(Icons.arrow_forward_rounded,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          // Day chips
          Row(
            children: List.generate(7, (i) {
              final dayNum = i + 1; // 1=Mon...7=Sun
              final isActive = activeDays.contains(dayNum);
              return Expanded(
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
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF004E7E)
                              : const Color(0xFFB0B8C4),
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
                  child: _buildTimePicker('START', startHour, startMinute, true)),
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

// ── Calendar Range Dialog ────────────────────────────────────────────────────

class _CalendarRangeDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;

  const _CalendarRangeDialog({
    required this.initialStart,
    required this.initialEnd,
  });

  @override
  State<_CalendarRangeDialog> createState() => _CalendarRangeDialogState();
}

class _CalendarRangeDialogState extends State<_CalendarRangeDialog> {
  late DateTime _viewMonth;
  late DateTime _start;
  late DateTime _end;
  bool _pickingEnd = false;

  static const _fullMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekDayHeaders = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _viewMonth = DateTime(_start.year, _start.month);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDayTap(DateTime date) {
    setState(() {
      if (!_pickingEnd) {
        _start = date;
        _end = date;
        _pickingEnd = true;
      } else {
        if (!date.isBefore(_start)) {
          _end = date;
        } else {
          _end = _start;
          _start = date;
        }
        _pickingEnd = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final leadingEmpty = (firstDay.weekday - 1) % 7;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  'Date',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(
                    context,
                    DateTimeRange(start: _start, end: _end),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          // ── Month navigation ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF004E7E)),
                  onPressed: () => setState(() => _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month - 1)),
                ),
                Text(
                  '${_fullMonths[_viewMonth.month - 1]} ${_viewMonth.year}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF004E7E)),
                  onPressed: () => setState(() => _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month + 1)),
                ),
              ],
            ),
          ),
          // ── Weekday headers ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _weekDayHeaders
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
          // ── Calendar grid ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2,
                crossAxisSpacing: 0,
              ),
              itemCount: leadingEmpty + daysInMonth,
              itemBuilder: (ctx, index) {
                if (index < leadingEmpty) return const SizedBox.shrink();
                final day = index - leadingEmpty + 1;
                final date =
                    DateTime(_viewMonth.year, _viewMonth.month, day);
                final isStart = _isSameDay(date, _start);
                final isEnd = _isSameDay(date, _end);
                final isSelected = isStart || isEnd;
                final inRange = !isSelected &&
                    date.isAfter(_start) &&
                    date.isBefore(_end);
                final isToday = _isSameDay(date, todayNorm);
                final isPast = date.isBefore(todayNorm);

                return GestureDetector(
                  onTap: () => _onDayTap(date),
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF004E7E)
                          : inRange
                              ? const Color(0xFFEBF3FE)
                              : null,
                      shape: isSelected
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius:
                          isSelected ? null : BorderRadius.circular(4),
                      border: (!isSelected && isToday)
                          ? Border.all(
                              color: const Color(0xFF3686AF),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : inRange
                                  ? const Color(0xFF004E7E)
                                  : isPast
                                      ? const Color(0xFFB0B8C4)
                                      : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          // ── Start / End date display ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _buildDateField('Start Date', _start)),
                const SizedBox(width: 10),
                Expanded(child: _buildDateField('End Date', _end)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            formatted,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
