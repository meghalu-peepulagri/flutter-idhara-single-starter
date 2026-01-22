import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
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
                      // _buildMotorName(context),
                      const SizedBox(height: 6),
                      _buildMotorMode(context),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMotorHP(context),
                        const SizedBox(
                            width: 12), // spacing between state & mode
                        _buildNetworkIcon(context)
                        // _buildMotorMode(context),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTimeStamp(context),
                  ],
                ),
              ],
            ),
            // _buildFaultBanner(context),
          ].divide(const SizedBox(height: 12.0)),
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
      if (signalQuality >= 2 && signalQuality <= 31) {
        if (signalQuality >= 2 && signalQuality <= 9) {
          bars = 1;
        } else if (signalQuality >= 10 && signalQuality <= 14) {
          bars = 2;
        } else if (signalQuality >= 15 && signalQuality <= 19) {
          bars = 3;
        } else if (signalQuality >= 20 && signalQuality <= 31) {
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
      return Row(
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
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
          ),
        ],
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
      final mode = controller.motorMode.value;
      final isAuto = mode == 'A' || mode.toLowerCase().contains('auto');

      String modeText = 'Manual';
      Color modeColor = const Color(0xFFFFEDD4);

      if (isAuto) {
        modeText = 'Auto';
        modeColor = const Color(0xFFFFEDD4);
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
              color: modeColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: Text(
              modeText,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w400,
                    ),
                    color: const Color(0XFFCA3500),
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                  ),
            ),
          ),
        ],
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
