import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:lottie/lottie.dart';

class MotorHeader extends StatelessWidget {
  final Motor motor;
  final MotorData? motorData;
  final VoidCallback onTap;

  const MotorHeader({
    super.key,
    required this.motor,
    required this.motorData,
    required this.onTap,
  });

  bool get _isPowerOn {
    if (motorData != null && motorData!.hasReceivedData) {
      return motorData!.power == 1;
    }
    return (motor.starter?.power ?? 0) == 1;
  }

  int get _faultValue {
    if (motorData != null && motorData!.hasReceivedData) {
      return motorData!.fault;
    }
    return motor.starter?.starterParameters?.firstOrNull?.fault ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AbsorbPointer(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
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
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Text(
                    (motor.aliasName != null &&
                                motor.aliasName!.trim().isNotEmpty
                            ? motor.aliasName!
                            : motor.name ?? '') ??
                        '',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0.0),
                    child: SvgPicture.asset(
                      _isPowerOn
                          ? 'assets/images/power.svg'
                          : 'assets/images/Power_red.svg',
                      width: 17,
                      height: 17,
                      fit: BoxFit.cover,
                    ),
                  ),
                  _SignalIcon(motor: motor, motorData: motorData),
                  if (_faultValue > 0)
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
                            8.0, 2.0, 8.0, 2.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Lottie.asset(
                              'assets/lottie_animations/warning 1.json',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              repeat: true,
                            )
                          ].divide(const SizedBox(width: 6.0)),
                        ),
                      ),
                    ),
                ].divide(const SizedBox(width: 8.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalIcon extends StatelessWidget {
  final Motor motor;
  final MotorData? motorData;

  const _SignalIcon({required this.motor, required this.motorData});

  @override
  Widget build(BuildContext context) {
    int bars = 0;
    if (motorData != null &&
        motorData!.hasReceivedData &&
        !motorData!.isSignalStale()) {
      bars = motorData!.signalBars;
    } else {
      final signalStrength = motor.starter?.signalQuality;
      if (signalStrength != null &&
          signalStrength >= 2 &&
          signalStrength <= 31) {
        if (signalStrength >= 2 && signalStrength <= 9) {
          bars = 1;
        } else if (signalStrength >= 10 && signalStrength <= 14) {
          bars = 2;
        } else if (signalStrength >= 15 && signalStrength <= 19) {
          bars = 3;
        } else if (signalStrength >= 20 && signalStrength <= 30) {
          bars = 4;
        }
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
  }
}
