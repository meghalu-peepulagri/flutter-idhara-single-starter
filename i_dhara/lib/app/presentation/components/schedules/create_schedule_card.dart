import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widget.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_bottomsheets.dart';

// ── Multi-Schedule Container ─────────────────────────────────────────────────

class _ScheduleEntry {
  final int id;
  final GlobalKey<ScheduleFormState> formKey;
  bool isExpanded;

  _ScheduleEntry({
    required this.id,
    required this.formKey,
    this.isExpanded = true,
  });
}

class MultiScheduleForm extends StatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onBack;
  final bool showBottomBar;

  const MultiScheduleForm({
    super.key,
    this.onSave,
    this.onBack,
    this.showBottomBar = true,
  });

  @override
  State<MultiScheduleForm> createState() => MultiScheduleFormState();
}

class MultiScheduleFormState extends State<MultiScheduleForm> {
  // ── Public accessors for parent coordination ───────────────────────────────
  List<ScheduleFormState> get scheduleStates => _schedules
      .map((e) => e.formKey.currentState)
      .whereType<ScheduleFormState>()
      .toList();

  int get scheduleCount => _schedules.length;
  // ── Shared date state ──────────────────────────────────────────────────────
  late DateTime startDate;
  late DateTime endDate;
  late Set<int> selectedDays;

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

  int get _activeDays => endDate.difference(startDate).inDays.abs() + 1;
  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  // ── Schedule list ──────────────────────────────────────────────────────────
  final List<_ScheduleEntry> _schedules = [];
  int _nextId = 1;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    startDate = today;
    endDate = today;
    selectedDays = {};
    // Add first schedule directly (no setState) so it renders expanded on first build
    _schedules.add(_ScheduleEntry(
      id: _nextId++,
      formKey: GlobalKey<ScheduleFormState>(),
      isExpanded: true,
    ));
  }

  void _addSchedule() {
    setState(() {
      _schedules.add(_ScheduleEntry(
        id: _nextId++,
        formKey: GlobalKey<ScheduleFormState>(),
        isExpanded: true,
      ));
    });
    // Scroll to reveal the new card after it renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
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

  CalendarDatePicker2WithActionButtonsConfig _calendarConfig({
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.single,
      firstDate: firstDate,
      lastDate: lastDate,
      selectedDayHighlightColor: const Color(0xFF004E7E),
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
    );
  }

  Future<void> _openStartDatePicker() async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: _calendarConfig(
        firstDate: todayNorm,
        lastDate: DateTime(todayNorm.year + 2),
      ),
      dialogSize: const Size(340, 350),
      value: [startDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results != null && results.isNotEmpty && mounted) {
      final picked = results[0];
      if (picked == null) return;
      setState(() {
        startDate = picked;
        // clamp endDate: must be >= startDate and within 7 days
        final maxEnd = picked.add(const Duration(days: 6));
        if (endDate.isBefore(picked)) {
          endDate = picked;
        } else if (endDate.isAfter(maxEnd)) {
          endDate = maxEnd;
        }
        selectedDays.retainWhere((d) => _validDays.contains(d));
      });
    }
  }

  Future<void> _openEndDatePicker() async {
    final maxEnd = startDate.add(const Duration(days: 6));
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: _calendarConfig(
        firstDate: startDate,
        lastDate: maxEnd,
      ),
      dialogSize: const Size(340, 350),
      value: [endDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results != null && results.isNotEmpty && mounted) {
      final picked = results[0];
      if (picked == null) return;
      setState(() {
        endDate = picked;
        selectedDays.retainWhere((d) => _validDays.contains(d));
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared date card — shown once for all schedules
          _buildSharedDateCard(),
          // Add schedule row — right below the date card
          _buildAddScheduleRow(),
          const SizedBox(height: 4),
          // Schedule cards
          for (int i = 0; i < _schedules.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildScheduleCard(_schedules[i], i),
          ],
        ],
      ),
    );

    if (!widget.showBottomBar) return scroll;

    return Column(
      children: [
        Expanded(child: scroll),
        ScheduleFormBottomBar(
          onBack: widget.onBack ?? () {},
          onSave: widget.onSave ?? () {},
          isEditMode: false,
        ),
      ],
    );
  }

  Widget _buildAddScheduleRow() {
    return GestureDetector(
      onTap: _addSchedule,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              'Add Schedule',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004E7E),
              ),
            ),
            const Spacer(),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF004E7E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared date card ───────────────────────────────────────────────────────

  Widget _buildSharedDateCard() {
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
          // Header
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
                onTap: _openStartDatePicker,
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
                  onTap: _openStartDatePicker,
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
                  onTap: _openEndDatePicker,
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
          // Day chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final valid = _validDays.contains(i);
              final isActive = selectedDays.contains(i);
              return GestureDetector(
                onTap: valid ? () => _toggleDay(i) : null,
                child: Opacity(
                  opacity: valid ? 1.0 : 0.35,
                  child: Container(
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFEBF3FE)
                          : Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF3686AF)
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF004E7E)
                              : const Color(0xFF64748B),
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
        border: Border.all(color: const Color(0xFF94A3B8), width: 1.2),
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

  // ── Schedule card ──────────────────────────────────────────────────────────

  Widget _buildScheduleCard(_ScheduleEntry entry, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCardHeader(entry, index),
          // maintainState: true keeps ScheduleFormState alive when collapsed
          // so time / cyclic / power-recovery values are never lost.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: entry.isExpanded,
              maintainState: true,
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ScheduleForm(
                    key: entry.formKey,
                    onSave: () {},
                    onBack: () {},
                    showBottomBar: false,
                    showDateCard: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(_ScheduleEntry entry, int index) {
    final state = entry.formKey.currentState;
    return GestureDetector(
      onTap: () => setState(() => entry.isExpanded = !entry.isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule ${index + 1}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  // Show selected values summary when collapsed
                  if (!entry.isExpanded && state != null) ...[
                    const SizedBox(height: 4),
                    _buildCollapsedSummary(state),
                  ],
                ],
              ),
            ),
            if (_schedules.length > 1) ...[
              GestureDetector(
                onTap: () => _removeSchedule(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              entry.isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSummary(ScheduleFormState state) {
    final sh = state.startHour.toString().padLeft(2, '0');
    final sm = state.startMinute.toString().padLeft(2, '0');
    final eh = state.endHour.toString().padLeft(2, '0');
    final em = state.endMinute.toString().padLeft(2, '0');
    final timeLine = '$sh:$sm → $eh:$em';

    final String detailLine;
    if (state.cyclicMode) {
      detailLine =
          'Cyclic  ON ${state.cyclicOnMinutes}m / OFF ${state.cyclicOffMinutes}m';
    } else {
      final parts = <String>[state.durationText];
      if (state.powerLossRecovery) parts.add('Power Recovery ON');
      detailLine = parts.join('  •  ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeLine,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF004E7E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detailLine,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

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
    final today = DateTime.now();
    startDate = widget.initialStartDate ?? today;
    endDate = widget.initialEndDate ?? today;

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
    // Max end = start + 6 days → 7 days total; dates beyond are disabled
    final maxEnd = startDate.add(const Duration(days: 6));
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
        final endLimit = startDate.add(const Duration(days: 6));
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

  // ── Form content ─────────────────────────────────────────────────────────

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date card — only shown in standalone (single) mode
        if (widget.showDateCard) ...[
          _buildDateCard(),
          const SizedBox(height: 24),
        ],
        scheduleSectionLabel('Schedule Timing'),
        const SizedBox(height: 10),
        _buildTimingCard(),
        const SizedBox(height: 16),
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
              final total = durationMinutes;
              if (cyclicOnMinutes + cyclicOffMinutes > total) {
                cyclicOnMinutes = (total ~/ 2).clamp(5, 120);
                cyclicOffMinutes = (total - cyclicOnMinutes).clamp(5, 120);
              }
            } else {
              cyclicOnMinutes = 20;
              cyclicOffMinutes = 15;
            }
          }),
          onOnDecrement: () => setState(() {
            if (cyclicOnMinutes > 5) cyclicOnMinutes -= 5;
          }),
          onOnIncrement: () => setState(() {
            final maxOn = durationMinutes - cyclicOffMinutes;
            if (cyclicOnMinutes + 5 <= maxOn && cyclicOnMinutes < 120) {
              cyclicOnMinutes += 5;
            }
          }),
          onOffDecrement: () => setState(() {
            if (cyclicOffMinutes > 5) cyclicOffMinutes -= 5;
          }),
          onOffIncrement: () => setState(() {
            final maxOff = durationMinutes - cyclicOnMinutes;
            if (cyclicOffMinutes + 5 <= maxOff && cyclicOffMinutes < 120) {
              cyclicOffMinutes += 5;
            }
          }),
          onIncrementEnabled:
              cyclicOnMinutes + 5 <= durationMinutes - cyclicOffMinutes &&
                  cyclicOnMinutes < 120,
          offIncrementEnabled:
              cyclicOffMinutes + 5 <= durationMinutes - cyclicOnMinutes &&
                  cyclicOffMinutes < 120,
          onDecrementEnabled: cyclicOnMinutes > 5,
          offDecrementEnabled: cyclicOffMinutes > 5,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Embedded inside MultiScheduleForm — no Expanded, no bottom bar
    if (!widget.showBottomBar) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _buildFormContent(),
      );
    }

    // Standalone usage (create / edit single schedule)
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final valid = _validDays.contains(i);
              final isActive = selectedDays.contains(i);
              return GestureDetector(
                onTap: valid ? () => _toggleDay(i) : null,
                child: Opacity(
                  opacity: valid ? 1.0 : 0.35,
                  child: Container(
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFEBF3FE)
                          : Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF3686AF)
                            : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF004E7E)
                              : const Color(0xFF64748B),
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
        border: Border.all(color: const Color(0xFF94A3B8), width: 1.2),
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
