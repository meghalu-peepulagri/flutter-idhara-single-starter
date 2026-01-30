import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

class MotorCardDialogs {
  static String _formatMotorName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    final formatted = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (formatted.length > 16) {
      return '${formatted.substring(0, 16)}...';
    }
    return formatted;
  }

  static void showSwitchCommandDialog(
    BuildContext context,
    Motor motor,
    bool newValue,
    Function(bool) onConfirm,
  ) {
    final stateName = newValue ? 'ON' : 'OFF';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to control the motor?',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
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
                      children: [
                        Text(
                          'Motor: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatMotorName(motor.aliasName?.capitalizeFirst),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'New State: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Text(
                          stateName,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: newValue
                                ? const Color(0xFF2F80ED) // ON
                                : const Color(0xFFDB3B2A), // OFF
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm(newValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showModeChangeDialog(
    BuildContext context,
    String motorName,
    int newModeIndex,
    Function(int) onConfirm,
  ) {
    final modeName = newModeIndex == 1 ? 'Auto' : 'Manual';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to change the motor mode?',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
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
                      children: [
                        Text(
                          "Motor: ",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatMotorName(motorName),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "New Mode: ",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Text(
                          modeName,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: newModeIndex == 1
                                ? const Color(0xFFFFA500)
                                : const Color(0xFF2F80ED),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm(newModeIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
