import 'dart:async';

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

    if (fromDevices && motor.id != null) {
      _fetchMotorDetails();
    }
  }

  Future<void> _fetchMotorDetails() async {
    setState(() {
      isLoadingApiData = true;
    });

    SharedPreference.setMotorId(motor.id!);
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

    for (final groupId in allowedGroups) {
      final motorData = mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) return groupId;
    }
    return 'G01';
  }

  bool isGroupAllowed() {
    final identifier = getMotorIdentifier();
    if (identifier.isEmpty) return false;

    for (final groupId in ['G03', 'G04']) {
      final motorData = mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null && motorData.hasReceivedData) return false;
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

    for (final groupId in allowedGroups) {
      final data = mqttService.motorDataMap['$identifier-$groupId'];
      if (data?.hasReceivedData == true) return data;
    }

    for (final groupId in allowedGroups) {
      final data = mqttService.motorDataMap['$identifier-$groupId'];
      if (data != null) return data;
    }
    return null;
  }

  String getMotorDisplayName() {
    final aliasName = normalizeMotorName(motor.aliasName);
    final motorName = normalizeMotorName(motor.name);
    final displayName = aliasName.isNotEmpty ? aliasName : motorName;
    return displayName.length > 16
        ? '${displayName.substring(0, 16)}...'
        : displayName;
  }

  String normalizeMotorName(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool get isPowerOn {
    final motorData = getMotorData();
    if (motorData != null && motorData.hasReceivedData) {
      return motorData.power == 1;
    }
    return (motor.starter?.power ?? 0) == 1;
  }

  int get faultValue {
    final motorData = getMotorData();
    if (motorData != null && motorData.hasReceivedData) {
      return motorData.fault;
    }
    return motor.starter?.starterParameters?.firstOrNull?.fault ?? 0;
  }

  int getSignalBars(MotorData? motorData) {
    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale()) {
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
      setState(() {
        isFailed = true;
      });
      return;
    }

    if (!isGroupAllowed()) {
      setState(() {
        isFailed = true;
        failureMessage = 'Test run is only supported for G01 and G02 motors';
      });
      return;
    }

    setState(() {
      isFailed = false;
      failureMessage = '';
      isTestRunning = true;
    });

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: ValueListenableBuilder<int>(
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
                      getMotorDisplayName(),
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    // const SizedBox(height: 8),
                    // Text(
                    //   'Waiting for response...',
                    //   style: GoogleFonts.dmSans(
                    //     fontSize: 14,
                    //     color: const Color(0xFF6B7280),
                    //   ),
                    // ),
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
        );
      },
    );
  }

  void cancelTestRun() {
    ackTimer?.cancel();
    countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(onDataUpdate);
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

    final identifier = getMotorIdentifier();
    if (identifier.isEmpty) return;

    for (final groupId in allowedGroups) {
      final motorId = '$identifier-$groupId';
      final motorData = mqttService.motorDataMap[motorId];

      if (motorData == null) continue;

      final lastAckTime = mqttService.getLastAckTime(motorId);
      if (lastAckTime != null &&
          lastAckTime.isAfter(testStartTime!) &&
          motorData.hasReceivedData) {
        debugPrint(
            'Test Run: Live data (type 35/41) received for $motorId at $lastAckTime');
        onAckReceived();
        return;
      }
    }
  }

  void onAckReceived() {
    ackTimer?.cancel();
    countdownTimer?.cancel();
    mqttService.dataUpdateNotifier.removeListener(onDataUpdate);

    if (motor.id != null) {
      SharedPreference.addCompletedTestRunMotor(motor.id!);
    }

    turnOffMotor();
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

    closeLoadingDialog();

    // Show error snackbar
    if (mounted) {
      errorSnackBar(
          context, 'ACK not received. Please check device connection.');
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
