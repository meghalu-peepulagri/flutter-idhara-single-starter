import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

class DashboardController extends GetxController {
  final motors = <Motor>[].obs;
  final allMotors = <Motor>[].obs;
  final locations = <LocationDropDown>[].obs;

  final isLoading = true.obs;
  var isRefreshing = false.obs;
  final isFiltering = false.obs;
  final isPageLoading = true.obs;

  final selectedLocationId = Rxn<int>();
  final errorMessage = RxnString();

  late MqttService mqttService;
  bool mqttInitialized = false;

  final Map<int, String> _motorIdToGroupId = {};

  @override
  void onInit() {
    super.onInit();
    _loadAllData();
    // fetchMotors();
    // fetchLocationDropDown();
  }

  Future<void> _loadAllData() async {
    try {
      isLoading.value = true;

      await Future.wait([
        fetchMotors(),
        fetchLocationDropDown(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    if (mqttInitialized) {
      mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
      mqttService.dispose();
    }
    super.onClose();
  }

  Future<void> refreshMotors() async {
    isRefreshing.value = true;

    try {
      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        final fetchedMotors = response.data!.records ?? [];
        allMotors.value = fetchedMotors;

        if (selectedLocationId.value != null) {
          motors.value = allMotors
              .where((m) => m.location?.id == selectedLocationId.value)
              .toList();
        } else {
          motors.value = allMotors.toList();
        }
        if (mqttInitialized) {
          final motorMap = <String, Motor>{};

          for (var motor in allMotors) {
            if (motor.starter?.macAddress != null) {
              final mac = motor.starter!.macAddress!;

              for (int i = 1; i <= 4; i++) {
                final groupId = 'G0$i';
                final key = '$mac-$groupId';
                motorMap[key] = motor;
              }
            }
          }
        }

        if (mqttInitialized) {
          _onMqttUpdate();
        }

        motors.refresh();
        allMotors.refresh();
      } else {
        errorMessage.value = 'Failed to refresh motors';
      }
    } catch (e, stackTrace) {
      errorMessage.value = 'Error: $e';
    } finally {
      isRefreshing.value = false;
      debugPrint('🔄 ===== REFRESH COMPLETED =====');
    }
  }

  String _getGroupIdForMotor(Motor motor) {
    if (_motorIdToGroupId.containsKey(motor.id)) {
      return _motorIdToGroupId[motor.id]!;
    }

    return 'G01';
  }

  Future<void> fetchMotors() async {
    try {
      if (!isRefreshing.value) {}

      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;

        final motorMap = <String, Motor>{};
        _motorIdToGroupId.clear();

        for (var motor in allMotors) {
          if (motor.starter?.macAddress != null) {
            final mac = motor.starter!.macAddress!;

            for (int i = 1; i <= 4; i++) {
              final groupId = 'G0$i';
              final key = '$mac-$groupId';
              motorMap[key] = motor;

              if (i == 1) {
                _motorIdToGroupId[motor.id!] = groupId;
              }
            }
          }
        }
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;

        await mqttService.initializeMqttClient();

        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        _onMqttUpdate();
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e, stackTrace) {
      // isLoading.value = false;
      errorMessage.value = 'Error: $e';
    } finally {
      // isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void _onMqttUpdate() {
    int mqttDataCount = 0;
    for (var key in mqttService.motorDataMap.keys) {
      final data = mqttService.motorDataMap[key];
      if (data?.hasReceivedData == true) {
        debugPrint(
            '  ✓ $key: state=${data?.state}, mode=${data?.motorMode}, power=${data?.power}');
        mqttDataCount++;
      }
    }

    int updatedCount = 0;

    for (var motor in allMotors) {
      if (motor.starter?.macAddress == null) continue;

      final mac = motor.starter!.macAddress!;

      bool hasAnyData = false;
      String? mostRecentGroupId;
      DateTime? mostRecentTimestamp;

      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        final key = '$mac-$groupId';
        final motorData = mqttService.motorDataMap[key];

        if (motorData != null && motorData.hasReceivedData) {
          hasAnyData = true;

          final timestamp = mqttService.getLastAckTime(key);
          if (mostRecentTimestamp == null ||
              (timestamp != null && timestamp.isAfter(mostRecentTimestamp))) {
            mostRecentTimestamp = timestamp;
            mostRecentGroupId = groupId;
          }
        }
      }

      if (!hasAnyData) {
        continue;
      }

      if (mostRecentGroupId != null) {
        _motorIdToGroupId[motor.id!] = mostRecentGroupId;
      }

      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        final key = '$mac-$groupId';
        final motorData = mqttService.motorDataMap[key];

        if (motorData == null || !motorData.hasReceivedData) continue;

        if (groupId == mostRecentGroupId) {
          motor.state = motorData.state;
          motor.mode = motorData.motorMode;
        }

        if (motor.starter != null && motorData.power != 0) {
          motor.starter!.power = motorData.power;
        }

        if (motor.starter != null) {
          if (motor.starter!.starterParameters == null) {
            motor.starter!.starterParameters = [];
          }

          if (motor.starter!.starterParameters!.isEmpty) {
            motor.starter!.starterParameters!.add(StarterParameter());
          }

          final params = motor.starter!.starterParameters!.first;

          if (motorData.voltageRed != '0') {
            final newValue = double.tryParse(motorData.voltageRed);
            if (newValue != null && newValue > 0) {
              params.lineVoltageR = newValue;
            }
          }
          if (motorData.voltageYellow != '0') {
            final newValue = double.tryParse(motorData.voltageYellow);
            if (newValue != null && newValue > 0) {
              params.lineVoltageY = newValue;
            }
          }
          if (motorData.voltageBlue != '0') {
            final newValue = double.tryParse(motorData.voltageBlue);
            if (newValue != null && newValue > 0) {
              params.lineVoltageB = newValue;
            }
          }

          if (motorData.currentRed != '0') {
            final newValue = double.tryParse(motorData.currentRed);
            if (newValue != null && newValue > 0) {
              params.currentR = newValue;
            }
          }
          if (motorData.currentYellow != '0') {
            final newValue = double.tryParse(motorData.currentYellow);
            if (newValue != null && newValue > 0) {
              params.currentY = newValue;
            }
          }
          if (motorData.currentBlue != '0') {
            final newValue = double.tryParse(motorData.currentBlue);
            if (newValue != null && newValue > 0) {
              params.currentB = newValue;
            }
          }

          if (motorData.fault != 0) {
            params.fault = motorData.fault;
            debugPrint('    ✓ Updated fault: ${motorData.fault}');
          }

          params.timeStamp = DateTime.now();
        }
      }

      updatedCount++;
    }

    motors.refresh();
    allMotors.refresh();
  }

  Future<void> fetchLocationDropDown() async {
    final response = await LocationRepoImpl().getLocations();
    if (response != null) {
      locations.value = response.data ?? [];
      locations.insert(0, LocationDropDown(id: null, name: 'All'));
    }
  }

  Future<void> filterMotorsByLocation(int? locationId) async {
    selectedLocationId.value = locationId;

    isFiltering.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (locationId == null) {
        motors.value = allMotors.toList();
      } else {
        motors.value =
            allMotors.where((m) => m.location?.id == locationId).toList();
      }

      motors.refresh();
    } finally {
      isFiltering.value = false;
    }
  }

  Future<void> toggleMotor(Motor motor, bool newState) async {
    if (motor.starter?.macAddress == null) {
      return;
    }

    final groupId = _getGroupIdForMotor(motor);
    final motorId = '${motor.starter!.macAddress}-$groupId';

    try {
      await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
    } catch (e) {
      errorMessage.value = 'Failed to toggle motor: $e';
    }
  }

  Future<void> changeMotorMode(Motor motor, int modeIndex) async {
    if (motor.starter?.macAddress == null) {
      return;
    }

    final groupId = _getGroupIdForMotor(motor);
    final motorId = '${motor.starter!.macAddress}-$groupId';

    try {
      await mqttService.publishModeCommand(motorId, modeIndex);
    } catch (e) {
      errorMessage.value = 'Failed to change mode: $e';
    }
  }

  MotorData? getMotorData(Motor motor) {
    if (!mqttInitialized || motor.starter?.macAddress == null) {
      return null;
    }

    final groupId = _getGroupIdForMotor(motor);
    final motorId = '${motor.starter!.macAddress}-$groupId';
    return mqttService.motorDataMap[motorId];
  }
}
