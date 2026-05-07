part of 'multi_schedule_form.dart';

/// Pure widget-construction methods for [MultiScheduleFormState]. Lives in a
/// part file so it can read private state fields and call private mutators
/// without expanding the State class body.
extension _MultiScheduleFormBuilders on MultiScheduleFormState {
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
                    : 'Maximum ${MultiScheduleFormState._absoluteMaxSchedules} schedules per date reached',
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

  // ── Shared date card ───────────────────────────────────────────────────────

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
          const SizedBox(height: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      onTap: () => _toggleEntryExpansion(entry),
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
                  // Show selected values summary when collapsed
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
