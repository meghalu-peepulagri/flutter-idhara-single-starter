import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_card_dialogs.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_controls_row.dart';
import 'package:i_dhara/app/presentation/components/motor_card/voltage_current_values_card.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:lottie/lottie.dart';

class TestRunPage extends StatefulWidget {
  const TestRunPage({super.key});

  @override
  State<TestRunPage> createState() => _TestRunPageState();
}

class _TestRunPageState extends State<TestRunPage> {
  late Motor motor;
  late MqttService mqttService;

  bool _isRunning = false;
  bool _isSuccess = false;
  bool _isFailed = false;
  String _statusMessage = 'Ready to test';
  Timer? _ackTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _selectedTimeoutMinutes = 3; // Default 3 minutes

  late ValueNotifier<bool> _localSwitchController;
  late ValueNotifier<int> _localModeController;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    motor = args['motor'] as Motor;
    mqttService = args['mqttService'] as MqttService;

    final motorData = _getMotorData();
    bool initialState;
    int initialMode;

    if (motorData != null && motorData.hasReceivedData) {
      initialState = motorData.state == 1;
      initialMode = motorData.modeIndex ?? 1;
    } else {
      final apiState = motor.state ?? 0;
      initialState = apiState == 1;
      initialMode = _getSimplifiedModeIndex(motor.mode ?? 'AUTO') ?? 1;
    }

    _localSwitchController = ValueNotifier(initialState);
    _localModeController = ValueNotifier(initialMode);
  }

  @override
  void dispose() {
    _ackTimer?.cancel();
    _countdownTimer?.cancel();
    _localSwitchController.dispose();
    _localModeController.dispose();
    super.dispose();
  }

  int? _getSimplifiedModeIndex(String motorMode) {
    if (motorMode.toUpperCase().contains('MANUAL')) return 0;
    if (motorMode.toUpperCase().contains('AUTO')) return 1;
    return 1;
  }

  String _getMotorId() {
    if (motor.starter == null) return '';
    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;
    if (mac?.isNotEmpty == true) return '$mac-G01';
    if (pcb?.isNotEmpty == true) return '$pcb-G01';
    return '';
  }

  MotorData? _getMotorData() {
    if (motor.starter == null) return null;
    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;
    final motorKey = '${mac ?? pcb}-';

    final workingId = mqttService.motorDataMap.keys.firstWhere(
        (k) =>
            k.startsWith(motorKey) &&
            mqttService.motorDataMap[k]?.hasReceivedData == true,
        orElse: () => '');

    if (workingId.isNotEmpty) {
      return mqttService.motorDataMap[workingId];
    }

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      if (mac != null && mac.isNotEmpty) {
        final data = mqttService.motorDataMap['$mac-$groupId'];
        if (data?.hasReceivedData == true) return data;
      }
      if (pcb != null && pcb.isNotEmpty) {
        final data = mqttService.motorDataMap['$pcb-$groupId'];
        if (data?.hasReceivedData == true) return data;
      }
    }
    return null;
  }

  void _showTestRunConfirmDialog() {
    MotorCardDialogs.showTestRunConfirmDialog(
      context,
      motor,
      (int timeoutMinutes) {
        _selectedTimeoutMinutes = timeoutMinutes;
        _startTestRun(timeoutMinutes);
      },
    );
  }

  Future<void> _startTestRun(int timeoutMinutes) async {
    final motorId = _getMotorId();
    if (motorId.isEmpty) {
      setState(() {
        _isFailed = true;
        _statusMessage = 'Motor ID not available';
      });
      return;
    }

    // Calculate timeout in seconds
    _remainingSeconds = timeoutMinutes * 60;

    setState(() {
      _isRunning = true;
      _isSuccess = false;
      _isFailed = false;
      _statusMessage = 'Sending command...';
    });

    // Listen for ACK
    mqttService.dataUpdateNotifier.addListener(_onDataUpdate);

    try {
      // Publish motor ON command (single publish, no retry)
      await mqttService.publishTestRunCommand(motorId, 1);

      setState(() {
        _statusMessage = 'Waiting for response... (${_formatTime(_remainingSeconds)})';
      });

      // Start countdown timer to update UI every second
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isRunning || _isSuccess) {
          timer.cancel();
          return;
        }
        _remainingSeconds--;
        if (_remainingSeconds > 0) {
          setState(() {
            _statusMessage = 'Waiting for response... (${_formatTime(_remainingSeconds)})';
          });
        }
      });

      // Start ACK timeout timer
      _ackTimer = Timer(Duration(minutes: timeoutMinutes), () {
        if (mounted && _isRunning && !_isSuccess) {
          _onAckTimeout();
        }
      });
    } catch (e) {
      debugPrint('Test run command failed: $e');
      setState(() {
        _isRunning = false;
        _isFailed = true;
        _statusMessage = 'Failed to send command';
      });
      mqttService.dataUpdateNotifier.removeListener(_onDataUpdate);
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _onDataUpdate() {
    if (!_isRunning || _isSuccess) return;

    // Check if we received data for this motor
    final motorData = _getMotorData();
    if (motorData != null && motorData.hasReceivedData) {
      _onAckReceived();
    }
  }

  void _onAckReceived() {
    _ackTimer?.cancel();
    _countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(_onDataUpdate);

    // Save motor ID to SharedPreferences to persist test run completion
    if (motor.id != null) {
      SharedPreference.addCompletedTestRunMotor(motor.id!);
    }

    setState(() {
      _isRunning = false;
      _isSuccess = true;
      _isFailed = false;
      _statusMessage = 'Test successful! Device is responding.';
    });

    // Turn off the motor after successful test
    _turnOffMotor();

    // Auto redirect to dashboard after success
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _goToDashboard();
      }
    });
  }

  Future<void> _turnOffMotor() async {
    final motorId = _getMotorId();
    if (motorId.isNotEmpty) {
      try {
        await mqttService.publishMotorCommand(motorId, 0);
      } catch (e) {
        debugPrint('Failed to turn off motor: $e');
      }
    }
  }

  void _onAckTimeout() {
    _ackTimer?.cancel();
    _countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(_onDataUpdate);

    setState(() {
      _isRunning = false;
      _isSuccess = false;
      _isFailed = true;
      _statusMessage = 'No response received after $_selectedTimeoutMinutes min. Please check device connection.';
    });
  }

  void _goBack() {
    Get.back();
  }

  void _goToDashboard() {
    Get.offAllNamed(Routes.dashboard);
  }

  String _normalizeMotorName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '';
    }
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool get _isPowerOn {
    final motorData = _getMotorData();
    if (motorData != null && motorData.hasReceivedData) {
      return motorData.power == 1;
    }
    return (motor.starter?.power ?? 0) == 1;
  }

  int get _faultValue {
    final motorData = _getMotorData();
    if (motorData != null && motorData.hasReceivedData) {
      return motorData.fault;
    }
    return motor.starter?.starterParameters?.firstOrNull?.fault ?? 0;
  }

  int _getSignalBars(MotorData? motorData) {
    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale()) {
      return motorData.signalBars;
    }
    final signalStrength = motor.starter?.signalQuality;
    if (signalStrength != null &&
        signalStrength >= 2 &&
        signalStrength <= 31) {
      if (signalStrength >= 2 && signalStrength <= 9) return 1;
      if (signalStrength >= 10 && signalStrength <= 14) return 2;
      if (signalStrength >= 15 && signalStrength <= 19) return 3;
      if (signalStrength >= 20 && signalStrength <= 30) return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF3FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: _goBack,
        ),
        title: Text(
          'Test Run',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: mqttService.dataUpdateNotifier,
          builder: (context, _, __) {
            final motorData = _getMotorData();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Motor Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 8.0, 0.0, 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Motor Header
                          _buildMotorHeader(motorData),
                          const Divider(
                              height: 0,
                              thickness: 1.0,
                              color: Color(0xFFECECEC)),
                          // Voltage Current Values
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                12.0, 0.0, 12.0, 0.0),
                            child: VoltageCurrentValuesCard(
                              motor: motor,
                              mqttService: mqttService,
                            ),
                          ),
                          const Divider(
                              height: 2,
                              thickness: 1.0,
                              color: Color(0xFFECECEC)),
                          // Motor Controls (disabled)
                          MotorControlsRow(
                            motor: motor,
                            motorData: motorData,
                            switchController: _localSwitchController,
                            modeController: _localModeController,
                            onToggleSwitch: (_) {},
                            onModeChange: (_) {},
                            isSwitchDisabled: true,
                            isModeDisabled: true,
                            onNavigateToDetails: () {},
                          ),
                        ].divide(const SizedBox(height: 4.0)),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Status Message (shown during test)
                  if (_isRunning || _isSuccess || _isFailed)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildStatusIcon(),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBackgroundColor(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isRunning)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF004E7E),
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    _statusMessage,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _getStatusTextColor(),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bottom Buttons
                  Column(
                    children: [
                      if (!_isRunning && !_isSuccess)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showTestRunConfirmDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004E7E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isFailed ? 'Retry Test' : 'Test Run',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (_isSuccess) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Redirecting to Dashboard...',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (!_isRunning && !_isSuccess)
                        TextButton(
                          onPressed: _goBack,
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMotorHeader(MotorData? motorData) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    () {
                      final aliasName = _normalizeMotorName(motor.aliasName);
                      final motorName = _normalizeMotorName(motor.name);
                      final displayName =
                          aliasName.isNotEmpty ? aliasName : motorName;
                      return displayName.length > 12
                          ? '${displayName.substring(0, 12)}...'
                          : displayName;
                    }(),
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
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 8.0),
              _buildSignalIcon(motorData),
              if (_faultValue > 0) ...[
                const SizedBox(width: 8.0),
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
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIcon(MotorData? motorData) {
    int bars = _getSignalBars(motorData);

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

  Widget _buildStatusIcon() {
    if (_isRunning) {
      return Lottie.asset(
        'assets/lottie_animations/loading.json',
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        repeat: true,
      );
    } else if (_isSuccess) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          size: 50,
          color: Color(0xFF22C55E),
        ),
      );
    } else if (_isFailed) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline,
          size: 50,
          color: Color(0xFFEF4444),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusBackgroundColor() {
    if (_isSuccess) return const Color(0xFF22C55E).withValues(alpha: 0.1);
    if (_isFailed) return const Color(0xFFEF4444).withValues(alpha: 0.1);
    return const Color(0xFFEBF3FE);
  }

  Color _getStatusTextColor() {
    if (_isSuccess) return const Color(0xFF22C55E);
    if (_isFailed) return const Color(0xFFEF4444);
    return const Color(0xFF004E7E);
  }
}
