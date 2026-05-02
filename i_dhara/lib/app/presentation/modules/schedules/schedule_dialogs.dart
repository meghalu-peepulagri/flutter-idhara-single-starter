import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showScheduleConfirmDialog({
  required BuildContext context,
  required String typeLabel,
  required String startDate,
  required String endDate,
  required String startTime,
  required String endTime,
  required String duration,
  required String powerRecovery,
  required Future<bool> Function() onConfirm,
  bool isCyclic = false,
  int cyclicOnMinutes = 0,
  int cyclicOffMinutes = 0,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool isLoading = false;

      return StatefulBuilder(
        builder: (_, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            // insetPadding:
            //     const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF3FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        size: 32, color: Color(0xFF004E7E)),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'Confirm Schedule',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF14181B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to create this schedule?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF57636C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF004E7E).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        _dialogRow('Type', typeLabel),
                        const SizedBox(height: 6),
                        _dialogRow('Start', startTime),
                        const SizedBox(height: 6),
                        _dialogRow('End', endTime),
                        const SizedBox(height: 6),
                        _dialogRow('Duration', duration),
                        if (isCyclic) ...[
                          const SizedBox(height: 6),
                          _dialogRow('Cyclic ON', '$cyclicOnMinutes min'),
                          const SizedBox(height: 6),
                          _dialogRow('Cyclic OFF', '$cyclicOffMinutes min'),
                        ] else ...[
                          const SizedBox(height: 6),
                          _dialogRow('Power Recovery', powerRecovery),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed:
                                isLoading ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isLoading
                                    ? const Color(0xFFBDBDBD)
                                    : const Color(0xFF004E7E),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isLoading
                                    ? const Color(0xFFBDBDBD)
                                    : const Color(0xFF004E7E),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setDialogState(() => isLoading = true);
                                    final success = await onConfirm();
                                    if (ctx.mounted && success) {
                                      Navigator.pop(ctx);
                                    } else if (ctx.mounted) {
                                      setDialogState(() => isLoading = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004E7E),
                              disabledBackgroundColor: const Color(0xFF004E7E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Confirm',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class MultiScheduleDialogItem {
  final String typeLabel;
  final String startTime;
  final String endTime;
  final String duration;
  final String powerRecovery;
  final bool isCyclic;
  final int cyclicOnMinutes;
  final int cyclicOffMinutes;

  const MultiScheduleDialogItem({
    required this.typeLabel,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.powerRecovery,
    this.isCyclic = false,
    this.cyclicOnMinutes = 0,
    this.cyclicOffMinutes = 0,
  });
}

Future<void> showMultiScheduleConfirmDialog({
  required BuildContext context,
  required String startDate,
  required String endDate,
  required List<MultiScheduleDialogItem> schedules,
  required Future<bool> Function() onConfirm,
  // Optional weekdays the user picked. Indexes use 0=Sun .. 6=Sat to match
  // the create page. When non-empty, they show on the right of the date row.
  List<int>? selectedDays,
  // Number of times each weekday occurs in the picked date range
  // (e.g. 14-day range → each day appears twice). Key = day index 0..6.
  // Counts > 1 are rendered as a small badge on top of the chip.
  Map<int, int>? dayCounts,
}) {
  const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final hasDays = selectedDays != null && selectedDays.isNotEmpty;
  final selectedDayEntries = hasDays
      ? [
          for (final i in (List<int>.from(selectedDays)..sort()))
            if (i >= 0 && i < 7)
              (label: dayLabels[i], count: dayCounts?[i] ?? 1),
        ]
      : const <({String label, int count})>[];
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool isLoading = false;
      return StatefulBuilder(
        builder: (_, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              // Cap dialog height — shrinks when less content, scrolls when more
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.58,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF3FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.schedule_rounded,
                          size: 26, color: Color(0xFF004E7E)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Schedules',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF14181B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Are you sure you want to create these ${schedules.length} schedule(s)?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF57636C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              const Color(0xFF004E7E).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(startDate,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A))),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: Color(0xFF94A3B8)),
                          Text(endDate,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Flexible: shrinks when few cards, scrolls when many
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (int i = 0; i < schedules.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              _multiScheduleCard(
                                i + 1,
                                schedules[i],
                                dayEntries: selectedDayEntries,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed:
                                  isLoading ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isLoading
                                      ? const Color(0xFFBDBDBD)
                                      : const Color(0xFF004E7E),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isLoading
                                      ? const Color(0xFFBDBDBD)
                                      : const Color(0xFF004E7E),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setDialogState(() => isLoading = true);
                                      final success = await onConfirm();
                                      if (ctx.mounted && success) {
                                        Navigator.pop(ctx);
                                      } else if (ctx.mounted) {
                                        setDialogState(() => isLoading = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF004E7E),
                                disabledBackgroundColor:
                                    const Color(0xFF004E7E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Confirm',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _multiScheduleCard(
  int idx,
  MultiScheduleDialogItem s, {
  List<({String label, int count})> dayEntries = const [],
}) {
  final String detail = s.isCyclic
      ? 'Cyclic  ·  ON ${s.cyclicOnMinutes}m / OFF ${s.cyclicOffMinutes}m'
      : '${s.duration}${s.powerRecovery == 'ON' ? '  ·  Pwr Recovery' : ''}';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0xFF004E7E).withValues(alpha: 0.15),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Index badge
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFEBF3FE),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$idx',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF004E7E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.startTime}  →  ${s.endTime}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (dayEntries.isNotEmpty) ...[
          const SizedBox(width: 8),
          // Day chips on the right side of each schedule card.
          // Each chip carries a small count badge on top-right when the
          // weekday occurs more than once in the selected date range.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Padding(
              // Reserve space above for the count badge so it isn't clipped.
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final entry in dayEntries)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF3686AF),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            entry.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF004E7E),
                            ),
                          ),
                        ),
                        if (entry.count > 1)
                          Positioned(
                            top: -7,
                            right: -6,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004E7E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white, width: 1),
                              ),
                              child: Text(
                                '${entry.count}',
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
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _dialogRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style:
              GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF57636C))),
      Text(value,
          style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF14181B))),
    ],
  );
}
