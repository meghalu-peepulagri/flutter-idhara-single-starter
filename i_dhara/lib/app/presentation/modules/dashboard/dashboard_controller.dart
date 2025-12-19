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

  // Loading state
  final isLoading = true.obs;
  var isRefreshing = false.obs;
  final isFiltering = false.obs;

  final selectedLocationId = Rxn<int>();
  final errorMessage = RxnString();

  late MqttService mqttService;
  bool mqttInitialized = false;

  // Store the motor-to-groupId mapping
  final Map<int, String> _motorIdToGroupId = {};

  @override
  void onInit() {
    super.onInit();
    fetchMotors();
    fetchLocationDropDown();
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
    debugPrint('🔄 ===== REFRESH STARTED =====');
    isRefreshing.value = true;

    try {
      // Step 1: Fetch fresh API data
      debugPrint('📡 Fetching fresh API data...');
      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        final fetchedMotors = response.data!.records ?? [];
        debugPrint('✅ API returned ${fetchedMotors.length} motors');

        // Step 2: Update motor list with fresh API data
        allMotors.value = fetchedMotors;

        // Apply location filter if active
        if (selectedLocationId.value != null) {
          motors.value = allMotors
              .where((m) => m.location?.id == selectedLocationId.value)
              .toList();
        } else {
          motors.value = allMotors.toList();
        }

        debugPrint('🔄 Motors list updated with API data');

        // Step 3: Update MQTT motor map with new motor references
        if (mqttInitialized) {
          final motorMap = <String, Motor>{};

          for (var motor in allMotors) {
            if (motor.starter?.macAddress != null) {
              final mac = motor.starter!.macAddress!;

              // Keep existing group mappings
              for (int i = 1; i <= 4; i++) {
                final groupId = 'G0$i';
                final key = '$mac-$groupId';
                motorMap[key] = motor;
              }
            }
          }

          debugPrint('🔄 Updated MQTT motor map with fresh motor references');
        }

        // Step 4: Force immediate MQTT data sync to update states
        if (mqttInitialized) {
          debugPrint('🔄 Syncing MQTT data after API refresh...');
          _onMqttUpdate();
        }

        // Step 5: Force UI refresh
        motors.refresh();
        allMotors.refresh();
        debugPrint('✅ UI refreshed with latest data');
      } else {
        errorMessage.value = 'Failed to refresh motors';
        debugPrint('❌ API returned null response');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error refreshing motors: $e');
      debugPrint('StackTrace: $stackTrace');
      errorMessage.value = 'Error: $e';
    } finally {
      isRefreshing.value = false;
      debugPrint('🔄 ===== REFRESH COMPLETED =====');
    }
  }

  String _getGroupIdForMotor(Motor motor) {
    // Return cached mapping if available
    if (_motorIdToGroupId.containsKey(motor.id)) {
      return _motorIdToGroupId[motor.id]!;
    }

    // Default to G01 if no mapping found yet
    return 'G01';
  }

  Future<void> fetchMotors() async {
    try {
      if (!isRefreshing.value) isLoading.value = true;

      debugPrint('📡 Fetching motors from API (initial load)...');
      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;

        debugPrint('✅ Fetched ${allMotors.length} motors from API');

        // Initialize MQTT service with motors
        final motorMap = <String, Motor>{};
        _motorIdToGroupId.clear();

        for (var motor in allMotors) {
          if (motor.starter?.macAddress != null) {
            final mac = motor.starter!.macAddress!;

            // Add motor for all groups G01-G04
            for (int i = 1; i <= 4; i++) {
              final groupId = 'G0$i';
              final key = '$mac-$groupId';
              motorMap[key] = motor;

              // Store the first group as default mapping
              if (i == 1) {
                _motorIdToGroupId[motor.id!] = groupId;
              }

              debugPrint(
                  'Added motor to map: $key - ${motor.name} (ID: ${motor.id})');
            }
          }
        }

        debugPrint(
            '🔌 Initializing MQTT with ${motorMap.length} motor entries');
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;

        // Initialize MQTT connection
        await mqttService.initializeMqttClient();

        // Listen to MQTT updates
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        debugPrint('✅ MQTT service initialized and listener added');

        // Initial sync with MQTT data
        _onMqttUpdate();
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching motors: $e');
      debugPrint('StackTrace: $stackTrace');
      isLoading.value = false;
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void _onMqttUpdate() {
    debugPrint('==== 📡 MQTT Update Received ====');
    debugPrint(
        'MQTT notification value: ${mqttService.dataUpdateNotifier.value}');
    debugPrint('Total motor data entries: ${mqttService.motorDataMap.length}');

    // Debug: Print all MQTT keys with actual data
    int mqttDataCount = 0;
    for (var key in mqttService.motorDataMap.keys) {
      final data = mqttService.motorDataMap[key];
      if (data?.hasReceivedData == true) {
        debugPrint(
            '  ✓ $key: state=${data?.state}, mode=${data?.motorMode}, power=${data?.power}');
        mqttDataCount++;
      }
    }
    debugPrint('Active MQTT data streams: $mqttDataCount');

    // FIXED: Merge data from ALL groups instead of replacing
    int updatedCount = 0;

    for (var motor in allMotors) {
      if (motor.starter?.macAddress == null) continue;

      final mac = motor.starter!.macAddress!;

      // Collect data from all groups for this MAC address
      bool hasAnyData = false;
      String? mostRecentGroupId;
      DateTime? mostRecentTimestamp;

      // Track which group has the most recent update for priority
      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        final key = '$mac-$groupId';
        final motorData = mqttService.motorDataMap[key];

        if (motorData != null && motorData.hasReceivedData) {
          hasAnyData = true;

          // Find the most recently updated group
          final timestamp = mqttService.getLastAckTime(key);
          if (mostRecentTimestamp == null ||
              (timestamp != null && timestamp.isAfter(mostRecentTimestamp))) {
            mostRecentTimestamp = timestamp;
            mostRecentGroupId = groupId;
          }
        }
      }

      if (!hasAnyData) {
        debugPrint(
            '⚠️ No MQTT data found for motor "${motor.name}" (MAC: $mac)');
        continue;
      }

      // Now MERGE data from all groups, prioritizing the most recent
      debugPrint(
          '✓ Merging MQTT data for motor "${motor.name}" (ID: ${motor.id})');
      debugPrint('  Most recent group: $mostRecentGroupId');

      // Update the motor-to-group mapping to the most recent
      if (mostRecentGroupId != null) {
        _motorIdToGroupId[motor.id!] = mostRecentGroupId;
      }

      // Merge data from ALL groups
      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        final key = '$mac-$groupId';
        final motorData = mqttService.motorDataMap[key];

        if (motorData == null || !motorData.hasReceivedData) continue;

        debugPrint('  Merging data from $groupId:');
        debugPrint(
            '    State: ${motorData.state}, Mode: ${motorData.motorMode}, Power: ${motorData.power}');

        // Update state and mode ONLY from the most recent group
        if (groupId == mostRecentGroupId) {
          motor.state = motorData.state;
          motor.mode = motorData.motorMode;
          debugPrint('    ✓ Updated state and mode from most recent group');
        }

        // Merge power from ANY group that has it
        if (motor.starter != null && motorData.power != 0) {
          motor.starter!.power = motorData.power;
          debugPrint('    ✓ Updated power: ${motorData.power}');
        }

        // Ensure starter parameters exist
        if (motor.starter != null) {
          if (motor.starter!.starterParameters == null) {
            motor.starter!.starterParameters = [];
          }

          if (motor.starter!.starterParameters!.isEmpty) {
            motor.starter!.starterParameters!.add(StarterParameter());
          }

          final params = motor.starter!.starterParameters!.first;

          // MERGE voltages - only update if new data is not '0' or if existing is null
          if (motorData.voltageRed != '0') {
            final newValue = double.tryParse(motorData.voltageRed);
            if (newValue != null && newValue > 0) {
              params.lineVoltageR = newValue;
              debugPrint('    ✓ Updated voltageR: $newValue');
            }
          }
          if (motorData.voltageYellow != '0') {
            final newValue = double.tryParse(motorData.voltageYellow);
            if (newValue != null && newValue > 0) {
              params.lineVoltageY = newValue;
              debugPrint('    ✓ Updated voltageY: $newValue');
            }
          }
          if (motorData.voltageBlue != '0') {
            final newValue = double.tryParse(motorData.voltageBlue);
            if (newValue != null && newValue > 0) {
              params.lineVoltageB = newValue;
              debugPrint('    ✓ Updated voltageB: $newValue');
            }
          }

          // MERGE currents - only update if new data is not '0' or if existing is null
          if (motorData.currentRed != '0') {
            final newValue = double.tryParse(motorData.currentRed);
            if (newValue != null && newValue > 0) {
              params.currentR = newValue;
              debugPrint('    ✓ Updated currentR: $newValue');
            }
          }
          if (motorData.currentYellow != '0') {
            final newValue = double.tryParse(motorData.currentYellow);
            if (newValue != null && newValue > 0) {
              params.currentY = newValue;
              debugPrint('    ✓ Updated currentY: $newValue');
            }
          }
          if (motorData.currentBlue != '0') {
            final newValue = double.tryParse(motorData.currentBlue);
            if (newValue != null && newValue > 0) {
              params.currentB = newValue;
              debugPrint('    ✓ Updated currentB: $newValue');
            }
          }

          // Update fault from ANY group that has it
          if (motorData.fault != 0) {
            params.fault = motorData.fault;
            debugPrint('    ✓ Updated fault: ${motorData.fault}');
          }

          params.timeStamp = DateTime.now();
        }
      }

      debugPrint(
          '  Final merged values - Power: ${motor.starter?.power}, State: ${motor.state}, Mode: ${motor.mode}');
      debugPrint(
          '    Voltages: R=${motor.starter?.starterParameters?.first.lineVoltageR}, Y=${motor.starter?.starterParameters?.first.lineVoltageY}, B=${motor.starter?.starterParameters?.first.lineVoltageB}');
      debugPrint(
          '    Currents: R=${motor.starter?.starterParameters?.first.currentR}, Y=${motor.starter?.starterParameters?.first.currentY}, B=${motor.starter?.starterParameters?.first.currentB}');

      updatedCount++;
    }

    debugPrint('✅ Updated $updatedCount motor instances from MQTT data');

    // Force UI refresh for both lists
    motors.refresh();
    allMotors.refresh();
    debugPrint('🔄 UI refresh triggered');
  }

  Future<void> fetchLocationDropDown() async {
    final response = await LocationRepoImpl().getLocations();
    if (response != null) {
      locations.value = response.data ?? [];
      locations.insert(0, LocationDropDown(id: null, name: 'All'));
    }
  }

  // void filterMotorsByLocation(int? locationId) {
  //   selectedLocationId.value = locationId;

  //   isFiltering.value = true;

  //   if (locationId == null) {
  //     motors.value = allMotors.toList();
  //     return;
  //   }

  //   motors.value =
  //       allMotors.where((m) => m.location?.id == locationId).toList();
  // }
  Future<void> filterMotorsByLocation(int? locationId) async {
    selectedLocationId.value = locationId;

    // 🔵 SHOW LOADING
    isFiltering.value = true;

    try {
      // OPTIONAL: If you want fresh API data every time
      // await refreshMotors();

      await Future.delayed(const Duration(milliseconds: 300)); // smooth UX

      if (locationId == null) {
        motors.value = allMotors.toList();
      } else {
        motors.value =
            allMotors.where((m) => m.location?.id == locationId).toList();
      }

      motors.refresh();
    } catch (e) {
      debugPrint('❌ Error filtering motors: $e');
    } finally {
      // 🔵 HIDE LOADING
      isFiltering.value = false;
    }
  }

  Future<void> toggleMotor(Motor motor, bool newState) async {
    if (motor.starter?.macAddress == null) {
      debugPrint('Cannot toggle motor: No MAC address');
      return;
    }

    final groupId = _getGroupIdForMotor(motor);
    final motorId = '${motor.starter!.macAddress}-$groupId';

    debugPrint('Toggling motor: $motorId to state: ${newState ? 1 : 0}');

    try {
      await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
    } catch (e) {
      debugPrint('Failed to toggle motor: $e');
      errorMessage.value = 'Failed to toggle motor: $e';
    }
  }

  Future<void> changeMotorMode(Motor motor, int modeIndex) async {
    if (motor.starter?.macAddress == null) {
      debugPrint('Cannot change mode: No MAC address');
      return;
    }

    final groupId = _getGroupIdForMotor(motor);
    final motorId = '${motor.starter!.macAddress}-$groupId';

    debugPrint('Changing motor mode: $motorId to mode: $modeIndex');

    try {
      await mqttService.publishModeCommand(motorId, modeIndex);
    } catch (e) {
      debugPrint('Failed to change mode: $e');
      errorMessage.value = 'Failed to change mode: $e';
    }
  }

  // Get MQTT data for a specific motor
  MotorData? getMotorData(Motor motor) {
    if (!mqttInitialized || motor.starter?.macAddress == null) {
      return null;
    }

    final groupId = _getGroupIdForMotor(motor);
    final motorId = '${motor.starter!.macAddress}-$groupId';
    return mqttService.motorDataMap[motorId];
  }
}
