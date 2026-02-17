import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

import '../../data/services/mqtt_manager/mqtt_service.dart';
import 'testrun_verification_card2.dart';

class ConfirmTestRunScreen extends StatefulWidget {
  final ValueNotifier<bool> cloudConnectionVerified;
  final ValueNotifier<bool> inputPowerVerified;
  final ValueNotifier<double> avgflc;
  final Motor motor;
  final MotorData? motorData;

  final MqttService mqttService;

  const ConfirmTestRunScreen({
    super.key,
    required this.cloudConnectionVerified,
    required this.inputPowerVerified,
    required this.avgflc,
    required this.motor,
    required this.mqttService,
    this.motorData,
  });

  @override
  State<ConfirmTestRunScreen> createState() => _ConfirmTestRunScreenState();
}

class _ConfirmTestRunScreenState extends State<ConfirmTestRunScreen> {
  bool isMotorWiresChecked = false;
  bool isPumpValveChecked = false;

  bool get _isPowerOn {
    if (widget.motorData != null && widget.motorData!.hasReceivedData) {
      return widget.motorData!.power == 1;
    }
    return (widget.motor.starter?.power ?? 0) == 1;
  }

  final ValueNotifier<double> avgflc = ValueNotifier(0.0);

  bool signalCheck(int val) {
    return val >= 1 && val <= 4;
  }

  double percentageOFAmps(double c1, double c2, double c3) {
    double sum = c1 + c2 + c3;
    final percent = sum / 3;
    return percent;
  }

  int _getSignalBars(MotorData? motorData) {
    if (motorData?.hasReceivedData == true && !motorData!.isSignalStale()) {
      return motorData.signalBars;
    }
    final signal = widget.motor.starter?.signalQuality;
    if (signal == null || signal < 2 || signal > 31) return 0;
    if (signal < 10) return 1;
    if (signal < 15) return 2;
    if (signal < 20) return 3;
    return 4;
  }

  bool get isActive {
    final motordata = widget.motorData;
    final signal = getSignalBars(motordata);
    final pwr = motordata?.power;

    final cloudOk = signal >= 1 && signal <= 4;
    final powerOk = pwr == 1;

    return isMotorWiresChecked && isPumpValveChecked && cloudOk && powerOk;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close icon

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Test Run',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Smart Calibration v2.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  // Close icon
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Pre-Test Verifications Section
              const Text(
                'Pre - Test Verifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),

              // Cloud Connection
              _buildVerificationCloudConnection(
                  'Network Connectivity',
                  _getSignalBars(widget.motorData),
                  'assets/images/network_device.svg'),
              const SizedBox(height: 16),
              // Input Power
              _buildVerificationInputPower(
                'Power Supply Status',
                _isPowerOn == true ? 1 : 0,
              ),
              const SizedBox(height: 24),
              // Motor wires checkbox
              _buildCheckboxItem(
                'Motor wires / terminals securely connected',
                isMotorWiresChecked,
                (value) {
                  setState(() {
                    isMotorWiresChecked = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Pump valve checkbox
              _buildCheckboxItem(
                'Pump / delivery valve fully open',
                isPumpValveChecked,
                (value) {
                  setState(() {
                    isPumpValveChecked = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Start Button - rebuilds on MQTT data changes
              ValueListenableBuilder(
                valueListenable: widget.mqttService.dataUpdateNotifier,
                builder: (context, _, __) {
                  final motordata = widget.motorData;
                  final c1 = double.parse(motordata?.currentBlue ?? "0.0");
                  final c2 = double.parse(motordata?.currentRed ?? "0.0");
                  final c3 = double.parse(motordata?.currentYellow ?? "0.0");
                  final avg = percentageOFAmps(c1, c2, c3);
                  avgflc.value = avg;

                  print("line 209 ${avgflc.value}");

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isActive
                          ? () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 24,
                                  ),
                                  child: MotorTestRunCard(
                                    avgflc: avgflc,
                                    motor: widget.motor,
                                    mqttService: widget.mqttService,
                                    motorData: widget.motorData,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? const Color(0xFF0F6B8A)
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'START TEST RUN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get checkIcon => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFECFDF5),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF10B981),
          size: 16,
        ),
      );

  Widget get closeIcon => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade100,
          border: Border.all(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.red,
          size: 16,
        ),
      );

  Widget get loadingIcon => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0F6B8A),
        ),
      );

  int getSignalBars(MotorData? motorData) {
    // CRITICAL: Only use signal from allowed groups (G01, G02)
    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale() &&
        motorData.groupId != null) {
      return motorData.signalBars;
    }
    final signalStrength = widget.motor.starter?.signalQuality;
    if (signalStrength != null && signalStrength >= 2 && signalStrength <= 31) {
      if (signalStrength >= 2 && signalStrength <= 9) return 1;
      if (signalStrength >= 10 && signalStrength <= 14) return 2;
      if (signalStrength >= 15 && signalStrength <= 19) return 3;
      if (signalStrength >= 20 && signalStrength <= 30) return 4;
    }
    print("line 419 --> $signalStrength");
    return 0;
  }

  Widget _buildVerificationCloudConnection(
      String text, int? signal, String svg) {
    return Row(
      spacing: 10,
      children: [
        SvgPicture.asset('assets/images/network_device.svg'),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
        signal != null
            ? signal >= 1 && signal <= 4
                ? checkIcon
                : closeIcon
            : loadingIcon
      ],
    );
  }

  Widget _buildVerificationInputPower(String text, int? verified) {
    return Row(
      spacing: 10,
      children: [
        SvgPicture.asset('assets/images/bulb_power.svg'),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
        verified != null
            ? verified == 1
                ? checkIcon
                : closeIcon
            : loadingIcon
      ],
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(
              color: Color(0xFFCBD5E1),
              width: 1.5,
            ),
            activeColor: const Color(0xFF0F6B8A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
