import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:lottie/lottie.dart';

class VoltageCurrentValuesCard extends StatelessWidget {
  final Motor motor;
  final MqttService mqttService;
  final bool isTestRunRequired;

  const VoltageCurrentValuesCard({
    super.key,
    required this.motor,
    required this.mqttService,
    this.isTestRunRequired = false,
  });

  MotorData? _getMotorData() {
    if (motor.starter == null || motor.id == null) return null;

    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;

    if ((mac == null || mac.isEmpty) && (pcb == null || pcb.isEmpty)) {
      return null;
    }

    MotorData? latestData;
    DateTime? latestTimestamp;

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';

      // Try both MAC and PCB identifiers
      final macMotorId = mac != null && mac.isNotEmpty ? '$mac-$groupId' : null;
      final pcbMotorId = pcb != null && pcb.isNotEmpty ? '$pcb-$groupId' : null;

      // Check MAC address
      if (macMotorId != null) {
        final data = mqttService.motorDataMap[macMotorId];
        if (data != null && data.hasReceivedData) {
          final dataTimestamp = mqttService.getLastAckTime(macMotorId);
          if (latestData == null ||
              (dataTimestamp != null &&
                  (latestTimestamp == null ||
                      dataTimestamp.isAfter(latestTimestamp)))) {
            latestData = data;
            latestTimestamp = dataTimestamp;
          }
        }
      }

      // Check PCB number - also compare timestamps (not just when latestData is null)
      if (pcbMotorId != null) {
        final data = mqttService.motorDataMap[pcbMotorId];
        if (data != null && data.hasReceivedData) {
          final dataTimestamp = mqttService.getLastAckTime(pcbMotorId);
          if (latestData == null ||
              (dataTimestamp != null &&
                  (latestTimestamp == null ||
                      dataTimestamp.isAfter(latestTimestamp)))) {
            latestData = data;
            latestTimestamp = dataTimestamp;
          }
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

        // Debug: Log motor identifiers and found data
        debugPrint(
            '🔍 VoltageCard: motor=${motor.name}, mac=${motor.starter?.macAddress}, pcb=${motor.starter?.pcbNumber}');
        if (motorData != null) {
          debugPrint(
              '  ✓ Found MQTT data: group=${motorData.groupId}, state=${motorData.state}, hasData=${motorData.hasReceivedData}');
          debugPrint(
              '  ✓ Voltages: R=${motorData.voltageRed}, Y=${motorData.voltageYellow}, B=${motorData.voltageBlue}');
        } else {
          debugPrint('  ✗ No MQTT data found, using API values');
        }

        String voltageR, voltageY, voltageB;
        String currentR, currentY, currentB;
        int motorState;

        // Priority: MQTT data > API data (starterParameters)
        if (motorData?.hasReceivedData == true) {
          // Use MQTT data if available
          voltageR = _formatValue(motorData!.voltageRed);
          voltageY = _formatValue(motorData.voltageYellow);
          voltageB = _formatValue(motorData.voltageBlue);
          currentR = _formatValue(motorData.currentRed);
          currentY = _formatValue(motorData.currentYellow);
          currentB = _formatValue(motorData.currentBlue);
          motorState = motorData.state;
        } else {
          // Use API data from starterParameters (even if test run is required)
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
                    ].divide(const SizedBox(height: 10)),
                  ),
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
                    ].divide(const SizedBox(height: 10)),
                  ),
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
                    ].divide(const SizedBox(height: 10)),
                  ),
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
                    ].divide(const SizedBox(height: 10)),
                  ),
                ].divide(const SizedBox(width: 16)),
              ),
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
