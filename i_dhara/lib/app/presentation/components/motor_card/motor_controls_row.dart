import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_card_dialogs.dart';

class MotorControlsRow extends StatelessWidget {
  final Motor motor;
  final MotorData? motorData;
  final ValueNotifier<bool> switchController;
  final ValueNotifier<int> modeController;
  final Function(bool) onToggleSwitch;
  final Function(int) onModeChange;
  final bool isSwitchDisabled;
  final bool isModeDisabled;

  const MotorControlsRow({
    super.key,
    required this.motor,
    required this.motorData,
    required this.switchController,
    required this.modeController,
    required this.onToggleSwitch,
    required this.onModeChange,
    required this.isSwitchDisabled,
    required this.isModeDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Builder(
                builder: (context) {
                  final mode = motor.mode?.toLowerCase() ?? 'manual';
                  final isAuto = mode == 'auto';

                  final String modeText = mode.replaceFirstMapped(
                    RegExp(r'^[a-z]'),
                    (m) => m.group(0)!.toUpperCase(),
                  );

                  return Container(
                    decoration: BoxDecoration(
                      color: isAuto
                          ? const Color(0xFFFFA500).withOpacity(0.8)
                          : const Color(0xFF2F80ED).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        8.0, 4.0, 8.0, 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text(
                        //   mode.substring(0, 1).toUpperCase(),
                        //   style:
                        //       FlutterFlowTheme.of(context).bodyMedium.override(
                        //             font: GoogleFonts.dmSans(
                        //               fontWeight: FontWeight.w600,
                        //             ),
                        //             color: Colors.white,
                        //             fontSize: 12.0,
                        //           ),
                        // ),

                        Text(
                          modeText,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    color: Colors.white,
                                    fontSize: 14.0,
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          ValueListenableBuilder(
            valueListenable: modeController,
            builder: (context, modeIndex, _) {
              return ValueListenableBuilder(
                valueListenable: switchController,
                builder: (context, isOn, child) {
                  return GestureDetector(
                    onTap: !isSwitchDisabled
                        ? () {
                            MotorCardDialogs.showSwitchCommandDialog(
                                context, motor, !isOn, (newValue) {
                              onToggleSwitch(newValue);
                            });
                          }
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Opacity(
                        opacity: !isSwitchDisabled ? 1.0 : 0.4,
                        child: AdvancedSwitch(
                          key: ValueKey('switch_${motor.id}_$isOn'),
                          controller: switchController,
                          initialValue: isOn,
                          activeColor: Colors.green,
                          inactiveColor: Colors.red.shade500,
                          activeChild: const Text(
                            'ON',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          inactiveChild: const Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(15)),
                          width: 55,
                          height: 25,
                          enabled: !isSwitchDisabled,
                          disabledOpacity: 0.9,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
