import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widget.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_bottomsheets.dart';

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

  final int existingScheduleCount;
  final DateTime? initialDate;

  const MultiScheduleForm({
    super.key,
    this.onSave,
    this.onBack,
    this.showBottomBar = true,
    this.existingScheduleCount = 0,
    this.initialDate,
  });

  @override
  State<MultiScheduleForm> createState() => MultiScheduleFormState();
}

class MultiScheduleFormState extends State<MultiScheduleForm> {
  List<ScheduleFormState> get scheduleStates => _schedules
      .map((e) => e.formKey.currentState)
      .whereType<ScheduleFormState>()
      .toList();

  int get scheduleCount => _schedules.length;
  late DateTime startDate;
  late DateTime endDate;
  late Set<int> selectedDays;

  bool _multiDay = false;
  final ValueNotifier<bool> _singleDayController = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _multiDayController = ValueNotifier<bool>(false);

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

  int get _activeDays {
    if (selectedDays.isEmpty) return 0;
    final rangeLength = endDate.difference(startDate).inDays.abs() + 1;
    int count = 0;
    for (int i = 0; i < rangeLength; i++) {
      final wd = startDate.add(Duration(days: i)).weekday;
      // weekday: Mon=1..Sun=7 in Dart; selectedDays uses Sun=0..Sat=6.
      final dayIndex = wd == 7 ? 0 : wd;
      if (selectedDays.contains(dayIndex)) count++;
    }
    return count;
  }

  Map<int, int> get _dayCounts {
    final counts = <int, int>{};
    final rangeLength = endDate.difference(startDate).inDays.abs() + 1;
    for (int i = 0; i < rangeLength; i++) {
      final wd = startDate.add(Duration(days: i)).weekday;
      final di = wd == 7 ? 0 : wd;
      counts[di] = (counts[di] ?? 0) + 1;
    }
    return counts;
  }

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const int _absoluteMaxSchedules = 4;
  static const int _maxRangeDays = 15;
  final List<_ScheduleEntry> _schedules = [];
  int _nextId = 1;
  final _scrollController = ScrollController();

  // Banner stays hidden until the user taps Save with an invalid or
  // overlapping schedule. The message is captured at that moment so the banner
  // reads the failure the user just triggered, not whatever state the form is
  // in afterwards. Any edit or the close icon clears it.
  bool _showConflict = false;
  String? _conflictBannerMessage;

  int get _maxSchedules {
    final remaining = _absoluteMaxSchedules - widget.existingScheduleCount;
    return remaining < 1 ? 1 : remaining;
  }

  /// Returns a human-readable message describing the first pair of schedules
  /// whose time ranges overlap (including midnight-wrap cases) so the user
  /// knows which entries to fix. Returns null when every schedule occupies a
  /// distinct slot.
  String? _scheduleConflictMessage() {
    final all = scheduleStates;
    if (all.length < 2) return null;

    List<List<int>> intervals(ScheduleFormState s) {
      final start = s.startHour * 60 + s.startMinute;
      final end = s.endHour * 60 + s.endMinute;
      // end <= start ⇒ wraps midnight, split into two day-bounded segments.
      if (end <= start) {
        return [
          [start, 1440],
          [0, end],
        ];
      }
      return [
        [start, end],
      ];
    }

    bool overlaps(ScheduleFormState a, ScheduleFormState b) {
      for (final ai in intervals(a)) {
        for (final bi in intervals(b)) {
          if (ai[1] > bi[0] && bi[1] > ai[0]) return true;
        }
      }
      return false;
    }

    for (int i = 0; i < all.length; i++) {
      if (all[i].durationMinutes <= 0) continue;
      for (int j = i + 1; j < all.length; j++) {
        if (all[j].durationMinutes <= 0) continue;
        if (overlaps(all[i], all[j])) {
          return 'Schedule ${i + 1} and Schedule ${j + 1} have overlapping times. Adjust the start or end time.';
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _singleDayController.dispose();
    _multiDayController.dispose();
    super.dispose();
  }

  void _setMultiDay(bool multi) {
    if (_multiDay == multi) return;
    setState(() {
      _multiDay = multi;
      _singleDayController.value = !multi;
      _multiDayController.value = multi;
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    final todayNorm = DateTime(now.year, now.month, now.day);
    // Seed from the date selected on the motor schedule tab when provided;
    // fall back to today. Never start before today (the date pickers also
    // gate on firstDate = today).
    final picked = widget.initialDate;
    final baseDate = (picked != null &&
            !DateTime(picked.year, picked.month, picked.day)
                .isBefore(todayNorm))
        ? DateTime(picked.year, picked.month, picked.day)
        : todayNorm;
    startDate = baseDate;
    endDate = baseDate;
    // Pre-select the base date's weekday so the user immediately sees the
    // current day chip rendered in the active state — no second tap
    // needed for a same-day schedule. Sun=0..Sat=6 mapping (Dart's
    // weekday returns Mon=1..Sun=7).
    final baseWd = baseDate.weekday == 7 ? 0 : baseDate.weekday;
    selectedDays = {baseWd};
    // Add first schedule directly (no setState) so it renders expanded on first build
    _schedules.add(_ScheduleEntry(
      id: _nextId++,
      formKey: GlobalKey<ScheduleFormState>(),
      isExpanded: true,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _addSchedule() {
    if (_schedules.length >= _maxSchedules) return;
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
        // clamp endDate: must be >= startDate and within the allowed range
        final maxEnd = picked.add(const Duration(days: _maxRangeDays - 1));
        if (endDate.isBefore(picked)) {
          endDate = picked;
        } else if (endDate.isAfter(maxEnd)) {
          endDate = maxEnd;
        }
        // Auto-select every weekday that falls inside the new range so
        // the chip row mirrors the picked dates by default — user can
        // still tap individual chips off to filter further.
        selectedDays = Set<int>.from(_validDays);
      });
    }
  }

  Future<void> _openEndDatePicker() async {
    final maxEnd = startDate.add(const Duration(days: _maxRangeDays - 1));
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
        // Same auto-select rule as `_openStartDatePicker`: extend the
        // chip selection to every weekday now in the range.
        selectedDays = Set<int>.from(_validDays);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSharedDateCard(),
          const SizedBox(height: 8),
          _buildAddScheduleRow(),
          const SizedBox(height: 8),
          for (int i = 0; i < _schedules.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildScheduleCard(_schedules[i], i),
          ],
        ],
      ),
    );

    if (!widget.showBottomBar) return scroll;

    final showBanner = _showConflict && _conflictBannerMessage != null;

    return Column(
      children: [
        Expanded(child: scroll),
        if (showBanner) _buildConflictBanner(_conflictBannerMessage!),
        ScheduleFormBottomBar(
          onBack: widget.onBack ?? () {},
          onSave: _handleSavePressed,
          isEditMode: false,
          saveEnabled: true,
        ),
      ],
    );
  }

  void _handleSavePressed() {
    final states = scheduleStates;
    final hasInvalidDuration = states.length != _schedules.length ||
        states.any((s) => s.durationMinutes <= 0);
    if (hasInvalidDuration) {
      setState(() {
        _conflictBannerMessage =
            'Set a valid start and end time for every schedule before saving.';
        _showConflict = true;
      });
      return;
    }
    final conflict = _scheduleConflictMessage();
    if (conflict != null) {
      setState(() {
        _conflictBannerMessage = conflict;
        _showConflict = true;
      });
      return;
    }
    widget.onSave?.call();
  }

  Widget _buildConflictBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: Color(0xFFE53935)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB71C1C),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _showConflict = false),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: const Color(0xFFE53935).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddScheduleRow() {
    final canAdd = _schedules.length < _maxSchedules;
    return GestureDetector(
      onTap: canAdd ? _addSchedule : null,
      child: Opacity(
        opacity: canAdd ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(
                canAdd
                    ? 'Add Schedule'
                    : 'Maximum $_absoluteMaxSchedules schedules per date reached',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004E7E),
                ),
              ),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF004E7E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedDateCard() {
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Date Range',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004E7E),
            ),
          ),
          const SizedBox(height: 8),
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
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Color(0xFF94A3B8)),
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
          _buildModeToggles(),
          if (_multiDay) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Select Days',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004E7E),
                  ),
                ),
                const Spacer(),
                if (selectedDays.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Builder(builder: (_) {
                final counts = _dayCounts;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final valid = _validDays.contains(i);
                    final isActive = selectedDays.contains(i);
                    final count = counts[i] ?? 0;
                    return GestureDetector(
                      onTap: valid ? () => _toggleDay(i) : null,
                      child: Opacity(
                        opacity: valid ? 1.0 : 0.35,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 34,
                              height: 26,
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
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? const Color(0xFF004E7E)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            if (isActive && count > 1)
                              Positioned(
                                top: -7,
                                right: -6,
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 14),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004E7E),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeToggles() {
    return Column(
      children: [
        buildScheduleToggle(
          icon: Icons.event_rounded,
          title: 'Single Day Schedule',
          subtitle: 'Run on the selected date only',
          controller: _singleDayController,
          onChanged: (v) => _setMultiDay(!v),
        ),
        const SizedBox(height: 8),
        buildScheduleToggle(
          icon: Icons.date_range_rounded,
          title: 'Multi Day Schedule',
          subtitle: 'Run across selected weekdays',
          controller: _multiDayController,
          onChanged: (v) => _setMultiDay(v),
        ),
      ],
    );
  }

  Widget _buildDateBox(String label, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          const SizedBox(height: 2),
          Text(
            _fmtDate(date),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

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
                    isMultiDay: _multiDay,
                    initialStartDate: startDate,
                    initialEndDate: endDate,
                    onChanged: () {
                      if (!mounted) return;
                      setState(() {
                        if (_showConflict) {
                          _showConflict = false;
                          _conflictBannerMessage = null;
                        }
                      });
                    },
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule ${index + 1}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (!entry.isExpanded && state != null) ...[
                    const SizedBox(height: 2),
                    _buildCollapsedSummary(state),
                  ],
                ],
              ),
            ),
            if (_schedules.length > 1) ...[
              GestureDetector(
                onTap: () => _removeSchedule(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
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
              size: 26,
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

class ScheduleForm extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onBack;
  final bool isEditMode;
  final bool showBottomBar;
  final bool showDateCard;
  final bool isMultiDay;

  final VoidCallback? onChanged;

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
    this.isMultiDay = false,
    this.onChanged,
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

  bool get _isSingleDay =>
      startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;

  ({int sh, int sm, int eh, int em}) _defaultsForDate(DateTime startD) {
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;
    final startIsToday = isToday(startD);
    final endIsToday = isToday(endDate);

    final sh = startIsToday ? now.hour : 0;
    final sm = startIsToday ? now.minute : 0;

    int eh, em;
    if (endIsToday) {
      final endTotal = (startIsToday ? now.hour * 60 + now.minute : 0) + 5;
      eh = (endTotal ~/ 60) % 24;
      em = endTotal % 60;
    } else if (startIsToday) {
      eh = 0;
      em = 0;
    } else {
      eh = 0;
      em = 5;
    }
    return (sh: sh, sm: sm, eh: eh, em: em);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final todayNorm = DateTime(now.year, now.month, now.day);
    startDate = widget.initialStartDate ?? todayNorm;
    endDate = widget.initialEndDate ?? todayNorm;

    if (widget.initialStartHour == null && widget.initialStartMinute == null) {
      // Fresh create — seed both start and end so the user sees a usable
      // default window (today-only: now → now+5m, otherwise 00:00 → 00:05).
      final d = _defaultsForDate(startDate);
      startHour = d.sh;
      startMinute = d.sm;
      endHour = d.eh;
      endMinute = d.em;
    } else {
      // Edit mode — the parent supplies the existing record's values.
      startHour = widget.initialStartHour ?? 0;
      startMinute = widget.initialStartMinute ?? 0;
      endHour = widget.initialEndHour ?? 0;
      endMinute = widget.initialEndMinute ?? 0;
    }
    cyclicMode = widget.initialCyclicMode ?? false;
    cyclicOnMinutes = widget.initialCyclicOnMinutes ?? 20;
    cyclicOffMinutes = widget.initialCyclicOffMinutes ?? 15;
    powerLossRecovery = widget.initialPowerLossRecovery ?? false;
    selectedDays = widget.initialSelectedDays?.toSet() ?? {};
    _cyclicController = ValueNotifier(cyclicMode);
    _powerLossController = ValueNotifier(powerLossRecovery);
    // Snapshot the initial values so edit mode can gate the Save
    // button on "is anything actually changed?". Create mode never
    // reads these (saveEnabled bypasses the dirty check).
    _initialStartHour = startHour;
    _initialStartMinute = startMinute;
    _initialEndHour = endHour;
    _initialEndMinute = endMinute;
    _initialCyclicMode = cyclicMode;
    _initialCyclicOnMinutes = cyclicOnMinutes;
    _initialCyclicOffMinutes = cyclicOffMinutes;
    _initialPowerLossRecovery = powerLossRecovery;
  }

  // Snapshots of the values at form mount — only used in edit mode to
  // decide whether anything has actually been changed and the Save
  // button should be enabled.
  late final int _initialStartHour;
  late final int _initialStartMinute;
  late final int _initialEndHour;
  late final int _initialEndMinute;
  late final bool _initialCyclicMode;
  late final int _initialCyclicOnMinutes;
  late final int _initialCyclicOffMinutes;
  late final bool _initialPowerLossRecovery;

  /// True when any edit-mode-editable field differs from the initial
  /// snapshot taken in `initState`. Cyclic on/off minutes only count
  /// when the user is currently in cyclic mode — toggling cyclic off
  /// makes those values irrelevant.
  bool get _isDirty {
    if (startHour != _initialStartHour ||
        startMinute != _initialStartMinute ||
        endHour != _initialEndHour ||
        endMinute != _initialEndMinute ||
        cyclicMode != _initialCyclicMode ||
        powerLossRecovery != _initialPowerLossRecovery) {
      return true;
    }
    if (cyclicMode &&
        (cyclicOnMinutes != _initialCyclicOnMinutes ||
            cyclicOffMinutes != _initialCyclicOffMinutes)) {
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant ScheduleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStart = widget.initialStartDate;
    final newEnd = widget.initialEndDate;
    final startChanged =
        newStart != null && newStart != oldWidget.initialStartDate;
    final endChanged = newEnd != null && newEnd != oldWidget.initialEndDate;
    if (!startChanged && !endChanged) return;
    setState(() {
      if (startChanged) startDate = newStart;
      if (endChanged) endDate = newEnd;
      final d = _defaultsForDate(startDate);
      startHour = d.sh;
      startMinute = d.sm;
      endHour = d.eh;
      endMinute = d.em;
      selectedDays.retainWhere((d) => _validDays.contains(d));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged?.call();
    });
  }

  @override
  void dispose() {
    _cyclicController.dispose();
    _powerLossController.dispose();
    super.dispose();
  }

  int get _activeDays {
    if (selectedDays.isEmpty) return 0;
    final rangeLength = endDate.difference(startDate).inDays.abs() + 1;
    int count = 0;
    for (int i = 0; i < rangeLength; i++) {
      final wd = startDate.add(Duration(days: i)).weekday;
      // weekday: Mon=1..Sun=7 in Dart; selectedDays uses Sun=0..Sat=6.
      final dayIndex = wd == 7 ? 0 : wd;
      if (selectedDays.contains(dayIndex)) count++;
    }
    return count;
  }

  Map<int, int> get _dayCounts {
    final counts = <int, int>{};
    final rangeLength = endDate.difference(startDate).inDays.abs() + 1;
    for (int i = 0; i < rangeLength; i++) {
      final wd = startDate.add(Duration(days: i)).weekday;
      final di = wd == 7 ? 0 : wd;
      counts[di] = (counts[di] ?? 0) + 1;
    }
    return counts;
  }

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

  /// Per-date duration in minutes. Each schedule fires this same window on
  /// every filtered date in the range, so the duration is the time delta
  /// between [startHour]:[startMinute] and [endHour]:[endMinute] on a single
  /// day (with `end <= start` rolling into the next day for midnight-wrap).
  int get durationMinutes {
    final startMin = startHour * 60 + startMinute;
    var endMin = endHour * 60 + endMinute;
    if (endMin == startMin) return 0;
    if (endMin < startMin) endMin += 1440;
    return endMin - startMin;
  }

  String get durationText {
    final total = durationMinutes;
    final h = total ~/ 60;
    final m = total % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Multi-day span from (startDate + start time) to (endDate + end time).
  /// Display only — the per-date backend runtime is still [durationMinutes].
  String get multiDaySpanText {
    final start = DateTime(
        startDate.year, startDate.month, startDate.day, startHour, startMinute);
    var end = DateTime(
        endDate.year, endDate.month, endDate.day, endHour, endMinute);
    // Same-day window that ends at/before it starts wraps past midnight.
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    var mins = end.difference(start).inMinutes;
    if (mins < 0) mins = 0;
    final d = mins ~/ 1440;
    final h = (mins % 1440) ~/ 60;
    final m = mins % 60;
    final hm = '${h}h ${m.toString().padLeft(2, '0')}m';
    return d > 0 ? '${d}d $hm' : hm;
  }

  void _onTimePicked(TimeOfDay t, bool isStart) {
    setState(() {
      if (isStart) {
        startHour = t.hour;
        startMinute = t.minute;
        // Per-date schedules run start → end **within a single day**, so
        // the comparison ignores startDate / endDate and just looks at
        // HH:MM. If end ≤ new start in single-day terms, bump end to
        // start + 5m so the window stays positive. If end is already
        // later than start (e.g. start=10 with end=11:05), leave it.
        final newStartMin = startHour * 60 + startMinute;
        final currentEndMin = endHour * 60 + endMinute;
        if (currentEndMin <= newStartMin) {
          final endTotal = newStartMin + 5;
          endHour = (endTotal ~/ 60) % 24;
          endMinute = endTotal % 60;
        }
      } else {
        endHour = t.hour;
        endMinute = t.minute;
      }
      if (cyclicMode) _clampCyclicDurations();
    });
    widget.onChanged?.call();
  }

  void _openTimePicker(bool isStart) {
    TimeOfDay? minTime;
    if (isStart && _isStartDateToday) {
      final now = DateTime.now();
      minTime = TimeOfDay(hour: now.hour, minute: now.minute);
    } else if (!isStart && _isSingleDay) {
      minTime = startTime;
    }
    showTimeBottomSheet(
      context,
      isStart ? startTime : endTime,
      (picked) => _onTimePicked(picked, isStart),
      minTime: minTime,
    );
  }

  CalendarDatePicker2WithActionButtonsConfig _scheduleFormCalendarConfig({
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.single,
      firstDate: firstDate,
      lastDate: lastDate,
      selectedDayHighlightColor: const Color(0xFF004E7E),
      selectedDayTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      todayTextStyle: const TextStyle(
          color: Color(0xFF004E7E), fontWeight: FontWeight.w600),
      dayTextStyle: const TextStyle(
          color: Color(0xFF0F172A), fontWeight: FontWeight.w400),
      disabledDayTextStyle: const TextStyle(color: Color(0xFFB0B8C4)),
      weekdayLabelTextStyle: const TextStyle(
          color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 12),
      controlsTextStyle: const TextStyle(
          color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
      lastMonthIcon:
          const Icon(Icons.chevron_left_rounded, color: Color(0xFF004E7E)),
      nextMonthIcon:
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF004E7E)),
      okButtonTextStyle: const TextStyle(
          color: Color(0xFF004E7E), fontWeight: FontWeight.w600, fontSize: 14),
      cancelButtonTextStyle: const TextStyle(
          color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 14),
    );
  }

  Future<void> _openStartDatePicker() async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: _scheduleFormCalendarConfig(
        firstDate: todayNorm,
        lastDate: DateTime(todayNorm.year + 2),
      ),
      dialogSize: const Size(340, 350),
      value: [startDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results == null || results.isEmpty || !mounted) return;
    final picked = results[0];
    if (picked == null) return;
    setState(() {
      startDate = picked;
      final maxEnd = picked.add(const Duration(days: 14));
      if (endDate.isBefore(picked)) {
        endDate = picked;
      } else if (endDate.isAfter(maxEnd)) {
        endDate = maxEnd;
      }
      selectedDays.retainWhere((d) => _validDays.contains(d));
      final d = _defaultsForDate(picked);
      startHour = d.sh;
      startMinute = d.sm;
      endHour = d.eh;
      endMinute = d.em;
    });
    widget.onChanged?.call();
  }

  Future<void> _openEndDatePicker() async {
    final maxEnd = startDate.add(const Duration(days: 14));
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: _scheduleFormCalendarConfig(
        firstDate: startDate,
        lastDate: maxEnd,
      ),
      dialogSize: const Size(340, 350),
      value: [endDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results == null || results.isEmpty || !mounted) return;
    final picked = results[0];
    if (picked == null) return;
    setState(() {
      endDate = picked;
      selectedDays.retainWhere((d) => _validDays.contains(d));
    });
    widget.onChanged?.call();
  }

  /// Edit-mode picker — the per-date schedule row owns exactly one day,
  /// so start/end collapse to a single value and the weekday chip mirrors
  /// whatever date the user picks. Keeping the form's `selectedDays`
  /// synced to the picked weekday also keeps `_buildDto`'s `daysOfWeek`
  /// + `bitwiseDays` consistent with the new date.
  Future<void> _openSingleDatePicker() async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: _scheduleFormCalendarConfig(
        firstDate: todayNorm,
        lastDate: DateTime(todayNorm.year + 2),
      ),
      dialogSize: const Size(340, 350),
      value: [startDate],
      borderRadius: BorderRadius.circular(16),
    );
    if (results == null || results.isEmpty || !mounted) return;
    final picked = results[0];
    if (picked == null) return;
    setState(() {
      startDate = picked;
      endDate = picked;
      final wd = picked.weekday == 7 ? 0 : picked.weekday; // Sun=0..Sat=6
      selectedDays = {wd};
    });
    widget.onChanged?.call();
  }

  void _toggleDay(int dayNum) {
    setState(() {
      if (selectedDays.contains(dayNum)) {
        selectedDays.remove(dayNum);
      } else {
        selectedDays.add(dayNum);
      }
    });
    widget.onChanged?.call();
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date card — only shown in standalone (single) mode
        if (widget.showDateCard) ...[
          _buildDateCard(),
          const SizedBox(height: 14),
        ],
        scheduleSectionLabel('Schedule Timing'),
        const SizedBox(height: 6),
        _buildTimingCard(),
        const SizedBox(height: 10),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 4),
      ],
    );
  }

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
          // Block save until the user has set a real start/end time
          // pair. In edit mode also require at least one actual change
          // from the loaded record — otherwise tapping Save fires a
          // pointless MQTT publish + PATCH for an unchanged schedule.
          saveEnabled: durationMinutes > 0 && (!widget.isEditMode || _isDirty),
        ),
      ],
    );
  }

  Widget _buildDateCard() {
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    // Edit mode locks the schedule's date and weekday selection — those
    // define which device-side slot the record owns, so they can't be
    // re-pointed once the record exists. The per-date storage model
    // also means the record covers exactly one day, so we collapse the
    // range view into a single-date display + the matching weekday
    // chip.
    final readOnly = widget.isEditMode;
    // Dart weekday: Mon=1..Sun=7. Day chip strip uses Sun=0..Sat=6.
    final singleDayIdx = startDate.weekday == 7 ? 0 : startDate.weekday;

    // Edit mode renders a read-only "calendar icon → 18 May 2026" row.
    // The date itself can't be changed during edit — only timing /
    // cyclic / power-recovery — so we drop the tap target and the
    // edit hint icon. No headings, no weekday chip.
    if (readOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Color(0xFF004E7E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fmtDate(startDate),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Date Range',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004E7E),
            ),
          ),
          const SizedBox(height: 8),
          if (readOnly) ...[
            // Edit-mode date card: a single tappable date pill plus a
            // read-only weekday pill that auto-mirrors whichever date
            // the user picks. The per-date schedule model means each
            // record covers exactly one day, so collapsing the range
            // view into one row is the natural fit.
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _openSingleDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF94A3B8),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF004E7E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Date',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _fmtDate(startDate),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    border: Border.all(
                      color: const Color(0xFF3686AF),
                      width: 1.4,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Day',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabels[singleDayIdx],
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF004E7E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openStartDatePicker,
                    child: _buildDateBox('Start', startDate),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Color(0xFF94A3B8)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _openEndDatePicker,
                    child: _buildDateBox('End', endDate),
                  ),
                ),
              ],
            ),
            if (selectedDays.isNotEmpty) ...[
              const SizedBox(height: 8),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            ],
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Builder(builder: (_) {
                final counts = _dayCounts;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final valid = _validDays.contains(i);
                    final isActive = selectedDays.contains(i);
                    final count = counts[i] ?? 0;
                    return GestureDetector(
                      onTap: !valid ? null : () => _toggleDay(i),
                      child: Opacity(
                        opacity: valid ? 1.0 : 0.35,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 34,
                              height: 26,
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
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? const Color(0xFF004E7E)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            if (isActive && count > 1)
                              Positioned(
                                top: -7,
                                right: -6,
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 14),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004E7E),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ],
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

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  height: 50,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(
                  child: _buildTimePicker('END', endHour, endMinute, false)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF3FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.isMultiDay
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Color(0xFF004E7E)),
                      const SizedBox(width: 6),
                      Text(
                        'Duration: $multiDaySpanText',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569)),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.nightlight_round,
                          size: 14, color: Color(0xFF004E7E)),
                      const SizedBox(width: 6),
                      Text('Overnight  •  $multiDaySpanText',
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
