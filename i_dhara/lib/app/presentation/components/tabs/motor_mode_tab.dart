import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../modules/motor_details/motor_details_controller.dart';

class MotorModeTab extends StatelessWidget {
  final AnalyticsController controller;

  const MotorModeTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'Motor Mode',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF004E7E),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch between Auto and Manual modes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() {
                  final currentModeIndex = controller.localModeIndex.value;
                  final isAuto = currentModeIndex == 1;
                  final int uiIndex = isAuto ? 0 : 1;
                  final isDisabled = controller.isWaitingForModeAck.value;

                  return ToggleSwitch(
                    key: ValueKey('mode_$currentModeIndex'),
                    changeOnTap: false,
                    customWidths: const [90, 90],
                    radiusStyle: true,
                    minWidth: 80.0,
                    minHeight: 30.0,
                    initialLabelIndex: uiIndex,
                    cornerRadius: 8.0,
                    activeBgColors: !isDisabled
                        ? [
                            [const Color(0xFFFFA500)],
                            [const Color(0xFF2F80ED)]
                          ]
                        : [
                            [const Color(0xFFFFA500).withValues(alpha: 0.3)],
                            [const Color(0xFF2F80ED).withValues(alpha: 0.3)],
                          ],
                    activeFgColor: !isDisabled ? Colors.white : Colors.black,
                    inactiveBgColor: Colors.white,
                    inactiveFgColor: Colors.black,
                    fontSize: 12,
                    totalSwitches: 2,
                    labels: const ['Auto', 'Manual'],
                    borderWidth: 1,
                    borderColor: [Colors.grey.shade300],
                    onToggle: !isDisabled
                        ? (index) {
                            if (index == null) return;
                            final newModeIndex = index == 0 ? 1 : 0;
                            if (newModeIndex != currentModeIndex) {
                              _showModeChangeDialog(context, newModeIndex);
                            }
                          }
                        : null,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showModeChangeDialog(BuildContext context, int newModeIndex) {
    final modeName = newModeIndex == 1 ? 'Auto' : 'Manual';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.settings,
                color: Color(0xFF004E7E),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Change Motor Mode',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004E7E),
                ),
              ),
            ],
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
                            controller.motorName.value,
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
                controller.handleModeChange(newModeIndex);
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
