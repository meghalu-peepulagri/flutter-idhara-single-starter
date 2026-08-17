import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/devices/motor_control_model.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_card_dialogs.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_controls_row.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_header.dart';
import 'package:i_dhara/app/presentation/components/motor_card/voltage_current_values_card.dart';
import 'package:i_dhara/app/presentation/components/testrun_verification_card.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../core/utils/mqtt_utils.dart';
import '../../../core/utils/snackbars/error_snackbar.dart';
import '../../../core/utils/snackbars/success_snackbar.dart';

class MotorCardWidget extends StatefulWidget {
  final Motor motor;
  final MqttService mqttService;
  final Function(Motor, bool) onToggleMotor;
  const MotorCardWidget({
    super.key,
    required this.motor,
    required this.mqttService,
    required this.onToggleMotor,
  });
  @override
  State<MotorCardWidget> createState() => _MotorCardWidgetState();
}

class _MotorCardWidgetState extends State<MotorCardWidget> {
  late ValueNotifier<bool> _localSwitchController;
  late ValueNotifier<int> _localModeController;
  bool _hasPendingSwitchCommand = false;
  bool _hasPendingModeCommand = false;
  bool? _pendingSwitchValue;
  int? _pendingModeValue;
  bool _isWaitingForSwitchAck = false;
  bool _isWaitingForModeAck = false;
  bool _isWaitingForFaultClear = false;
  Timer? _switchAckTimer;
  Timer? _modeAckTimer;
  static const Duration _ackTimeout = Duration(seconds: 13);
  @override
  void initState() {
    super.initState();
    final motorData = _getMotorData();
    bool initialState;
    int initialMode;
    if (motorData != null && motorData.hasReceivedData) {
      initialState = motorData.state == 1;
      initialMode = motorData.modeIndex ?? 1;
    } else {
      final apiState = widget.motor.state ?? 0;
      initialState = apiState == 1;
      initialMode = _getSimplifiedModeIndex(widget.motor.mode ?? 'AUTO') ?? 1;
    }
    _localSwitchController = ValueNotifier(initialState);
    _localModeController = ValueNotifier(initialMode);
    widget.mqttService.commandStatusNotifier
        .addListener(_onCommandStatusChanged);
    widget.mqttService.faultClearResultNotifier
        .addListener(_onFaultClearResult);
    _localModeController.addListener(_onModeControllerChanged);
  }

  void _onModeControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onFaultClearResult() async {
    final raw = widget.mqttService.faultClearResultNotifier.value;
    if (raw == null || !mounted) return;

    // Value is '<motorId>|<motorReference>' — every card in a
    // MULTIPLE_MOTORS group resolves to the same motorId (see _getMotorId),
    // so the reference tells m1 and m2 apart when only one of them was
    // actually cleared.
    final sep = raw.indexOf('|');
    final clearedMotorId = sep >= 0 ? raw.substring(0, sep) : raw;
    final clearedRef = sep >= 0 ? raw.substring(sep + 1) : '';

    // Check if this ACK is for our motor
    final ourMotorId = _getMotorId();
    if (clearedMotorId != ourMotorId) return;

    if (widget.motor.starter?.motorSupportType == 'MULTIPLE_MOTORS' &&
        clearedRef.isNotEmpty) {
      final myRef = widget.motor.motorReference ?? 'm1';
      if (clearedRef != myRef) return;
    }

    _isWaitingForFaultClear = false;
    setState(() {});

    // Show snackbar immediately before clearFaultAck, because clearFaultAck
    // sets isLoading=true which rebuilds the widget tree and unmounts this card.
    getsuccessSnackBar('Fault cleared successfully');

    // Call API to patch fault clear and then fetch motors
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().clearFaultAck(widget.motor);
    }
  }

  // --- Logic Methods ---

  void _startSwitchAckTimer(bool previousValue) {
    _switchAckTimer?.cancel();
    _switchAckTimer = Timer(_ackTimeout, () {
      if (mounted && _hasPendingSwitchCommand) {
        debugPrint(
            ' Switch ACK timeout - reverting to previous state: $previousValue');
        _localSwitchController.value = previousValue;
        _hasPendingSwitchCommand = false;
        _pendingSwitchValue = null;
        if (mounted) {
          setState(() {
            _isWaitingForSwitchAck = false;
          });
        }
      }
    });
  }

  void _startModeAckTimer(int previousValue) {
    _modeAckTimer?.cancel();
    _modeAckTimer = Timer(_ackTimeout, () {
      if (mounted && _hasPendingModeCommand) {
        debugPrint(
            ' Mode ACK timeout - reverting to previous mode: $previousValue');
        _localModeController.value = previousValue;
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        if (mounted) {
          setState(() {
            _isWaitingForModeAck = false;
          });
        }
      }
    });
  }

  String _formatMotorName(String name) {
    final formatted = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (formatted.length > 10) {
      return '${formatted.substring(0, 10)}...';
    }
    return formatted;
  }

  void _onCommandStatusChanged() {
    final message = widget.mqttService.commandStatusNotifier.value;
    if (message != null && mounted) {
      final motorName = _formatMotorName(widget.motor.aliasName ?? 'Motor');
      if (message.contains(motorName)) {
        // Reset fault clear waiting state on timeout so user can retry
        if (_isWaitingForFaultClear) {
          setState(() => _isWaitingForFaultClear = false);
        }
        showTopSnackBar(
          Overlay.of(context),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0XFFDB3B2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          displayDuration: const Duration(seconds: 4),
        );
        widget.mqttService.commandStatusNotifier.value = null;
      }
    }
  }

  @override
  void dispose() {
    widget.mqttService.commandStatusNotifier
        .removeListener(_onCommandStatusChanged);
    widget.mqttService.faultClearResultNotifier
        .removeListener(_onFaultClearResult);
    _localModeController.removeListener(_onModeControllerChanged);
    _switchAckTimer?.cancel();
    _modeAckTimer?.cancel();
    _localSwitchController.dispose();
    _localModeController.dispose();
    super.dispose();
  }

  MotorData? _getMotorData() {
    if (widget.motor.starter == null) return null;
    final mac = widget.motor.starter!.macAddress;
    final pcb = widget.motor.starter!.pcbNumber;
    MotorData? bestData;
    DateTime? bestTime;
    final ref = widget.motor.motorReference;
    for (var entry in widget.mqttService.motorDataMap.entries) {
      final data = entry.value;
      if (data.hasReceivedData != true) continue;
      if (ref != null && ref.isNotEmpty && data.motorReference != ref) continue;
      final key = entry.key;
      final matchesByKey =
          (mac != null && mac.isNotEmpty && key.startsWith('$mac-')) ||
              (pcb != null && pcb.isNotEmpty && key.startsWith('$pcb-'));
      final matchesByData = (mac != null &&
              mac.isNotEmpty &&
              (data.macAddress == mac || data.pcbNumber == mac)) ||
          (pcb != null &&
              pcb.isNotEmpty &&
              (data.macAddress == pcb || data.pcbNumber == pcb));
      if (matchesByKey || matchesByData) {
        final ackTime = widget.mqttService.getLastAckTime(key);
        if (bestData == null ||
            (ackTime != null &&
                (bestTime == null || ackTime.isAfter(bestTime)))) {
          bestData = data;
          bestTime = ackTime;
        }
      }
    }
    return bestData;
  }

  String _getMotorId() {
    if (widget.motor.starter == null) return '';
    final mac = widget.motor.starter!.macAddress;
    final pcb = widget.motor.starter!.pcbNumber;
    final deviceallow = widget.motor.starter?.deviceAllocation;
    final publishedNumber = getMotorIdentifier(
        deviceallow.toString(), pcb.toString(), mac.toString());
    if (widget.motor.starter == null) return '';
    final motorData = _getMotorData();
    if (motorData?.groupId != null) {
      if (motorData!.macAddress?.isNotEmpty == true) {
        return '$publishedNumber-${motorData.groupId}';
      }
      if (motorData.pcbNumber?.isNotEmpty == true) {
        return '$publishedNumber-${motorData.groupId}';
      }
    }
    if (mac?.isNotEmpty == true) return '$publishedNumber-G01';
    if (pcb?.isNotEmpty == true) return '$publishedNumber-G01';
    return '';
  }

  bool _isMotorAvailable() {
    final mac = widget.motor.starter?.macAddress;
    final pcb = widget.motor.starter?.pcbNumber;
    return (mac?.isNotEmpty == true) || (pcb?.isNotEmpty == true);
  }

  /// Check if motor is currently in fault state
  bool _isMotorInFault() {
    // Check if fault is cleared by API
    final starterParams = widget.motor.starter?.starterParameters;
    final isFaultCleared = starterParams?.firstOrNull?.faultCleared == true;

    if (isFaultCleared) {
      return false;
    }

    final motorData = _getMotorData();
    if (motorData != null && motorData.hasReceivedData) {
      return motorData.fault != 0;
    }
    // Also check API data
    if (starterParams != null && starterParams.isNotEmpty) {
      return (starterParams.first.fault ?? 0) != 0;
    }
    return false;
  }

  Future<void> _handleToggle(bool newValue) async {
    if (_isWaitingForSwitchAck) return;
    if (!_isMotorAvailable()) return;
    final motorId = _getMotorId();
    if (motorId.isEmpty) return;

    // If fault clear was waiting but the pending command is gone (retries
    // exhausted or ACK received), reset the flag so the user can retry.
    if (_isWaitingForFaultClear) {
      _isWaitingForFaultClear = false;
      setState(() {});
    }

    // If turning ON and motor has fault, show fault clear dialog first.
    // After fault is cleared, _onFaultClearResult will show the switch dialog.
    if (newValue && _isMotorInFault()) {
      MotorCardDialogs.showFaultClearDialog(
        context,
        widget.motor,
        () => _sendFaultClearCommand(motorId),
      );
      return;
    }

    // If turning OFF while in Auto mode, show the auto-mode warning dialog
    if (!newValue && _localModeController.value == 1) {
      MotorCardDialogs.showAutoModeOffWarningDialog(
        context,
        widget.motor,
        onOffAnyway: () {
          // Temporary off — just send switch command, motor stays in Auto mode
          _executeSwitchCommand(motorId, false);
        },
        onModeChange: () {
          // Navigate to motor details page so user can change mode themselves
          SharedPreference.setMotorId(widget.motor.id ?? 0);
          SharedPreference.setStarterId(widget.motor.starter?.id ?? 0);
          Get.offAllNamed(Routes.motorDetails, arguments: {
            'motorId': widget.motor.id,
            'tabIndex': 0,
          });
        },
      );
      return;
    }

    // No fault — show switch confirmation dialog, then execute on confirm
    _showSwitchDialogAndExecute(motorId, newValue);
  }

  void _showSwitchDialogAndExecute(String motorId, bool newValue) {
    MotorCardDialogs.showSwitchCommandDialog(
      context,
      widget.motor,
      newValue,
      (confirmed) => _executeSwitchCommand(motorId, confirmed),
    );
  }

  /// Send fault clear command with retry logic. Waits for the real device
  /// ACK (via faultClearResultNotifier / _onFaultClearResult) before
  /// treating the fault as cleared — for single- and multi-motor starters
  /// alike.
  Future<void> _sendFaultClearCommand(String motorId) async {
    setState(() => _isWaitingForFaultClear = true);

    try {
      await widget.mqttService.publishFaultClearCommand(motorId,
          motorReference: widget.motor.motorReference);
    } catch (e) {
      if (mounted) {
        setState(() => _isWaitingForFaultClear = false);
        errorSnackBar(
            context, 'Failed to send fault clear command. Please try again.');
      }
    }
  }

  /// Execute the actual motor switch command
  Future<void> _executeSwitchCommand(String motorId, bool newValue) async {
    final previousValue = _localSwitchController.value;
    setState(() => _isWaitingForSwitchAck = true);
    _localSwitchController.value = newValue;
    _hasPendingSwitchCommand = true;
    _pendingSwitchValue = newValue;

    if (widget.motor.starter?.motorSupportType == 'MULTIPLE_MOTORS') {
      await _executeMultiMotorSwitchCommand(previousValue, newValue);
      return;
    }

    _startSwitchAckTimer(previousValue);
    try {
      await widget.mqttService.publishMotorCommand(motorId, newValue ? 1 : 0);
    } catch (e) {
      _switchAckTimer?.cancel();
      _localSwitchController.value = !newValue;
      _hasPendingSwitchCommand = false;
      _pendingSwitchValue = null;
      if (mounted) setState(() => _isWaitingForSwitchAck = false);
    }
  }

  Future<void> _executeMultiMotorSwitchCommand(
      bool previousValue, bool newValue) async {
    final starterId = widget.motor.starter?.id;
    final numericMotorId = widget.motor.id;
    if (starterId == null || numericMotorId == null) {
      _revertMultiMotorSwitch(previousValue);
      return;
    }
    try {
      final response = await DevicesRepositoryImpl().controlMotors(
        starterId,
        MotorControlRequest(
          motors: [
            MotorControlItem(motorId: numericMotorId, state: newValue ? 1 : 0),
          ],
        ),
      );
      MotorControlResult? result;
      for (final r in response?.results ?? <MotorControlResult>[]) {
        if (r.motorId == numericMotorId) {
          result = r;
          break;
        }
      }
      if (result?.acked == true) {
        _hasPendingSwitchCommand = false;
        _pendingSwitchValue = null;
        if (mounted) setState(() => _isWaitingForSwitchAck = false);
        final status = result?.ackStatus;
        if (status != null && status.isNotEmpty) getsuccessSnackBar(status);
      } else {
        _revertMultiMotorSwitch(previousValue);
      }
    } catch (e) {
      _revertMultiMotorSwitch(previousValue);
    }
  }

  void _revertMultiMotorSwitch(bool previousValue) {
    _localSwitchController.value = previousValue;
    _hasPendingSwitchCommand = false;
    _pendingSwitchValue = null;
    if (mounted) setState(() => _isWaitingForSwitchAck = false);
  }

  int? _getSimplifiedModeIndex(String motorMode) {
    final upper = motorMode.toUpperCase();
    if (upper.contains('MANUAL')) return 0;
    if (upper.contains('SCHEDULE')) return 2;
    if (upper.contains('AUTO')) return 1;
    return 1;
  }

  void _updateSwitchFromMqtt(bool newState) {
    if (_localSwitchController.value != newState) {
      _localSwitchController.value = newState;
    }
  }

  void _updateModeFromMqtt(int newMode) {
    if (_localModeController.value != newMode) {
      _localModeController.value = newMode;
    }
  }

  void _handleModeChange(int newMode) {
    if (_isWaitingForModeAck) return;
    if (!_isMotorAvailable()) return;
    final motorId = _getMotorId();
    if (motorId.isEmpty) return;
    final motorName = widget.motor.aliasName ?? widget.motor.name ?? 'Motor';
    MotorCardDialogs.showModeChangeDialog(context, motorName, newMode,
        (confirmedMode) async {
      final previousMode = _localModeController.value;
      setState(() => _isWaitingForModeAck = true);
      _localModeController.value = confirmedMode;
      _hasPendingModeCommand = true;
      _pendingModeValue = confirmedMode;

      if (widget.motor.starter?.motorSupportType == 'MULTIPLE_MOTORS') {
        await _executeMultiMotorModeCommand(previousMode, confirmedMode);
        return;
      }

      _startModeAckTimer(previousMode);

      try {
        // UI index 2 (Schedule) maps to device code 6 on the wire. The ACK
        // path in MqttService translates D:6 back to modeIndex=2, so the
        // _pendingModeValue comparison below stays in UI-index space.
        final deviceCode = confirmedMode == 2 ? 6 : confirmedMode;
        await widget.mqttService.publishModeCommand(motorId, deviceCode);
      } catch (e) {
        _modeAckTimer?.cancel();
        _localModeController.value = previousMode;
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        if (mounted) setState(() => _isWaitingForModeAck = false);
      }
    });
  }

  String? _modeIndexToApiString(int modeIndex) {
    switch (modeIndex) {
      case 0:
        return 'MANUAL';
      case 1:
        return 'AUTO';
      case 2:
        return 'SCHEDULE';
    }
    return null;
  }

  Future<void> _executeMultiMotorModeCommand(
      int previousMode, int newMode) async {
    final starterId = widget.motor.starter?.id;
    final numericMotorId = widget.motor.id;
    final modeStr = _modeIndexToApiString(newMode);
    if (starterId == null || numericMotorId == null || modeStr == null) {
      _revertMultiMotorMode(previousMode);
      return;
    }
    try {
      final response = await DevicesRepositoryImpl().changeMotorsMode(
        starterId,
        MotorModeRequest(
          motors: [MotorModeItem(motorId: numericMotorId, mode: modeStr)],
        ),
      );
      MotorModeResult? result;
      for (final r in response?.results ?? <MotorModeResult>[]) {
        if (r.motorId == numericMotorId) {
          result = r;
          break;
        }
      }
      if (result?.acked == true) {
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        if (mounted) setState(() => _isWaitingForModeAck = false);
        final status = result?.ackStatus;
        if (status != null && status.isNotEmpty) getsuccessSnackBar(status);
      } else {
        _revertMultiMotorMode(previousMode);
      }
    } catch (e) {
      _revertMultiMotorMode(previousMode);
    }
  }

  void _revertMultiMotorMode(int previousMode) {
    _localModeController.value = previousMode;
    _hasPendingModeCommand = false;
    _pendingModeValue = null;
    if (mounted) setState(() => _isWaitingForModeAck = false);
  }

  bool _canControlMotor(MotorData? motorData) {
    if (!_isMotorAvailable()) return false;
    final int signalBars = _getSignalBars(motorData);

    // If motor is in test run, skip power check — only signal matters
    if (_isNewDeviceWithoutAck(motorData)) {
      return signalBars > 0;
    }

    final isPowerOn = (motorData?.hasReceivedData == true)
        ? motorData!.power == 1
        : (widget.motor.starter?.power ?? 0) == 1;
    return isPowerOn && signalBars > 0;
  }

  int _getSignalBars(MotorData? motorData) {
    if (motorData?.hasReceivedData == true && !motorData!.isSignalStale()) {
      return motorData.signalBars;
    }
    final signal = widget.motor.starter?.signalQuality;
    if (signal == null || signal < 2 || signal > 40) return 0;
    if (signal < 10) return 1;
    if (signal < 15) return 2;
    if (signal < 20) return 3;
    return 4;
  }

  void _navigateToDetails() {
    SharedPreference.setMotorId(widget.motor.id ?? 0);
    SharedPreference.setStarterId(widget.motor.starter?.id ?? 0);
    Get.toNamed(
      Routes.motorDetails,
      arguments: {'motorId': widget.motor.id},
    );
  }

  void ontapFault() {
    SharedPreference.setMotorId(widget.motor.id ?? 0);
    SharedPreference.setStarterId(widget.motor.starter?.id ?? 0);
    // Get.toNamed(
    //   Routes.motorDetails,
    //   arguments: {'motorId': widget.motor.id},
    // );

    Get.offAllNamed(Routes.motorDetails, arguments: {
      'motorId': widget.motor.id,
      'tabIndex': 3,
      'logFilter': 'Faults'
    });
  }

  void _navigateToTestRun() {
    SharedPreference.setMotorId(widget.motor.id ?? 0);
    SharedPreference.setStarterId(widget.motor.starter?.id ?? 0);
    _showConfirmTestRunDialog();
  }

  void _showConfirmTestRunDialog() async {
    final cloudConnectionVerified = ValueNotifier<bool>(false);
    final inputPowerVerified = ValueNotifier<bool>(false);
    final avgflc = ValueNotifier<double>(0.0);

    // Publish verification command (type 5)
    try {
      final identifier = getMotorIdentifier(
          widget.motor.starter!.deviceAllocation.toString(),
          widget.motor.starter!.pcbNumber.toString(),
          widget.motor.starter!.macAddress.toString());
      final map = {identifier: widget.motor};
      widget.mqttService.updateMotors(map);
      if (identifier.isNotEmpty) {
        final groupId = _getMotorGroupId(identifier);
        final mqttMotorId = '$identifier-$groupId';

        await widget.mqttService.publishTestRunCommand(mqttMotorId, 1,
            data: 1,
            type: MqttService.topicLiveDataRequest,
            motorReference: widget.motor.motorReference);
      }
    } catch (e) {
      // ignore
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder(
          valueListenable: widget.mqttService.dataUpdateNotifier,
          builder: (context, _, __) {
            final motorData = _getMotorData();
            return ConfirmTestRunScreen(
              motorData: motorData,
              motor: widget.motor,
              mqttService: widget.mqttService,
              cloudConnectionVerified: cloudConnectionVerified,
              inputPowerVerified: inputPowerVerified,
              avgflc: avgflc,
            );
          }),
    );
  }

  String _getMotorGroupId(String identifier) {
    const allowedGroups = ['G01', 'G02'];
    for (final groupId in allowedGroups) {
      final motorData = widget.mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) return groupId;
    }
    return 'G01';
  }

  bool _isNewDeviceWithoutAck(MotorData? motorData) {
    // Check test_run_status from API response first
    final testRunStatus = widget.motor.testrunStatus?.toUpperCase();

    if (testRunStatus == 'COMPLETED') {
      return false; // Test run completed, allow control
    }

    if (testRunStatus == 'IN_TEST') {
      return true; // Test run in progress, show test run
    }

    if (testRunStatus == 'FAILED') {
      return true; // Test run failed, allow retry
    }

    // Fallback to existing logic if test_run_status is not available
    final motorId = widget.motor.id;

    // Check if test run was completed locally
    if (motorId != null && SharedPreference.hasCompletedTestRun(motorId)) {
      return false; // Test run completed, allow control
    }

    // Check if device has existing ACK data from API (starterParameters)
    final starterParams = widget.motor.starter?.starterParameters;
    if (starterParams != null && starterParams.isNotEmpty) {
      // Device has previous calibration data from API, test run already done
      return false;
    }

    return true; // New device — test run required
  }

  /// Determine if Test Run button should be enabled
  bool _shouldShowTestRun(MotorData? motorData) {
    // Enable only if it's a new device without ACK and motor is available
    return _isNewDeviceWithoutAck(motorData) && _isMotorAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.mqttService.dataUpdateNotifier,
      builder: (context, _, __) {
        final motorData = _getMotorData();
        final canControl = _canControlMotor(motorData);
        final canChangeMode =
            (!_isMotorAvailable() || _getSignalBars(motorData) == 0)
                ? false
                : true;

        if (motorData?.hasReceivedData == true) {
          // Sync Switch
          if (_hasPendingSwitchCommand) {
            if ((motorData!.state == 1) == _pendingSwitchValue) {
              _switchAckTimer?.cancel();
              _hasPendingSwitchCommand = false;
              _pendingSwitchValue = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isWaitingForSwitchAck = false);
              });
            }
          } else {
            final mqttState = motorData!.state == 1;
            if (_localSwitchController.value != mqttState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasPendingSwitchCommand)
                  _updateSwitchFromMqtt(mqttState);
              });
            }
          }

          // Sync Mode
          if (_hasPendingModeCommand) {
            if (motorData.modeIndex == _pendingModeValue) {
              _modeAckTimer?.cancel();
              _hasPendingModeCommand = false;
              _pendingModeValue = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isWaitingForModeAck = false);
              });
            }
          } else {
            if (motorData.modeIndex != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasPendingModeCommand) {
                  _updateModeFromMqtt(motorData.modeIndex!);
                }
              });
            }
          }
        }

        final isSwitchDisabled = _isWaitingForSwitchAck || !(canControl);
        final hasSignal = _getSignalBars(motorData) > 0;

        return Opacity(
          opacity: hasSignal ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  MotorHeader(
                    ontapFault: ontapFault,
                    motor: widget.motor,
                    motorData: motorData,
                    onTap: _navigateToDetails,
                  ),
                  const Divider(
                      height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _navigateToDetails,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12.0, 0.0, 12.0, 0.0),
                      child: VoltageCurrentValuesCard(
                        motor: widget.motor,
                        mqttService: widget.mqttService,
                        isTestRunRequired: false,
                        showTestRun: _shouldShowTestRun(motorData),
                        onTestRun: _navigateToTestRun,
                      ),
                    ),
                  ),
                  const Divider(
                      height: 2, thickness: 1.0, color: Color(0xFFECECEC)),
                  MotorControlsRow(
                    motor: widget.motor,
                    motorData: motorData,
                    switchController: _localSwitchController,
                    modeController: _localModeController,
                    onToggleSwitch: _handleToggle,
                    onModeChange: _handleModeChange,
                    isSwitchDisabled: isSwitchDisabled,
                    isModeDisabled: _isWaitingForModeAck || !canChangeMode,
                    onNavigateToDetails: _navigateToDetails,
                    onScheduleTap: () {
                      SharedPreference.setMotorId(widget.motor.id ?? 0);
                      SharedPreference.setStarterId(
                          widget.motor.starter?.id ?? 0);
                      Get.offAllNamed(Routes.motorDetails, arguments: {
                        'motorId': widget.motor.id,
                        'tabIndex': 1,
                      });
                    },
                  ),
                ].divide(const SizedBox(height: 4.0)),
              ),
            ),
          ),
        );
      },
    );
  }
}
