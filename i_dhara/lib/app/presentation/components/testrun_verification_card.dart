import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

import '../../core/utils/mqtt_utils.dart';
import '../../data/services/mqtt_manager/mqtt_service.dart';
import '../modules/dashboard/dashboard_controller.dart';
import '../routes/app_routes.dart';
import 'popups/emergency_popup.dart';

enum _TestRunPhase { preCheck, measuring, completed, saving, success, failure }

class ConfirmTestRunScreen extends StatefulWidget {
  final ValueNotifier<bool> cloudConnectionVerified;
  final ValueNotifier<bool> inputPowerVerified;
  final ValueNotifier<double> avgflc;
  final Motor motor;
  final MotorData? motorData;
  final MqttService mqttService;
  final String route;

  const ConfirmTestRunScreen(
      {super.key,
      required this.cloudConnectionVerified,
      required this.inputPowerVerified,
      required this.avgflc,
      required this.motor,
      required this.mqttService,
      this.motorData,
      this.route = '/dashboard'});

  @override
  State<ConfirmTestRunScreen> createState() => _ConfirmTestRunScreenState();
}

class _ConfirmTestRunScreenState extends State<ConfirmTestRunScreen> {
  // --- Connectivity state ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;
  bool _isSubDialogOpen = false;

  // --- Phase 1: Pre-check state ---
  bool isMotorWiresChecked = false;
  bool isPumpValveChecked = false;
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

  // --- Pre-check timeout state ---
  // Set to true 15 s after dialog opens; forces every still-loading icon to ❌.
  bool _preCheckTimedOut = false;
  Timer? _preCheckTimeoutTimer;
  // Guards against showing duplicate connection snackbars.
  bool _connectionSnackBarShown = false;

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

  bool _freshSignalReceived = false;
  bool _freshLiveDataReceived = false;
  // Dedicated notifier so the Network Connectivity builder rebuilds
  // immediately whenever signal is confirmed (T:40 heartbeat OR T:41/T:35
  // live data), without depending on heartbeatNotifier alone.
  final ValueNotifier<bool> _freshSignalNotifier = ValueNotifier(false);

  bool get _isPowerOn {
    if (widget.motorData != null && widget.motorData!.hasReceivedLiveData) {
      return widget.motorData!.power == 1;
    }
    return (widget.motor.starter?.power ?? 0) == 1;
  }

  static const double _minVoltage = 370.0;
  static const double _maxVoltage = 450.0;

  bool _isVoltageValid(double? voltage) {
    if (voltage == null) return false;
    return voltage >= _minVoltage && voltage <= _maxVoltage;
  }

  /// Returns null if all voltages are in range, or an error message string.
  String? get _voltageError {
    if (widget.motorData == null || !widget.motorData!.hasReceivedLiveData) {
      return null; // No data yet, don't block
    }

    final v1 = double.tryParse(widget.motorData?.voltageBlue ?? '0') ?? 0;
    final v2 = double.tryParse(widget.motorData?.voltageRed ?? '0') ?? 0;
    final v3 = double.tryParse(widget.motorData?.voltageYellow ?? '0') ?? 0;

    final outOfRange = <String>[];
    if (!_isVoltageValid(v1))
      outOfRange.add('B-phase = ${v1.toStringAsFixed(0)} V');
    if (!_isVoltageValid(v2))
      outOfRange.add('R-phase = ${v2.toStringAsFixed(0)} V');
    if (!_isVoltageValid(v3))
      outOfRange.add('Y-phase = ${v3.toStringAsFixed(0)} V');

    if (outOfRange.isEmpty) return null;
    return 'Voltage out of range: ${outOfRange.join(', ')}. Test cannot proceed.';
  }

  bool get _isVoltageInRange {
    if (widget.motorData == null || !widget.motorData!.hasReceivedLiveData) {
      return false; // No data yet, not verified
    }
    return _voltageError == null;
  }

  /// True when network connectivity is definitively known to be absent —
  /// either the pre-check timed out without a heartbeat, or a fresh heartbeat
  /// arrived but reported 0 signal bars.
  bool get _isNetworkFalse {
    if (_preCheckTimedOut && !_freshSignalReceived) return true;
    if (_freshSignalReceived && _getSignalBars(widget.motorData) == 0) {
      return true;
    }
    return false;
  }

  /// True when the network check has completed AND passed (signal ≥ 1).
  bool get _networkVerified =>
      _freshSignalReceived && _getSignalBars(widget.motorData) >= 1;

  /// True when the power check has completed AND passed.
  /// Only evaluated after [_networkVerified] is true.
  bool get _powerVerified {
    if (!_networkVerified) return false;
    final liveReady = _freshLiveDataReceived &&
        (widget.motorData?.hasReceivedLiveData ?? false);
    return liveReady && _isPowerOn;
  }

  bool get isActive {
    if (!_freshSignalReceived || !_freshLiveDataReceived) return false;
    final signal = _getSignalBars(widget.motorData);
    final cloudOk = signal >= 1 && signal <= 4;
    final powerOk = _isPowerOn;
    final voltageOk = _isVoltageInRange;

    return isMotorWiresChecked &&
        isPumpValveChecked &&
        cloudOk &&
        powerOk &&
        voltageOk;
  }

  /// True when the motor is in Auto mode (live MQTT value takes priority
  /// over the API value stored in [widget.motor.mode]).
  bool get _isAutoMode {
    final liveIndex = widget.motorData?.modeIndex;
    if (liveIndex != null) return liveIndex == 1;
    return widget.motor.mode?.toUpperCase().contains('AUTO') ?? false;
  }

  /// Guards [_startMeasuring]: blocks and warns when the motor is in Auto mode.
  void _onStartPressed() {
    if (_isAutoMode) {
      geterrorSnackBar('Motor is in Auto Mode. Switch to Manual Mode');
      return;
    }
    _startMeasuring();
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    // Delay listener registration so loading icons are always shown for at
    // least 1 second each time the dialog opens, even when MQTT is already
    // streaming. Each icon type listens to its own topic-specific notifier.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.mqttService.heartbeatNotifier
            .removeListener(_onFirstHeartbeat); // guard double-add
        widget.mqttService.heartbeatNotifier.addListener(_onFirstHeartbeat);
        // Also listen directly to liveDataNotifier — if T:41 arrives before
        // T:40 heartbeat, receiving live data implies network connectivity and
        // unlocks the signal icon before checking power & voltage.
        widget.mqttService.liveDataNotifier
            .removeListener(_onFirstLiveData); // guard double-add
        widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
      }
    });
    _startPreCheckTimeout();
  }

  void _startPreCheckTimeout() {
    _preCheckTimeoutTimer?.cancel();
    _preCheckTimeoutTimer =
        Timer(const Duration(seconds: 15), _onPreCheckTimeout);
  }

  void _onPreCheckTimeout() {
    if (!mounted || _phase != _TestRunPhase.preCheck) return;

    setState(() => _preCheckTimedOut = true);

    // Immediate checks already fired a snackbar — don't duplicate.
    if (_connectionSnackBarShown) return;

    // Priority 1: network never responded, or responded with 0 bars.
    if (!_freshSignalReceived || _isNetworkFalse) {
      _connectionSnackBarShown = true;
      geterrorSnackBar('Device is not connected.');
      return;
    }

    // Priority 2: network OK but live data never arrived, or power/voltage bad.
    if (!_freshLiveDataReceived || !_isPowerOn || !_isVoltageInRange) {
      _connectionSnackBarShown = true;
      geterrorSnackBar('Device is not connected');
    }
  }

  /// Called on the first T:40 heartbeat — unlocks signal icon.
  ///
  /// Network-first priority:
  /// • signal >= 1 → network OK → register liveDataNotifier and proceed to
  ///   power / voltage checks.
  /// • signal == 0 → network false → show snackbar immediately; power and
  ///   voltage are never fetched or processed.
  void _onFirstHeartbeat() {
    if (!_freshSignalReceived && mounted) {
      widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _freshSignalReceived = true);
        _freshSignalNotifier.value = true;

        if (_getSignalBars(widget.motorData) >= 1) {
          // Network confirmed OK — now safe to listen for live data.
          widget.mqttService.liveDataNotifier
              .removeListener(_onFirstLiveData); // guard double-add
          widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
        } else {
          // Network false — show error immediately; skip live data entirely.
          if (!_connectionSnackBarShown) {
            _connectionSnackBarShown = true;
            geterrorSnackBar('Device is not connected.');
          }
        }
      });
    }
  }

  /// Called on the first T:35/T:41 live-data update — unlocks power & voltage
  /// icons and checks them. If T:41 arrives before T:40, receiving live data
  /// implies network connectivity, so the signal icon is unlocked first in a
  /// separate frame before power / voltage are evaluated.
  void _onFirstLiveData() {
    if (!_freshLiveDataReceived && mounted) {
      widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Step 1 — T:35/T:41 implies network connectivity.
        // Unlock signal icon first so the UI confirms network before checking
        // the remaining conditions.
        if (!_freshSignalReceived) {
          setState(() => _freshSignalReceived = true);
          _freshSignalNotifier.value = true;
        }
        // Step 2 — After the signal rebuild, unlock live data and evaluate
        // power status and voltage range in the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _freshLiveDataReceived = true);
          _checkPowerVoltageNow();
        });
      });
    }
  }

  /// Immediately checks power / voltage once live data arrives.
  /// A short delay lets [widget.motorData.hasReceivedLiveData] settle.
  void _checkPowerVoltageNow() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _connectionSnackBarShown || _isNetworkFalse) return;
      if (!(widget.motorData?.hasReceivedLiveData ?? false)) return;
      if (!_isPowerOn || !_isVoltageInRange) {
        _connectionSnackBarShown = true;
        geterrorSnackBar(
            'Device is not connected due to no power or voltage mismatch.');
      }
    });
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
      // Close any open sub-dialogs (emergency stop, cancel confirmation, etc.)
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
    // Reset both fresh flags and re-register type-specific listeners after
    // a 1-second delay so loading icons are shown when coming back online.
    _freshSignalReceived = false;
    _freshSignalNotifier.value = false;
    _freshLiveDataReceived = false;
    _preCheckTimedOut = false;
    _connectionSnackBarShown = false;
    _startPreCheckTimeout();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
        widget.mqttService.heartbeatNotifier.addListener(_onFirstHeartbeat);
        // Also listen directly to liveDataNotifier — if T:41 arrives before
        // T:40, receiving live data implies network connectivity.
        widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
        widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
      }
    });
    setState(() {
      _isOffline = false;
      // Reset to preCheck so user can re-verify and start fresh
      _phase = _TestRunPhase.preCheck;
      isMotorWiresChecked = false;
      isPumpValveChecked = false;
      _flcData.clear();
      _remainingSeconds = _totalSeconds;
      _avgCurrent.value = 0;
      _overalCurrent.value = 0;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
    widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
    if (_phase == _TestRunPhase.measuring) {
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    }
    _timer?.cancel();
    _preCheckTimeoutTimer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    _avgCurrent.dispose();
    _overalCurrent.dispose();
    _freshSignalNotifier.dispose();
    super.dispose();
  }

  void _resetPreCheckState() {
    setState(() {
      _avgCurrent.value = 0;
      _overalCurrent.value = 0;
      _flcData.clear();
      isMotorWiresChecked = false;
      isPumpValveChecked = false;
      widget.cloudConnectionVerified.value = false;
      widget.inputPowerVerified.value = false;
    });
  }

  // --- Helper methods ---

  int getSignalBars(MotorData? motorData) {
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
    return 0;
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

  double _percentageOfAmps(double c1, double c2, double c3) {
    return (c1 + c2 + c3) / 3;
  }

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

  // --- Phase transitions ---

  void _startMeasuring() {
    _preCheckTimeoutTimer?.cancel();
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
    } else {}
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
            _resetPreCheckState(); // Clear pre-test verification after testrun
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
              _resetPreCheckState(); // Clear pre-test verification after testrun
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
              color: Colors.black.withOpacity(0.1),
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

  // ===================== Phase 1: Pre-Check =====================

  Widget _buildPreCheckPhase() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        'Smart Calibration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 28,
                        color: Color(0xFF6B7280),
                      )),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Network Connectivity — rebuilds whenever signal is
                  // confirmed via T:40 heartbeat OR T:41/T:35 live data.
                  ValueListenableBuilder<bool>(
                    valueListenable: _freshSignalNotifier,
                    builder: (context, freshSignal, __) {
                      final int? signal = freshSignal
                          ? _getSignalBars(widget.motorData)
                          : (_preCheckTimedOut ? 0 : null);
                      return _buildVerificationCloudConnection(
                        'Network Connectivity',
                        signal,
                        'assets/images/network_device.svg',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Power Supply Status — sequential step 2.
                  // Stays loading until network (step 1) is confirmed first.
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.mqttService.liveDataNotifier,
                      _freshSignalNotifier,
                    ]),
                    builder: (context, _) {
                      final int? powerVerified;
                      final bool liveReady = _freshLiveDataReceived &&
                          (widget.motorData?.hasReceivedLiveData ?? false);
                      if (!_freshSignalReceived && !_preCheckTimedOut) {
                        // Gate: network check not done yet → keep loading.
                        powerVerified = null;
                      } else if (_isNetworkFalse || !_networkVerified) {
                        // Network failed → power is blocked.
                        powerVerified = 0;
                      } else if (liveReady) {
                        // Network OK, live data available → evaluate power.
                        powerVerified = _isPowerOn ? 1 : 0;
                      } else if (_preCheckTimedOut) {
                        // Network OK but timed out before live data arrived.
                        powerVerified = 0;
                      } else {
                        // Network OK, still waiting for live data.
                        powerVerified = null;
                      }
                      return _buildVerificationInputPower(
                          'Power Supply Status', powerVerified);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Voltage Range — sequential step 3.
                  // Stays loading until both network (step 1) and power
                  // (step 2) are confirmed first.
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.mqttService.liveDataNotifier,
                      _freshSignalNotifier,
                    ]),
                    builder: (context, _) {
                      return _buildVoltageVerification();
                    },
                  ),
                  const SizedBox(height: 24),

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

                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isActive ? _onStartPressed : null,
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
                  ),
                ],
              ),
            ),
          ],
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
              color: Colors.black.withOpacity(0.1),
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
                      color: const Color(0xFF004E7E).withOpacity(0.7),
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
  // ===================== Shared UI Helpers =====================

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

  Widget _buildVoltageVerification() {
    final hasData = _freshLiveDataReceived &&
        widget.motorData != null &&
        widget.motorData!.hasReceivedLiveData;
    final networkDone = _freshSignalReceived || _preCheckTimedOut;

    // Sequential gates — voltage is only evaluated after network AND power pass.
    final bool showLoading;
    final bool forceFail;

    if (!networkDone) {
      // Gate 1: still waiting for network result → loading.
      showLoading = true;
      forceFail = false;
    } else if (!_networkVerified) {
      // Gate 2: network failed → voltage is blocked.
      showLoading = false;
      forceFail = true;
    } else if (!hasData && !_preCheckTimedOut) {
      // Gate 3: network OK, waiting for live data (power step) → loading.
      showLoading = true;
      forceFail = false;
    } else if (!_powerVerified) {
      // Gate 4: power failed or timed out → voltage is blocked.
      showLoading = false;
      forceFail = true;
    } else {
      // All previous checks passed → evaluate actual voltage.
      showLoading = false;
      forceFail = false;
    }

    final voltageOk = !showLoading && !forceFail && hasData && _isVoltageInRange;
    final error = (!showLoading && !forceFail && hasData) ? _voltageError : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            const Icon(Icons.electric_bolt, size: 20, color: Color(0xFF64748B)),
            const Expanded(
              child: Text(
                'Voltage Range (370V - 450V)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            if (showLoading)
              loadingIcon
            else if (voltageOk)
              checkIcon
            else
              closeIcon,
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
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
      ),
    );
  }
}
