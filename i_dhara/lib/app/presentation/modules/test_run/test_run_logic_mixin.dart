import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_card_dialogs.dart';
import 'package:i_dhara/app/presentation/modules/test_run/test_run_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:lottie/lottie.dart';

import '../../../data/services/storages/hive_handler.dart';
import 'test_run_page.dart';

mixin TestRunLogicMixin on State<TestRunPage> {
  late Motor motor;
  late MqttService mqttService;
  bool fromDevices = false;
  bool isLoadingApiData = false;

  bool isFailed = false;
  String failureMessage = '';
  Timer? ackTimer;
  Timer? countdownTimer;
  int remainingSeconds = 0;
  int selectedTimeoutMinutes = 3;
  bool isTestRunning = false;

  // Test run controller for API calls
  final TestRunController testRunController = TestRunController();

  final ValueNotifier<int> countdownNotifier = ValueNotifier(0);
  bool isDialogOpen = false;

  // Connectivity
  final connectivity = Connectivity();
  final ValueNotifier<bool> hasInternet = ValueNotifier(true);

  bool get isTestRunRequired {
    // If coming from devices page, show API data without blocking
    if (fromDevices) {
      return false;
    }
    final motorId = motor.id;
    if (motorId != null && SharedPreference.hasCompletedTestRun(motorId)) {
      return false; // Test run completed, show data
    }
    if (isTestRunning) {
      return false; // Test run in progress, show data
    }
    return true; // Block data until test run starts
  }

  late ValueNotifier<bool> localSwitchController;
  late ValueNotifier<int> localModeController;

  DateTime? testStartTime;

  static const List<String> allowedGroups = ['G01', 'G02'];

  void initLogic() {
    final args = Get.arguments as Map<String, dynamic>;
    motor = args['motor'] as Motor;
    mqttService = args['mqttService'] as MqttService;
    fromDevices = args['fromDevices'] as bool? ?? false;

    final motorData = getMotorData();
    bool initialState;
    int initialMode;

    if (motorData != null && motorData.hasReceivedData) {
      initialState = motorData.state == 1;
      initialMode = motorData.modeIndex ?? 1;
    } else {
      final apiState = motor.state ?? 0;
      initialState = apiState == 1;
      initialMode = getSimplifiedModeIndex(motor.mode ?? 'AUTO') ?? 1;
    }

    localSwitchController = ValueNotifier(initialState);
    localModeController = ValueNotifier(initialMode);

    _initConnectivity();

    if (fromDevices && motor.id != null) {
      _fetchMotorDetails();
    }
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.isNotEmpty) {
      _updateConnectionStatus(connectivityResult.first);
    }
    connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (mounted) {
      hasInternet.value = result != ConnectivityResult.none;
    }
  }

  Future<void> _fetchMotorDetails() async {
    setState(() {
      isLoadingApiData = true;
    });
    HiveHandler.setValue(Hivekeys.motorId, motor.id.toString());
    final response = await MotorsRepositoryImpl().getMotorDetails();
    if (response?.data != null && mounted) {
      final details = response!.data!;
      // Update motor with starterParameters from API
      motor = Motor(
        id: details.id,
        name: details.name,
        hp: details.hp,
        mode: details.mode,
        state: details.state,
        aliasName: details.aliasName,
        location: details.location != null
            ? Location(
                id: details.location!.id,
                name: details.location!.name,
              )
            : null,
        starter: details.starter != null
            ? Starter(
                id: details.starter!.id,
                name: details.starter!.name,
                status: details.starter!.status,
                macAddress: details.starter!.macAddress,
                pcbNumber: details.starter!.pcbNumber,
                signalQuality: details.starter!.signalQuality,
                power: details.starter!.power,
                networkType: details.starter!.networkType,
                starterParameters: details.starter!.starterParameters
                    ?.map((p) => StarterParameter(
                          id: p.id,
                          timeStamp: p.timeStamp,
                          fault: p.fault,
                          faultDescription: p.faultDescription,
                          lineVoltageR: p.lineVoltageR,
                          lineVoltageY: p.lineVoltageY,
                          lineVoltageB: p.lineVoltageB,
                          currentR: p.currentR,
                          currentY: p.currentY,
                          currentB: p.currentB,
                        ))
                    .toList(),
              )
            : null,
      );
      setState(() {
        isLoadingApiData = false;
      });
    } else {
      if (mounted) {
        setState(() {
          isLoadingApiData = false;
        });
      }
    }
  }

  void disposeLogic() {
    ackTimer?.cancel();
    countdownTimer?.cancel();
    countdownNotifier.dispose();
    localSwitchController.dispose();
    localModeController.dispose();
    hasInternet.dispose();
  }

  int? getSimplifiedModeIndex(String motorMode) {
    if (motorMode.toUpperCase().contains('MANUAL')) return 0;
    if (motorMode.toUpperCase().contains('AUTO')) return 1;
    return 1;
  }

  String getMotorIdentifier() {
    if (motor.starter == null) return '';
    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;
    if (mac?.isNotEmpty == true) return mac!;
    if (pcb?.isNotEmpty == true) return pcb!;
    return '';
  }

  String getMotorGroupId() {
    final identifier = getMotorIdentifier();
    if (identifier.isEmpty) return '';

    // ONLY search in allowed groups (G01, G02) - never check G03, G04
    for (final groupId in allowedGroups) {
      final motorData = mqttService.motorDataMap['$identifier-$groupId'];
      // Verify the motor data's groupId also matches allowed groups
      if (motorData != null &&
          (motorData.groupId == null ||
              allowedGroups.contains(motorData.groupId))) {
        return groupId;
      }
    }
    return 'G01';
  }

  bool isGroupAllowed() {
    final identifier = getMotorIdentifier();
    if (identifier.isEmpty) {
      debugPrint('❌ isGroupAllowed: identifier is empty');
      return false;
    }

    // Check if motor has data in blocked groups (G03, G04)
    for (final groupId in ['G03', 'G04']) {
      final motorData = mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null && motorData.hasReceivedData) {
        debugPrint(
            '❌ isGroupAllowed: Motor $identifier has data in blocked group $groupId - TEST RUN NOT ALLOWED');
        return false;
      }
    }

    // Verify motor has data in allowed groups (G01, G02)
    bool hasAllowedGroupData = false;
    for (final groupId in allowedGroups) {
      final motorData = mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) {
        hasAllowedGroupData = true;
        debugPrint(
            '✓ isGroupAllowed: Motor $identifier found in allowed group $groupId');
        break;
      }
    }

    if (!hasAllowedGroupData) {
      debugPrint(
          '⚠️ isGroupAllowed: Motor $identifier has no data in allowed groups (G01, G02)');
    }

    return true;
  }

  String getMotorId() {
    final identifier = getMotorIdentifier();
    if (identifier.isEmpty) return '';
    final groupId = getMotorGroupId();
    return '$identifier-$groupId';
  }

  MotorData? getMotorData() {
    if (motor.starter == null) return null;
    final identifier = getMotorIdentifier();
    if (identifier.isEmpty) return null;

    // ONLY check allowed groups (G01, G02) - completely ignore G03, G04
    for (final groupId in allowedGroups) {
      final motorId = '$identifier-$groupId';
      final data = mqttService.motorDataMap[motorId];

      // Extra validation: ensure the data's groupId matches allowed groups
      if (data != null &&
          data.hasReceivedData == true &&
          data.groupId != null &&
          allowedGroups.contains(data.groupId!)) {
        return data;
      }
    }

    // Fallback: check for non-received data only from allowed groups
    for (final groupId in allowedGroups) {
      final motorId = '$identifier-$groupId';
      final data = mqttService.motorDataMap[motorId];

      // Extra validation: ensure the data's groupId matches allowed groups
      if (data != null &&
          (data.groupId == null || allowedGroups.contains(data.groupId!))) {
        return data;
      }
    }

    return null;
  }

  String getMotorDisplayName({int maxLength = 16}) {
    final aliasName = normalizeMotorName(motor.aliasName);
    final motorName = normalizeMotorName(motor.name);
    final displayName = aliasName.isNotEmpty ? aliasName : motorName;
    if (displayName.isEmpty) return 'Unknown';
    return displayName.length > maxLength
        ? '${displayName.substring(0, maxLength)}...'
        : displayName;
  }

  String normalizeMotorName(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool get isPowerOn {
    final motorData = getMotorData();
    // CRITICAL: Only use power status from allowed groups (G01, G02)
    if (motorData != null &&
        motorData.hasReceivedData &&
        motorData.groupId != null &&
        allowedGroups.contains(motorData.groupId!)) {
      return motorData.power == 1;
    }
    return (motor.starter?.power ?? 0) == 1;
  }

  int get faultValue {
    final motorData = getMotorData();
    // CRITICAL: Only use fault value from allowed groups (G01, G02)
    if (motorData != null &&
        motorData.hasReceivedData &&
        motorData.groupId != null &&
        allowedGroups.contains(motorData.groupId!)) {
      return motorData.fault;
    }
    return motor.starter?.starterParameters?.firstOrNull?.fault ?? 0;
  }

  int getSignalBars(MotorData? motorData) {
    // CRITICAL: Only use signal from allowed groups (G01, G02)
    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale() &&
        motorData.groupId != null &&
        allowedGroups.contains(motorData.groupId!)) {
      return motorData.signalBars;
    }
    final signalStrength = motor.starter?.signalQuality;
    if (signalStrength != null && signalStrength >= 2 && signalStrength <= 31) {
      if (signalStrength >= 2 && signalStrength <= 9) return 1;
      if (signalStrength >= 10 && signalStrength <= 14) return 2;
      if (signalStrength >= 15 && signalStrength <= 19) return 3;
      if (signalStrength >= 20 && signalStrength <= 30) return 4;
    }
    return 0;
  }

  void showTestRunConfirmDialog() {
    MotorCardDialogs.showTestRunConfirmDialog(
      context,
      motor,
      (int timeoutMinutes) {
        selectedTimeoutMinutes = timeoutMinutes;
        startTestRun(timeoutMinutes);
      },
    );
  }

  Future<void> startTestRun(int timeoutMinutes) async {
    final mqttMotorId = getMotorId();
    if (mqttMotorId.isEmpty) {
      debugPrint('❌ Test Run: Motor ID is empty, cannot start test run');
      setState(() {
        isFailed = true;
      });
      return;
    }

    if (!isGroupAllowed()) {
      debugPrint('❌ Test Run: Motor is in G03/G04 group, test run not allowed');
      setState(() {
        isFailed = true;
        failureMessage = 'Test run is only supported for G01 and G02 motors';
      });
      return;
    }

    debugPrint(
        '🚀 Test Run: Starting test run for motor: $mqttMotorId (allowed groups: $allowedGroups)');

    setState(() {
      isFailed = false;
      failureMessage = '';
      isTestRunning = true;
    });

    // Add motor to test run mode (will ignore type 31 and 32)
    mqttService.addTestRunMotor(mqttMotorId);
    debugPrint(
        '✓ Test Run: Motor $mqttMotorId added to test run mode - types 31 and 32 will be ignored');

    // Show loading dialog IMMEDIATELY
    testStartTime = DateTime.now();
    remainingSeconds = timeoutMinutes * 60;
    countdownNotifier.value = remainingSeconds;
    showLoadingDialog(timeoutMinutes);

    // Start countdown timer immediately
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !isDialogOpen) {
        timer.cancel();
        return;
      }
      remainingSeconds--;
      countdownNotifier.value = remainingSeconds;
      if (remainingSeconds <= 0) timer.cancel();
    });

    // Step 1: Call PATCH API with IN_TEST status
    final apiSuccess = await testRunController.startTestRun(motor.id!);

    if (!apiSuccess) {
      // API call failed - close dialog and show error
      closeLoadingDialog();
      countdownTimer?.cancel();

      // Remove motor from test run mode
      mqttService.removeTestRunMotor(mqttMotorId);

      setState(() {
        isFailed = true;
        failureMessage = testRunController.errorMessage.value.isNotEmpty
            ? testRunController.errorMessage.value
            : 'Failed to start test run';
        isTestRunning = false;
      });
      return;
    }

    // Step 2: API successful - now publish the payload
    mqttService.dataUpdateNotifier.addListener(onDataUpdate);

    try {
      await mqttService.publishTestRunCommand(mqttMotorId, 1);

      ackTimer = Timer(Duration(minutes: timeoutMinutes), () {
        if (mounted && isDialogOpen) onAckTimeout();
      });
    } catch (e) {
      debugPrint('Test run command failed: $e');
      closeLoadingDialog();
      countdownTimer?.cancel();

      // Remove motor from test run mode
      mqttService.removeTestRunMotor(mqttMotorId);

      // Call PATCH API with FAILED status since publish failed
      await testRunController.failTestRun(motor.id!);
      setState(() {
        isFailed = true;
        failureMessage = 'Failed to send command';
        isTestRunning = false;
      });
      mqttService.dataUpdateNotifier.removeListener(onDataUpdate);
    }
  }

  void showLoadingDialog(int timeoutMinutes) {
    isDialogOpen = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 400 ? screenWidth * 0.85 : 300.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth < 400 ? 20 : 40,
              vertical: 24,
            ),
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(20),
              child: ValueListenableBuilder<int>(
                valueListenable: countdownNotifier,
                builder: (context, remainingSeconds, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/lottie_animations/loading.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        getMotorDisplayName(maxLength: 10),
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF101828),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FE),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 20,
                              color: Color(0xFF004E7E),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatTime(remainingSeconds),
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004E7E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: cancelTestRun,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF6B7280),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void cancelTestRun() {
    ackTimer?.cancel();
    countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(onDataUpdate);

    // Remove motor from test run mode
    final mqttMotorId = getMotorId();
    if (mqttMotorId.isNotEmpty) {
      mqttService.removeTestRunMotor(mqttMotorId);
      debugPrint('✓ Test Run: Motor $mqttMotorId removed from test run mode');
    }

    closeLoadingDialog();
    setState(() {
      isTestRunning = false;
    });
  }

  void closeLoadingDialog() {
    if (isDialogOpen && mounted) {
      isDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void onDataUpdate() {
    if (!isDialogOpen || testStartTime == null) return;

    if (motor.starter == null) return;

    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;

    // Check all motors that match this motor's MAC or PCB
    for (final entry in mqttService.motorDataMap.entries) {
      final motorData = entry.value;
      final motorId = entry.key;

      // CRITICAL: Block G03 and G04 groups completely in test run
      final groupId = motorData.groupId;
      if (groupId == null || !allowedGroups.contains(groupId)) {
        // Explicitly skip G03, G04, and any other non-allowed groups
        continue;
      }

      // Check if this motor matches our motor (by MAC or PCB)
      final matchesMac = mac != null &&
          mac.isNotEmpty &&
          (motorData.macAddress == mac || motorData.pcbNumber == mac);
      final matchesPcb = pcb != null &&
          pcb.isNotEmpty &&
          (motorData.macAddress == pcb || motorData.pcbNumber == pcb);

      if (!matchesMac && !matchesPcb) continue;

      // Check if ACK was received after test started
      final lastAckTime = mqttService.getLastAckTime(motorId);
      if (lastAckTime != null &&
          lastAckTime.isAfter(testStartTime!) &&
          motorData.hasReceivedData) {
        debugPrint(
            'Test Run: ACK received for $motorId at $lastAckTime (mac=$mac, pcb=$pcb, group=$groupId)');
        onAckReceived();
        return;
      }
    }
  }

  void onAckReceived() {
    ackTimer?.cancel();
    countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(onDataUpdate);

    // Remove motor from test run mode
    final mqttMotorId = getMotorId();
    if (mqttMotorId.isNotEmpty) {
      mqttService.removeTestRunMotor(mqttMotorId);
      debugPrint(
          '✓ Test Run: ACK received - Motor $mqttMotorId removed from test run mode');
    }

    if (motor.id != null) {
      HiveHandler.setValue(Hivekeys.testrunStatus, motor.id);
      SharedPreference.addCompletedTestRunMotor(motor.id!);
    }

    // CRITICAL: Clear any existing pending commands to prevent any retries
    if (mqttMotorId.isNotEmpty) {
      mqttService.clearAllPendingCommandsForMotor(mqttMotorId);
      debugPrint(
          '✓ Test Run: Cleared all pending commands for $mqttMotorId - NO turn-off command will be sent');
    }

    // NOTE: We do NOT send turn-off command after test run completion
    // The motor state is managed by the device itself after test run

    closeLoadingDialog();

    if (mounted) {
      successSnackBar(context, 'Test Run completed successfully');
    }

    // Call PATCH API with COMPLETED status in background (don't wait)
    testRunController.completeTestRun(motor.id!);

    // Navigate IMMEDIATELY based on level
    if (fromDevices) {
      goToDevices();
    } else {
      goToDashboard();
    }
  }

  Future<void> turnOffMotor() async {
    final motorId = getMotorId();
    if (motorId.isNotEmpty) {
      try {
        await mqttService.publishMotorCommand(motorId, 0);
      } catch (e) {
        debugPrint('Failed to turn off motor: $e');
      }
    }
  }

  void onAckTimeout() {
    ackTimer?.cancel();
    countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(onDataUpdate);

    // Remove motor from test run mode
    final mqttMotorId = getMotorId();
    if (mqttMotorId.isNotEmpty) {
      mqttService.removeTestRunMotor(mqttMotorId);
      debugPrint(
          '⚠️ Test Run: Timeout - Motor $mqttMotorId removed from test run mode');
    }

    closeLoadingDialog();

    // Show error snackbar
    if (mounted) {
      errorSnackBar(context, 'No response from the device.');
    }

    // Call PATCH API with FAILED status in background (don't wait)
    testRunController.failTestRun(motor.id!);

    setState(() {
      isFailed = true;
      isTestRunning = false;
      // failureMessage = 'ACK not received. Please check device connection.';
    });
  }

  void goBack() => Get.back();

  void goToDashboard() => Get.offAllNamed(Routes.dashboard);

  void goToDevices() => Get.offAllNamed(Routes.devices);
}
