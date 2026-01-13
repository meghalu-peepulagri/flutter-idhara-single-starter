import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_card_dialogs.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_controls_row.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_header.dart';
import 'package:i_dhara/app/presentation/components/motor_card/voltage_current_values_card.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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
  // bool _isInitialized = false; // Not strictly used in snippet
  bool _hasPendingSwitchCommand = false;
  bool _hasPendingModeCommand = false;
  bool? _pendingSwitchValue;
  int? _pendingModeValue;
  // bool _isUpdatingFromMqtt = false;
  bool _isWaitingForSwitchAck = false;
  bool _isWaitingForModeAck = false;

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
    // _isInitialized = true;
    widget.mqttService.commandStatusNotifier
        .addListener(_onCommandStatusChanged);
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

  void _onCommandStatusChanged() {
    final message = widget.mqttService.commandStatusNotifier.value;
    if (message != null && mounted) {
      final motorName = widget.motor.aliasName ?? 'Motor';
      if (message.contains(motorName)) {
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
              style: const TextStyle(color: Colors.white),
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
    final motorKey = '${mac ?? pcb}-';

    // Check for existing active data
    final workingId = widget.mqttService.motorDataMap.keys.firstWhere(
        (k) =>
            k.startsWith(motorKey) &&
            widget.mqttService.motorDataMap[k]?.hasReceivedData == true,
        orElse: () => '');

    if (workingId.isNotEmpty) {
      return widget.mqttService.motorDataMap[workingId];
    }

    // Fallback scan
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      if (mac != null && mac.isNotEmpty) {
        final data = widget.mqttService.motorDataMap['$mac-$groupId'];
        if (data?.hasReceivedData == true) return data;
      }
      if (pcb != null && pcb.isNotEmpty) {
        final data = widget.mqttService.motorDataMap['$pcb-$groupId'];
        if (data?.hasReceivedData == true) return data;
      }
    }
    return null;
  }

  String _getMotorId() {
    if (widget.motor.starter == null) return '';
    final motorData = _getMotorData();

    if (motorData?.groupId != null) {
      if (motorData!.macAddress?.isNotEmpty == true) {
        return '${motorData.macAddress}-${motorData.groupId}';
      }
      if (motorData.pcbNumber?.isNotEmpty == true) {
        return '${motorData.pcbNumber}-${motorData.groupId}';
      }
    }

    final mac = widget.motor.starter!.macAddress;
    final pcb = widget.motor.starter!.pcbNumber;
    if (mac?.isNotEmpty == true) return '$mac-G01';
    if (pcb?.isNotEmpty == true) return '$pcb-G01';
    return '';
  }

  bool _isMotorAvailable() {
    final mac = widget.motor.starter?.macAddress;
    final pcb = widget.motor.starter?.pcbNumber;
    return (mac?.isNotEmpty == true) || (pcb?.isNotEmpty == true);
  }

  Future<void> _handleToggle(bool newValue) async {
    // if (_isUpdatingFromMqtt || _isWaitingForSwitchAck) return;
    if (_isWaitingForSwitchAck) return;
    if (!_isMotorAvailable()) return;

    final motorId = _getMotorId();
    if (motorId.isEmpty) return;

    final previousValue = _localSwitchController.value;

    setState(() => _isWaitingForSwitchAck = true);
    _localSwitchController.value = newValue;
    _hasPendingSwitchCommand = true;
    _pendingSwitchValue = newValue;
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

  Future<void> _handleModeToggle(int? index) async {
    if (index == null || !_isMotorAvailable() || _isWaitingForModeAck) return;
    final motorId = _getMotorId();
    if (motorId.isEmpty) return;

    final previousValue = _localModeController.value;
    setState(() => _isWaitingForModeAck = true);

    final oldIndex = _localModeController.value;
    _localModeController.value = index;
    _hasPendingModeCommand = true;
    _pendingModeValue = index;
    _startModeAckTimer(previousValue);

    try {
      await widget.mqttService.publishModeCommand(motorId, index);
    } catch (e) {
      _modeAckTimer?.cancel();
      _localModeController.value = oldIndex;
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      if (mounted) setState(() => _isWaitingForModeAck = false);
    }
  }

  int? _getSimplifiedModeIndex(String motorMode) {
    if (motorMode.toUpperCase().contains('MANUAL')) return 0;
    if (motorMode.toUpperCase().contains('AUTO')) return 1;
    return 1;
  }

  void _updateSwitchFromMqtt(bool newState) {
    if (_localSwitchController.value != newState) {
      // _isUpdatingFromMqtt = true;
      _localSwitchController.value = newState;
      // Future.delayed(const Duration(milliseconds: 50), () {
      //   _isUpdatingFromMqtt = false;
      // });
    }
  }

  void _updateModeFromMqtt(int newMode) {
    if (_localModeController.value != newMode) {
      _localModeController.value = newMode;
    }
  }

  bool _canControlMotor(MotorData? motorData) {
    if (!_isMotorAvailable()) return false;
    final isPowerOn = (motorData?.hasReceivedData == true)
        ? motorData!.power == 1
        : (widget.motor.starter?.power ?? 0) == 1;

    int signalBars = _getSignalBars(motorData);
    return isPowerOn && signalBars > 0;
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

  void _navigateToDetails() {
    SharedPreference.setMotorId(widget.motor.id ?? 0);
    SharedPreference.setStarterId(widget.motor.starter?.id ?? 0);
    Get.toNamed(
      Routes.motorDetails,
      arguments: {'motorId': widget.motor.id},
    );
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
                if (mounted && !_hasPendingModeCommand)
                  _updateModeFromMqtt(motorData.modeIndex!);
              });
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                MotorHeader(
                  motor: widget.motor,
                  motorData: motorData,
                  onTap: _navigateToDetails,
                ),
                const Divider(
                    height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _navigateToDetails,
                  child: AbsorbPointer(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12.0, 0.0, 12.0, 0.0),
                      child: VoltageCurrentValuesCard(
                        motor: widget.motor,
                        mqttService: widget.mqttService,
                      ),
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
                  onModeChange: (_) {
                    /* Mode change from UI usually handled by tap, but logic is here if needed */
                  },
                  isSwitchDisabled: _isWaitingForSwitchAck ||
                      !(canControl && _localModeController.value == 0),
                  isModeDisabled: _isWaitingForModeAck || !canChangeMode,
                ),
              ].divide(const SizedBox(height: 4.0)),
            ),
          ),
        );
      },
    );
  }
}
