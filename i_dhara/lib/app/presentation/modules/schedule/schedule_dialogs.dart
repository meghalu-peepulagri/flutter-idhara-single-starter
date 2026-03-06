import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showScheduleConfirmDialog({
  required BuildContext context,
  required String typeLabel,
  required String startTime,
  required String endTime,
  required String duration,
  required String powerRecovery,
  required Future<bool> Function() onConfirm,
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
                        const SizedBox(height: 6),
                        _dialogRow('Power Recovery', powerRecovery),
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
