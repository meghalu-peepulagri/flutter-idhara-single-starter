import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:lottie/lottie.dart';

import '../modules/motor_details/motor_details_controller.dart';

class MotorDetailsCard extends StatelessWidget {
  final AnalyticsController controller;

  const MotorDetailsCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMotorState(context),
                      const SizedBox(height: 6),
                      _buildMotorMode(context),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMotorHP(context),
                        const SizedBox(width: 12),
                        _buildNetworkIcon(context),
                        const SizedBox(width: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTimeStamp(context),
                  ],
                ),
              ],
            ),
            // const SizedBox(height: 10),
            // _buildSimAndExpiryRow(context),
            // _buildFaultBanner(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkIcon(BuildContext context) {
    return Obx(() {
      // Get signal quality from controller
      final signalQuality = controller.signalQuality.value;

      int bars = 0;

      // Calculate signal bars based on signal quality
      if (signalQuality >= 2 && signalQuality <= 40) {
        if (signalQuality >= 2 && signalQuality <= 9) {
          bars = 1;
        } else if (signalQuality >= 10 && signalQuality <= 14) {
          bars = 2;
        } else if (signalQuality >= 15 && signalQuality <= 19) {
          bars = 3;
        } else if (signalQuality >= 20 && signalQuality <= 40) {
          bars = 4;
        }
      }

      String assetPath;
      double iconWidth = 16;
      double iconHeight = 16;

      switch (bars) {
        case 1:
          assetPath = 'assets/images/first_signal.svg';
          break;
        case 2:
          assetPath = 'assets/images/second_signal.svg';
          break;
        case 3:
          assetPath = 'assets/images/third_signal.svg';
          break;
        case 4:
          assetPath = 'assets/images/network.svg';
          break;
        case 0:
        default:
          assetPath = 'assets/images/no_network.svg';
          iconWidth = 20;
          iconHeight = 20;
          break;
      }

      return SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: iconWidth,
            height: iconHeight,
            fit: BoxFit.contain,
          ),
        ),
      );
    });
  }

  Widget _buildMotorName(BuildContext context) {
    return Obx(() {
      return Text(
        controller.motorName.value,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
              color: const Color(0xFF0A0A0A),
              fontSize: 20.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
            ),
      );
    });
  }

  Widget _buildTimeStamp(BuildContext context) {
    return Obx(() {
      final dateText = controller.timeStamp.value.trim();
      return GestureDetector(
        onTap: () async {
          await controller.handleLiveData();
        },
        child: Row(
          children: [
            const Icon(
              Icons.sync,
              color: Color(0xFF166491),
              size: 16,
            ),
            Text(
              ' ${dateText.isEmpty || dateText == 'N/A' ? ' N/A' : dateText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: const Color(0xFF166491),
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMotorHP(BuildContext context) {
    return Obx(() {
      return Row(
        children: [
          Text(
            '${controller.hp.value} HP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: const Color(0xFF6A7282),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
          ),
        ],
      );
    });
  }

  Widget _buildMotorState(BuildContext context) {
    return Obx(() {
      final state = controller.motorState.value;
      final isOn = state == 1;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'State :  ',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                  ),
                  color: const Color(0xFF000000),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFDCDCDC),
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle_rounded,
                  size: 10,
                  color:
                      isOn ? const Color(0xFF45A845) : const Color(0xFFF90707),
                ),
                const SizedBox(width: 6),
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w400,
                        ),
                        color: isOn
                            ? const Color(0xFF45A845)
                            : const Color(0xFFF90707),
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMotorMode(BuildContext context) {
    return Obx(() {
      // controller.motorMode.value is one of 'Auto' / 'Manual' / 'Schedule'
      // — set from the motors/:id `mode` field (see motor_details_controller
      // .api.dart) or from an MQTT mode tick via _labelForMode. The card used
      // to branch only on Auto vs. everything-else, so 'Schedule' fell
      // through and rendered as "Manual".
      final mode = controller.motorMode.value.toLowerCase();

      final String modeText;
      final Color bgColor;
      final Color textColor;
      if (mode == 'a' || mode.contains('auto')) {
        modeText = 'Auto';
        bgColor = const Color(0xFFFFEDD4);
        textColor = const Color(0xFFCA3500);
      } else if (mode.contains('schedule')) {
        modeText = 'Schedule';
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF6D28D9);
      } else {
        modeText = 'Manual';
        bgColor = const Color(0xFFFFEDD4);
        textColor = const Color(0xFFCA3500);
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mode: ',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: const Color(0xFF000000),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
          ),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: Text(
              modeText,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w400,
                    ),
                    color: textColor,
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSimAndExpiryRow(BuildContext context) {
    return Obx(() {
      final simNumber = controller.motorDetails.value?.starter?.simNumber;
      final rechargeExpiry =
          controller.motorDetails.value?.starter?.simRechargeexpiresDate;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFFE0EAF1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.sim_card_outlined,
                      size: 16, color: Color(0xFF166491)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIM Number',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w500),
                              color: const Color(0xFF6A7282),
                              fontSize: 11.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                      Text(
                        simNumber ?? 'N/A',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600),
                              color: const Color(0xFF166491),
                              fontSize: 13.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: const Color(0xFFD0DDE8),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Color(0xFF166491)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recharge Expiry',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500),
                                  color: const Color(0xFF6A7282),
                                  fontSize: 11.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          Text(
                            rechargeExpiry ?? 'N/A',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600),
                                  color: const Color(0xFF166491),
                                  fontSize: 13.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFaultBanner(BuildContext context) {
    return Obx(() {
      final fault = controller.faultMessage.value.trim();

      if (fault.isEmpty ||
          fault == '0' ||
          fault == 'N/A' ||
          fault.toLowerCase() == 'no fault') {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF4D9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Lottie.asset(
              'assets/lottie_animations/warning 1.json',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fault,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.dmSans(fontWeight: FontWeight.w300),
                      fontSize: 12,
                      color: const Color(0xFFFF8A00),
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
