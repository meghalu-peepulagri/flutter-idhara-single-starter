part of 'schedule_form.dart';

/// Pure widget-construction methods for [ScheduleFormState]. Lives in a part
/// file so it can read private state fields and call private mutators without
/// expanding the State class body.
extension _ScheduleFormBuilders on ScheduleFormState {
  // ── Form content ───────────────────────────────────────────────────────────

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
          onCyclicChanged: _onCyclicChanged,
          onOnDecrement: _onCyclicOnDecrement,
          onOnIncrement: _onCyclicOnIncrement,
          onOffDecrement: _onCyclicOffDecrement,
          onOffIncrement: _onCyclicOffIncrement,
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
          onChanged: _onPowerLossChanged,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Date Card ──────────────────────────────────────────────────────────────

  Widget _buildDateCard() {
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
          Text(
            'Date Range',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004E7E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openCalendarDialog,
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
                  onTap: _openCalendarDialog,
                  child: _buildDateBox('End', endDate),
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 6),
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

  // ── Timing Card ────────────────────────────────────────────────────────────

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
