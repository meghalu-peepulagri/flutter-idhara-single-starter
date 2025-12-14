// import 'package:flutter/material.dart';
// import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
// import 'package:i_dhara/app/presentation/widgets/motor_card/voltage_current_values_card.dart';

// import '../../../core/flutter_flow/flutter_flow_theme.dart';

// class MotorCardWidget extends StatelessWidget {
//   final Motor motor;
//   final MqttService mqttService;
//   final Function(Motor, bool) onToggleMotor;

//   const MotorCardWidget({
//     super.key,
//     required this.motor,
//     required this.mqttService,
//     required this.onToggleMotor,
//   });

//   MotorData? _getMotorData() {
//     if (motor.starter?.macAddress == null || motor.id == null) return null;

//     // Try all possible groups to find the motor
//     for (int i = 1; i <= 4; i++) {
//       final groupId = 'G0$i';
//       final motorId = '${motor.starter!.macAddress}-$groupId';
//       final data = mqttService.motorDataMap[motorId];
//       if (data != null) {
//         return data;
//       }
//     }
//     return null;
//   }

//   List<String> getFaults(String? faultCode) {
//     Map<int, String> faultCodes = {
//       0x01: "Dry Run Fault",
//       0x02: "Overload Fault",
//       0x04: "Locked Rotor Fault",
//       0x08: "Current Imbalance Fault",
//       0x10: "Frequent Start Fault",
//       0x20: "Phase Failure Fault",
//       0x40: "Low Voltage Fault",
//       0x80: "Over Voltage Fault",
//       0x100: "Voltage Imbalance Fault",
//       0x200: "Phase Reversal Fault",
//       0x400: "Frequency deviation Fault",
//       0x800: "Over Temperature Fault",
//     };

//     if (faultCode == null || faultCode.trim().isEmpty) {
//       return [];
//     }

//     try {
//       int input = int.parse(faultCode);

//       if (input == 4095) {
//         return faultCodes.values.toList(); // All faults
//       }

//       List<String> faults = [];
//       faultCodes.forEach((code, message) {
//         if ((input & code) != 0) {
//           faults.add(message);
//         }
//       });

//       return faults;
//     } catch (e) {
//       return [];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<int>(
//       valueListenable: mqttService.dataUpdateNotifier,
//       builder: (context, _, __) {
//         final motorData = _getMotorData();

//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12.0),
//           ),
//           child: Padding(
//             padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Padding(
//                   padding: const EdgeInsetsDirectional.fromSTEB(
//                       12.0, 0.0, 12.0, 0.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.max,
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(0.0),
//                             child: SvgPicture.asset(
//                               'assets/images/motor.svg',
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           Text(
//                             motor.name ?? '',
//                             style: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   font: GoogleFonts.dmSans(
//                                     fontWeight: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontWeight,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                                   color: const Color(0xFF1E1E1E),
//                                   fontSize: 16.0,
//                                   letterSpacing: 0.0,
//                                 ),
//                           ),
//                         ].divide(const SizedBox(width: 8.0)),
//                       ),
//                       Row(
//                         mainAxisSize: MainAxisSize.max,
//                         children: [
//                           // Connection status
//                           if (motorData?.hasReceivedData ?? false)
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(0.0),
//                               child: SvgPicture.asset(
//                                 'assets/images/wifi.svg',
//                                 fit: BoxFit.cover,
//                               ),
//                             )
//                           else
//                             const Icon(
//                               Icons.wifi_off,
//                               color: Colors.grey,
//                               size: 20,
//                             ),
//                           // Power status
//                           if ((motorData?.power ?? motor.starter?.power ?? 0) >
//                               0)
//                             ClipRRect(
//                               borderRadius: BorderRadius.circular(0.0),
//                               child: SvgPicture.asset(
//                                 'assets/images/power.svg',
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           // Fault indicator
//                           if ((motorData?.fault ?? 0) > 0)
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(24.0),
//                                 border: Border.all(
//                                   color: const Color(0xFFDCDCDC),
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsetsDirectional.fromSTEB(
//                                     8.0, 4.0, 8.0, 4.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   children: [
//                                     const FaIcon(
//                                       FontAwesomeIcons.exclamationTriangle,
//                                       color: Color(0xFFEB5757),
//                                       size: 14.0,
//                                     ),
//                                     Text(
//                                       '${motorData?.fault ?? 0}',
//                                       style: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .override(
//                                             font: GoogleFonts.dmSans(
//                                               fontWeight: FontWeight.w500,
//                                               fontStyle:
//                                                   FlutterFlowTheme.of(context)
//                                                       .bodyMedium
//                                                       .fontStyle,
//                                             ),
//                                             color: const Color(0xFF2B2B2B),
//                                             letterSpacing: 0.0,
//                                             fontWeight: FontWeight.w500,
//                                             fontStyle:
//                                                 FlutterFlowTheme.of(context)
//                                                     .bodyMedium
//                                                     .fontStyle,
//                                           ),
//                                     ),
//                                   ].divide(const SizedBox(width: 6.0)),
//                                 ),
//                               ),
//                             ),
//                         ].divide(const SizedBox(width: 8.0)),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Divider(
//                   thickness: 1.0,
//                   color: Color(0xFFECECEC),
//                 ),
//                 Padding(
//                   padding: const EdgeInsetsDirectional.fromSTEB(
//                       12.0, 0.0, 12.0, 0.0),
//                   child: VoltageCurrentValuesCard(
//                     motor: motor,
//                     mqttService: mqttService,
//                   ),
//                 ),
//                 const Divider(
//                   thickness: 1.0,
//                   color: Color(0xFFECECEC),
//                 ),
//                 Padding(
//                   padding: const EdgeInsetsDirectional.fromSTEB(
//                       12.0, 0.0, 12.0, 0.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.max,
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF2F80ED),
//                               borderRadius: BorderRadius.circular(4.0),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsetsDirectional.fromSTEB(
//                                   8.0, 4.0, 8.0, 4.0),
//                               child: Text(
//                                 'M',
//                                 style: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .override(
//                                       font: GoogleFonts.dmSans(
//                                         fontWeight: FontWeight.w600,
//                                         fontStyle: FlutterFlowTheme.of(context)
//                                             .bodyMedium
//                                             .fontStyle,
//                                       ),
//                                       color: Colors.white,
//                                       fontSize: 16.0,
//                                       letterSpacing: 0.0,
//                                       fontWeight: FontWeight.w600,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                               ),
//                             ),
//                           ),
//                           Text(
//                             motorData?.motorMode ?? motor.mode ?? '--',
//                             style: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   font: GoogleFonts.dmSans(
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                                   color: Colors.black,
//                                   fontSize: 14.0,
//                                   letterSpacing: 0.0,
//                                   fontWeight: FontWeight.w500,
//                                   fontStyle: FlutterFlowTheme.of(context)
//                                       .bodyMedium
//                                       .fontStyle,
//                                 ),
//                           ),
//                         ].divide(const SizedBox(width: 8.0)),
//                       ),
//                       // Switch with ValueListenableBuilder
//                       if (motorData?.controller != null)
//                         ValueListenableBuilder<bool>(
//                           valueListenable: motorData!.controller,
//                           builder: (context, isOn, child) {
//                             return AdvancedSwitch(
//                               initialValue:
//                                   motorData.state == 1 || motorData.state == 6,
//                               controller: motorData.controller,
//                               activeColor: Colors.green,
//                               inactiveColor: Colors.red.shade500,
//                               activeChild: const Text('ON'),
//                               inactiveChild: const Text('OFF'),
//                               borderRadius:
//                                   const BorderRadius.all(Radius.circular(15)),
//                               width: 55,
//                               height: 25,
//                               enabled: true,
//                               // ? true
//                               // : false,
//                               disabledOpacity: 0.5,
//                               onChanged: null,
//                             );
//                           },
//                         )
//                     ],
//                   ),
//                 ),
//               ].divide(const SizedBox(height: 8.0)),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/widgets/motor_card/voltage_current_values_card.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';

class MotorCardWidget extends StatelessWidget {
  final Motor motor;
  final MqttService mqttService;
  final Function(Motor, bool) onToggleMotor;

  const MotorCardWidget({
    super.key,
    required this.motor,
    required this.mqttService,
    required this.onToggleMotor,
  });

  MotorData? _getMotorData() {
    if (motor.starter?.macAddress == null || motor.id == null) return null;

    // Try all possible groups to find the motor
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      final motorId = '${motor.starter!.macAddress}-$groupId';
      final data = mqttService.motorDataMap[motorId];
      if (data != null) {
        return data;
      }
    }
    return null;
  }

  String _getMotorId() {
    if (motor.starter?.macAddress == null) return '';

    // Try to find which group this motor belongs to
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      final motorId = '${motor.starter!.macAddress}-$groupId';
      if (mqttService.motorDataMap.containsKey(motorId)) {
        return motorId;
      }
    }

    // If not found, default to G01
    return '${motor.starter!.macAddress}-G01';
  }

  // Check if motor/starter is active and available for control
  bool _isMotorAvailable() {
    // Starter must exist and be ACTIVE
    if (motor.starter == null) {
      return false;
    }
    if (motor.starter?.status?.toUpperCase() != 'ACTIVE') {
      return false;
    }
    return true;
  }

  Future<void> _handleToggle(bool newValue, MotorData motorData) async {
    final motorId = _getMotorId();
    if (motorId.isEmpty) {
      debugPrint('Cannot toggle: Invalid motor ID');
      return;
    }

    // Optimistically update the UI
    motorData.controller.value = newValue;

    try {
      // Publish the command: 1 for ON, 0 for OFF
      final state = newValue ? 1 : 0;
      await mqttService.publishMotorCommand(motorId, state);
      debugPrint('Toggle command sent: $motorId -> $state');
    } catch (e) {
      // Revert on error
      motorData.controller.value = !newValue;
      debugPrint('Failed to toggle motor: $e');
    }
  }

  Future<void> _handleModeToggle(int? index, MotorData motorData) async {
    if (index == null) return;

    final motorId = _getMotorId();
    if (motorId.isEmpty) {
      debugPrint('Cannot change mode: Invalid motor ID');
      return;
    }

    // Optimistically update the UI
    final oldIndex = motorData.modeIndex;
    motorData.modeswitchcontroller.value = index;

    try {
      // Send mode change command
      // 0 = Auto, 1 = Manual
      await mqttService.publishModeCommand(motorId, index);
      debugPrint(
          'Mode command sent: $motorId -> $index (${index == 0 ? "Auto" : "Manual"})');
    } catch (e) {
      // Revert on error
      motorData.modeswitchcontroller.value = oldIndex;
      debugPrint('Failed to change mode: $e');
    }
  }

  List<String> getFaults(String? faultCode) {
    Map<int, String> faultCodes = {
      0x01: "Dry Run Fault",
      0x02: "Overload Fault",
      0x04: "Locked Rotor Fault",
      0x08: "Current Imbalance Fault",
      0x10: "Frequent Start Fault",
      0x20: "Phase Failure Fault",
      0x40: "Low Voltage Fault",
      0x80: "Over Voltage Fault",
      0x100: "Voltage Imbalance Fault",
      0x200: "Phase Reversal Fault",
      0x400: "Frequency deviation Fault",
      0x800: "Over Temperature Fault",
    };

    if (faultCode == null || faultCode.trim().isEmpty) {
      return [];
    }

    try {
      int input = int.parse(faultCode);

      if (input == 4095) {
        return faultCodes.values.toList();
      }

      List<String> faults = [];
      faultCodes.forEach((code, message) {
        if ((input & code) != 0) {
          faults.add(message);
        }
      });

      return faults;
    } catch (e) {
      return [];
    }
  }

  int? _getSimplifiedModeIndex(String motorMode) {
    // Extract only Auto/Manual from the mode string
    if (motorMode.contains('AUTO')) {
      return 0; // Auto
    } else if (motorMode.contains('MANUAL')) {
      return 1; // Manual
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mqttService.dataUpdateNotifier,
      builder: (context, _, __) {
        final motorData = _getMotorData();

        // Create a default MotorData if none exists
        final displayData = motorData ??
            MotorData(
              macAddress: motor.starter?.macAddress,
              groupId: 'G01',
              title: motor.name,
            )
          ..controller.value = (motor.state == 1 || motor.state == 6);
        final bool isPowerOn = displayData.power == 1;

        // Check if motor is available for control
        final isAvailable = _isMotorAvailable();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0.0),
                            child: SvgPicture.asset(
                              'assets/images/motor.svg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            motor.name?.capitalizeFirst ?? '',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: const Color(0xFF1E1E1E),
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ].divide(const SizedBox(width: 8.0)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Connection status
                          if (displayData.hasReceivedData)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/wifi.svg',
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Icon(
                              Icons.wifi_off,
                              color: Colors.grey,
                              size: 20,
                            ),
                          // Power status
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0.0),
                            child: SvgPicture.asset(
                              isPowerOn
                                  ? 'assets/images/power.svg'
                                  : 'assets/images/Power_red.svg',
                              width: 17,
                              height: 17,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Fault indicator
                          if ((displayData.fault) > 0)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color: const Color(0xFFDCDCDC),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8.0, 4.0, 8.0, 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.exclamationTriangle,
                                      color: Color(0xFFEB5757),
                                      size: 14.0,
                                    ),
                                    Text(
                                      '${displayData.fault}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.dmSans(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: const Color(0xFF2B2B2B),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ].divide(const SizedBox(width: 6.0)),
                                ),
                              ),
                            ),
                        ].divide(const SizedBox(width: 8.0)),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  thickness: 1.0,
                  color: Color(0xFFECECEC),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
                  child: VoltageCurrentValuesCard(
                    motor: motor,
                    mqttService: mqttService,
                  ),
                ),
                const Divider(
                  thickness: 1.0,
                  color: Color(0xFFECECEC),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFF2F80ED),
                          //     borderRadius: BorderRadius.circular(4.0),
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsetsDirectional.fromSTEB(
                          //         8.0, 4.0, 8.0, 4.0),
                          //     child: Text(
                          //       'M',
                          //       style: FlutterFlowTheme.of(context)
                          //           .bodyMedium
                          //           .override(
                          //             font: GoogleFonts.dmSans(
                          //               fontWeight: FontWeight.w600,
                          //             ),
                          //             color: Colors.white,
                          //             fontSize: 16.0,
                          //             letterSpacing: 0.0,
                          //           ),
                          //     ),
                          //   ),
                          // ),
                          // Mode Toggle Switch - Always enabled when starter is ACTIVE
                          ValueListenableBuilder<int?>(
                            valueListenable: displayData.modeswitchcontroller,
                            builder: (context, currentModeIndex, child) {
                              final simplifiedIndex = _getSimplifiedModeIndex(
                                  displayData.motorMode);
                              final displayIndex =
                                  currentModeIndex ?? simplifiedIndex ?? 0;

                              return AbsorbPointer(
                                absorbing: !isAvailable,
                                child: Opacity(
                                  opacity: isAvailable ? 1.0 : 0.5,
                                  child: ToggleSwitch(
                                    changeOnTap: isAvailable,
                                    customWidths: const [90, 90],
                                    radiusStyle: true,
                                    minWidth: 80.0,
                                    minHeight: 30.0,
                                    initialLabelIndex: displayIndex,
                                    cornerRadius: 8.0,
                                    activeBgColors: isAvailable
                                        ? [
                                            [
                                              const Color(0xFFFFA500)
                                            ], // Orange for Auto (index 0)
                                            [
                                              const Color(0xFF2F80ED)
                                            ] // Blue for Manual (index 1)
                                          ]
                                        : [
                                            [Colors.grey.shade300],
                                            [Colors.grey.shade300]
                                          ],
                                    activeFgColor: Colors.white,
                                    inactiveBgColor: Colors.white,
                                    inactiveFgColor: Colors.black,
                                    fontSize: 12,
                                    totalSwitches: 2,
                                    labels: const ['Auto', 'Manual'],
                                    borderWidth: 1,
                                    borderColor: [Colors.grey.shade300],
                                    onToggle: isAvailable
                                        ? (index) {
                                            _handleModeToggle(
                                                index, displayData);
                                          }
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ].divide(const SizedBox(width: 8.0)),
                      ),
                      // ON/OFF Toggle Switch - Always enabled when starter is ACTIVE
                      ValueListenableBuilder<bool>(
                        valueListenable: displayData.controller,
                        builder: (context, isOn, child) {
                          return AdvancedSwitch(
                            controller: displayData.controller,
                            activeColor: Colors.green,
                            inactiveColor: Colors.red.shade500,
                            activeChild: const Text('ON'),
                            inactiveChild: const Text('OFF'),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            width: 55,
                            height: 25,
                            enabled: isAvailable,
                            disabledOpacity: 0.5,
                            onChanged: (value) {
                              _handleToggle(value, displayData);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ].divide(const SizedBox(height: 8.0)),
            ),
          ),
        );
      },
    );
  }
}
