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

//     // Re-fetch motors from API to get updated data
//     await fetchMotors();

//     // Force UI update after refresh
//     motors.refresh();
//     allMotors.refresh();
//   }

//   String _getGroupIdForMotor(Motor motor) {
//     // Return cached mapping if available
//     if (_motorIdToGroupId.containsKey(motor.id)) {
//       return _motorIdToGroupId[motor.id]!;
//     }

//     // Default to G01 if no mapping found yet
//     return 'G01';
//   }

//   Future<void> fetchMotors() async {
//     try {
//       if (!isRefreshing.value) isLoading.value = true;

//       final response = await MotorsRepositoryImpl().getMotors();

//       if (response != null && response.data != null) {
//         final fetchedMotors = response.data!.records ?? [];

//         debugPrint('Fetched ${fetchedMotors.length} motors from API');

//         // If this is a refresh, merge the new API data with existing MQTT state
//         if (isRefreshing.value && allMotors.isNotEmpty) {
//           // Update existing motors with fresh API data while preserving MQTT updates
//           for (var newMotor in fetchedMotors) {
//             final existingIndex =
//                 allMotors.indexWhere((m) => m.id == newMotor.id);
//             if (existingIndex != -1) {
//               final existingMotor = allMotors[existingIndex];

//               // Preserve MQTT state and mode if available
//               if (existingMotor.state != null) {
//                 newMotor.state = existingMotor.state;
//               }
//               if (existingMotor.mode != null) {
//                 newMotor.mode = existingMotor.mode;
//               }

//               // Update the motor in the list
//               allMotors[existingIndex] = newMotor;
//             } else {
//               // New motor, add it
//               allMotors.add(newMotor);
//             }
//           }

//           // Remove motors that no longer exist
//           allMotors.removeWhere(
//               (motor) => !fetchedMotors.any((m) => m.id == motor.id));
//         } else {
//           // Initial load
//           allMotors.value = fetchedMotors;
//         }

//         // Apply location filter if active
//         if (selectedLocationId.value != null) {
//           motors.value = allMotors
//               .where((m) => m.location?.id == selectedLocationId.value)
//               .toList();
//         } else {
//           motors.value = allMotors.toList();
//         }

//         // Initialize or re-initialize MQTT service
//         final motorMap = <String, Motor>{};

//         if (!mqttInitialized) {
//           _motorIdToGroupId.clear();
//         }

//         for (var motor in allMotors) {
//           if (motor.starter?.macAddress != null) {
//             final mac = motor.starter!.macAddress!;

//             // Add motor for all groups G01-G04
//             for (int i = 1; i <= 4; i++) {
//               final groupId = 'G0$i';
//               final key = '$mac-$groupId';
//               motorMap[key] = motor;

//               // Store the first group as default mapping only if not already mapped
//               if (i == 1 && !_motorIdToGroupId.containsKey(motor.id!)) {
//                 _motorIdToGroupId[motor.id!] = groupId;
//               }

//               debugPrint(
//                   'Motor map entry: $key - ${motor.name} (ID: ${motor.id})');
//             }
//           }
//         }

//         if (!mqttInitialized) {
//           debugPrint('Initializing MQTT with ${motorMap.length} motor entries');
//           mqttService = MqttService(initialMotors: motorMap);
//           mqttInitialized = true;

//           // Initialize MQTT connection
//           await mqttService.initializeMqttClient();

//           // Listen to MQTT updates
//           mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

//           debugPrint('MQTT service initialized and listener added');
//         } else {
//           // Update existing MQTT service with new motor map
//           debugPrint('Updating MQTT motor map with ${motorMap.length} entries');
//           // If your MqttService has an update method, call it here
//           // Otherwise, the existing connections will continue to work
//         }

//         // Immediately sync with latest MQTT data after refresh
//         if (mqttInitialized && isRefreshing.value) {
//           _onMqttUpdate();
//         }
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

//     // Debug: Print all MQTT keys with actual data
//     debugPrint('MQTT motorDataMap keys with data:');
//     for (var key in mqttService.motorDataMap.keys) {
//       final data = mqttService.motorDataMap[key];
//       if (data?.hasReceivedData == true) {
//         debugPrint(
//             '  ✓ $key: state=${data?.state}, mode=${data?.motorMode}, power=${data?.power}');
//       }
//     }

//     // Update motor states from MQTT data
//     int updatedCount = 0;
//     for (var motor in allMotors) {
//       if (motor.starter?.macAddress == null) continue;

//       final mac = motor.starter!.macAddress!;

//       // Check all groups to find which one has data
//       MotorData? foundData;
//       String? foundGroupId;

//       for (int i = 1; i <= 4; i++) {
//         final groupId = 'G0$i';
//         final key = '$mac-$groupId';
//         final motorData = mqttService.motorDataMap[key];

//         if (motorData != null && motorData.hasReceivedData) {
//           foundData = motorData;
//           foundGroupId = groupId;
//           break;
//         }
//       }

//       if (foundData != null && foundGroupId != null) {
//         debugPrint(
//             '✓ Found MQTT data for motor ${motor.name} in group $foundGroupId');
//         debugPrint(
//             '  State: ${foundData.state}, Mode: ${foundData.motorMode}, Power: ${foundData.power}');

//         // Update the mapping to use the correct group
//         _motorIdToGroupId[motor.id!] = foundGroupId;

//         motor.state = foundData.state;
//         motor.mode = foundData.motorMode;

//         // Update starter parameters with live data
//         if (motor.starter != null) {
//           motor.starter!.power = foundData.power;

//           if (motor.starter!.starterParameters == null) {
//             motor.starter!.starterParameters = [];
//           }

//           if (motor.starter!.starterParameters!.isEmpty) {
//             motor.starter!.starterParameters!.add(StarterParameter());
//           }

//           final params = motor.starter!.starterParameters!.first;
//           params.lineVoltageR = double.tryParse(foundData.voltageRed);
//           params.lineVoltageY = double.tryParse(foundData.voltageYellow);
//           params.lineVoltageB = double.tryParse(foundData.voltageBlue);
//           params.currentR = double.tryParse(foundData.currentRed);
//           params.currentY = double.tryParse(foundData.currentYellow);
//           params.currentB = double.tryParse(foundData.currentBlue);
//           params.fault = foundData.fault;
//           params.timeStamp = DateTime.now();

//           debugPrint(
//               '  Voltages: R=${params.lineVoltageR}, Y=${params.lineVoltageY}, B=${params.lineVoltageB}');
//           debugPrint(
//               '  Currents: R=${params.currentR}, Y=${params.currentY}, B=${params.currentB}');
//         }
//         updatedCount++;
//       } else {
//         debugPrint(
//             '✗ No MQTT data found for motor ${motor.name} with MAC: $mac');
//       }
//     }

//     debugPrint('Updated $updatedCount motors from MQTT data');

//     // Force UI refresh for both lists
//     motors.refresh();
//     allMotors.refresh();
//     debugPrint('Motors lists refreshed, triggering UI update');
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
//       motors.value = allMotors.toList();
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
// }

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
//       mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
//       mqttService.dispose();
//     }
//     super.onClose();
//   }

//   Future<void> refreshMotors() async {
//     debugPrint('🔄 ===== REFRESH STARTED =====');
//     isRefreshing.value = true;

//     try {
//       // Step 1: Fetch fresh API data
//       debugPrint('📡 Fetching fresh API data...');
//       final response = await MotorsRepositoryImpl().getMotors();

//       if (response != null && response.data != null) {
//         final fetchedMotors = response.data!.records ?? [];
//         debugPrint('✅ API returned ${fetchedMotors.length} motors');

//         // Step 2: Update motor list with fresh API data
//         allMotors.value = fetchedMotors;

//         // Apply location filter if active
//         if (selectedLocationId.value != null) {
//           motors.value = allMotors
//               .where((m) => m.location?.id == selectedLocationId.value)
//               .toList();
//         } else {
//           motors.value = allMotors.toList();
//         }

//         debugPrint('🔄 Motors list updated with API data');

//         // Step 3: Update MQTT motor map with new motor references
//         if (mqttInitialized) {
//           final motorMap = <String, Motor>{};

//           for (var motor in allMotors) {
//             if (motor.starter?.macAddress != null) {
//               final mac = motor.starter!.macAddress!;

//               // Keep existing group mappings
//               for (int i = 1; i <= 4; i++) {
//                 final groupId = 'G0$i';
//                 final key = '$mac-$groupId';
//                 motorMap[key] = motor;
//               }
//             }
//           }

//           debugPrint('🔄 Updated MQTT motor map with fresh motor references');
//         }

//         // Step 4: Force immediate MQTT data sync to update states
//         if (mqttInitialized) {
//           debugPrint('🔄 Syncing MQTT data after API refresh...');
//           _onMqttUpdate();
//         }

//         // Step 5: Force UI refresh
//         motors.refresh();
//         allMotors.refresh();
//         debugPrint('✅ UI refreshed with latest data');
//       } else {
//         errorMessage.value = 'Failed to refresh motors';
//         debugPrint('❌ API returned null response');
//       }
//     } catch (e, stackTrace) {
//       debugPrint('❌ Error refreshing motors: $e');
//       debugPrint('StackTrace: $stackTrace');
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isRefreshing.value = false;
//       debugPrint('🔄 ===== REFRESH COMPLETED =====');
//     }
//   }

//   String _getGroupIdForMotor(Motor motor) {
//     // Return cached mapping if available
//     if (_motorIdToGroupId.containsKey(motor.id)) {
//       return _motorIdToGroupId[motor.id]!;
//     }

//     // Default to G01 if no mapping found yet
//     return 'G01';
//   }

//   Future<void> fetchMotors() async {
//     try {
//       if (!isRefreshing.value) isLoading.value = true;

//       debugPrint('📡 Fetching motors from API (initial load)...');
//       final response = await MotorsRepositoryImpl().getMotors();

//       if (response != null && response.data != null) {
//         allMotors.value = response.data!.records ?? [];
//         motors.value = allMotors;

//         debugPrint('✅ Fetched ${allMotors.length} motors from API');

//         // Initialize MQTT service with motors
//         final motorMap = <String, Motor>{};
//         _motorIdToGroupId.clear();

//         for (var motor in allMotors) {
//           if (motor.starter?.macAddress != null) {
//             final mac = motor.starter!.macAddress!;

//             // Add motor for all groups G01-G04
//             for (int i = 1; i <= 4; i++) {
//               final groupId = 'G0$i';
//               final key = '$mac-$groupId';
//               motorMap[key] = motor;

//               // Store the first group as default mapping
//               if (i == 1) {
//                 _motorIdToGroupId[motor.id!] = groupId;
//               }

//               debugPrint(
//                   'Added motor to map: $key - ${motor.name} (ID: ${motor.id})');
//             }
//           }
//         }

//         debugPrint(
//             '🔌 Initializing MQTT with ${motorMap.length} motor entries');
//         mqttService = MqttService(initialMotors: motorMap);
//         mqttInitialized = true;

//         // Initialize MQTT connection
//         await mqttService.initializeMqttClient();

//         // Listen to MQTT updates
//         mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

//         debugPrint('✅ MQTT service initialized and listener added');

//         // Initial sync with MQTT data
//         _onMqttUpdate();
//       } else {
//         errorMessage.value = 'Failed to load motors';
//       }
//     } catch (e, stackTrace) {
//       debugPrint('❌ Error fetching motors: $e');
//       debugPrint('StackTrace: $stackTrace');
//       isLoading.value = false;
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isLoading.value = false;
//       isRefreshing.value = false;
//     }
//   }

//   void _onMqttUpdate() {
//     debugPrint('==== 📡 MQTT Update Received ====');
//     debugPrint(
//         'MQTT notification value: ${mqttService.dataUpdateNotifier.value}');
//     debugPrint('Total motor data entries: ${mqttService.motorDataMap.length}');

//     // Debug: Print all MQTT keys with actual data
//     int mqttDataCount = 0;
//     for (var key in mqttService.motorDataMap.keys) {
//       final data = mqttService.motorDataMap[key];
//       if (data?.hasReceivedData == true) {
//         debugPrint(
//             '  ✓ $key: state=${data?.state}, mode=${data?.motorMode}, power=${data?.power}');
//         mqttDataCount++;
//       }
//     }
//     debugPrint('Active MQTT data streams: $mqttDataCount');

//     // FIXED: Update motors by checking ALL groups for each MAC address
//     int updatedCount = 0;

//     for (var motor in allMotors) {
//       if (motor.starter?.macAddress == null) continue;

//       final mac = motor.starter!.macAddress!;

//       // Check all groups (G01-G04) for this MAC address to find ANY data
//       MotorData? latestData;
//       String? latestGroupId;

//       for (int i = 1; i <= 4; i++) {
//         final groupId = 'G0$i';
//         final key = '$mac-$groupId';
//         final motorData = mqttService.motorDataMap[key];

//         if (motorData != null && motorData.hasReceivedData) {
//           // Use the data from ANY group that has received data
//           latestData = motorData;
//           latestGroupId = groupId;

//           debugPrint(
//               '✓ Found MQTT data for motor "${motor.name}" (ID: ${motor.id}) in group $groupId');
//           debugPrint(
//               '  State: ${motorData.state}, Mode: ${motorData.motorMode}, Power: ${motorData.power}');

//           // Update the motor-to-group mapping
//           _motorIdToGroupId[motor.id!] = groupId;

//           // Update motor state and mode
//           motor.state = motorData.state;
//           motor.mode = motorData.motorMode;

//           // Update starter parameters with live data
//           if (motor.starter != null) {
//             motor.starter!.power = motorData.power;

//             if (motor.starter!.starterParameters == null) {
//               motor.starter!.starterParameters = [];
//             }

//             if (motor.starter!.starterParameters!.isEmpty) {
//               motor.starter!.starterParameters!.add(StarterParameter());
//             }

//             final params = motor.starter!.starterParameters!.first;

//             // Only update values if they're not zero (to preserve existing data)
//             if (motorData.voltageRed != '0' || params.lineVoltageR == null) {
//               params.lineVoltageR = double.tryParse(motorData.voltageRed);
//             }
//             if (motorData.voltageYellow != '0' || params.lineVoltageY == null) {
//               params.lineVoltageY = double.tryParse(motorData.voltageYellow);
//             }
//             if (motorData.voltageBlue != '0' || params.lineVoltageB == null) {
//               params.lineVoltageB = double.tryParse(motorData.voltageBlue);
//             }
//             if (motorData.currentRed != '0' || params.currentR == null) {
//               params.currentR = double.tryParse(motorData.currentRed);
//             }
//             if (motorData.currentYellow != '0' || params.currentY == null) {
//               params.currentY = double.tryParse(motorData.currentYellow);
//             }
//             if (motorData.currentBlue != '0' || params.currentB == null) {
//               params.currentB = double.tryParse(motorData.currentBlue);
//             }

//             params.fault = motorData.fault;
//             params.timeStamp = DateTime.now();

//             debugPrint(
//                 '  Updated Voltages: R=${params.lineVoltageR}, Y=${params.lineVoltageY}, B=${params.lineVoltageB}');
//             debugPrint(
//                 '  Updated Currents: R=${params.currentR}, Y=${params.currentY}, B=${params.currentB}');
//           }

//           updatedCount++;
//           // Don't break - continue checking other groups to get the most complete data
//         }
//       }

//       if (latestData == null) {
//         debugPrint(
//             '⚠️ No MQTT data found for motor "${motor.name}" (MAC: $mac)');
//       }
//     }

//     debugPrint('✅ Updated $updatedCount motor instances from MQTT data');

//     // Force UI refresh for both lists
//     motors.refresh();
//     allMotors.refresh();
//     debugPrint('🔄 UI refresh triggered');
//   }

//   Future<void> fetchLocationDropDown() async {
//     final response = await LocationRepoImpl().getLocations();
//     if (response != null) {
//       locations.value = response.data ?? [];
//       // if (locations.isNotEmpty && selectedLocationId.value == null) {
//       //   selectedLocationId.value = locations.first.id;
//       // }
//       locations.insert(0, LocationDropDown(id: null, name: 'All'));
//     }
//   }

//   void filterMotorsByLocation(int? locationId) {
//     selectedLocationId.value = locationId;

//     if (locationId == null) {
//       motors.value = allMotors.toList();
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
// }
//updated code

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

  void filterMotorsByLocation(int? locationId) {
    selectedLocationId.value = locationId;

    if (locationId == null) {
      motors.value = allMotors.toList();
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
