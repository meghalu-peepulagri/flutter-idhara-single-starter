import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_widgets.dart';

void showDateBottomSheet(
  BuildContext context,
  DateTime current,
  Function(DateTime) onPicked, {
  DateTime? minDate,
}) {
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final now = DateTime.now();
  final minD = minDate != null
      ? DateTime(minDate.year, minDate.month, minDate.day)
      : DateTime(now.year, now.month, now.day);

  DateTime clamped = DateTime(current.year, current.month, current.day);
  if (clamped.isBefore(minD)) clamped = minD;

  int selDay = clamped.day;
  int selMonth = clamped.month - 1; // 0-indexed
  int selYear = clamped.year;

  final years = List.generate(6, (i) => now.year + i);

  int daysInMonth(int year, int month1Based) =>
      DateTime(year, month1Based + 1, 0).day;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final maxDay = daysInMonth(selYear, selMonth + 1);
          if (selDay > maxDay) selDay = maxDay;
          final days = List.generate(maxDay, (i) => i + 1);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(),
                const SizedBox(height: 16),
                _buildTitle('Select Date'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Center(
                        child: Text('Day',
                            style: _wheelLabelStyle()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: Center(
                        child: Text('Month',
                            style: _wheelLabelStyle()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: Text('Year',
                            style: _wheelLabelStyle()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildScrollWheel(
                      key: ValueKey('day_${selMonth}_$selYear'),
                      values: days,
                      selected: selDay,
                      onChanged: (v) => setSheetState(() => selDay = v),
                      padZero: true,
                    ),
                    const SizedBox(width: 8),
                    buildStringScrollWheel(
                      key: ValueKey('mon_$selYear'),
                      values: monthNames,
                      selectedIndex: selMonth,
                      onChanged: (i) => setSheetState(() {
                        selMonth = i;
                        final maxD = daysInMonth(selYear, selMonth + 1);
                        if (selDay > maxD) selDay = maxD;
                      }),
                    ),
                    const SizedBox(width: 8),
                    buildScrollWheel(
                      key: const ValueKey('year'),
                      values: years,
                      selected: selYear,
                      onChanged: (v) => setSheetState(() {
                        selYear = v;
                        final maxD = daysInMonth(selYear, selMonth + 1);
                        if (selDay > maxD) selDay = maxD;
                      }),
                      width: 80,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBottomSheetButtons(
                  ctx,
                  onConfirm: () {
                    onPicked(DateTime(selYear, selMonth + 1, selDay));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

TextStyle _wheelLabelStyle() => GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF94A3B8),
    );

void showTimeBottomSheet(
  BuildContext context,
  TimeOfDay current,
  Function(TimeOfDay) onPicked, {
  TimeOfDay? minTime,
}) {
  // Minutes in 5-min steps
  final minuteSteps = List.generate(12, (i) => i * 5); // 0,5,10,...,55

  // Minimum total minutes (snapped to next 5-min step strictly after minTime)
  int? minTotal;
  if (minTime != null) {
    final raw = minTime.hour * 60 + minTime.minute;
    minTotal = ((raw ~/ 5) + 1) * 5;
  }

  bool isValid(int h, int m) {
    if (minTotal == null) return true;
    return h * 60 + m >= minTotal;
  }

  // Snap current to nearest 5-min step, clamp to minTotal if needed
  int selectedHour = current.hour;
  int selectedMinute = (current.minute ~/ 5) * 5;

  if (minTotal != null && selectedHour * 60 + selectedMinute < minTotal) {
    selectedHour = (minTotal ~/ 60) % 24;
    selectedMinute = minTotal % 60;
  }

  // Valid hours: hours that have at least one valid minute
  List<int> validHours() => List.generate(24, (i) => i)
      .where((h) => minuteSteps.any((m) => isValid(h, m)))
      .toList();

  // Valid minutes for a given hour
  List<int> validMinutes(int h) =>
      minuteSteps.where((m) => isValid(h, m)).toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final hours = validHours();
          final minutes = validMinutes(selectedHour);

          // Clamp selection if it became invalid after state changes
          if (hours.isNotEmpty && !hours.contains(selectedHour)) {
            selectedHour = hours.first;
          }
          if (minutes.isNotEmpty && !minutes.contains(selectedMinute)) {
            selectedMinute = minutes.first;
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(),
                const SizedBox(height: 16),
                _buildTitle('Select Time'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildScrollWheel(
                      key: ValueKey('h_$selectedHour'),
                      values: hours.isNotEmpty ? hours : List.generate(24, (i) => i),
                      selected: selectedHour,
                      onChanged: (v) => setSheetState(() {
                        selectedHour = v;
                        final mins = validMinutes(v);
                        if (mins.isNotEmpty && !mins.contains(selectedMinute)) {
                          selectedMinute = mins.first;
                        }
                      }),
                      padZero: true,
                    ),
                    _buildColon(),
                    buildScrollWheel(
                      key: ValueKey('m_$selectedHour'),
                      values: minutes.isNotEmpty ? minutes : minuteSteps,
                      selected: selectedMinute,
                      onChanged: (v) => setSheetState(() => selectedMinute = v),
                      padZero: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBottomSheetButtons(
                  ctx,
                  onConfirm: () {
                    onPicked(
                        TimeOfDay(hour: selectedHour, minute: selectedMinute));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ─── Shared helpers ────────────────────────────────────────

Widget _buildHandle() {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFDCDCDC),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _buildTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF004E7E),
    ),
  );
}

Widget _buildColon() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      ':',
      style: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF004E7E),
      ),
    ),
  );
}

Widget _buildBottomSheetButtons(
  BuildContext ctx, {
  required VoidCallback onConfirm,
}) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Color(0xFFDCDCDC)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
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
              onTap: onConfirm,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
