import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';

class MotorCardDialogs {
  static void showSwitchCommandDialog(BuildContext context, Motor motor,
      bool newValue, Function(bool) onConfirm) {
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
                'Are you sure you want to control this motor?',
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
                    'State:',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    newValue ? 'ON' : 'OFF',
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
                onConfirm(newValue);
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
