import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
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
  final bool isAutoMode;
  final bool isModeDisabled;
  final VoidCallback? onNavigateToDetails;

  const MotorControlsRow({
    super.key,
    required this.motor,
    required this.motorData,
    required this.switchController,
    required this.modeController,
    required this.onToggleSwitch,
    required this.onModeChange,
    required this.isSwitchDisabled,
    this.isAutoMode = false,
    required this.isModeDisabled,
    this.onNavigateToDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: onNavigateToDetails,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: modeController,
                  builder: (context, modeIndex, _) {
                    final isAuto = modeIndex == 1;
                    final String modeText = isAuto ? 'Auto' : 'Manual';

                    return Container(
                      decoration: BoxDecoration(
                        color: isAuto
                            ? const Color(0xFFFFA500).withValues(alpha: 0.8)
                            : const Color(0xFF2F80ED).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          8.0, 4.0, 8.0, 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            modeText,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
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
          ),
          const Expanded(child: SizedBox(height: 25)),
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
                            }, isAutoMode: isAutoMode);
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
