import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widget.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_form.dart';

part 'multi_schedule_form_builders.dart';

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

  /// Number of schedules that already cover the selected date. The form caps
  /// new entries at `4 - existingScheduleCount` so the per-date total never
  /// exceeds 4. Defaults to 0 → full 4-slot allowance.
  final int existingScheduleCount;

  const MultiScheduleForm({
    super.key,
    this.onSave,
    this.onBack,
    this.showBottomBar = true,
    this.existingScheduleCount = 0,
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
  /// Hard cap for schedules per date across the whole app.
  static const int _absoluteMaxSchedules = 4;
  static const int _maxRangeDays = 15;
  final List<_ScheduleEntry> _schedules = [];
  int _nextId = 1;
  final _scrollController = ScrollController();

  /// Slots remaining for new schedules after subtracting whatever already
  /// covers the selected date. Always >= 1 so the form is never unusable —
  /// the FAB on the schedule list is responsible for blocking entry when
  /// the date is genuinely full.
  int get _maxSchedules {
    final remaining = _absoluteMaxSchedules - widget.existingScheduleCount;
    return remaining < 1 ? 1 : remaining;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Normalize to midnight so endDate.difference(startDate).inDays is a
    // clean day count and `_validDays` covers every weekday in the range.
    // DateTime.now() carries the current time-of-day, which would otherwise
    // round inDays down (e.g. Fri 14:00 → Sat 00:00 → 0 days).
    final todayNorm = DateTime(now.year, now.month, now.day);
    startDate = todayNorm;
    endDate = todayNorm;
    selectedDays = {};
    // Add first schedule directly (no setState) so it renders expanded on first build
    _schedules.add(_ScheduleEntry(
      id: _nextId++,
      formKey: GlobalKey<ScheduleFormState>(),
      isExpanded: true,
    ));
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

  /// Wraps `setState` so the builder layer (in the part file) can mutate the
  /// expansion flag of a [_ScheduleEntry] without invoking a protected member.
  void _toggleEntryExpansion(_ScheduleEntry entry) {
    setState(() => entry.isExpanded = !entry.isExpanded);
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
        selectedDays.retainWhere((d) => _validDays.contains(d));
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
        selectedDays.retainWhere((d) => _validDays.contains(d));
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared date card — shown once for all schedules
          _buildSharedDateCard(),
          const SizedBox(height: 8),
          // Add schedule row — right below the date card
          _buildAddScheduleRow(),
          const SizedBox(height: 8),
          // Schedule cards
          for (int i = 0; i < _schedules.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
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
}
