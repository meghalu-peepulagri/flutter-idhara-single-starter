import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';

class MotorCardDialogs {
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
                            motor.aliasName?.capitalizeFirst ?? 'Unknown',
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

  static void showModeCommandDialog(
      BuildContext context, Motor motor, int newMode, Function(int) onConfirm) {
    final modeName = newMode == 1 ? 'Auto' : 'Manual';

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
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Motor: ",
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    motor.aliasName?.capitalizeFirst ?? "Unknown",
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Mode:',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    modeName,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm(newMode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}
