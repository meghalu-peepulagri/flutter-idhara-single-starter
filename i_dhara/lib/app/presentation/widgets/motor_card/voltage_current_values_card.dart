// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';

// class VoltageCurrentValuesCard extends StatelessWidget {
//   final Motor motor;

//   const VoltageCurrentValuesCard({
//     super.key,
//     required this.motor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<DashboardController>();

//     return Obx(() {
//       // Force rebuild when motors list changes
//       final _ = controller.motors.length;

//       // Get fresh MQTT data
//       final motorData = controller.getMotorData(motor);

//       // Use MQTT data if available, otherwise fall back to API data
//       final StarterParameter =
//           motor.starter?.starterParameters?.isNotEmpty == true
//               ? motor.starter!.starterParameters!.first
//               : null;

//       // Voltage values - prefer MQTT data
//       final voltageR = motorData?.hasReceivedData == true
//           ? motorData!.voltageRed
//           : (StarterParameter?.lineVoltageR.toString() ?? '0');
//       final voltageY = motorData?.hasReceivedData == true
//           ? motorData!.voltageYellow
//           : (StarterParameter?.lineVoltageY.toString() ?? '0');
//       final voltageB = motorData?.hasReceivedData == true
//           ? motorData!.voltageBlue
//           : (StarterParameter?.lineVoltageB.toString() ?? '0');

//       // Current values - prefer MQTT data
//       final currentR = motorData?.hasReceivedData == true
//           ? motorData!.currentRed
//           : (StarterParameter?.currentR.toString() ?? '0');
//       final currentY = motorData?.hasReceivedData == true
//           ? motorData!.currentYellow
//           : (StarterParameter?.currentY.toString() ?? '0');
//       final currentB = motorData?.hasReceivedData == true
//           ? motorData!.currentBlue
//           : (StarterParameter?.currentB.toString() ?? '0');

//       // Motor state - prefer MQTT data
//       final motorState = motorData?.hasReceivedData == true
//           ? motorData!.state
//           : (motor.state ?? 0);

//       return Row(
//         mainAxisSize: MainAxisSize.max,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             mainAxisSize: MainAxisSize.max,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Text(
//                     '(V)',
//                     style: FlutterFlowTheme.of(context).bodyMedium.override(
//                           font: GoogleFonts.dmSans(
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                           color: const Color(0xFF828282),
//                           letterSpacing: 0.0,
//                           fontWeight: FontWeight.w500,
//                           fontStyle:
//                               FlutterFlowTheme.of(context).bodyMedium.fontStyle,
//                         ),
//                   ),
//                   Row(
//                     mainAxisSize: MainAxisSize.max,
//                     children: [
//                       Text(
//                         voltageR,
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF4F4F4F),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                       Text(
//                         voltageY,
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF4F4F4F),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                       Text(
//                         voltageB,
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF4F4F4F),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                     ].divide(const SizedBox(width: 24.0)),
//                   ),
//                 ].divide(const SizedBox(width: 32.0)),
//               ),
//               Row(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Opacity(
//                     opacity: 0.0,
//                     child: Text(
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
//                   ),
//                   Row(
//                     mainAxisSize: MainAxisSize.max,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(0.0),
//                         child: SvgPicture.asset(
//                           'assets/images/Line_7.svg',
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(0.0),
//                         child: SvgPicture.asset(
//                           'assets/images/Line_7-1.svg',
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(0.0),
//                         child: SvgPicture.asset(
//                           'assets/images/Line_7-2.svg',
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ].divide(const SizedBox(width: 18.0)),
//                   ),
//                 ].divide(const SizedBox(width: 28.0)),
//               ),
//               Row(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Text(
//                     '(A)',
//                     style: FlutterFlowTheme.of(context).bodyMedium.override(
//                           font: GoogleFonts.dmSans(
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                           color: const Color(0xFF828282),
//                           letterSpacing: 0.0,
//                           fontWeight: FontWeight.w500,
//                           fontStyle:
//                               FlutterFlowTheme.of(context).bodyMedium.fontStyle,
//                         ),
//                   ),
//                   Row(
//                     mainAxisSize: MainAxisSize.max,
//                     children: [
//                       Text(
//                         currentR,
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF4F4F4F),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                       Text(
//                         currentY,
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF4F4F4F),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                       Text(
//                         currentB,
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w500,
//                                 fontStyle: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .fontStyle,
//                               ),
//                               color: const Color(0xFF4F4F4F),
//                               letterSpacing: 0.0,
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                       ),
//                     ].divide(const SizedBox(width: 34.0)),
//                   ),
//                 ].divide(const SizedBox(width: 32.0)),
//               ),
//             ].divide(const SizedBox(height: 4.0)),
//           ),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(0.0),
//             child: SvgPicture.asset(
//               motorState == 1
//                   ? 'assets/images/pump.svg'
//                   : 'assets/images/pump_off.svg',
//               fit: BoxFit.cover,
//             ),
//           ),
//         ],
//       );
//     });
//   }
// } //
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

class VoltageCurrentValuesCard extends StatelessWidget {
  final Motor motor;
  final MqttService mqttService;

  const VoltageCurrentValuesCard({
    super.key,
    required this.motor,
    required this.mqttService,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mqttService.dataUpdateNotifier,
      builder: (context, _, __) {
        final motorData = _getMotorData();
        final StarterParameter =
            motor.starter?.starterParameters?.isNotEmpty == true
                ? motor.starter!.starterParameters!.first
                : null;

        // Use MQTT data if available, otherwise fall back to API data
        final voltageR = motorData?.hasReceivedData == true
            ? motorData!.voltageRed
            : (StarterParameter?.lineVoltageR.toString() ?? '0');
        final voltageY = motorData?.hasReceivedData == true
            ? motorData!.voltageYellow
            : (StarterParameter?.lineVoltageY.toString() ?? '0');
        final voltageB = motorData?.hasReceivedData == true
            ? motorData!.voltageBlue
            : (StarterParameter?.lineVoltageB.toString() ?? '0');

        final currentR = motorData?.hasReceivedData == true
            ? motorData!.currentRed
            : (StarterParameter?.currentR.toString() ?? '0');
        final currentY = motorData?.hasReceivedData == true
            ? motorData!.currentYellow
            : (StarterParameter?.currentY.toString() ?? '0');
        final currentB = motorData?.hasReceivedData == true
            ? motorData!.currentBlue
            : (StarterParameter?.currentB.toString() ?? '0');

        final motorState = motorData?.hasReceivedData == true
            ? motorData!.state
            : (motor.state ?? 0);

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
                          voltageR,
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
                          voltageY,
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
                          voltageB,
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
                          currentR,
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
                          currentY,
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
                          currentB,
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
              child: SvgPicture.asset(
                motorState == 1
                    ? 'assets/images/pump.svg'
                    : 'assets/images/pump_off.svg',
                fit: BoxFit.cover,
              ),
            ),
          ],
        );
      },
    );
  }
}
