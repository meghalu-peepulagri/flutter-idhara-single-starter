// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
// import 'package:lottie/lottie.dart';

// class VoltageCurrentValuesCard extends StatelessWidget {
//   final Motor motor;
//   final MqttService mqttService;

//   const VoltageCurrentValuesCard({
//     super.key,
//     required this.motor,
//     required this.mqttService,
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

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<int>(
//       valueListenable: mqttService.dataUpdateNotifier,
//       builder: (context, _, __) {
//         final motorData = _getMotorData();
//         final StarterParameter =
//             motor.starter?.starterParameters?.isNotEmpty == true
//                 ? motor.starter!.starterParameters!.first
//                 : null;

//         // Use MQTT data if available, otherwise fall back to API data
//         final voltageR = motorData?.hasReceivedData == true
//             ? motorData!.voltageRed
//             : (StarterParameter?.lineVoltageR.toString() ?? '0');
//         final voltageY = motorData?.hasReceivedData == true
//             ? motorData!.voltageYellow
//             : (StarterParameter?.lineVoltageY.toString() ?? '0');
//         final voltageB = motorData?.hasReceivedData == true
//             ? motorData!.voltageBlue
//             : (StarterParameter?.lineVoltageB.toString() ?? '0');

//         final currentR = motorData?.hasReceivedData == true
//             ? motorData!.currentRed
//             : (StarterParameter?.currentR.toString() ?? '0');
//         final currentY = motorData?.hasReceivedData == true
//             ? motorData!.currentYellow
//             : (StarterParameter?.currentY.toString() ?? '0');
//         final currentB = motorData?.hasReceivedData == true
//             ? motorData!.currentBlue
//             : (StarterParameter?.currentB.toString() ?? '0');

//         final motorState = motorData?.hasReceivedData == true
//             ? motorData!.state
//             : (motor.state ?? 0);

//         return Row(
//           mainAxisSize: MainAxisSize.max,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               mainAxisSize: MainAxisSize.max,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     Text(
//                       '(V)',
//                       style: FlutterFlowTheme.of(context).bodyMedium.override(
//                             font: GoogleFonts.dmSans(
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                             color: const Color(0xFF828282),
//                             letterSpacing: 0.0,
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Text(
//                           voltageR,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           voltageY,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           voltageB,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                       ].divide(const SizedBox(width: 24.0)),
//                     ),
//                   ].divide(const SizedBox(width: 32.0)),
//                 ),
//                 Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     Opacity(
//                       opacity: 0.0,
//                       child: Text(
//                         '(V)',
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF828282),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(0.0),
//                           child: SvgPicture.asset(
//                             'assets/images/Line_7.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(0.0),
//                           child: SvgPicture.asset(
//                             'assets/images/Line_7-1.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(0.0),
//                           child: SvgPicture.asset(
//                             'assets/images/Line_7-2.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ].divide(const SizedBox(width: 18.0)),
//                     ),
//                   ].divide(const SizedBox(width: 28.0)),
//                 ),
//                 Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     Text(
//                       '(A)',
//                       style: FlutterFlowTheme.of(context).bodyMedium.override(
//                             font: GoogleFonts.dmSans(
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                             color: const Color(0xFF828282),
//                             letterSpacing: 0.0,
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Text(
//                           currentR,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           currentY,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           currentB,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                       ].divide(const SizedBox(width: 34.0)),
//                     ),
//                   ].divide(const SizedBox(width: 32.0)),
//                 ),
//               ].divide(const SizedBox(height: 4.0)),
//             ),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(0.0),
//               child: motorState == 1
//                   ? Lottie.asset(
//                       'assets/lottie_animations/pump_on.json',
//                       fit: BoxFit.contain,
//                       repeat: true,
//                     )
//                   : SvgPicture.asset(
//                       'assets/images/red pump.svg',
//                       fit: BoxFit.contain,
//                     ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
// import 'package:lottie/lottie.dart';

// class VoltageCurrentValuesCard extends StatelessWidget {
//   final Motor motor;
//   final MqttService mqttService;

//   const VoltageCurrentValuesCard({
//     super.key,
//     required this.motor,
//     required this.mqttService,
//   });

//   MotorData? _getMotorData() {
//     if (motor.starter?.macAddress == null || motor.id == null) return null;

//     final mac = motor.starter!.macAddress!;

//     // Check all groups and return the one with actual received data
//     MotorData? foundData;
//     for (int i = 1; i <= 4; i++) {
//       final groupId = 'G0$i';
//       final motorId = '$mac-$groupId';
//       final data = mqttService.motorDataMap[motorId];
//       if (data != null && data.hasReceivedData) {
//         foundData = data;
//         debugPrint(
//             'VoltageCurrentValuesCard - ${motor.name} - Found MQTT data in $groupId');
//       }
//     }

//     return foundData;
//   }

//   String _formatValue(String value) {
//     if (value == '0' || value == '0.0') return '0';
//     try {
//       final doubleValue = double.parse(value);
//       return doubleValue.toStringAsFixed(2);
//     } catch (e) {
//       return value;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<int>(
//       valueListenable: mqttService.dataUpdateNotifier,
//       builder: (context, notificationValue, __) {
//         final motorData = _getMotorData();
//         final starterParameter =
//             motor.starter?.starterParameters?.isNotEmpty == true
//                 ? motor.starter!.starterParameters!.first
//                 : null;

//         debugPrint('🔧 VoltageCurrentValuesCard rebuild - ${motor.name}');
//         debugPrint('  Notification value: $notificationValue');
//         debugPrint('  Has MQTT data: ${motorData?.hasReceivedData ?? false}');

//         // Determine data source and values
//         String voltageR, voltageY, voltageB;
//         String currentR, currentY, currentB;
//         int motorState;

//         if (motorData?.hasReceivedData == true) {
//           // Use MQTT data
//           voltageR = _formatValue(motorData!.voltageRed);
//           voltageY = _formatValue(motorData.voltageYellow);
//           voltageB = _formatValue(motorData.voltageBlue);
//           currentR = _formatValue(motorData.currentRed);
//           currentY = _formatValue(motorData.currentYellow);
//           currentB = _formatValue(motorData.currentBlue);
//           motorState = motorData.state;

//           debugPrint('  Using MQTT data:');
//           debugPrint('    Voltages: R=$voltageR, Y=$voltageY, B=$voltageB');
//           debugPrint('    Currents: R=$currentR, Y=$currentY, B=$currentB');
//           debugPrint('    State: $motorState');
//         } else {
//           // Fallback to API data
//           voltageR =
//               _formatValue(starterParameter?.lineVoltageR?.toString() ?? '0');
//           voltageY =
//               _formatValue(starterParameter?.lineVoltageY?.toString() ?? '0');
//           voltageB =
//               _formatValue(starterParameter?.lineVoltageB?.toString() ?? '0');
//           currentR =
//               _formatValue(starterParameter?.currentR?.toString() ?? '0');
//           currentY =
//               _formatValue(starterParameter?.currentY?.toString() ?? '0');
//           currentB =
//               _formatValue(starterParameter?.currentB?.toString() ?? '0');
//           motorState = motor.state ?? 0;

//           debugPrint('  Using API data:');
//           debugPrint('    Voltages: R=$voltageR, Y=$voltageY, B=$voltageB');
//           debugPrint('    Currents: R=$currentR, Y=$currentY, B=$currentB');
//           debugPrint('    State: $motorState');
//         }

//         return Row(
//           mainAxisSize: MainAxisSize.max,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               mainAxisSize: MainAxisSize.max,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     Text(
//                       '(V)',
//                       style: FlutterFlowTheme.of(context).bodyMedium.override(
//                             font: GoogleFonts.dmSans(
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                             color: const Color(0xFF828282),
//                             letterSpacing: 0.0,
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Text(
//                           (double.tryParse(voltageR) ?? 0.0)
//                               .toStringAsFixed(voltageR.contains('.') ? 1 : 0),
//                           // voltageR,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           (double.tryParse(voltageY) ?? 0.0)
//                               .toStringAsFixed(voltageY.contains('.') ? 1 : 0),
//                           // voltageY,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           (double.tryParse(voltageB) ?? 0.0)
//                               .toStringAsFixed(voltageB.contains('.') ? 1 : 0),
//                           // voltageB,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                       ].divide(const SizedBox(width: 24.0)),
//                     ),
//                   ].divide(const SizedBox(width: 32.0)),
//                 ),
//                 Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     Opacity(
//                       opacity: 0.0,
//                       child: Text(
//                         '(V)',
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF828282),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(0.0),
//                           child: SvgPicture.asset(
//                             'assets/images/Line_7.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(0.0),
//                           child: SvgPicture.asset(
//                             'assets/images/Line_7-1.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(0.0),
//                           child: SvgPicture.asset(
//                             'assets/images/Line_7-2.svg',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ].divide(const SizedBox(width: 18.0)),
//                     ),
//                   ].divide(const SizedBox(width: 28.0)),
//                 ),
//                 Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     Text(
//                       '(A)',
//                       style: FlutterFlowTheme.of(context).bodyMedium.override(
//                             font: GoogleFonts.dmSans(
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                             color: const Color(0xFF828282),
//                             letterSpacing: 0.0,
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Text(
//                           (double.tryParse(currentR) ?? 0.0)
//                               .toStringAsFixed(currentR.contains('.') ? 1 : 0),
//                           // currentR,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           (double.tryParse(currentY) ?? 0.0)
//                               .toStringAsFixed(currentY.contains('.') ? 1 : 0),
//                           // currentY,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                         Text(
//                           (double.tryParse(currentB) ?? 0.0)
//                               .toStringAsFixed(currentB.contains('.') ? 1 : 0),
//                           // currentB,
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF4F4F4F),
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                         ),
//                       ].divide(const SizedBox(width: 34.0)),
//                     ),
//                   ].divide(const SizedBox(width: 32.0)),
//                 ),
//               ].divide(const SizedBox(height: 4.0)),
//             ),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(0.0),
//               child: motorState == 1
//                   ? Lottie.asset(
//                       'assets/lottie_animations/pump_on.json',
//                       fit: BoxFit.contain,
//                       repeat: true,
//                     )
//                   : SvgPicture.asset(
//                       'assets/images/red pump.svg',
//                       fit: BoxFit.contain,
//                     ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }--updated code

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:lottie/lottie.dart';

class VoltageCurrentValuesCard extends StatelessWidget {
  final Motor motor;
  final MqttService mqttService;

  const VoltageCurrentValuesCard({
    super.key,
    required this.motor,
    required this.mqttService,
  });

  // FIXED: Always check ALL groups dynamically and return the most recent data
  MotorData? _getMotorData() {
    if (motor.starter?.macAddress == null || motor.id == null) return null;

    final mac = motor.starter!.macAddress!;

    // Check all groups and return the MOST RECENTLY UPDATED one with data
    MotorData? latestData;
    DateTime? latestTimestamp;

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      final motorId = '$mac-$groupId';
      final data = mqttService.motorDataMap[motorId];

      if (data != null && data.hasReceivedData) {
        // Check if this data is more recent
        final dataTimestamp = mqttService.getLastAckTime(motorId);

        if (latestData == null ||
            (dataTimestamp != null &&
                (latestTimestamp == null ||
                    dataTimestamp.isAfter(latestTimestamp)))) {
          latestData = data;
          latestTimestamp = dataTimestamp;
          debugPrint(
              'VoltageCurrentValuesCard - ${motor.name} - Found MQTT data in $groupId (timestamp: $dataTimestamp)');
        }
      }
    }

    return latestData;
  }

  String _formatValue(String value) {
    if (value == '0' || value == '0.0') return '0';
    try {
      final doubleValue = double.parse(value);
      return doubleValue.toStringAsFixed(2);
    } catch (e) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mqttService.dataUpdateNotifier,
      builder: (context, notificationValue, __) {
        // CRITICAL: Get fresh motor data on EVERY build
        final motorData = _getMotorData();
        final starterParameter =
            motor.starter?.starterParameters?.isNotEmpty == true
                ? motor.starter!.starterParameters!.first
                : null;

        debugPrint('🔧 VoltageCurrentValuesCard rebuild - ${motor.name}');
        debugPrint('  Notification value: $notificationValue');
        debugPrint('  Has MQTT data: ${motorData?.hasReceivedData ?? false}');
        if (motorData != null) {
          debugPrint('  MQTT Group: ${motorData.groupId}');
        }

        // Determine data source and values
        String voltageR, voltageY, voltageB;
        String currentR, currentY, currentB;
        int motorState;

        if (motorData?.hasReceivedData == true) {
          // Use MQTT data
          voltageR = _formatValue(motorData!.voltageRed);
          voltageY = _formatValue(motorData.voltageYellow);
          voltageB = _formatValue(motorData.voltageBlue);
          currentR = _formatValue(motorData.currentRed);
          currentY = _formatValue(motorData.currentYellow);
          currentB = _formatValue(motorData.currentBlue);
          motorState = motorData.state;

          debugPrint('  Using MQTT data from ${motorData.groupId}:');
          debugPrint('    Voltages: R=$voltageR, Y=$voltageY, B=$voltageB');
          debugPrint('    Currents: R=$currentR, Y=$currentY, B=$currentB');
          debugPrint('    State: $motorState');
        } else {
          // Fallback to API data
          voltageR =
              _formatValue(starterParameter?.lineVoltageR?.toString() ?? '0');
          voltageY =
              _formatValue(starterParameter?.lineVoltageY?.toString() ?? '0');
          voltageB =
              _formatValue(starterParameter?.lineVoltageB?.toString() ?? '0');
          currentR =
              _formatValue(starterParameter?.currentR?.toString() ?? '0');
          currentY =
              _formatValue(starterParameter?.currentY?.toString() ?? '0');
          currentB =
              _formatValue(starterParameter?.currentB?.toString() ?? '0');
          motorState = motor.state ?? 0;

          debugPrint('  Using API data:');
          debugPrint('    Voltages: R=$voltageR, Y=$voltageY, B=$voltageB');
          debugPrint('    Currents: R=$currentR, Y=$currentY, B=$currentB');
          debugPrint('    State: $motorState');
        }

        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      '(V)',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: const Color(0xFF828282),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          (double.tryParse(voltageR) ?? 0.0)
                              .toStringAsFixed(voltageR.contains('.') ? 1 : 0),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF4F4F4F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                        Text(
                          (double.tryParse(voltageY) ?? 0.0)
                              .toStringAsFixed(voltageY.contains('.') ? 1 : 0),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF4F4F4F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                        Text(
                          (double.tryParse(voltageB) ?? 0.0)
                              .toStringAsFixed(voltageB.contains('.') ? 1 : 0),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF4F4F4F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ].divide(const SizedBox(width: 24.0)),
                    ),
                  ].divide(const SizedBox(width: 32.0)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Opacity(
                      opacity: 0.0,
                      child: Text(
                        '(V)',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF828282),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: SvgPicture.asset(
                            'assets/images/Line_7.svg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: SvgPicture.asset(
                            'assets/images/Line_7-1.svg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: SvgPicture.asset(
                            'assets/images/Line_7-2.svg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ].divide(const SizedBox(width: 18.0)),
                    ),
                  ].divide(const SizedBox(width: 28.0)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      '(A)',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: const Color(0xFF828282),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          (double.tryParse(currentR) ?? 0.0)
                              .toStringAsFixed(currentR.contains('.') ? 1 : 0),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF4F4F4F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                        Text(
                          (double.tryParse(currentY) ?? 0.0)
                              .toStringAsFixed(currentY.contains('.') ? 1 : 0),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF4F4F4F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                        Text(
                          (double.tryParse(currentB) ?? 0.0)
                              .toStringAsFixed(currentB.contains('.') ? 1 : 0),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF4F4F4F),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ].divide(const SizedBox(width: 34.0)),
                    ),
                  ].divide(const SizedBox(width: 32.0)),
                ),
              ].divide(const SizedBox(height: 4.0)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: motorState == 1
                  ? Lottie.asset(
                      'assets/lottie_animations/pump_on.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    )
                  : SvgPicture.asset(
                      'assets/images/red pump.svg',
                      fit: BoxFit.contain,
                    ),
            ),
          ],
        );
      },
    );
  }
}
