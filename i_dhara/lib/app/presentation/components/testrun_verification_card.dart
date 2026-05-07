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

part 'testrun/testrun_lifecycle.dart';
part 'testrun/testrun_handlers.dart';
part 'testrun/testrun_actions.dart';
part 'testrun/testrun_phase_pre_check.dart';
part 'testrun/testrun_phase_motor_run.dart';
part 'testrun/testrun_phase_terminal.dart';
part 'testrun/testrun_widgets.dart';

enum _TestRunPhase { preCheck, motorOnWaiting, measuring, completed, saving, success, failure }

// ── Top-level constants (shared across the part files) ─────────────────────
const int _kTotalSeconds = 60;
const int _kWaitingTimerSeconds = 23;

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
  int _remainingSeconds = _kTotalSeconds;
  DateTime? _testStartTime;
  Timer? _timer;
  final List<double> _flcData = [];
  final ValueNotifier<double> _avgCurrent = ValueNotifier(0);
  final ValueNotifier<double> _overalCurrent = ValueNotifier(0);
  String _mqttMotorId = '';
  double _finalFLC = 0.0;
  // Timestamp of the last motor command (D:2 or D:0) so we can detect
  // whether a T:31 ACK belongs to the command we just sent.
  DateTime? _motorCmdSentAt;

  // --- Motor ON waiting phase ---
  DateTime? _motorOnCmdSentAt;
  bool _motorOnFailed = false;
  String _motorOnFailureMsg = '';
  int _motorOnCountdown = _kWaitingTimerSeconds;
  Timer? _motorOnCountdownTimer;

  // --- Saving phase sub-state ---
  bool _savingIsSendingSettings = false;
  int _d0Countdown = _kWaitingTimerSeconds;
  Timer? _d0CountdownTimer;
  bool _motorOffFailed = false;
  String _motorOffFailureMsg = '';
  final ValueNotifier<int> _settingsCountdown = ValueNotifier(15);
  Timer? _settingsCountdownTimer;

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

  // --- Lifecycle (must live on the class for Flutter to dispatch) ---

  @override
  void initState() {
    super.initState();
    initStateImpl();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    didChangeAppLifecycleStateImpl(state);
  }

  @override
  void dispose() {
    disposeImpl();
    super.dispose();
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
}
