// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
// import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
// import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

// class DashboardController extends GetxController {
//   final motors = <Motor>[].obs;
//   final allMotors = <Motor>[].obs;
//   final locations = <LocationDropDown>[].obs;

//   // Loading state
//   final isLoading = true.obs;
//   var isRefreshing = false.obs;
//   final isFiltering = false.obs;

//   final selectedLocationId = Rxn<int>();
//   final errorMessage = RxnString();

//   late MqttService mqttService;
//   bool mqttInitialized = false;

//   // Store the motor-to-groupId mapping
//   final Map<int, String> _motorIdToGroupId = {};

//   @override
//   void onInit() {
//     super.onInit();
//     fetchMotors();
//     fetchLocationDropDown();
//   }

//   @override
//   void onClose() {
//     if (mqttInitialized) {
//       mqttService.dispose();
//     }
//     super.onClose();
//   }

//   Future<void> refreshMotors() async {
//     isRefreshing.value = true;
//     selectedLocationId.value = null;
//     await fetchMotors();
//   }

//   String _getGroupIdForMotor(Motor motor) {
//     // Check if we already have a mapping
//     if (_motorIdToGroupId.containsKey(motor.id)) {
//       return _motorIdToGroupId[motor.id]!;
//     }

//     // Create new mapping based on motor properties
//     // You may need to adjust this logic based on how your system assigns groups
//     // For now, using a simple modulo approach
//     final groupId = 'G0${(motor.id! % 4) + 1}';
//     _motorIdToGroupId[motor.id!] = groupId;

//     debugPrint('Assigned group $groupId to motor ${motor.id} (${motor.name})');
//     return groupId;
//   }

//   Future<void> fetchMotors() async {
//     try {
//       if (!isRefreshing.value) isLoading.value = true;

//       final response = await MotorsRepositoryImpl().getMotors();

//       if (response != null && response.data != null) {
//         allMotors.value = response.data!.records ?? [];
//         motors.value = allMotors;

//         debugPrint('Fetched ${allMotors.length} motors from API');

//         // Initialize MQTT service with motors
//         final motorMap = <String, Motor>{};
//         _motorIdToGroupId.clear(); // Clear old mappings

//         for (var motor in allMotors) {
//           if (motor.starter?.macAddress != null) {
//             final groupId = _getGroupIdForMotor(motor);
//             final key = '${motor.starter!.macAddress}-$groupId';
//             motorMap[key] = motor;
//             debugPrint(
//                 'Added motor to map: $key - ${motor.name} (ID: ${motor.id})');
//           }
//         }

//         debugPrint('Initializing MQTT with ${motorMap.length} motors');
//         mqttService = MqttService(initialMotors: motorMap);
//         mqttInitialized = true;

//         // Initialize MQTT connection
//         await mqttService.initializeMqttClient();

//         // Listen to MQTT updates
//         mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

//         debugPrint('MQTT service initialized and listener added');
//       } else {
//         errorMessage.value = 'Failed to load motors';
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching motors: $e');
//       debugPrint('StackTrace: $stackTrace');
//       isLoading.value = false;
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isLoading.value = false;
//       isRefreshing.value = false;
//     }
//   }

//   void _onMqttUpdate() {
//     debugPrint('==== MQTT Update Received in Dashboard Controller ====');
//     debugPrint(
//         'MQTT notification value: ${mqttService.dataUpdateNotifier.value}');
//     debugPrint('Total motor data entries: ${mqttService.motorDataMap.length}');

//     // Debug: Print all MQTT keys
//     debugPrint('MQTT motorDataMap keys:');
//     for (var key in mqttService.motorDataMap.keys) {
//       final data = mqttService.motorDataMap[key];
//       debugPrint(
//           '  - $key: hasData=${data?.hasReceivedData}, state=${data?.state}');
//     }

//     // Update motor states from MQTT data
//     int updatedCount = 0;
//     for (var motor in motors) {
//       if (motor.starter?.macAddress != null) {
//         final groupId = _getGroupIdForMotor(motor);
//         final key = '${motor.starter!.macAddress}-$groupId';

//         debugPrint('Looking for motor ${motor.name} with key: $key');

//         final motorData = mqttService.motorDataMap[key];

//         if (motorData != null) {
//           if (motorData.hasReceivedData) {
//             debugPrint(
//                 '✓ Found MQTT data for motor ${motor.name} (${motor.id})');
//             debugPrint(
//                 '  State: ${motorData.state}, Mode: ${motorData.motorMode}');

//             motor.state = motorData.state;
//             motor.mode = motorData.motorMode;

//             // Update starter parameters with live data
//             if (motor.starter != null) {
//               motor.starter!.power = motorData.power;

//               if (motor.starter!.starterParameters == null) {
//                 motor.starter!.starterParameters = [];
//               }

//               if (motor.starter!.starterParameters!.isEmpty) {
//                 motor.starter!.starterParameters!.add(StarterParameter());
//               }

//               final params = motor.starter!.starterParameters!.first;
//               params.lineVoltageR = int.tryParse(motorData.voltageRed);
//               params.lineVoltageY = double.tryParse(motorData.voltageYellow);
//               params.lineVoltageB = double.tryParse(motorData.voltageBlue);
//               params.currentR = int.tryParse(motorData.currentRed);
//               params.currentY = int.tryParse(motorData.currentYellow);
//               params.currentB = int.tryParse(motorData.currentBlue);
//               params.fault = motorData.fault;
//               params.timeStamp = DateTime.now();

//               debugPrint(
//                   '  Voltages: R=${params.lineVoltageR}, Y=${params.lineVoltageY}, B=${params.lineVoltageB}');
//               debugPrint(
//                   '  Currents: R=${params.currentR}, Y=${params.currentY}, B=${params.currentB}');
//             }
//             updatedCount++;
//           } else {
//             debugPrint(
//                 '✗ Motor ${motor.name} found but no MQTT data received yet');
//           }
//         } else {
//           debugPrint(
//               '✗ No MQTT data found for motor ${motor.name} with key: $key');
//         }
//       }
//     }

//     debugPrint('Updated $updatedCount motors from MQTT data');

//     // Force UI refresh
//     motors.refresh();
//     debugPrint('Motors list refreshed, triggering UI update');
//   }

//   Future<void> fetchLocationDropDown() async {
//     final response = await LocationRepoImpl().getLocations();
//     if (response != null) {
//       locations.value = response.data ?? [];
//       locations.insert(0, LocationDropDown(id: null, name: 'All'));
//     }
//   }

//   void filterMotorsByLocation(int? locationId) {
//     selectedLocationId.value = locationId;

//     if (locationId == null) {
//       motors.value = allMotors;
//       return;
//     }

//     motors.value =
//         allMotors.where((m) => m.location?.id == locationId).toList();
//   }

//   Future<void> toggleMotor(Motor motor, bool newState) async {
//     if (motor.starter?.macAddress == null) {
//       debugPrint('Cannot toggle motor: No MAC address');
//       return;
//     }

//     final groupId = _getGroupIdForMotor(motor);
//     final motorId = '${motor.starter!.macAddress}-$groupId';

//     debugPrint('Toggling motor: $motorId to state: ${newState ? 1 : 0}');

//     try {
//       await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
//     } catch (e) {
//       debugPrint('Failed to toggle motor: $e');
//       errorMessage.value = 'Failed to toggle motor: $e';
//     }
//   }

//   Future<void> changeMotorMode(Motor motor, int modeIndex) async {
//     if (motor.starter?.macAddress == null) {
//       debugPrint('Cannot change mode: No MAC address');
//       return;
//     }

//     final groupId = _getGroupIdForMotor(motor);
//     final motorId = '${motor.starter!.macAddress}-$groupId';

//     debugPrint('Changing motor mode: $motorId to mode: $modeIndex');

//     try {
//       await mqttService.publishModeCommand(motorId, modeIndex);
//     } catch (e) {
//       debugPrint('Failed to change mode: $e');
//       errorMessage.value = 'Failed to change mode: $e';
//     }
//   }

//   // Get MQTT data for a specific motor
//   MotorData? getMotorData(Motor motor) {
//     if (!mqttInitialized || motor.starter?.macAddress == null) {
//       return null;
//     }

//     final groupId = _getGroupIdForMotor(motor);
//     final motorId = '${motor.starter!.macAddress}-$groupId';
//     return mqttService.motorDataMap[motorId];
//   }
// }//main code

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
      mqttService.dispose();
    }
    super.onClose();
  }

  Future<void> refreshMotors() async {
    isRefreshing.value = true;
    selectedLocationId.value = null;
    await fetchMotors();
  }

  String _getGroupIdForMotor(Motor motor) {
    // Return cached mapping if available
    if (_motorIdToGroupId.containsKey(motor.id)) {
      return _motorIdToGroupId[motor.id]!;
    }

    // Default to G01 if no mapping found yet
    // The actual group will be determined when MQTT data arrives
    return 'G01';
  }

  Future<void> fetchMotors() async {
    try {
      if (!isRefreshing.value) isLoading.value = true;

      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;

        debugPrint('Fetched ${allMotors.length} motors from API');

        // Initialize MQTT service with motors
        // Create entries for all possible groups (G01-G04) for each MAC address
        final motorMap = <String, Motor>{};
        _motorIdToGroupId.clear(); // Clear old mappings

        for (var motor in allMotors) {
          if (motor.starter?.macAddress != null) {
            final mac = motor.starter!.macAddress!;

            // Add motor for all groups G01-G04
            // The MQTT data will determine which group is actually active
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

        debugPrint('Initializing MQTT with ${motorMap.length} motor entries');
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;

        // Initialize MQTT connection
        await mqttService.initializeMqttClient();

        // Listen to MQTT updates
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        debugPrint('MQTT service initialized and listener added');
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching motors: $e');
      debugPrint('StackTrace: $stackTrace');
      isLoading.value = false;
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void _onMqttUpdate() {
    debugPrint('==== MQTT Update Received in Dashboard Controller ====');
    debugPrint(
        'MQTT notification value: ${mqttService.dataUpdateNotifier.value}');
    debugPrint('Total motor data entries: ${mqttService.motorDataMap.length}');

    // Debug: Print all MQTT keys with actual data
    debugPrint('MQTT motorDataMap keys with data:');
    for (var key in mqttService.motorDataMap.keys) {
      final data = mqttService.motorDataMap[key];
      if (data?.hasReceivedData == true) {
        debugPrint('  ✓ $key: state=${data?.state}, mode=${data?.motorMode}');
      }
    }

    // Update motor states from MQTT data
    int updatedCount = 0;
    for (var motor in motors) {
      if (motor.starter?.macAddress == null) continue;

      final mac = motor.starter!.macAddress!;

      // Check all groups to find which one has data
      MotorData? foundData;
      String? foundGroupId;

      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        final key = '$mac-$groupId';
        final motorData = mqttService.motorDataMap[key];

        if (motorData != null && motorData.hasReceivedData) {
          foundData = motorData;
          foundGroupId = groupId;
          break;
        }
      }

      if (foundData != null && foundGroupId != null) {
        debugPrint(
            '✓ Found MQTT data for motor ${motor.name} in group $foundGroupId');
        debugPrint('  State: ${foundData.state}, Mode: ${foundData.motorMode}');

        // Update the mapping to use the correct group
        _motorIdToGroupId[motor.id!] = foundGroupId;

        motor.state = foundData.state;
        motor.mode = foundData.motorMode;

        // Update starter parameters with live data
        if (motor.starter != null) {
          motor.starter!.power = foundData.power;

          if (motor.starter!.starterParameters == null) {
            motor.starter!.starterParameters = [];
          }

          if (motor.starter!.starterParameters!.isEmpty) {
            motor.starter!.starterParameters!.add(StarterParameter());
          }

          final params = motor.starter!.starterParameters!.first;
          params.lineVoltageR = double.tryParse(foundData.voltageRed);
          params.lineVoltageY = double.tryParse(foundData.voltageYellow);
          params.lineVoltageB = double.tryParse(foundData.voltageBlue);
          params.currentR = double.tryParse(foundData.currentRed);
          params.currentY = double.tryParse(foundData.currentYellow);
          params.currentB = double.tryParse(foundData.currentBlue);
          params.fault = foundData.fault;
          params.timeStamp = DateTime.now();

          debugPrint(
              '  Voltages: R=${params.lineVoltageR}, Y=${params.lineVoltageY}, B=${params.lineVoltageB}');
          debugPrint(
              '  Currents: R=${params.currentR}, Y=${params.currentY}, B=${params.currentB}');
        }
        updatedCount++;
      } else {
        debugPrint(
            '✗ No MQTT data found for motor ${motor.name} with MAC: $mac');
      }
    }

    debugPrint('Updated $updatedCount motors from MQTT data');

    // Force UI refresh
    motors.refresh();
    debugPrint('Motors list refreshed, triggering UI update');
  }

  Future<void> fetchLocationDropDown() async {
    final response = await LocationRepoImpl().getLocations();
    if (response != null) {
      locations.value = response.data ?? [];
      locations.insert(0, LocationDropDown(id: null, name: 'All'));
    }
  }

  void filterMotorsByLocation(int? locationId) {
    selectedLocationId.value = locationId;

    if (locationId == null) {
      motors.value = allMotors;
      return;
    }

    motors.value =
        allMotors.where((m) => m.location?.id == locationId).toList();
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
