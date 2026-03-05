import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_utils.dart';

// ─── Scroll Wheel ──────────────────────────────────────────
class ScrollWheel extends StatelessWidget {
  final List<int> values;
  final int selected;
  final Function(int) onChanged;
  final bool padZero;

  const ScrollWheel({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.padZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = FixedExtentScrollController(
      initialItem: values.indexOf(selected),
    );
    return Container(
      width: 64,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => onChanged(values[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: values.length,
          builder: (context, index) {
            final isSelected = values[index] == selected;
            final display = padZero
                ? values[index].toString().padLeft(2, '0')
                : values[index].toString();
            return Center(
              child: Text(
                display,
                style: GoogleFonts.dmSans(
                  fontSize: isSelected ? 24 : 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF004E7E)
                      : const Color(0xFF828282),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF14181B),
      ),
    );
  }
}

// ─── Day Selector ──────────────────────────────────────────
class DaySelector extends StatelessWidget {
  final Set<int> selectedDays;
  final Function(Set<int>) onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  void _toggleDay(int i) {
    final newDays = Set<int>.from(selectedDays);
    newDays.contains(i) ? newDays.remove(i) : newDays.add(i);
    onChanged(newDays);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (i) => _DayChip(
                dayIndex: i,
                isSelected: selectedDays.contains(i),
                onTap: () => _toggleDay(i),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...List.generate(3, (idx) {
                final i = idx + 4;
                return _DayChip(
                  dayIndex: i,
                  isSelected: selectedDays.contains(i),
                  onTap: () => _toggleDay(i),
                );
              }),
              const SizedBox(width: 52),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int dayIndex;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.dayIndex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFEBF3FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFDCDCDC),
          ),
        ),
        child: Center(
          child: Text(
            dayLabels[dayIndex],
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF57636C),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Time Card ─────────────────────────────────────────────
class TimeCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const TimeCard({
    super.key,
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF004E7E)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTime24h(time),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14181B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Duration Card ─────────────────────────────────────────
class DurationCard extends StatelessWidget {
  final int durationH;
  final int durationM;
  final VoidCallback? onTap;

  const DurationCard({
    super.key,
    required this.durationH,
    required this.durationM,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF004E7E)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDurationHM(durationH, durationM),
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004E7E),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 14, color: Color(0xFF004E7E)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Repeat Info Card ──────────────────────────────────────
class RepeatInfoCard extends StatelessWidget {
  final Set<int> selectedDays;
  const RepeatInfoCard({super.key, required this.selectedDays});

  @override
  Widget build(BuildContext context) {
    final sorted = selectedDays.toList()..sort();
    String repeatText;
    if (sorted.isEmpty) {
      repeatText = 'No days selected';
    } else if (sorted.length == 7) {
      repeatText = 'Repeats every day';
    } else {
      repeatText = 'Every ${sorted.map((d) => dayFullLabels[d]).join(', ')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFA500).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA500).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.repeat_rounded,
                size: 16, color: Color(0xFFFFA500)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repeat Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repeatText,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Power Toggle Row ──────────────────────────────────────
class PowerToggleRow extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;

  const PowerToggleRow({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.green.withValues(alpha: 0.12)
                    : const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                size: 18,
                color: isEnabled ? Colors.green : const Color(0xFF004E7E),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Schedule Power',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF14181B),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 50,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isEnabled ? Colors.green : Colors.red.shade400,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment:
                  isEnabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Create Schedule Button ────────────────────────────────
class CreateScheduleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const CreateScheduleButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_send_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Create Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
