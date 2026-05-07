import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widget.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_bottomsheets.dart';

part 'schedule_form_builders.dart';

// ── Single Schedule Form ─────────────────────────────────────────────────────

class ScheduleForm extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onBack;
  final bool isEditMode;
  final bool showBottomBar;
  final bool showDateCard;

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
    this.isEditMode = false,
    this.showBottomBar = true,
    this.showDateCard = true,
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
  late Set<int> selectedDays;

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
    'Dec',
  ];

  bool get _isStartDateToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Normalize today to midnight — see MultiScheduleFormState.initState
    // for why this matters for the day-chip valid-day calculation.
    final todayNorm = DateTime(now.year, now.month, now.day);
    startDate = widget.initialStartDate ?? todayNorm;
    endDate = widget.initialEndDate ?? todayNorm;

    if (widget.initialStartHour == null && widget.initialStartMinute == null) {
      final now = DateTime.now();
      final isToday = startDate.year == now.year &&
          startDate.month == now.month &&
          startDate.day == now.day;
      if (isToday) {
        startHour = now.hour;
        startMinute = now.minute;
      } else {
        startHour = 0;
        startMinute = 0;
      }
    } else {
      startHour = widget.initialStartHour ?? 0;
      startMinute = widget.initialStartMinute ?? 0;
    }

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

  void _clampCyclicDurations() {
    final total = durationMinutes;
    if (cyclicOnMinutes + cyclicOffMinutes > total) {
      cyclicOnMinutes = (total ~/ 2).clamp(5, 120);
      cyclicOffMinutes = (total - cyclicOnMinutes).clamp(5, 120);
    }
  }

  Set<int> get _validDays {
    final days = <int>{};
    final rangeLength = endDate.difference(startDate).inDays.abs() + 1;
    if (rangeLength >= 7) return {0, 1, 2, 3, 4, 5, 6};
    for (int i = 0; i < rangeLength; i++) {
      final wd = startDate.add(Duration(days: i)).weekday;
      days.add(wd == 7 ? 0 : wd);
    }
    return days;
  }

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  int get durationMinutes {
    final start = DateTime(
        startDate.year, startDate.month, startDate.day, startHour, startMinute);
    final end =
        DateTime(endDate.year, endDate.month, endDate.day, endHour, endMinute);
    final endAdjusted = end.isBefore(start) || end.isAtSameMomentAs(start)
        ? end.add(const Duration(days: 1))
        : end;
    return endAdjusted.difference(start).inMinutes;
  }

  String get durationText {
    final total = durationMinutes;
    final d = total ~/ 1440;
    final h = (total % 1440) ~/ 60;
    final m = total % 60;
    if (d > 0) return '${d}d ${h}h ${m.toString().padLeft(2, '0')}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  void _onTimePicked(TimeOfDay t, bool isStart) => setState(() {
        if (isStart) {
          startHour = t.hour;
          startMinute = t.minute;
          endHour = 0;
          endMinute = 0;
        } else {
          endHour = t.hour;
          endMinute = t.minute;
        }
        if (cyclicMode) _clampCyclicDurations();
      });

  void _openTimePicker(bool isStart) {
    TimeOfDay? minTime;
    if (isStart && _isStartDateToday) {
      final now = DateTime.now();
      minTime = TimeOfDay(hour: now.hour, minute: now.minute);
    } else if (!isStart) {
      final isSameDate = startDate.year == endDate.year &&
          startDate.month == endDate.month &&
          startDate.day == endDate.day;
      if (isSameDate) minTime = startTime;
    }
    showTimeBottomSheet(
      context,
      isStart ? startTime : endTime,
      (picked) => _onTimePicked(picked, isStart),
      minTime: minTime,
    );
  }

  Future<void> _openCalendarDialog() async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    // Max end = start + 14 days → 15 days total; dates beyond are disabled
    final maxEnd = startDate.add(const Duration(days: 14));
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        firstDate: todayNorm,
        lastDate: maxEnd,
        selectedDayHighlightColor: const Color(0xFF004E7E),
        selectedRangeHighlightColor: const Color(0xFFEBF3FE),
        selectedDayTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        todayTextStyle: const TextStyle(
            color: Color(0xFF004E7E), fontWeight: FontWeight.w600),
        dayTextStyle: const TextStyle(
            color: Color(0xFF0F172A), fontWeight: FontWeight.w400),
        disabledDayTextStyle: const TextStyle(color: Color(0xFFB0B8C4)),
        weekdayLabelTextStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
            fontSize: 12),
        controlsTextStyle: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 14),
        lastMonthIcon:
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF004E7E)),
        nextMonthIcon:
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF004E7E)),
        okButtonTextStyle: const TextStyle(
            color: Color(0xFF004E7E),
            fontWeight: FontWeight.w600,
            fontSize: 14),
        cancelButtonTextStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 14),
      ),
      dialogSize: const Size(340, 350),
      value: [startDate, endDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results != null && results.isNotEmpty && mounted) {
      setState(() {
        startDate = results[0] ?? startDate;
        final rawEnd =
            results.length > 1 ? (results[1] ?? startDate) : startDate;
        final endLimit = startDate.add(const Duration(days: 14));
        endDate = rawEnd.isAfter(endLimit) ? endLimit : rawEnd;
        selectedDays.retainWhere((d) => _validDays.contains(d));
        if (_isStartDateToday) {
          final now = DateTime.now();
          startHour = now.hour;
          startMinute = now.minute;
        } else {
          startHour = 0;
          startMinute = 0;
        }
        endHour = 0;
        endMinute = 0;
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

  // ── Cyclic / Power-loss state mutators ─────────────────────────────────────

  void _onCyclicChanged(bool v) {
    setState(() {
      cyclicMode = v;
      _cyclicController.value = v;
      if (v) {
        powerLossRecovery = false;
        _powerLossController.value = false;
        final total = durationMinutes;
        if (cyclicOnMinutes + cyclicOffMinutes > total) {
          cyclicOnMinutes = (total ~/ 2).clamp(5, 120);
          cyclicOffMinutes = (total - cyclicOnMinutes).clamp(5, 120);
        }
      } else {
        cyclicOnMinutes = 20;
        cyclicOffMinutes = 15;
      }
    });
  }

  void _onCyclicOnDecrement() {
    setState(() {
      if (cyclicOnMinutes > 5) cyclicOnMinutes -= 5;
    });
  }

  void _onCyclicOnIncrement() {
    setState(() {
      final maxOn = durationMinutes - cyclicOffMinutes;
      if (cyclicOnMinutes + 5 <= maxOn && cyclicOnMinutes < 120) {
        cyclicOnMinutes += 5;
      }
    });
  }

  void _onCyclicOffDecrement() {
    setState(() {
      if (cyclicOffMinutes > 5) cyclicOffMinutes -= 5;
    });
  }

  void _onCyclicOffIncrement() {
    setState(() {
      final maxOff = durationMinutes - cyclicOnMinutes;
      if (cyclicOffMinutes + 5 <= maxOff && cyclicOffMinutes < 120) {
        cyclicOffMinutes += 5;
      }
    });
  }

  void _onPowerLossChanged(bool v) {
    setState(() {
      powerLossRecovery = v;
      _powerLossController.value = v;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Embedded inside MultiScheduleForm — no Expanded, no bottom bar
    if (!widget.showBottomBar) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: _buildFormContent(),
      );
    }

    // Standalone usage (create / edit single schedule)
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildFormContent(),
          ),
        ),
        ScheduleFormBottomBar(
          onBack: widget.onBack,
          onSave: widget.onSave,
          isEditMode: widget.isEditMode,
        ),
      ],
    );
  }
}
