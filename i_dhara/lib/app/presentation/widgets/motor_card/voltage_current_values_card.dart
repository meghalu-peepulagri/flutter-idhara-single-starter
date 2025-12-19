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

  MotorData? _getMotorData() {
    if (motor.starter?.macAddress == null || motor.id == null) return null;

    final mac = motor.starter!.macAddress!;

    MotorData? latestData;
    DateTime? latestTimestamp;

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      final motorId = '$mac-$groupId';
      final data = mqttService.motorDataMap[motorId];

      if (data != null && data.hasReceivedData) {
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

        String voltageR, voltageY, voltageB;
        String currentR, currentY, currentB;
        int motorState;

        if (motorData?.hasReceivedData == true) {
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

        return Padding(
          padding: const EdgeInsets.only(left: 2, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Labels Column
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: SvgPicture.asset(
                            'assets/images/Line_7.svg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        'V',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF828282),
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        'A',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF828282),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ].divide(const SizedBox(height: 14)),
                  ),
                  // Phase R Column
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: SvgPicture.asset(
                          'assets/images/Line_7.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        (double.tryParse(voltageR) ?? 0.0)
                            .toStringAsFixed(voltageR.contains('.') ? 1 : 0),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF4F4F4F),
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        (double.tryParse(currentR) ?? 0.0)
                            .toStringAsFixed(currentR.contains('.') ? 1 : 0),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF4F4F4F),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ].divide(const SizedBox(height: 16)),
                  ),
                  // Phase Y Column
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: SvgPicture.asset(
                          'assets/images/Line_7-1.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        (double.tryParse(voltageY) ?? 0.0)
                            .toStringAsFixed(voltageY.contains('.') ? 1 : 0),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF4F4F4F),
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        (double.tryParse(currentY) ?? 0.0)
                            .toStringAsFixed(currentY.contains('.') ? 1 : 0),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF4F4F4F),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ].divide(const SizedBox(height: 16)),
                  ),
                  // Phase B Column
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: SvgPicture.asset(
                          'assets/images/Line_7-2.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        (double.tryParse(voltageB) ?? 0.0)
                            .toStringAsFixed(voltageB.contains('.') ? 1 : 0),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF4F4F4F),
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        (double.tryParse(currentB) ?? 0.0)
                            .toStringAsFixed(currentB.contains('.') ? 1 : 0),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              color: const Color(0xFF4F4F4F),
                              letterSpacing: 0.0,
                            ),
                      ),
                    ].divide(const SizedBox(height: 16)),
                  ),
                ].divide(const SizedBox(width: 16)),
              ),
              // Motor/Pump Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(0),
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
          ),
        );
      },
    );
  }
}
