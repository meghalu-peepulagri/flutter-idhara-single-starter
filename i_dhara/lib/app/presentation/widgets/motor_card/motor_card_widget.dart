import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/widgets/motor_card/voltage_current_values_card.dart';
import 'package:lottie/lottie.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';

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
  bool _isInitialized = false;
  bool _hasPendingSwitchCommand = false;
  bool _hasPendingModeCommand = false;
  bool? _pendingSwitchValue;
  int? _pendingModeValue;
  bool _isUpdatingFromMqtt = false;
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
    _isInitialized = true;
    widget.mqttService.commandStatusNotifier
        .addListener(_onCommandStatusChanged);
  }

  void _startSwitchAckTimer(bool previousValue) {
    _switchAckTimer?.cancel();
    _switchAckTimer = Timer(_ackTimeout, () {
      if (mounted && _hasPendingSwitchCommand) {
        debugPrint(
            '⏱️ Switch ACK timeout - reverting to previous state: $previousValue');

        _localSwitchController.value = previousValue;
        _hasPendingSwitchCommand = false;
        _pendingSwitchValue = null;

        setState(() {
          _isWaitingForSwitchAck = false;
        });
      }
    });
  }

  void _startModeAckTimer(int previousValue) {
    _modeAckTimer?.cancel();
    _modeAckTimer = Timer(_ackTimeout, () {
      if (mounted && _hasPendingModeCommand) {
        debugPrint(
            '⏱️ Mode ACK timeout - reverting to previous mode: $previousValue');

        _localModeController.value = previousValue;
        _hasPendingModeCommand = false;
        _pendingModeValue = null;

        setState(() {
          _isWaitingForModeAck = false;
        });
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
            constraints: const BoxConstraints(
              maxWidth: 350,
              minHeight: 40,
              maxHeight: 50,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0XFFDB3B2A),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          displayDuration: const Duration(seconds: 4),
        );

        // Clear the message after showing
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
    if (widget.motor.starter?.macAddress == null || widget.motor.id == null) {
      return null;
    }

    final mac = widget.motor.starter!.macAddress!;

    MotorData? latestData;
    DateTime? latestTimestamp;

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      final motorId = '$mac-$groupId';
      final data = widget.mqttService.motorDataMap[motorId];

      if (data != null && data.hasReceivedData) {
        final dataTimestamp = widget.mqttService.getLastAckTime(motorId);

        if (latestData == null ||
            (dataTimestamp != null &&
                (latestTimestamp == null ||
                    dataTimestamp.isAfter(latestTimestamp)))) {
          latestData = data;
          latestTimestamp = dataTimestamp;
          debugPrint(
              '${widget.motor.name} - Found MQTT data in $groupId (timestamp: $dataTimestamp)');
        }
      }
    }

    return latestData;
  }

  String _getMotorId() {
    if (widget.motor.starter?.macAddress == null) return '';

    final motorData = _getMotorData();
    if (motorData != null && motorData.groupId != null) {
      return '${widget.motor.starter!.macAddress}-${motorData.groupId}';
    }

    return '${widget.motor.starter!.macAddress}-G01';
  }

  bool _isMotorAvailable() {
    if (widget.motor.starter?.macAddress == null ||
        widget.motor.starter!.macAddress!.isEmpty) {
      return false;
    }
    return true;
  }

  void _showSwitchConfirmationBottomSheet(bool newValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSwitchCommandDialog(newValue);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: newValue ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showModeConfirmationBottomSheet(int newMode) {
    final modeName = newMode == 1 ? 'Auto' : 'Manual';
    final modeColor =
        newMode == 1 ? const Color(0xFFFFA500) : const Color(0xFF2F80ED);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showModeCommandDialog(newMode);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: modeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSwitchCommandDialog(bool newValue) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to control this motor?',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Motor: ",
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.motor.aliasName?.capitalizeFirst ?? "Unknown",
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'State:',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    newValue ? 'ON' : 'OFF',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleToggle(newValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showModeCommandDialog(int newMode) {
    final modeName = newMode == 1 ? 'Auto' : 'Manual';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to change the motor mode?',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Motor: ",
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.motor.aliasName?.capitalizeFirst ?? "Unknown",
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Mode:',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    modeName,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleModeToggle(newMode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleToggle(bool newValue) async {
    if (_isUpdatingFromMqtt || _isWaitingForSwitchAck) {
      debugPrint('Ignoring toggle - triggered by MQTT update');
      return;
    }

    if (!_isMotorAvailable()) {
      debugPrint('Cannot toggle: Motor not available');
      return;
    }

    final motorId = _getMotorId();
    if (motorId.isEmpty) {
      debugPrint('Cannot toggle: Invalid motor ID');
      return;
    }

    final previousValue = _localSwitchController.value;

    setState(() {
      _isWaitingForSwitchAck = true;
    });

    _localSwitchController.value = newValue;
    _hasPendingSwitchCommand = true;
    _pendingSwitchValue = newValue;

    _startSwitchAckTimer(previousValue);

    try {
      final state = newValue ? 1 : 0;
      await widget.mqttService.publishMotorCommand(motorId, state);
      debugPrint('✓ Toggle command sent: $motorId -> $state');
    } catch (e) {
      _switchAckTimer?.cancel();
      _localSwitchController.value = !newValue;
      _hasPendingSwitchCommand = false;
      _pendingSwitchValue = null;
      setState(() {
        _isWaitingForSwitchAck = false;
      });
      debugPrint('✗ Failed to toggle motor: $e');
    }
  }

  Future<void> _handleModeToggle(int? index) async {
    if (index == null || !_isMotorAvailable() || _isWaitingForModeAck) {
      return;
    }

    final motorId = _getMotorId();
    if (motorId.isEmpty) {
      debugPrint('Cannot change mode: Invalid motor ID');
      return;
    }
    final previousValue = _localModeController.value;

    setState(() {
      _isWaitingForModeAck = true;
    });

    final oldIndex = _localModeController.value;
    _localModeController.value = index;
    _hasPendingModeCommand = true;
    _pendingModeValue = index;

    _startModeAckTimer(previousValue);

    try {
      await widget.mqttService.publishModeCommand(motorId, index);
      debugPrint('✓ Mode command sent: $motorId -> $index');
    } catch (e) {
      _modeAckTimer?.cancel();
      _localModeController.value = oldIndex;
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      setState(() {
        _isWaitingForModeAck = false;
      });
      debugPrint('✗ Failed to change mode: $e');
    }
  }

  int? _getSimplifiedModeIndex(String motorMode) {
    if (motorMode.toUpperCase().contains('MANUAL')) {
      return 0;
    } else if (motorMode.toUpperCase().contains('AUTO')) {
      return 1;
    }
    return 1;
  }

  void _updateSwitchFromMqtt(bool newState) {
    if (_localSwitchController.value != newState) {
      _isUpdatingFromMqtt = true;
      _localSwitchController.value = newState;
      Future.delayed(const Duration(milliseconds: 50), () {
        _isUpdatingFromMqtt = false;
      });
    }
  }

  void _updateModeFromMqtt(int newMode) {
    if (_localModeController.value != newMode) {
      debugPrint('🔄 Updating mode from MQTT: $newMode');
      _localModeController.value = newMode;
    }
  }

  Widget _buildSignalIcon(MotorData? motorData) {
    int? signalStrength;
    int bars = 0;

    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale()) {
      bars = motorData.signalBars;
      signalStrength = motorData.signalStrength;
      debugPrint(
          '${widget.motor.name} - Using MQTT signal: strength=$signalStrength, bars=$bars');
    } else {
      signalStrength = widget.motor.starter?.signalQuality;
      debugPrint(
          '${widget.motor.name} - Using API signal quality: $signalStrength');

      if (signalStrength == null || signalStrength < 2 || signalStrength > 31) {
        bars = 0;
      } else if (signalStrength >= 2 && signalStrength <= 9) {
        bars = 1;
      } else if (signalStrength >= 10 && signalStrength <= 14) {
        bars = 2;
      } else if (signalStrength >= 15 && signalStrength <= 19) {
        bars = 3;
      } else if (signalStrength >= 20 && signalStrength <= 30) {
        bars = 4;
      } else {
        bars = 0;
      }

      debugPrint(
          '${widget.motor.name} - Calculated bars from API signal: $bars');
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

  bool _canControlMotor(MotorData? motorData) {
    // Check if motor is available
    if (!_isMotorAvailable()) {
      return false;
    }

    // Check power status
    final bool isPowerOn;
    if (motorData != null && motorData.hasReceivedData) {
      isPowerOn = motorData.power == 1;
    } else {
      isPowerOn = (widget.motor.starter?.power ?? 0) == 1;
    }

    // Check network/signal status
    int signalBars = _getSignalBars(motorData);

    // Motor can be controlled only if power is ON AND there's network (signal bars > 0)
    return isPowerOn && signalBars > 0;
  }

  bool _canChangeMode(MotorData? motorData) {
    // Check if motor is available
    if (!_isMotorAvailable()) {
      return false;
    }

    // Check network/signal status only
    int signalBars = _getSignalBars(motorData);

    // Mode can be changed if there's network (signal bars > 0)
    return signalBars > 0;
  }

// Helper method to get signal bars
  int _getSignalBars(MotorData? motorData) {
    int signalBars = 0;
    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale()) {
      signalBars = motorData.signalBars;
    } else {
      final signalStrength = widget.motor.starter?.signalQuality;
      if (signalStrength != null &&
          signalStrength >= 2 &&
          signalStrength <= 31) {
        if (signalStrength >= 2 && signalStrength <= 9) {
          signalBars = 1;
        } else if (signalStrength >= 10 && signalStrength <= 14) {
          signalBars = 2;
        } else if (signalStrength >= 15 && signalStrength <= 19) {
          signalBars = 3;
        } else if (signalStrength >= 20 && signalStrength <= 30) {
          signalBars = 4;
        }
      }
    }
    return signalBars;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.mqttService.dataUpdateNotifier,
      builder: (context, notificationValue, __) {
        final motorData = _getMotorData();

        final bool isPowerOn;
        if (motorData != null && motorData.hasReceivedData) {
          isPowerOn = motorData.power == 1;
          debugPrint(
              '${widget.motor.name} - Using MQTT power: ${motorData.power}');
        } else {
          isPowerOn = (widget.motor.starter?.power ?? 0) == 1;
          debugPrint(
              '${widget.motor.name} - Using API power: ${widget.motor.starter?.power ?? 0}');
        }

        // final isAvailable = _isMotorAvailable();
        final canControl = _canControlMotor(motorData);
        final canChangeMode = _canChangeMode(motorData);

        if (motorData != null && motorData.hasReceivedData) {
          // Update switch state
          if (_hasPendingSwitchCommand) {
            final mqttState = motorData.state == 1;
            if (mqttState == _pendingSwitchValue) {
              debugPrint(
                  '✓ Switch ACK received: $mqttState matches pending $_pendingSwitchValue');
              _switchAckTimer?.cancel();
              _hasPendingSwitchCommand = false;
              _pendingSwitchValue = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isWaitingForSwitchAck = false;
                  });
                }
              });
            }
          } else {
            final mqttState = motorData.state == 1;
            if (_localSwitchController.value != mqttState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasPendingSwitchCommand) {
                  debugPrint('🔄 Updating switch from MQTT: $mqttState');
                  _updateSwitchFromMqtt(mqttState);
                }
              });
            }
          }

          // Update mode
          if (_hasPendingModeCommand) {
            final mqttMode = motorData.modeIndex;
            if (mqttMode == _pendingModeValue) {
              debugPrint(
                  '✓ Mode ACK received: $mqttMode matches pending $_pendingModeValue');
              _modeAckTimer?.cancel();
              _hasPendingModeCommand = false;
              _pendingModeValue = null;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isWaitingForModeAck = false;
                  });
                }
              });
            }
          } else {
            final mqttMode = motorData.modeIndex;
            if (mqttMode != null && _localModeController.value != mqttMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasPendingModeCommand) {
                  debugPrint('🔄 Updating mode from MQTT: $mqttMode');
                  _updateModeFromMqtt(mqttMode);
                }
              });
            }
          }
        }

        final int faultValue;
        if (motorData != null && motorData.hasReceivedData) {
          faultValue = motorData.fault;
        } else {
          faultValue =
              widget.motor.starter?.starterParameters?.firstOrNull?.fault ?? 0;
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
                // Header Row
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
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
                            (widget.motor.aliasName != null &&
                                            widget.motor.aliasName!
                                                .trim()
                                                .isNotEmpty
                                        ? widget.motor.aliasName!
                                        : widget.motor.name ?? '')
                                    .capitalizeFirst ??
                                '',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
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
                          // _buildSignalIcon(motorData),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0.0),
                            child: SvgPicture.asset(
                              isPowerOn
                                  ? 'assets/images/power.svg'
                                  : 'assets/images/Power_red.svg',
                              width: 17,
                              height: 17,
                              fit: BoxFit.cover,
                            ),
                          ),
                          _buildSignalIcon(motorData),
                          if (faultValue > 0)
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
                                    8.0, 4.0, 8.0, 4.0),
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
                const Divider(
                  height: 0,
                  thickness: 1.0,
                  color: Color(0xFFECECEC),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
                  child: VoltageCurrentValuesCard(
                    motor: widget.motor,
                    mqttService: widget.mqttService,
                  ),
                ),
                const Divider(
                  height: 2,
                  thickness: 1.0,
                  color: Color(0xFFECECEC),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _localModeController,
                        builder: (context, currentModeIndex, child) {
                          final uiIndex = currentModeIndex == 1 ? 0 : 1;
                          final isDisabled =
                              _isWaitingForModeAck || !canChangeMode;
                          debugPrint('🎨 Mode UI rendering: $currentModeIndex');
                          return ToggleSwitch(
                            changeOnTap: false,
                            customWidths: const [90, 90],
                            radiusStyle: true,
                            minWidth: 80.0,
                            minHeight: 30.0,
                            initialLabelIndex: uiIndex,
                            cornerRadius: 8.0,
                            activeBgColors: !isDisabled
                                ? [
                                    [const Color(0xFFFFA500)],
                                    [const Color(0xFF2F80ED)]
                                  ]
                                : [
                                    [const Color(0xFFFFA500).withOpacity(0.3)],
                                    [const Color(0xFF2F80ED).withOpacity(0.3)],
                                  ],
                            activeFgColor:
                                !isDisabled ? Colors.white : Colors.black,
                            inactiveBgColor: Colors.white,
                            inactiveFgColor: Colors.black,
                            fontSize: 12,
                            totalSwitches: 2,
                            labels: const ['Auto', 'Manual'],
                            borderWidth: 1,
                            borderColor: [Colors.grey.shade300],
                            onToggle: !isDisabled
                                ? (index) {
                                    if (index == null) return;

                                    debugPrint(
                                        '🔄 Toggle clicked: UI index=$index');

                                    // Map UI index back to mode index
                                    // UI index 0 (Auto) -> Mode 1
                                    // UI index 1 (Manual) -> Mode 0
                                    final newMode = index == 0 ? 1 : 0;

                                    debugPrint(
                                        '🔄 Mapped mode: $newMode (current=$currentModeIndex)');

                                    // Only show dialog if mode is actually changing
                                    if (newMode != currentModeIndex) {
                                      debugPrint(
                                          '✓ Mode changed, showing dialog');
                                      _showModeCommandDialog(newMode);
                                    } else {
                                      debugPrint(
                                          '⊗ Same mode clicked, ignoring');
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                      // ValueListenableBuilder(
                      //   valueListenable: _localSwitchController,
                      //   builder: (context, isOn, child) {
                      //     return GestureDetector(
                      //       onTap: isAvailable
                      //           ? () {
                      //               _showSwitchCommandDialog(!isOn);
                      //             }
                      //           : null,
                      //       behavior: HitTestBehavior.opaque,
                      //       child: AbsorbPointer(
                      //         absorbing: true,
                      //         child: Opacity(
                      //           opacity: isAvailable ? 1.0 : 0.5,
                      //           child: AdvancedSwitch(
                      //             key: ValueKey(
                      //                 'switch_${widget.motor.id}_$isOn'),
                      //             controller: _localSwitchController,
                      //             initialValue: isOn,
                      //             activeColor: Colors.green,
                      //             inactiveColor: Colors.red.shade500,
                      //             activeChild: const Text(
                      //               'ON',
                      //               style: TextStyle(
                      //                 color: Colors.white,
                      //                 fontSize: 11,
                      //                 fontWeight: FontWeight.bold,
                      //               ),
                      //             ),
                      //             inactiveChild: const Text(
                      //               'OFF',
                      //               style: TextStyle(
                      //                 color: Colors.white,
                      //                 fontSize: 10,
                      //                 fontWeight: FontWeight.bold,
                      //               ),
                      //             ),
                      //             borderRadius: const BorderRadius.all(
                      //                 Radius.circular(15)),
                      //             width: 55,
                      //             height: 25,
                      //             enabled: true,
                      //             disabledOpacity: 0.5,
                      //           ),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                      ValueListenableBuilder(
                        valueListenable: _localModeController,
                        builder: (context, modeIndex, _) {
                          final bool isManualMode =
                              modeIndex == 0; // 0 = MANUAL, 1 = AUTO
                          final bool isSwitchDisabled =
                              _isWaitingForSwitchAck ||
                                  !(canControl && isManualMode);

                          return ValueListenableBuilder(
                            valueListenable: _localSwitchController,
                            builder: (context, isOn, child) {
                              return GestureDetector(
                                onTap: !isSwitchDisabled
                                    ? () {
                                        _showSwitchCommandDialog(!isOn);
                                      }
                                    : null,
                                behavior: HitTestBehavior.opaque,
                                child: AbsorbPointer(
                                  absorbing: true,
                                  child: Opacity(
                                    opacity: !isSwitchDisabled ? 1.0 : 0.4,
                                    child: AdvancedSwitch(
                                      key: ValueKey(
                                          'switch_${widget.motor.id}_$isOn'),
                                      controller: _localSwitchController,
                                      initialValue: isOn,
                                      activeColor: Colors.green,
                                      inactiveColor: Colors.red.shade500,
                                      activeChild: const Text(
                                        'ON',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      inactiveChild: const Text(
                                        'OFF',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(15)),
                                      width: 55,
                                      height: 25,
                                      enabled: !isSwitchDisabled,
                                      disabledOpacity: 0.9,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ].divide(const SizedBox(height: 4.0)),
            ),
          ),
        );
      },
    );
  }
}
