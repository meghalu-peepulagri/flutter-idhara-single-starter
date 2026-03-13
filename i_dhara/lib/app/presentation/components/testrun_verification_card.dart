import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

import '../../core/utils/mqtt_utils.dart';
import '../../data/services/mqtt_manager/mqtt_service.dart';
import '../modules/dashboard/dashboard_controller.dart';
import '../routes/app_routes.dart';
import 'popups/emergency_popup.dart';
import 'precheck_phase.dart';

enum _TestRunPhase { preCheck, measuring, completed, saving, success, failure }

class ConfirmTestRunScreen extends StatefulWidget {
  final ValueNotifier<bool> cloudConnectionVerified;
  final ValueNotifier<bool> inputPowerVerified;
  final ValueNotifier<double> avgflc;
  final Motor motor;
  final MotorData? motorData;
  final MqttService mqttService;
  final String route;

  const ConfirmTestRunScreen({
    super.key,
    required this.cloudConnectionVerified,
    required this.inputPowerVerified,
    required this.avgflc,
    required this.motor,
    required this.mqttService,
    this.motorData,
    this.route = '/dashboard',
  });

  @override
  State<ConfirmTestRunScreen> createState() => _ConfirmTestRunScreenState();
}

class _ConfirmTestRunScreenState extends State<ConfirmTestRunScreen> {
  // --- Connectivity state ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;
  bool _isSubDialogOpen = false;

  StreamSubscription? mqttStreamSubscription;

  String failureMessage = '';
  Timer? ackTimer;
  Timer? countdownTimer;
  int remainingSeconds = 0;
  int selectedTimeoutMinutes = 3;
  bool isTestRunning = false;
  bool isWaitingForAck = false;
  bool _hasPendingSave = false;
  bool _ackInProgress = false;
  Timer? settingsAckTimer;

  final Color _testrunColor = const Color(0xFFEFF6FF);

  // --- Phase 2: Measuring state ---
  static const int _totalSeconds = 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  final List<double> _flcData = [];
  final ValueNotifier<double> _avgCurrent = ValueNotifier(0);
  final ValueNotifier<double> _overalCurrent = ValueNotifier(0);
  String _mqttMotorId = '';
  double _finalFLC = 0.0;

  // --- Common state ---
  _TestRunPhase _phase = _TestRunPhase.preCheck;
  DashboardController? _controller;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  void _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted && result.first == ConnectivityResult.none) {
      _goOffline();
      return;
    }
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      if (results.first == ConnectivityResult.none) {
        _goOffline();
      } else if (_isOffline) {
        _goOnline();
      }
    });
  }

  void _goOffline() {
    if (_isOffline) return;
    _timer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    if (_phase == _TestRunPhase.measuring) {
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    }
    if (mounted) {
      if (_isSubDialogOpen) {
        Navigator.of(context).pop();
        _isSubDialogOpen = false;
      }
      setState(() {
        _isOffline = true;
      });
    }
  }

  void _goOnline() {
    if (!_isOffline || !mounted) return;
    // Rebuilding with _isOffline = false causes Flutter to recreate
    // PreCheckPhase, which initialises its own listeners and timer fresh.
    setState(() {
      _isOffline = false;
      _phase = _TestRunPhase.preCheck;
      _flcData.clear();
      _remainingSeconds = _totalSeconds;
      _avgCurrent.value = 0;
      _overalCurrent.value = 0;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    if (_phase == _TestRunPhase.measuring) {
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    }
    _timer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    _avgCurrent.dispose();
    _overalCurrent.dispose();
    super.dispose();
  }

  void _resetPreCheckState() {
    setState(() {
      _avgCurrent.value = 0;
      _overalCurrent.value = 0;
      _flcData.clear();
      widget.cloudConnectionVerified.value = false;
      widget.inputPowerVerified.value = false;
    });
  }

  // --- Helper methods ---

  String _getMotorGroupId(String identifier) {
    const allowedGroups = ['G01', 'G02'];
    for (final groupId in allowedGroups) {
      final motorData = widget.mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) return groupId;
    }
    return 'G01';
  }

  double _calculatedFlc(double val, double flcVal) {
    final percentLow = val.toInt() / 100;
    final res = percentLow * flcVal;
    return double.parse(res.toStringAsFixed(2));
  }

  double _percentageOfAmps(double c1, double c2, double c3) {
    return (c1 + c2 + c3) / 3;
  }

  // --- Phase transitions ---

  void _startMeasuring() {
    _avgCurrent.value = 0;
    _overalCurrent.value = 0;
    _flcData.clear();
    _controller = Get.put(DashboardController());
    widget.mqttService.dataUpdateNotifier.addListener(_checkUpdates);

    final identifier = getMotorIdentifier(
        widget.motor.starter!.deviceAllocation.toString(),
        widget.motor.starter!.pcbNumber.toString(),
        widget.motor.starter!.macAddress.toString());
    final groupId = identifier.isNotEmpty ? _getMotorGroupId(identifier) : '';
    _mqttMotorId = identifier.isNotEmpty ? '$identifier-$groupId' : '';
    final mqttMotorId = _mqttMotorId;

    setState(() {
      _phase = _TestRunPhase.measuring;
      _remainingSeconds = _totalSeconds;
    });
    _avgCurrent.value = 0.0;
    _flcData.clear();
    _overalCurrent.value = 0.0;

    // Publish immediately at the start
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService
          .publishTestRunCommand(mqttMotorId, 1, data: 2, type: 1);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        if (mqttMotorId.isNotEmpty && _remainingSeconds % 10 == 0) {
          widget.mqttService
              .publishTestRunCommand(mqttMotorId, 1, data: 1, type: 5);
        }
      } else {
        timer.cancel();
        widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
        final sum =
            _flcData.isNotEmpty ? _flcData.reduce((a, b) => a + b) : 0.0;
        final average = _flcData.isNotEmpty ? sum / _flcData.length : 0.0;
        _overalCurrent.value = average;
        widget.mqttService
            .publishTestRunCommand(mqttMotorId, 1, data: 0, type: 1);
        setState(() {
          _phase = _TestRunPhase.completed;
        });
      }
    });
  }

  void _checkUpdates() {
    if (!mounted) return;
    // Read directly from the live map so we always get the freshest data,
    // rather than relying on widget.motorData which is a stale prop at the
    // moment this listener fires (the outer ValueListenableBuilder hasn't
    // rebuilt yet in this same listener-fire cycle).
    final motordata = _mqttMotorId.isNotEmpty
        ? widget.mqttService.motorDataMap[_mqttMotorId]
        : widget.motorData;
    final c1 = double.tryParse(motordata?.currentRed ?? "0.0") ?? 0.0;
    final c2 = double.tryParse(motordata?.currentBlue ?? "0.0") ?? 0.0;
    final c3 = double.tryParse(motordata?.currentYellow ?? "0.0") ?? 0.0;

    // Only accept if all phases have at least 0.5A
    if (c1 >= 0.5 && c2 >= 0.5 && c3 >= 0.5) {
      final res = _percentageOfAmps(c1, c2, c3);
      final avg = double.parse(res.toStringAsFixed(2));

      setState(() {
        _avgCurrent.value = avg;
      });

      if (!_flcData.contains(avg)) {
        _flcData.add(avg);
        final sum = _flcData.reduce((a, b) => a + b);
        _overalCurrent.value = sum / _flcData.length;
      }
    }
  }

  void _emergencyStop() {
    _isSubDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomConfirmationDialog(
        title: "Emergency Stop",
        message:
            "Emergency stop will immediately abort the ongoing test process.\n\nAre you sure you want to continue?",
        confirmText: "Stop Test",
        confirmColor: const Color(0xFFDC2626),
        icon: Icons.warning_amber_rounded,
        onConfirm: _confirmEmergencyStop,
      ),
    ).then((_) => _isSubDialogOpen = false);
  }

  void _confirmEmergencyStop() {
    _timer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);

    final identifier = getMotorIdentifier(
        widget.motor.starter!.deviceAllocation.toString(),
        widget.motor.starter!.pcbNumber.toString(),
        widget.motor.starter!.macAddress.toString());
    final groupId = identifier.isNotEmpty ? _getMotorGroupId(identifier) : '';
    final mqttMotorId = identifier.isNotEmpty ? '$identifier-$groupId' : '';

    // Send stop command T=1, D=0
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService
          .publishTestRunCommand(mqttMotorId, 1, data: 0, type: 1)
          .then((_) {
        if (widget.route == Routes.dashboard) {
          Get.offAllNamed(widget.route, arguments: {'refresh': true});
        } else {
          Navigator.of(context).pop();
        }
        debugPrint('Emergency stop command sent for $mqttMotorId');
      }).catchError((e) {
        if (widget.route == Routes.dashboard) {
          Get.offAllNamed(widget.route, arguments: {'refresh': true});
        } else {
          Navigator.of(context).pop();
        }
        debugPrint('Failed to send emergency stop command: $e');
      });
    }
  }

  Future<void> _onSave() async {
    setState(() {
      _phase = _TestRunPhase.saving;
      isWaitingForAck = true;
      _hasPendingSave = true;
      _ackInProgress = false;
    });

    try {
      final identifier = getMotorIdentifier(
          widget.motor.starter!.deviceAllocation.toString(),
          widget.motor.starter!.pcbNumber.toString(),
          widget.motor.starter!.macAddress.toString());
      if (identifier.isNotEmpty && _controller != null) {
        final groupId = _getMotorGroupId(identifier);
        final mqttMotorId = '$identifier-$groupId';
        await _controller!.fetchUserSettings2();
        final avgFlc = _overalCurrent.value;
        final OLR1 = _calculatedFlc(_controller!.olr.value, avgFlc);
        final LRF2 = _calculatedFlc(_controller!.lrf.value, avgFlc);
        final LRR3 = _calculatedFlc(_controller!.lrr.value, avgFlc);
        final DRF4 = _calculatedFlc(_controller!.drf.value.toDouble(), avgFlc);
        final OLF5 = _calculatedFlc(_controller!.olf.value.toDouble(), avgFlc);
        final trimFlc = avgFlc.toStringAsFixed(2);
        final flc = double.parse(trimFlc);
        final payload = {
          "dvc_c": {
            "olr": OLR1,
            "lrr": LRR3,
            "lrf": LRF2,
            "drf": DRF4,
            "olf": OLF5,
            'flc': flc
          },
        };
        _controller!.flc.value = flc;
        await widget.mqttService
            .publishUpdateSettings(_controller!.pcbNumber.value, payload);
        await _controller?.fetchupdateSettings();
        settingsAckTimer = Timer(const Duration(seconds: 10), () {
          mqttStreamSubscription?.cancel();
          if (mounted && !_ackInProgress) {
            _resetPreCheckState();
            setState(() {
              isWaitingForAck = false;
              _hasPendingSave = false;
              _phase = _TestRunPhase.failure;
              failureMessage = 'No acknowledgment received from device';
            });
            if (widget.motor.testrunStatus?.toUpperCase() == "IN_TEST") {
              _controller?.startTestRun(widget.motor.id!);
            } else {
              _controller?.completeTestRun(widget.motor.id!);
            }
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) {
                if (widget.route == Routes.dashboard) {
                  Get.offAllNamed(widget.route, arguments: {'refresh': true});
                } else {
                  Get.offAllNamed(Routes.devices);
                }
              }
            });
          }
        });

        // Listen for ACK on settingstream
        mqttStreamSubscription =
            widget.mqttService.settingstream.listen((data) async {
          final type = data["D"];
          final topic = data["topic"];
          if (topic != _controller!.pcbNumber.value &&
              topic != _controller!.macAddress.value) return;
          if (type == 1 && !_ackInProgress && _hasPendingSave) {
            settingsAckTimer?.cancel();
            _hasPendingSave = false;
            _ackInProgress = true;
            mqttStreamSubscription?.cancel();
            // Capture before reset so success phase can still display it.
            _finalFLC = _overalCurrent.value;
            _resetPreCheckState();
            if (mounted) {
              setState(() {
                isWaitingForAck = false;
                _phase = _TestRunPhase.success;
              });
            }
            try {
              _controller?.completeTestRun(widget.motor.id!);
              _controller?.fetchupdateSettingsAck();
            } finally {
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted) {
                  if (widget.route == Routes.dashboard) {
                    Get.offAllNamed(widget.route, arguments: {'refresh': true});
                  } else {
                    Get.offAllNamed(Routes.devices);
                  }
                }
              });
            }
          } else {
            mqttStreamSubscription?.cancel();
            if (mounted && !_ackInProgress) {
              _resetPreCheckState();
              setState(() {
                isWaitingForAck = false;
                _hasPendingSave = false;
                _phase = _TestRunPhase.failure;
                failureMessage = 'Smart Calibration Failed';
              });
              if (widget.motor.testrunStatus?.toUpperCase() == "IN_TEST") {
                _controller?.startTestRun(widget.motor.id!);
              } else {
                _controller?.completeTestRun(widget.motor.id!);
              }
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted) {
                  if (widget.route == Routes.dashboard) {
                    Get.offAllNamed(widget.route, arguments: {'refresh': true});
                  } else {
                    Get.offAllNamed(Routes.devices);
                  }
                }
              });
            }
          }
        });
      }
    } catch (e) {
      print("Error publishing verification command: $e");
      if (mounted) {
        setState(() {
          isWaitingForAck = false;
          _hasPendingSave = false;
          _phase = _TestRunPhase.completed;
        });
      }
    }
  }

  void _onCancel() {
    _isSubDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomConfirmationDialog(
        title: "Cancel Settings",
        message:
            "Are you sure you want to cancel? The calibration data will not be saved.",
        confirmText: "Yes, Cancel",
        confirmColor: const Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
        onConfirm: () {
          _flcData.clear();
          _overalCurrent.value = 0.0;
          _avgCurrent.value = 0.0;
          if (widget.route == Routes.dashboard) {
            Get.offAllNamed(widget.route, arguments: {'refresh': true});
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    ).then((_) => _isSubDialogOpen = false);
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return _buildNoInternetWidget();
    }

    switch (_phase) {
      case _TestRunPhase.preCheck:
        return _buildPreCheckPhase();
      case _TestRunPhase.measuring:
        return _buildMeasuringPhase();
      case _TestRunPhase.completed:
        return _buildCompletedPhase();
      case _TestRunPhase.saving:
        return _buildSavingPhase();
      case _TestRunPhase.success:
        return _buildSuccessPhase();
      case _TestRunPhase.failure:
        return _buildFailurePhase();
    }
  }

  // ===================== Phase 1: Pre-Check =====================

  Widget _buildPreCheckPhase() {
    return PreCheckPhase(
      motor: widget.motor,
      motorData: widget.motorData,
      mqttService: widget.mqttService,
      onStartPressed: _startMeasuring,
      onClose: () => Navigator.of(context).pop(),
    );
  }

  // ===================== No Internet Widget =====================

  Widget _buildNoInternetWidget() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.red.shade400,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your internet connection.\nThe test run will resume automatically\nonce you are back online.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Waiting for connection...',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Phase 2: Measuring =====================

  double get _progress => _remainingSeconds / _totalSeconds;

  Widget _buildMeasuringPhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Top Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _testrunColor,
                  borderRadius: const BorderRadius.vertical(
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
                      "Smart Calibration",
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
                        valueListenable: _avgCurrent,
                        builder: (context, val, _) {
                          return RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _avgCurrent.value.toStringAsFixed(2),
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
                        onPressed: _emergencyStop,
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
      ),
    );
  }

  // ===================== Phase 3: Completed =====================

  Widget _buildCompletedPhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _testrunColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Motor Test Run',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004E7E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart Calibration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF004E7E).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Calibration Completed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Value Display
                  ValueListenableBuilder(
                    valueListenable: _overalCurrent,
                    builder: (context, _, __) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _overalCurrent.value.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF009336),
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'A',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF009336),
                              height: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Detected Full Load Current',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF004E7E),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF828282),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FFButtonWidget(
                            text: 'Save Settings',
                            showLoadingIndicator: true,
                            onPressed: _onSave,
                            options: FFButtonOptions(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              borderRadius: BorderRadius.circular(8),
                              height: 43,
                              color: const Color(0xFF0F6B8A),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Phase 4: Saving (waiting for ACK) =====================

  Widget _buildSavingPhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF0F6B8A),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Saving Settings...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF004E7E),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Waiting for device acknowledgment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== Phase 5: Success =====================

  Widget _buildSuccessPhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smart Calibration\nSuccessful',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'FLC: ${_finalFLC.toStringAsFixed(1)} A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Settings saved to device',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== Phase 6: Failure =====================

  Widget _buildFailurePhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Smart Calibration\nFailed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  failureMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please try again later',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
