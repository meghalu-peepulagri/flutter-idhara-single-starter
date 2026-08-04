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

enum _TestRunPhase { preCheck, motorOnWaiting, measuring, completed, saving, success, failure }

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

class _ConfirmTestRunScreenState extends State<ConfirmTestRunScreen>
    with WidgetsBindingObserver {
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
  DateTime? _testStartTime;
  Timer? _timer;
  final List<double> _flcData = [];
  final ValueNotifier<double> _avgCurrent = ValueNotifier(0);
  final ValueNotifier<double> _overalCurrent = ValueNotifier(0);
  String _mqttMotorId = '';
  double _finalFLC = 0.0;

  /// 'm1'/'m2' on a multi-motor starter, null on a single-motor one. Null keeps
  /// every published payload flat, exactly as single-motor has always sent them.
  String? get _motorRef {
    final ref = widget.motor.motorReference;
    return (ref != null && ref.isNotEmpty) ? ref : null;
  }

  /// Live-data key for this motor: multi-motor entries are stored per motor as
  /// '<identifier>-<groupId>-<motorReference>'; single-motor has no suffix.
  String get _liveDataKey =>
      _motorRef == null ? _mqttMotorId : '$_mqttMotorId-$_motorRef';
  // Timestamp of the last motor command (D:2 or D:0) so we can detect
  // whether a T:31 ACK belongs to the command we just sent.
  DateTime? _motorCmdSentAt;

  // --- Motor ON waiting phase ---
  DateTime? _motorOnCmdSentAt;
  bool _motorOnFailed = false;
  String _motorOnFailureMsg = '';
  static const int _waitingTimerSeconds = 20;
  int _motorOnCountdown = _waitingTimerSeconds;
  Timer? _motorOnCountdownTimer;

  // --- Saving phase sub-state ---
  bool _savingIsSendingSettings = false;
  int _d0Countdown = _waitingTimerSeconds;
  Timer? _d0CountdownTimer;
  bool _motorOffFailed = false;
  String _motorOffFailureMsg = '';
  final ValueNotifier<int> _settingsCountdown = ValueNotifier(15);
  Timer? _settingsCountdownTimer;

  // --- Smart Calibration (T:4 → T:34 ACK) retry state ---
  // The calibration payload is computed once, then re-published on each retry
  // so every attempt sends identical data. The device ACK's "D" is a result
  // code (1 = success). Any error code re-publishes instead of failing, until
  // a D:1 arrives or the attempts are exhausted.
  Map<String, dynamic>? _settingsPayload;
  int _settingsAttempt = 0;
  static const int _maxSettingsAttempts = 3;

  /// Calibration mirrors the MQTT layer's control-command ladder: publish,
  /// retry after 10s, retry after 10s, then a 3s grace before giving up —
  /// so attempts land at 0s/10s/20s and the window closes at 23s.
  static const int _settingsRetryGapSeconds = 10;
  static const Duration _settingsRetryGap =
      Duration(seconds: _settingsRetryGapSeconds);
  static const int _settingsFinalGraceSeconds = 3;
  static const int _settingsWindowSeconds =
      _settingsRetryGapSeconds * (_maxSettingsAttempts - 1) +
          _settingsFinalGraceSeconds;
  Timer? _settingsRetryTimer;

  // T:34 ACK "D" result codes → user-understandable messages. D:1 is success
  // (handled separately). Codes mirror the device firmware:
  //   2 FLASH_PARSING_ERROR   3 FLASH_ERASING_ERROR   4 FLASH_WRITE_ERROR
  //   5 FLASH_VERIFY_ERROR    6 FLASH_UPDATE_PENDING  7 FLASH_UPDATE_STARTED
  //   8 PAYLOAD_TOO_LARGE_ERROR
  static const Map<int, String> _calibrationErrorMessages = {
    2: 'Device couldn\'t read the calibration data.',
    3: 'Device couldn\'t prepare its storage for calibration.',
    4: 'Device couldn\'t save the calibration.',
    5: 'Device couldn\'t verify the saved calibration.',
    6: 'Device is still applying a previous update.',
    7: 'Device started applying the update but didn\'t confirm.',
    8: 'Calibration data is too large for the device.',
  };

  String _calibrationErrorMessage(dynamic code) {
    final c = code is int ? code : int.tryParse(code.toString());
    return _calibrationErrorMessages[c] ?? 'Smart Calibration Failed';
  }

  // --- Common state ---
  _TestRunPhase _phase = _TestRunPhase.preCheck;
  DashboardController? _controller;

  bool _freshSignalReceived = false;
  bool _freshLiveDataReceived = false;
  // Dedicated notifier so the Network Connectivity builder rebuilds
  // immediately whenever signal is confirmed (T:40 heartbeat OR T:41/T:35
  // live data), without depending on heartbeatNotifier alone.
  final ValueNotifier<bool> _freshSignalNotifier = ValueNotifier(false);

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

  bool get isActive {
    final signalOk = widget.motorData?.testRunSignal == true;
    final powerOk = widget.motorData?.testrunPowerSupply == true;
    final voltageOk =
        widget.motorData?.testrunVoltageRange == true && _isVoltageInRange;

    return isMotorWiresChecked &&
        isPumpValveChecked &&
        signalOk &&
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
    WidgetsBinding.instance.addObserver(this);
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

    if (_connectionSnackBarShown) return;

    if (widget.motorData?.testRunSignal != true) {
      _connectionSnackBarShown = true;
      geterrorSnackBar('Device is not connected.');
      return;
    }

    if (widget.motorData?.testrunPowerSupply != true ||
        widget.motorData?.testrunVoltageRange != true ||
        !_isVoltageInRange) {
      _connectionSnackBarShown = true;
      geterrorSnackBar(
          'Device is not connected due to no power or voltage mismatch.');
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

        // Always listen for live data regardless of signal bars.
        // Errors are only reported after the 15-second timeout.
        widget.mqttService.liveDataNotifier
            .removeListener(_onFirstLiveData); // guard double-add
        widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
      });
    }
  }

  /// Called on the first T:35/T:41 live-data update — unlocks power & voltage
  /// icons only. Network Connectivity (signal) is ONLY unlocked by T:40
  /// heartbeat via [_onFirstHeartbeat]. Live data and heartbeat are separate
  /// payloads and must be verified independently.
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

  /// Immediately checks all verification states once live data arrives.
  /// If all three icons show close (network/power/voltage all failed),
  /// fires the error snackbar right away without waiting for the 15-second timeout.
  void _checkPowerVoltageNow() {
    // No early snackbar — errors are only shown after the 15-second timeout
    // in _onPreCheckTimeout. This method only triggers a rebuild so the UI
    // icons update immediately when live data arrives.
    if (mounted) setState(() {});
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
    _motorOnCountdownTimer?.cancel();
    _d0CountdownTimer?.cancel();
    _settingsCountdownTimer?.cancel();
    _settingsRetryTimer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    if (_phase == _TestRunPhase.measuring ||
        _phase == _TestRunPhase.motorOnWaiting) {
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
      _motorOffFailed = false;
      _motorOffFailureMsg = '';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _phase == _TestRunPhase.measuring &&
        _testStartTime != null) {
      final elapsed = DateTime.now().difference(_testStartTime!).inSeconds;
      if (elapsed >= _totalSeconds) {
        _timer?.cancel();
        _completeTestRun();
      } else {
        setState(() => _remainingSeconds = _totalSeconds - elapsed);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
    widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    if (_mqttMotorId.isNotEmpty &&
        (_phase == _TestRunPhase.motorOnWaiting ||
            _phase == _TestRunPhase.measuring ||
            _phase == _TestRunPhase.saving)) {
      widget.mqttService.removeTestRunMotor(_mqttMotorId);
    }
    _timer?.cancel();
    _preCheckTimeoutTimer?.cancel();
    _motorOnCountdownTimer?.cancel();
    _d0CountdownTimer?.cancel();
    _settingsCountdownTimer?.cancel();
    _settingsRetryTimer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    _avgCurrent.dispose();
    _overalCurrent.dispose();
    _freshSignalNotifier.dispose();
    _settingsCountdown.dispose();
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

  /// Fires when [commandStatusNotifier] changes (T:1 retries exhausted).
  ///
  /// • During [measuring]: D:2 never ACK'd → stop timer, snackbar, go to dashboard.
  /// • During [saving]: D:0 never ACK'd → snackbar, navigate away.
  void _onCommandStatus() {
    final message = widget.mqttService.commandStatusNotifier.value;
    if (message == null || !mounted) return;
    widget.mqttService.commandStatusNotifier.value = null;

    if (_phase == _TestRunPhase.motorOnWaiting) {
      // D:2 retries exhausted — motor never confirmed ON.
      _handleMotorOnFailure(message);
    } else if (_phase == _TestRunPhase.measuring) {
      // D:2 retries exhausted — motor never confirmed ON, stop the run.
      _timer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) widget.mqttService.removeTestRunMotor(_mqttMotorId);
      geterrorSnackBar(message);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (widget.route == Routes.dashboard) {
          Get.offAllNamed(Routes.dashboard, arguments: {'refresh': true});
        } else {
          Navigator.of(context).pop();
        }
      });
    } else if (_phase == _TestRunPhase.saving) {
      _d0CountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) widget.mqttService.removeTestRunMotor(_mqttMotorId);
      if (!_savingIsSendingSettings) {
        // D:0 retries exhausted — motor didn't confirm OFF.
        _handleMotorOffFailure(message);
      } else {
        // Calibration retries exhausted.
        geterrorSnackBar(message);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            if (widget.route == Routes.dashboard) {
              Get.offAllNamed(widget.route, arguments: {'refresh': true});
            } else {
              Navigator.of(context).pop();
            }
          }
        });
      }
    }
  }

  /// Listens to [dataUpdateNotifier] during [saving] (D:0 wait sub-state).
  /// When T:31 ACK for D:0 arrives, transitions to [completed] so the user
  /// can review the FLC and tap "Save Settings".
  void _checkMotorOffAck() {
    if (!mounted) return;
    if (_phase != _TestRunPhase.saving) return;
    if (_savingIsSendingSettings) return; // Already in calibration sub-state
    if (!_hasPendingSave) return;
    final ackTime = widget.mqttService.getLastAckTime(_mqttMotorId);
    if (ackTime != null &&
        _motorCmdSentAt != null &&
        ackTime.isAfter(_motorCmdSentAt!)) {
      _d0CountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) {
        widget.mqttService.removeTestRunMotor(_mqttMotorId);
      }
      _hasPendingSave = false;
      // Motor confirmed OFF — show FLC result and "Save Settings" button.
      if (mounted) setState(() => _phase = _TestRunPhase.completed);
    }
  }

  /// Listens on [dataUpdateNotifier] during [motorOnWaiting].
  /// When T:31 ACK for D:2 arrives, cancels the countdown and starts measuring.
  void _checkMotorOnAck() {
    if (!mounted || _phase != _TestRunPhase.motorOnWaiting) return;
    final ackTime = widget.mqttService.getLastAckTime(_mqttMotorId);
    if (ackTime != null &&
        _motorOnCmdSentAt != null &&
        ackTime.isAfter(_motorOnCmdSentAt!)) {
      _motorOnCountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      _startActualMeasuring();
    }
  }

  /// Terminal "motor never confirmed ON" state — shown when the D:2 retries are
  /// exhausted, or when the waiting countdown reaches 0 with no T:31 ACK.
  void _handleMotorOnFailure(String message) {
    _motorOnCountdownTimer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    if (_mqttMotorId.isNotEmpty) {
      widget.mqttService.removeTestRunMotor(_mqttMotorId);
    }
    if (mounted) {
      setState(() {
        _motorOnFailed = true;
        _motorOnFailureMsg = message;
      });
    }
  }

  void _handleMotorOffFailure(String message) {
    _d0CountdownTimer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    if (_mqttMotorId.isNotEmpty) widget.mqttService.removeTestRunMotor(_mqttMotorId);
    if (mounted) {
      setState(() {
        _hasPendingSave = false;
        _motorOffFailed = true;
        _motorOffFailureMsg = message;
      });
    }
  }

  void _completeTestRun() {
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    final sum = _flcData.isNotEmpty ? _flcData.reduce((a, b) => a + b) : 0.0;
    final average = _flcData.isNotEmpty ? sum / _flcData.length : 0.0;
    _overalCurrent.value = average;

    // Immediately send motor OFF (D:0) in the background so it is confirmed
    // by the time the user taps "Save Settings".
    _motorCmdSentAt = DateTime.now();
    _hasPendingSave = true;
    _savingIsSendingSettings = false;
    _d0Countdown = _waitingTimerSeconds;

    if (_mqttMotorId.isNotEmpty) {
      // Listen for D:0 ACK.
      widget.mqttService.dataUpdateNotifier.addListener(_checkMotorOffAck);
      // Listen for retry exhaustion.
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      widget.mqttService.commandStatusNotifier.addListener(_onCommandStatus);
      // Start 15s countdown shown in the "Stopping Motor..." dialog.
      _d0CountdownTimer?.cancel();
      _d0CountdownTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (_d0Countdown > 0) {
          setState(() => _d0Countdown--);
        } else {
          timer.cancel();
          _handleMotorOffFailure('No acknowledgment received from device');
        }
      });
      // Wait 5s after the last test-run (T:5) command before sending the
      // motor OFF (T:1), so the two don't hit the device at the same instant.
      final offMotorId = _mqttMotorId;
      Future.delayed(const Duration(seconds: 5), () {
        widget.mqttService.publishTestRunCommand(offMotorId, 1,
            data: 0, type: 1, motorReference: _motorRef);
      });
    } else {
      // No motor ID — skip D:0, go straight to completed.
      _hasPendingSave = false;
      if (mounted) setState(() { _remainingSeconds = 0; _phase = _TestRunPhase.completed; });
      return;
    }

    // Show "Stopping Motor..." loading dialog immediately.
    if (mounted) {
      setState(() {
        _remainingSeconds = 0;
        _phase = _TestRunPhase.saving;
      });
    }
  }

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

    _motorOnCmdSentAt = DateTime.now();
    _motorOnFailed = false;
    _motorOnFailureMsg = '';
    _motorOnCountdown = _waitingTimerSeconds;

    setState(() => _phase = _TestRunPhase.motorOnWaiting);

    // Register BEFORE publishing so T:31 ACK never updates motor state.
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService.addTestRunMotor(mqttMotorId);
    }

    // Listen for retry-exhaustion → shows error in the waiting dialog.
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    widget.mqttService.commandStatusNotifier.addListener(_onCommandStatus);

    // Listen for T:31 ACK → transition to measuring.
    widget.mqttService.dataUpdateNotifier.addListener(_checkMotorOnAck);

    // Publish D:2 (motor ON) with retry.
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService.publishTestRunCommand(mqttMotorId, 1,
          data: 2, type: 1, motorReference: _motorRef);
    }

    // 15-second countdown shown in the waiting dialog.
    _motorOnCountdownTimer?.cancel();
    _motorOnCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_motorOnCountdown > 0) {
        setState(() => _motorOnCountdown--);
      } else {
        timer.cancel();
        if (_phase == _TestRunPhase.motorOnWaiting && !_motorOnFailed) {
          _handleMotorOnFailure('No acknowledgment received from device');
        }
      }
    });
  }

  /// Starts the measuring timer after motor ON ACK is confirmed.
  void _startActualMeasuring() {
    _avgCurrent.value = 0.0;
    _flcData.clear();
    _overalCurrent.value = 0.0;
    _testStartTime = DateTime.now();
    final mqttMotorId = _mqttMotorId;

    if (mounted) {
      setState(() {
        _phase = _TestRunPhase.measuring;
        _remainingSeconds = _totalSeconds;
      });
    }

    // Wall-clock elapsed keeps countdown accurate even when OS throttles timers.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_testStartTime!).inSeconds;
      final remaining = (_totalSeconds - elapsed).clamp(0, _totalSeconds);

      if (mqttMotorId.isNotEmpty && elapsed > 0 && elapsed % 10 == 0) {
        widget.mqttService.publishTestRunCommand(mqttMotorId, 1,
            data: 1, type: 5, motorReference: _motorRef);
      }

      if (remaining > 0) {
        if (mounted) setState(() => _remainingSeconds = remaining);
      } else {
        timer.cancel();
        _completeTestRun();
      }
    });
  }

  void _checkUpdates() {
    if (!mounted) return;

    // Try direct lookup by _mqttMotorId first (fast path).
    // Fall back to MAC/PCB search because the device may publish T:41 live data
    // on a topic whose identifier (MAC or PCB) differs from the one used in
    // commands — e.g. commands use PCB but status topics use MAC. In that case
    // _handleLiveData creates an alias under a different key, so the direct
    // lookup returns null or stale data. Searching by MAC/PCB always finds the
    // correct entry regardless of which identifier the device uses on the wire.
    MotorData? motordata;
    if (_mqttMotorId.isNotEmpty) {
      final direct = widget.mqttService.motorDataMap[_liveDataKey];
      if (direct != null && direct.hasReceivedLiveData) {
        motordata = direct;
      }
    }

    if (motordata == null) {
      final mac = widget.motor.starter?.macAddress;
      final pcb = widget.motor.starter?.pcbNumber;
      final ref = widget.motor.motorReference;
      DateTime? bestTime;
      for (final entry in widget.mqttService.motorDataMap.entries) {
        final data = entry.value;
        if (!data.hasReceivedLiveData) continue;
        if (ref != null && ref.isNotEmpty && data.motorReference != ref) {
          continue;
        }
        final matchesMac = mac != null &&
            mac.isNotEmpty &&
            (data.macAddress == mac || data.pcbNumber == mac);
        final matchesPcb = pcb != null &&
            pcb.isNotEmpty &&
            (data.macAddress == pcb || data.pcbNumber == pcb);
        if (matchesMac || matchesPcb) {
          final ackTime = widget.mqttService.getLastAckTime(entry.key);
          if (motordata == null ||
              (ackTime != null &&
                  (bestTime == null || ackTime.isAfter(bestTime)))) {
            motordata = data;
            bestTime = ackTime;
            // Fix _mqttMotorId so _completeTestRun's publishMotorOFF and
            // future direct lookups use the correct key. Multi-motor keys end
            // in '-<motorReference>', which is not part of the command id — the
            // publish topic is derived from it, so the suffix must be dropped.
            final key = entry.key;
            final dataRef = data.motorReference;
            final commandId = (dataRef != null &&
                    dataRef.isNotEmpty &&
                    key.endsWith('-$dataRef'))
                ? key.substring(0, key.length - dataRef.length - 1)
                : key;
            if (commandId != _mqttMotorId) {
              // Re-register under the new id, otherwise the T:31 ACK is stamped
              // on the old one and _checkMotorOffAck never sees it.
              if (_mqttMotorId.isNotEmpty) {
                widget.mqttService.removeTestRunMotor(_mqttMotorId);
              }
              _mqttMotorId = commandId;
              widget.mqttService.addTestRunMotor(_mqttMotorId);
            }
          }
        }
      }
    }

    motordata ??= widget.motorData;

    final c1 = double.tryParse(motordata?.currentRed ?? '0.0') ?? 0.0;
    final c2 = double.tryParse(motordata?.currentBlue ?? '0.0') ?? 0.0;
    final c3 = double.tryParse(motordata?.currentYellow ?? '0.0') ?? 0.0;

    // Only accept if all phases have at least 0.5A
    if (c1 >= 0.5 && c2 >= 0.5 && c3 >= 0.5) {
      final res = _percentageOfAmps(c1, c2, c3);
      final avg = double.parse(res.toStringAsFixed(2));

      // Update ValueNotifier directly — ValueListenableBuilder in
      // _buildMeasuringPhase handles its own rebuild without setState.
      _avgCurrent.value = avg;

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
    _motorOnCountdownTimer?.cancel();
    _d0CountdownTimer?.cancel();
    _settingsCountdownTimer?.cancel();
    _settingsRetryTimer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    if (_mqttMotorId.isNotEmpty) {
      widget.mqttService.removeTestRunMotor(_mqttMotorId);
    }

    final identifier = getMotorIdentifier(
        widget.motor.starter!.deviceAllocation.toString(),
        widget.motor.starter!.pcbNumber.toString(),
        widget.motor.starter!.macAddress.toString());
    final groupId = identifier.isNotEmpty ? _getMotorGroupId(identifier) : '';
    final mqttMotorId = identifier.isNotEmpty ? '$identifier-$groupId' : '';

    // Send stop command T=1, D=0
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService
          .publishTestRunCommand(mqttMotorId, 1,
              data: 0, type: 1, motorReference: _motorRef)
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

  /// Called when user taps "Save Settings".
  /// Motor OFF (D:0) is already confirmed by this point — transition to saving
  /// phase and send the calibration payload (T:4).
  Future<void> _onSave() async {
    _hasPendingSave = true;
    setState(() {
      _phase = _TestRunPhase.saving;
      isWaitingForAck = true;
      _savingIsSendingSettings = true;
    });
    _sendSettings();
  }

  /// Sends the calibration settings payload (T:4) and awaits T:34 ACK.
  /// Called after D:0 T:31 ACK is confirmed by [_checkMotorOffAck].
  Future<void> _sendSettings() async {
    try {
      final identifier = getMotorIdentifier(
          widget.motor.starter!.deviceAllocation.toString(),
          widget.motor.starter!.pcbNumber.toString(),
          widget.motor.starter!.macAddress.toString());
      if (identifier.isNotEmpty && _controller != null) {
        await _controller!.fetchUserSettings2();
        final avgFlc = _overalCurrent.value;
        final OLR1 = _calculatedFlc(_controller!.olr.value, avgFlc);
        final LRF2 = _calculatedFlc(_controller!.lrf.value, avgFlc);
        final LRR3 = _calculatedFlc(_controller!.lrr.value, avgFlc);
        final DRF4 = _calculatedFlc(_controller!.drf.value.toDouble(), avgFlc);
        final OLF5 = _calculatedFlc(_controller!.olf.value.toDouble(), avgFlc);
        final trimFlc = avgFlc.toStringAsFixed(2);
        final flc = double.parse(trimFlc);
        final motorFields = {
          "olr": OLR1,
          "lrr": LRR3,
          "lrf": LRF2,
          "drf": DRF4,
          "olf": OLF5,
          'flc': flc
        };
        // Multi-motor nests the calibration under the motor reference
        // (dvc_c:{m2:{...}}); single-motor keeps the flat dvc_c it always sent.
        final ref = _motorRef;
        final payload = {
          "dvc_c": ref == null ? motorFields : {ref: motorFields},
        };
        _controller!.flc.value = flc;

        // Compute the calibration payload once, then drive retries from
        // _publishSettingsAttempt so every retry re-sends identical data.
        _settingsPayload = payload;
        _settingsAttempt = 0;
        await _publishSettingsAttempt();
      }
    } catch (e) {
      print("Error publishing settings command: $e");
      if (mounted) {
        setState(() {
          isWaitingForAck = false;
          _hasPendingSave = false;
          failureMessage = 'Failed to send settings command';
          _phase = _TestRunPhase.failure;
        });
      }
    }
  }

  /// Publishes one calibration (T:4) attempt and waits for the T:34 ACK.
  ///
  /// Retry rule (driven here, not by the MQTT layer):
  ///  • D:1                    → success, stop retrying.
  ///  • error code (2–8)       → shows the code's message immediately, then
  ///                             re-publishes the next attempt, up to
  ///                             [_maxSettingsAttempts], without resetting
  ///                             the 15s countdown — it keeps ticking down
  ///                             across these quick retries. Only after the
  ///                             last attempt still errors do we stop and
  ///                             show the terminal failure.
  ///  • no ACK within 15s      → terminal failure. The device stayed silent,
  ///                             so there is a single 15s window and it is
  ///                             never restarted.
  Future<void> _publishSettingsAttempt({bool resetTimer = true}) async {
    final payload = _settingsPayload;
    if (payload == null || _controller == null) return;
    _settingsAttempt++;

    if (resetTimer) {
      // (Re)start the countdown shown in the saving dialog for this attempt.
      _settingsCountdownTimer?.cancel();
      _settingsCountdown.value = _settingsWindowSeconds;
      _settingsCountdownTimer =
          Timer.periodic(const Duration(seconds: 1), (t) {
        if (_settingsCountdown.value > 0) {
          _settingsCountdown.value--;
        } else {
          t.cancel();
        }
      });

      // Silence doesn't re-publish on its own — the MQTT-layer retry is
      // cancelled right after each publish — so drive the re-sends here until
      // the attempt budget is spent. The countdown keeps running through them.
      _settingsRetryTimer?.cancel();
      _settingsRetryTimer = Timer.periodic(_settingsRetryGap, (t) {
        if (!mounted || _ackInProgress || !_hasPendingSave) {
          t.cancel();
          return;
        }
        if (_settingsAttempt >= _maxSettingsAttempts) {
          t.cancel();
          return;
        }
        _publishSettingsAttempt(resetTimer: false);
      });

      // No ACK within the window → terminal. One window only; never restart it.
      settingsAckTimer?.cancel();
      settingsAckTimer =
          Timer(const Duration(seconds: _settingsWindowSeconds), () {
        _settingsCountdownTimer?.cancel();
        _settingsRetryTimer?.cancel();
        mqttStreamSubscription?.cancel();
        if (!mounted || _ackInProgress) return;
        _failCalibration('No acknowledgment received from device');
      });
    }

    // Listen for the T:34 ACK BEFORE publishing (broadcast stream — events
    // emitted before listen() are lost).
    mqttStreamSubscription?.cancel();
    mqttStreamSubscription =
        widget.mqttService.settingstream.listen((data) async {
      final code = data["D"];
      final topic = data["topic"];
      if (topic != _controller!.pcbNumber.value &&
          topic != _controller!.macAddress.value) return;

      // Multi-motor ACKs carry the reference (D:{"m2":1}) — ignore the other
      // motor's ACK. Single-motor ACKs have no reference and always pass.
      final ackRef = data["motor"] as String?;
      if (ackRef != null && _motorRef != null && ackRef != _motorRef) return;

      if (code == 1 && !_ackInProgress && _hasPendingSave) {
        // Success — stop the card retries and the MQTT-layer retries.
        settingsAckTimer?.cancel();
        _settingsCountdownTimer?.cancel();
        _settingsRetryTimer?.cancel();
        _hasPendingSave = false;
        _ackInProgress = true;
        mqttStreamSubscription?.cancel();
        widget.mqttService.cancelPendingSettingsCommand();
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
        return;
      }

      // Error code (2–8): this attempt failed. Don't give up yet — re-publish,
      // unless the attempts are exhausted. The 15s countdown keeps running
      // uninterrupted through these quick retries; only a full no-ACK
      // timeout restarts it.
      if (_ackInProgress) return;
      if (_settingsAttempt < _maxSettingsAttempts) {
        // Still retrying — show this attempt's error now; the terminal
        // failure (below) shows its own message via _failCalibration.
        geterrorSnackBar(_calibrationErrorMessage(code));
        debugPrint(
            '🔄 Calibration error code $code → retry ${_settingsAttempt + 1}/$_maxSettingsAttempts');
        _publishSettingsAttempt(resetTimer: false);
      } else {
        settingsAckTimer?.cancel();
        _settingsCountdownTimer?.cancel();
        _settingsRetryTimer?.cancel();
        if (mounted) _failCalibration(_calibrationErrorMessage(code));
      }
    });

    // Publish, then disable the MQTT-layer auto-retry so retries are driven
    // solely from here (avoids double publishing).
    await widget.mqttService
        .publishUpdateSettings(_controller!.pcbNumber.value, payload);
    widget.mqttService.cancelPendingSettingsCommand();
    _controller?.fetchupdateSettings();
  }

  /// Terminal calibration failure — shown after retries are exhausted (error
  /// codes) or no ACK arrives. Sets the failure phase with [message] and
  /// navigates back after a short delay.
  void _failCalibration(String message) {
    _resetPreCheckState();
    if (mounted) {
      setState(() {
        isWaitingForAck = false;
        _hasPendingSave = false;
        _phase = _TestRunPhase.failure;
        failureMessage = message;
      });
      geterrorSnackBar(message);
    }
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

  void _onCancel() {
    _isSubDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomConfirmationDialog(
        title: "Cancel Settings ?",
        message:
            "Are you sure you want to cancel? The calibration data will not be saved.",
        confirmText: "Yes",
        cancelText: 'No',
        confirmColor: const Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
        onConfirm: () {
          _flcData.clear();
          _overalCurrent.value = 0.0;
          _avgCurrent.value = 0.0;
          if (_mqttMotorId.isNotEmpty) {
            widget.mqttService.removeTestRunMotor(_mqttMotorId);
          }
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
      case _TestRunPhase.motorOnWaiting:
        return _buildMotorOnWaitingPhase();
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

                  // Network Connectivity — verified via motorData.testRunSignal.
                  // Listens to both liveDataNotifier (T:35/T:41) and
                  // heartbeatNotifier (T:40) so the icon updates from either.
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.mqttService.liveDataNotifier,
                      widget.mqttService.heartbeatNotifier,
                    ]),
                    builder: (context, _) {
                      // widget.motorData may be a stale reference if the map
                      // was rebuilt after the dialog opened. Fall back to a
                      // fresh lookup by MAC / PCB so heartbeat updates (which
                      // update the live map entry) are always reflected.
                      MotorData? motorData = widget.motorData;
                      if (motorData?.testRunSignal != true) {
                        final mac = widget.motor.starter?.macAddress;
                        final pcb = widget.motor.starter?.pcbNumber;
                        for (final data
                            in widget.mqttService.motorDataMap.values) {
                          if ((mac != null && data.macAddress == mac) ||
                              (pcb != null && data.pcbNumber == pcb)) {
                            motorData = data;
                            break;
                          }
                        }
                      }
                      final bool? signal;
                      if (motorData?.testRunSignal == true) {
                        signal = true;
                      } else if (_preCheckTimedOut) {
                        signal = false;
                      } else {
                        signal = null;
                      }
                      return _buildVerificationCloudConnection(
                        'Network Connectivity',
                        signal,
                        'assets/images/network_device.svg',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Power Supply Status — verified via motorData.testrunPowerSupply.
                  ValueListenableBuilder<int>(
                    valueListenable: widget.mqttService.liveDataNotifier,
                    builder: (context, _, __) {
                      final int? powerVerified;
                      if (widget.motorData?.testrunPowerSupply == true) {
                        powerVerified = 1;
                      } else if (_preCheckTimedOut) {
                        powerVerified = 0;
                      } else {
                        powerVerified = null;
                      }
                      return _buildVerificationInputPower(
                          'Power Supply Status', powerVerified);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Voltage Range — verified via motorData.testrunVoltageRange
                  // and actual phase voltage values.
                  ValueListenableBuilder<int>(
                    valueListenable: widget.mqttService.liveDataNotifier,
                    builder: (context, _, __) {
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

  // ===================== Phase 1b: Motor ON Waiting =====================

  Widget _buildMotorOnWaitingPhase() {
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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _testrunColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Motor Test Run',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Smart Calibration',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(32),
                child: _motorOnFailed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Motor Failed to Respond',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _motorOnFailureMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.route == Routes.dashboard) {
                                  Get.offAllNamed(Routes.dashboard,
                                      arguments: {'refresh': true});
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F6B8A),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Dismiss',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF0F6B8A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Starting Motor...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF004E7E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_motorOnCountdown s',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F6B8A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Waiting for device acknowledgment',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _testrunColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Motor Test Run',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Smart Calibration',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(32),
                child: _motorOffFailed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Motor Failed to Stop',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _motorOffFailureMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.route == Routes.dashboard) {
                                  Get.offAllNamed(Routes.dashboard,
                                      arguments: {'refresh': true});
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F6B8A),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Dismiss',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF0F6B8A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _savingIsSendingSettings
                                ? 'Saving Calibration...'
                                : 'Stopping Motor...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF004E7E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_savingIsSendingSettings) ...[
                            Text(
                              '$_d0Countdown s',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F6B8A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Waiting for device acknowledgment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ] else ...[
                            ValueListenableBuilder<int>(
                              valueListenable: _settingsCountdown,
                              builder: (context, countdown, _) {
                                return Text(
                                  '$countdown s',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F6B8A),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sending calibration to device',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
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
      String text, bool? signal, String svg) {
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
            ? signal
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
    final bool hasSignal = widget.motorData?.testrunVoltageRange == true;
    final bool showLoading;
    final bool voltageOk;

    if (hasSignal && _isVoltageInRange) {
      showLoading = false;
      voltageOk = true;
    } else if (hasSignal || _preCheckTimedOut) {
      // Data received but voltage out of range, or timed out without data.
      showLoading = false;
      voltageOk = false;
    } else {
      showLoading = true;
      voltageOk = false;
    }

    final String? error =
        (!showLoading && !voltageOk && hasSignal) ? _voltageError : null;

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
