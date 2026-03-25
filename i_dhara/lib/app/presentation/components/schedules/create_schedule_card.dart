import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widgets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_bottom_sheets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_dialogs.dart';

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
  late final TextEditingController _powerLossTimeCtrl;
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    startDate = widget.initialStartDate ?? today;
    endDate = widget.initialEndDate ?? today;

    // Default start time to "now" when opening fresh on today's date
    final isStartToday = widget.initialStartDate == null ||
        (widget.initialStartDate!.year == today.year &&
            widget.initialStartDate!.month == today.month &&
            widget.initialStartDate!.day == today.day);
    if (widget.initialStartHour != null) {
      startHour = widget.initialStartHour!;
      startMinute = widget.initialStartMinute ?? 0;
    } else if (isStartToday) {
      startHour = now.hour;
      startMinute = now.minute;
    } else {
      startHour = 0;
      startMinute = 0;
    }

    // Default end time to start + 5 min
    if (widget.initialEndHour != null) {
      endHour = widget.initialEndHour!;
      endMinute = widget.initialEndMinute ?? 0;
    } else {
      final endTotal = startHour * 60 + startMinute + 5;
      endHour = (endTotal ~/ 60) % 24;
      endMinute = endTotal % 60;
    }
    cyclicMode = widget.initialCyclicMode ?? false;
    cyclicOnMinutes = widget.initialCyclicOnMinutes ?? 20;
    cyclicOffMinutes = widget.initialCyclicOffMinutes ?? 15;
    powerLossRecovery = widget.initialPowerLossRecovery ?? false;
    _powerLossTimeCtrl = TextEditingController(text: '30');
    selectedDays = widget.initialSelectedDays?.toSet() ?? {};
    _cyclicController = ValueNotifier(cyclicMode);
    _powerLossController = ValueNotifier(powerLossRecovery);
  }

  @override
  void dispose() {
    _cyclicController.dispose();
    _powerLossController.dispose();
    _powerLossTimeCtrl.dispose();
    super.dispose();
  }

  /// Returns the entered delay clamped to 1–60; defaults to 30.
  int get powerLossRecoveryTime {
    final n = int.tryParse(_powerLossTimeCtrl.text) ?? 30;
    return n.clamp(1, 60);
  }

  int get _activeDays => endDate.difference(startDate).inDays.abs() + 1;

  /// Weekdays (Mon=1…Sat=6, Sun=7) that actually exist in the selected range.
  Set<int> get _availableDays {
    final diff = endDate.difference(startDate).inDays;
    if (diff >= 6) return {1, 2, 3, 4, 5, 6, 7};
    final days = <int>{};
    for (int i = 0; i <= diff; i++) {
      days.add(startDate.add(Duration(days: i)).weekday); // Mon=1…Sun=7
    }
    return days;
  }

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
          // If end time is not after new start time, bump it by 5 min
          final startTotal = t.hour * 60 + t.minute;
          final endTotal = endHour * 60 + endMinute;
          if (endTotal <= startTotal) {
            final bumped = startTotal + 5;
            endHour = (bumped ~/ 60) % 24;
            endMinute = bumped % 60;
          }
        } else {
          endHour = t.hour;
          endMinute = t.minute;
        }
      });

  void _openTimePicker(bool isStart) {
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    final isStartToday = startDate == todayNorm;
    final nowTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final isEndToday = endDate == todayNorm;
    final isSameDay = startDate == endDate;

    TimeOfDay? minT;
    if (isStart) {
      minT = isStartToday ? nowTime : null;
    } else {
      if (isSameDay) {
        // Same day: end must be after start (and after now if today)
        if (isEndToday) {
          final startTotal = startHour * 60 + startMinute;
          final nowTotal = nowTime.hour * 60 + nowTime.minute;
          minT = startTotal >= nowTotal ? startTime : nowTime;
        } else {
          minT = startTime;
        }
      } else {
        // End date is a future date — no time restriction
        minT = null;
      }
    }

    showTimeBottomSheet(
      context,
      isStart ? startTime : endTime,
      (picked) => _onTimePicked(picked, isStart),
      minTime: minT,
    );
  }

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
        // Remove selected days that no longer fall in the new range
        selectedDays.removeWhere((d) => !_availableDays.contains(d));

        final now = DateTime.now();
        final todayNorm = DateTime(now.year, now.month, now.day);
        if (startDate == todayNorm) {
          startHour = now.hour;
          startMinute = now.minute;
        } else {
          startHour = 0;
          startMinute = 0;
        }
        if (endDate == startDate) {
          final endTotal = startHour * 60 + startMinute + 5;
          endHour = (endTotal ~/ 60) % 24;
          endMinute = endTotal % 60;
        } else {
          endHour = 0;
          endMinute = 0;
        }
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

  Widget _buildPowerLossCard() {
    return Opacity(
      opacity: cyclicMode ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            // ── Toggle row ──────────────────────────────────
            Row(
              children: [
                const Icon(Icons.power_rounded,
                    size: 18, color: Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Power Loss Recovery',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('Auto-resume after power restored',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: cyclicMode
                      ? null
                      : () async {
                          final enabling = !powerLossRecovery;
                          final confirmed = await showPowerLossConfirmDialog(
                              context, enabling);
                          if (!confirmed || !mounted) return;
                          setState(() {
                            powerLossRecovery = enabling;
                            _powerLossController.value = enabling;
                            if (!enabling) _powerLossTimeCtrl.text = '30';
                          });
                        },
                  child: AbsorbPointer(
                    child: AdvancedSwitch(
                      controller: _powerLossController,
                      initialValue: _powerLossController.value,
                      activeColor: const Color(0xFF34C759),
                      inactiveColor: const Color(0xFFE0E0E0),
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      width: 46,
                      height: 24,
                      enabled: !cyclicMode,
                      onChanged: null,
                    ),
                  ),
                ),
              ],
            ),
            // ── Inline delay input (shown when ON) ──────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: powerLossRecovery && !cyclicMode
                  ? Column(
                      children: [
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: Color(0xFF004E7E)),
                            const SizedBox(width: 8),
                            Text(
                              'Recovery Time',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF374151)),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _powerLossTimeCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (val) {
                                  final n = int.tryParse(val);
                                  if (n != null && n > 60) {
                                    _powerLossTimeCtrl.text = '60';
                                    _powerLossTimeCtrl.selection =
                                        const TextSelection.collapsed(
                                            offset: 2);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: '30',
                                  // hintStyle: TextStyle(
                                  //   color: Colors.grey.shade400,
                                  //   fontWeight: FontWeight.normal,
                                  // ),
                                  suffixText: 'mins',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF004E7E)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
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
                    } else {
                      cyclicOnMinutes = 20;
                      cyclicOffMinutes = 15;
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
                _buildPowerLossCard(),
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
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
          // Day chips — only days in the selected date range are tappable
          Row(
            children: List.generate(7, (i) {
              final dayNum = i == 0 ? 7 : i; // Sun=7, Mon=1...Sat=6
              final isAvailable = _availableDays.contains(dayNum);
              final isActive = isAvailable && selectedDays.contains(dayNum);
              return Expanded(
                child: GestureDetector(
                  onTap: isAvailable ? () => _toggleDay(dayNum) : null,
                  child: Opacity(
                    opacity: isAvailable ? 1.0 : 0.35,
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
