import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

import 'dialog_helpers.dart';

/// Confirmation dialog with timeout selection (1m / 2m) before starting a
/// test run.
void showTestRunConfirmDialog(
  BuildContext context,
  Motor motor,
  Function(int timeoutMinutes) onConfirm,
) {
  int selectedTimeout = 3;
  final screenWidth = MediaQuery.of(context).size.width;
  final dialogWidth = screenWidth < 400 ? screenWidth * 0.9 : 340.0;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth < 400 ? 16 : 40,
              vertical: 24,
            ),
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Test Run',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Motor: ',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF004E7E),
                              ),
                            ),
                            Text(
                              formatMotorNameShort(motor),
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Time: ',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF004E7E),
                              ),
                            ),
                            // const Spacer(),
                            const SizedBox(width: 10),

                            _buildTimeChip(
                              context,
                              1,
                              selectedTimeout,
                              (value) =>
                                  setState(() => selectedTimeout = value),
                            ),
                            const SizedBox(width: 20),
                            _buildTimeChip(
                              context,
                              2,
                              selectedTimeout,
                              (value) =>
                                  setState(() => selectedTimeout = value),
                            ),
                            // const SizedBox(width: 6),
                            // _buildTimeChip(
                            //   context,
                            //   3,
                            //   selectedTimeout,
                            //   (value) =>
                            //       setState(() => selectedTimeout = value),
                            // ),
                            // const SizedBox(width: 6),
                            // _buildTimeChip(
                            //   context,
                            //   4,
                            //   selectedTimeout,
                            //   (value) =>
                            //       setState(() => selectedTimeout = value),
                            // ),
                            // const SizedBox(width: 6),
                            // _buildTimeChip(
                            //   context,
                            //   5,
                            //   selectedTimeout,
                            //   (value) =>
                            //       setState(() => selectedTimeout = value),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                              onTap: () {
                                Navigator.of(context).pop();
                                onConfirm(selectedTimeout);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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

/// Build time selection chip for test run dialog
Widget _buildTimeChip(
  BuildContext context,
  int minutes,
  int selectedMinutes,
  Function(int) onSelect,
) {
  final isSelected = minutes == selectedMinutes;
  return GestureDetector(
    onTap: () => onSelect(minutes),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFDCDCDC),
        ),
      ),
      child: Text(
        '${minutes}m',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    ),
  );
}
