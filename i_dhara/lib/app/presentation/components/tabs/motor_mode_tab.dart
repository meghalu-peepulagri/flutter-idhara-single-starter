import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../modules/motor_details/motor_details_controller.dart';
import '../motor_card/motor_card_dialogs.dart';
import 'motor_mode_info_sheet.dart';

class MotorModeTab extends StatefulWidget {
  final AnalyticsController controller;

  const MotorModeTab({
    super.key,
    required this.controller,
  });

  @override
  State<MotorModeTab> createState() => _MotorModeTabState();
}

class _MotorModeTabState extends State<MotorModeTab> {
  late ValueNotifier<int> _modeNotifier;
  Worker? _modeWorker;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _modeNotifier = ValueNotifier<int>(widget.controller.localModeIndex.value);

    // Listen to controller mode changes and update the notifier
    _modeWorker = ever(widget.controller.localModeIndex, (value) {
      if (mounted && _modeNotifier.value != value) {
        _modeNotifier.value = value;
      }
    });
  }

  @override
  void dispose() {
    _modeWorker?.dispose();
    _modeNotifier.dispose();
    super.dispose();
  }

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
          child: Stack(
            children: [
              Padding(
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
                    ValueListenableBuilder<int>(
                      valueListenable: _modeNotifier,
                      builder: (context, currentModeIndex, child) {
                        // Controller mode index: 0 = Manual, 1 = Auto,
                        // 2 = Schedule. Toggle UI order: Auto, Manual,
                        // Schedule (Auto first because it's the most-used
                        // mode and matches the prior 2-segment layout).
                        int uiForMode(int m) {
                          if (m == 1) return 0; // Auto
                          if (m == 0) return 1; // Manual
                          return 2; // Schedule
                        }

                        int modeForUi(int u) {
                          if (u == 0) return 1; // Auto
                          if (u == 1) return 0; // Manual
                          return 2; // Schedule
                        }

                        final int uiIndex = uiForMode(currentModeIndex);

                        return Obx(() {
                          final isDisabled =
                              widget.controller.isWaitingForModeAck.value ||
                                  !widget.controller.canChangeMode.value;

                          return Column(
                            children: [
                              ToggleSwitch(
                                key: ValueKey('mode_toggle_$currentModeIndex'),
                                changeOnTap: false,
                                // Schedule's label is wider than Auto/Manual,
                                // so give it a touch more room.
                                customWidths: const [85, 85, 100],
                                radiusStyle: true,
                                minWidth: 80.0,
                                minHeight: 30.0,
                                initialLabelIndex: uiIndex,
                                cornerRadius: 8.0,
                                activeBgColors: !isDisabled
                                    ? [
                                        [const Color(0xFFFFA500)],
                                        [const Color(0xFF2F80ED)],
                                        [const Color(0xFF8B5CF6)],
                                      ]
                                    : [
                                        [
                                          const Color(0xFFFFA500)
                                              .withValues(alpha: 0.3)
                                        ],
                                        [
                                          const Color(0xFF2F80ED)
                                              .withValues(alpha: 0.3)
                                        ],
                                        [
                                          const Color(0xFF8B5CF6)
                                              .withValues(alpha: 0.3)
                                        ],
                                      ],
                                activeFgColor:
                                    !isDisabled ? Colors.white : Colors.black54,
                                inactiveBgColor: Colors.white,
                                inactiveFgColor: Colors.black,
                                fontSize: 12,
                                totalSwitches: 3,
                                labels: const ['Auto', 'Manual', 'Schedule'],
                                borderWidth: 1,
                                borderColor: [Colors.grey.shade300],
                                onToggle: !isDisabled
                                    ? (index) {
                                        if (index == null || _isDialogOpen)
                                          return;
                                        final newModeIndex = modeForUi(index);
                                        if (newModeIndex != currentModeIndex) {
                                          setState(() => _isDialogOpen = true);
                                          MotorCardDialogs.showModeChangeDialog(
                                            context,
                                            widget.controller.motorName.value,
                                            newModeIndex,
                                            widget.controller.handleModeChange,
                                          ).then((_) {
                                            if (mounted) {
                                              setState(
                                                  () => _isDialogOpen = false);
                                            }
                                          });
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Info icon in top-right corner
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => MotorModeInfoSheet.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF004E7E),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
