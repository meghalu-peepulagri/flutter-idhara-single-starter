import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

import '../../data/services/mqtt_manager/mqtt_service.dart';
import '../modules/dashboard/dashboard_controller.dart';
import 'testrun_verification_card3.dart';

class MotorTestRunCard extends StatefulWidget {
  final Motor motor;
  final MqttService mqttService;
  final String? flc;
  final ValueNotifier<double> avgflc;
  final MotorData? motorData;

  const MotorTestRunCard(
      {super.key,
      this.flc,
      required this.avgflc,
      required this.motor,
      required this.mqttService,
      required this.motorData});

  @override
  State<MotorTestRunCard> createState() => _MotorTestRunCardState();
}

class _MotorTestRunCardState extends State<MotorTestRunCard> {
  static const int _totalSeconds = 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _timerRunning = true;
  double overalFlc = 0.0;

  DashboardController controller = Get.put(DashboardController());

  final List<double> flcdata = [];
  final ValueNotifier<double> avgCurrent = ValueNotifier(0);
  final ValueNotifier<double> overalCurrent = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _startTimer();

    widget.mqttService.dataUpdateNotifier.addListener(checkUpdates);
  }

  void checkUpdates() {
    if (!mounted) return;
    print("line 50  ----->");
    final motordata = widget.motorData;
    final c2 = double.parse(motordata?.currentBlue ?? "0.0");
    final c1 = double.parse(motordata?.currentRed ?? "0.0");
    final c3 = double.parse(motordata?.currentYellow ?? "0.0");
    final avg = percentageOFAmps(c1, c2, c3);

    setState(() {
      avgCurrent.value = avg;
    });

    if (avg > 0 && !flcdata.contains(avg)) {
      flcdata.add(avg);
      final sum = flcdata.reduce((a, b) => a + b);
      overalCurrent.value = sum / flcdata.length;
    }

    print(
        "line 50  ----->   ${avgCurrent.value} $c1 ,$c2 ,$c3  flcdata: $flcdata  overalAvg: ${overalCurrent.value}");
  }

  void _onAvgFlcChanged() {
    if (_timerRunning && widget.avgflc.value > 0) {
      print("line 39 ------> ${widget.avgflc.value}");
      flcdata.add(widget.avgflc.value);
    }
  }

  double calculatedFlc(double val, double flcVal) {
    final percentLow = val.toInt() / 100;
    final res = percentLow * flcVal;
    final newRes = double.parse(res.toStringAsFixed(2)) ?? 0.0;
    return newRes;
  }

  String _getMotorIdentifier() {
    if (widget.motor.starter == null) return '';
    final mac = widget.motor.starter!.macAddress;
    final pcb = widget.motor.starter!.pcbNumber;
    if (mac?.isNotEmpty == true) return mac!;
    if (pcb?.isNotEmpty == true) return pcb!;
    return '';
  }

  double percentageOFAmps(double c1, double c2, double c3) {
    double sum = c1 + c2 + c3;
    final percent = sum / 3;
    return percent;
  }

  String _getMotorGroupId(String identifier) {
    const allowedGroups = ['G01', 'G02'];
    for (final groupId in allowedGroups) {
      final motorData = widget.mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) return groupId;
    }
    return 'G01';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _timerRunning = false;
        final sum = flcdata.isNotEmpty ? flcdata.reduce((a, b) => a + b) : 0.0;
        final average = flcdata.isNotEmpty ? sum / flcdata.length : 0.0;
        overalCurrent.value = average;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ValueListenableBuilder(
                valueListenable: overalCurrent,
                builder: (context, _, v) {
                  print("line 102 $overalCurrent $flcdata");
                  return MotorTestCard(
                    onSave: () async {
                      // Publish verification command (type 5)
                      try {
                        final identifier = _getMotorIdentifier();
                        if (identifier.isNotEmpty) {
                          final groupId = _getMotorGroupId(identifier);
                          final mqttMotorId = '$identifier-$groupId';
                          await widget.mqttService.publishTestRunCommand(
                              mqttMotorId, 1,
                              data: 0, type: 1);
                          await controller
                              .fetchUserSettings2()
                              .then((val) async {
                            final OLR1 = calculatedFlc(
                                controller.olr.value, controller.flc.value);
                            final LRF2 = calculatedFlc(
                                controller.lrf.value, controller.flc.value);
                            final LRR3 = calculatedFlc(
                                controller.lrr.value, controller.flc.value);
                            final DRF4 = calculatedFlc(
                                controller.drf.value.toDouble(),
                                controller.flc.value);
                            final OLF5 = calculatedFlc(
                                controller.olf.value.toDouble(),
                                controller.flc.value);
                            final pcbNumber = controller.pcbNumber.value;
                            final macAddress = controller.macAddress.value;
                            final payload = {
                              "dvc_c": {
                                "olr": OLR1,
                                "lrr": LRR3,
                                "lrf": LRF2,
                                "drf": DRF4,
                                "olf": OLF5,
                                'flc': controller.flc.value
                              },
                            };
                            await widget.mqttService
                                .publishTestRunCommand(mqttMotorId, 1, data: 0);
                            await widget.mqttService.publishUpdateSettings(
                                controller.pcbNumber.value, payload);
                          });
                        }
                      } catch (e) {
                        print("Error publishing verification command: $e");
                      }
                      // await widget.mqttService.publishTestRunCommand(, state)
                    },
                    currentValue: average,
                    overalFlc: overalCurrent,
                  );
                }),
          ),
        );
        print(
            "line 40 -----> sum: $sum, average: $average, entries: ${flcdata.length}, values: $flcdata");
      }
    });
  }

  @override
  void dispose() {
    widget.mqttService.dataUpdateNotifier.removeListener(checkUpdates);
    widget.avgflc.removeListener(_onAvgFlcChanged);
    _timer?.cancel();
    super.dispose();
  }

  double get _progress => _remainingSeconds / _totalSeconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Top Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFE5E7EB),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    "Motor Test Run",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004E7E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Smart Calibration v2.0",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF004E7E),
                    ),
                  ),
                ],
              ),
            ),

            /// Body Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Measuring Full Load Current ( FLC )..",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Current Value
                  ValueListenableBuilder(
                      valueListenable: avgCurrent,
                      builder: (context, val, _) {
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: avgCurrent.value.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const TextSpan(
                                text: "  A",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                  const SizedBox(height: 18),

                  /// Progress Line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFD1D5DB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF004E7E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Time remaining: $_remainingSeconds Seconds",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF004E7E),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Emergency Stop Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "EMERGENCY STOP",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
