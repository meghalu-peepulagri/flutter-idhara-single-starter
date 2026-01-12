// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
// import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
// import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
// import 'package:i_dhara/app/data/services/weather_service/permission_handler.dart';

// class DashboardController extends GetxController {
//   final motors = <Motor>[].obs;
//   final allMotors = <Motor>[].obs;
//   final locations = <LocationDropDown>[].obs;

//   final isLoading = true.obs;
//   var isRefreshing = false.obs;
//   final isFiltering = false.obs;
//   final isPageLoading = true.obs;
//   final isLoadingLocations = false.obs;
//   final hasLocationPermission = false.obs;
//   final isLoadingMore = false.obs; // New: For pagination loading

//   final selectedLocationId = Rxn<int>();
//   final errorMessage = RxnString();

//   late MqttService mqttService;
//   bool mqttInitialized = false;

//   final Map<int, String> _motorIdToGroupId = {};
//   final connectivity = Connectivity();
//   var hasInternet = true.obs;
//   var totalPages = 1.obs;
//   var currentPage = 0.obs; // Changed from 0 to 1
//   var page = 1.obs;
//   var limit = 10.obs;
//   Data? response;

//   @override
//   void onInit() {
//     super.onInit();
//     _initConnectivity();
//     _loadAllData();
//     _requestPermissionAndLoad();
//     final args = Get.arguments;
//     if (args?['refresh'] == true) {
//       fetchMotors();
//     }
//   }

//   Future<void> _requestPermissionAndLoad() async {
//     hasLocationPermission.value =
//         await PermissionService.requestLocationPermission();
//   }

//   void _initConnectivity() async {
//     final connectivityResult = await connectivity.checkConnectivity();
//     _updateConnectionStatus(connectivityResult.first);
//     connectivity.onConnectivityChanged.listen((results) {
//       _updateConnectionStatus(results.first);
//     });
//   }

//   void _updateConnectionStatus(ConnectivityResult result) {
//     hasInternet.value = result != ConnectivityResult.none;
//   }

//   Future<void> _loadAllData() async {
//     try {
//       isLoading.value = true;

//       await Future.wait([
//         fetchMotors(),
//         fetchLocationDropDown(),
//       ]);
//     } finally {
//       isLoading.value = false;
//     }
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
//     isRefreshing.value = true;
//     page.value = 1; // Reset to first page
//     currentPage.value = 1;

//     try {
//       final response =
//           await MotorsRepositoryImpl().getMotors(page.value, limit.value);

//       if (response != null && response.data != null) {
//         this.response = response.data;
//         final fetchedMotors = response.data!.records ?? [];
//         allMotors.value = fetchedMotors;

//         // Apply location filter
//         if (selectedLocationId.value != null) {
//           motors.value = allMotors
//               .where((m) => m.location?.id == selectedLocationId.value)
//               .toList();
//         } else {
//           motors.value = allMotors.toList();
//         }

//         // Update pagination info
//         currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
//         totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

//         // Update MQTT service with new motor data
//         if (mqttInitialized) {
//           final motorMap = <String, Motor>{};
//           _motorIdToGroupId.clear();

//           for (var motor in allMotors) {
//             if (motor.starter != null) {
//               final mac = motor.starter!.macAddress;
//               final pcb = motor.starter!.pcbNumber;

//               for (int i = 1; i <= 4; i++) {
//                 final groupId = 'G0$i';

//                 if (mac != null && mac.isNotEmpty) {
//                   final macKey = '$mac-$groupId';
//                   motorMap[macKey] = motor;

//                   if (i == 1) {
//                     _motorIdToGroupId[motor.id!] = groupId;
//                   }
//                 }

//                 if (pcb != null && pcb.isNotEmpty) {
//                   final pcbKey = '$pcb-$groupId';
//                   motorMap[pcbKey] = motor;

//                   if (i == 1 && (mac == null || mac.isEmpty)) {
//                     _motorIdToGroupId[motor.id!] = groupId;
//                   }
//                 }
//               }
//             }
//           }

//           mqttService.updateMotors(motorMap);
//           await mqttService.resubscribeToTopics();
//           await Future.delayed(const Duration(milliseconds: 500));
//           _onMqttUpdate();
//         }

//         motors.refresh();
//         allMotors.refresh();
//       } else {
//         errorMessage.value = 'Failed to refresh motors';
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   // New: Load more motors for pagination
//   Future<void> loadMoreMotors() async {
//     if (isLoadingMore.value || currentPage.value >= totalPages.value) {
//       return; // Already loading or no more pages
//     }

//     isLoadingMore.value = true;

//     try {
//       page.value = currentPage.value + 1;
//       final response =
//           await MotorsRepositoryImpl().getMotors(page.value, limit.value);

//       if (response != null && response.data != null) {
//         this.response = response.data;
//         final fetchedMotors = response.data!.records ?? [];

//         // Add new motors to existing list
//         allMotors.addAll(fetchedMotors);

//         // Apply location filter
//         if (selectedLocationId.value != null) {
//           motors.value = allMotors
//               .where((m) => m.location?.id == selectedLocationId.value)
//               .toList();
//         } else {
//           motors.value = allMotors.toList();
//         }

//         // Update pagination info
//         currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
//         totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

//         // Update MQTT service with new motors
//         if (mqttInitialized) {
//           final motorMap = <String, Motor>{};

//           for (var motor in allMotors) {
//             if (motor.starter != null) {
//               final mac = motor.starter!.macAddress;
//               final pcb = motor.starter!.pcbNumber;

//               for (int i = 1; i <= 4; i++) {
//                 final groupId = 'G0$i';

//                 if (mac != null && mac.isNotEmpty) {
//                   final macKey = '$mac-$groupId';
//                   motorMap[macKey] = motor;

//                   if (i == 1) {
//                     _motorIdToGroupId[motor.id!] = groupId;
//                   }
//                 }

//                 if (pcb != null && pcb.isNotEmpty) {
//                   final pcbKey = '$pcb-$groupId';
//                   motorMap[pcbKey] = motor;

//                   if (i == 1 && (mac == null || mac.isEmpty)) {
//                     _motorIdToGroupId[motor.id!] = groupId;
//                   }
//                 }
//               }
//             }
//           }

//           mqttService.updateMotors(motorMap);
//           _onMqttUpdate();
//         }

//         motors.refresh();
//         allMotors.refresh();
//       }
//     } catch (e) {
//       errorMessage.value = 'Error loading more: $e';
//     } finally {
//       isLoadingMore.value = false;
//     }
//   }

//   String _getGroupIdForMotor(Motor motor) {
//     if (_motorIdToGroupId.containsKey(motor.id)) {
//       return _motorIdToGroupId[motor.id]!;
//     }
//     return 'G01';
//   }

//   Future<void> fetchMotors() async {
//     try {
//       final response =
//           await MotorsRepositoryImpl().getMotors(page.value, limit.value);

//       if (response != null && response.data != null) {
//         this.response = response.data;
//         allMotors.value = response.data!.records ?? [];
//         motors.value = allMotors;

//         // Update pagination info
//         currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
//         totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

//         final motorMap = <String, Motor>{};
//         _motorIdToGroupId.clear();

//         for (var motor in allMotors) {
//           if (motor.starter != null) {
//             final mac = motor.starter!.macAddress;
//             final pcb = motor.starter!.pcbNumber;

//             for (int i = 1; i <= 4; i++) {
//               final groupId = 'G0$i';

//               if (mac != null && mac.isNotEmpty) {
//                 final macKey = '$mac-$groupId';
//                 motorMap[macKey] = motor;

//                 if (i == 1) {
//                   _motorIdToGroupId[motor.id!] = groupId;
//                 }
//               }

//               if (pcb != null && pcb.isNotEmpty) {
//                 final pcbKey = '$pcb-$groupId';
//                 motorMap[pcbKey] = motor;

//                 if (i == 1 && (mac == null || mac.isEmpty)) {
//                   _motorIdToGroupId[motor.id!] = groupId;
//                 }
//               }
//             }
//           }
//         }

//         mqttService = MqttService(initialMotors: motorMap);
//         mqttInitialized = true;

//         await mqttService.initializeMqttClient();
//         mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

//         if (motorMap.isNotEmpty) {
//           _onMqttUpdate();
//         }
//       } else {
//         errorMessage.value = 'Failed to load motors';
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   void _onMqttUpdate() {
//     int mqttDataCount = 0;
//     for (var key in mqttService.motorDataMap.keys) {
//       final data = mqttService.motorDataMap[key];
//       if (data?.hasReceivedData == true) {
//         mqttDataCount++;
//       }
//     }

//     print(' Total MQTT data entries: $mqttDataCount');

//     for (var motor in allMotors) {
//       if (motor.starter == null) continue;

//       final mac = motor.starter!.macAddress;
//       final pcb = motor.starter!.pcbNumber;
//       final currentGroupId = _getGroupIdForMotor(motor);

//       String? currentKey;
//       MotorData? currentMotorData;

//       for (int i = 1; i <= 4; i++) {
//         if (currentMotorData != null) break;
//         final groupId = 'G0$i';

//         if (mac != null && mac.isNotEmpty) {
//           final key = '$mac-$groupId';
//           final data = mqttService.motorDataMap[key];
//           if (data?.hasReceivedData == true) {
//             currentMotorData = data;
//             break;
//           }
//         }

//         if (pcb != null && pcb.isNotEmpty) {
//           final key = '$pcb-$groupId';
//           final data = mqttService.motorDataMap[key];
//           if (data?.hasReceivedData == true) {
//             currentMotorData = data;
//             break;
//           }
//         }
//       }

//       if (currentMotorData != null && currentMotorData.hasReceivedData) {
//         motor.state = currentMotorData.state;
//         motor.mode = currentMotorData.motorMode;

//         if (currentMotorData.power != 0 && motor.starter != null) {
//           motor.starter!.power = currentMotorData.power;
//         }

//         if (motor.starter != null) {
//           if (motor.starter!.starterParameters == null) {
//             motor.starter!.starterParameters = [];
//           }

//           if (motor.starter!.starterParameters!.isEmpty) {
//             motor.starter!.starterParameters!.add(StarterParameter());
//           }

//           final params = motor.starter!.starterParameters!.first;

//           if (currentMotorData.voltageRed != '0') {
//             final newValue = double.tryParse(currentMotorData.voltageRed);
//             if (newValue != null && newValue > 0) {
//               params.lineVoltageR = newValue;
//             }
//           }
//           if (currentMotorData.voltageYellow != '0') {
//             final newValue = double.tryParse(currentMotorData.voltageYellow);
//             if (newValue != null && newValue > 0) {
//               params.lineVoltageY = newValue;
//             }
//           }
//           if (currentMotorData.voltageBlue != '0') {
//             final newValue = double.tryParse(currentMotorData.voltageBlue);
//             if (newValue != null && newValue > 0) {
//               params.lineVoltageB = newValue;
//             }
//           }

//           if (currentMotorData.currentRed != '0') {
//             final newValue = double.tryParse(currentMotorData.currentRed);
//             if (newValue != null && newValue > 0) {
//               params.currentR = newValue;
//             }
//           }
//           if (currentMotorData.currentYellow != '0') {
//             final newValue = double.tryParse(currentMotorData.currentYellow);
//             if (newValue != null && newValue > 0) {
//               params.currentY = newValue;
//             }
//           }
//           if (currentMotorData.currentBlue != '0') {
//             final newValue = double.tryParse(currentMotorData.currentBlue);
//             if (newValue != null && newValue > 0) {
//               params.currentB = newValue;
//             }
//           }

//           if (currentMotorData.fault != 0) {
//             params.fault = currentMotorData.fault;
//           }

//           params.timeStamp = DateTime.now();
//         }
//       } else {
//         print(' No MQTT data for current group, keeping API data');
//       }
//     }

//     motors.refresh();
//     allMotors.refresh();
//   }

//   Future<void> fetchLocationDropDown() async {
//     try {
//       isLoadingLocations.value = true;

//       final response = await LocationRepoImpl().getLocations();

//       if (response != null) {
//         locations.value = response.data ?? [];
//         locations.insert(0, LocationDropDown(id: null, name: 'All'));
//       }
//     } catch (e) {
//       print('Error fetching locations: $e');
//     } finally {
//       isLoadingLocations.value = false;
//     }
//   }

//   Future<void> filterMotorsByLocation(int? locationId) async {
//     selectedLocationId.value = locationId;
//     isFiltering.value = true;

//     try {
//       await Future.delayed(const Duration(milliseconds: 300));

//       if (locationId == null) {
//         motors.value = allMotors.toList();
//       } else {
//         motors.value =
//             allMotors.where((m) => m.location?.id == locationId).toList();
//       }

//       motors.refresh();
//     } finally {
//       isFiltering.value = false;
//     }
//   }

//   Future<void> toggleMotor(Motor motor, bool newState) async {
//     if (motor.starter == null) {
//       return;
//     }

//     final groupId = _getGroupIdForMotor(motor);

//     String? identifier;
//     if (motor.starter!.macAddress != null &&
//         motor.starter!.macAddress!.isNotEmpty) {
//       identifier = motor.starter!.macAddress;
//     } else if (motor.starter!.pcbNumber != null &&
//         motor.starter!.pcbNumber!.isNotEmpty) {
//       identifier = motor.starter!.pcbNumber;
//     }

//     if (identifier == null) {
//       return;
//     }

//     final motorId = '$identifier-$groupId';

//     try {
//       await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
//     } catch (e) {
//       errorMessage.value = 'Failed to toggle motor: $e';
//     }
//   }

//   Future<void> changeMotorMode(Motor motor, int modeIndex) async {
//     if (motor.starter == null) {
//       return;
//     }

//     final groupId = _getGroupIdForMotor(motor);

//     String? identifier;
//     if (motor.starter!.macAddress != null &&
//         motor.starter!.macAddress!.isNotEmpty) {
//       identifier = motor.starter!.macAddress;
//     } else if (motor.starter!.pcbNumber != null &&
//         motor.starter!.pcbNumber!.isNotEmpty) {
//       identifier = motor.starter!.pcbNumber;
//     }

//     if (identifier == null) {
//       return;
//     }

//     final motorId = '$identifier-$groupId';

//     try {
//       await mqttService.publishModeCommand(motorId, modeIndex);
//     } catch (e) {
//       errorMessage.value = 'Failed to change mode: $e';
//     }
//   }

//   MotorData? getMotorData(Motor motor) {
//     if (!mqttInitialized || motor.starter?.macAddress == null) {
//       return null;
//     }

//     final groupId = _getGroupIdForMotor(motor);
//     final motorId = '${motor.starter!.macAddress}-$groupId';
//     return mqttService.motorDataMap[motorId];
//   }
// }

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
// import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
// import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
// import 'package:i_dhara/app/data/services/weather_service/permission_handler.dart';

// class DashboardController extends GetxController {
//   final motors = <Motor>[].obs;
//   final allMotors = <Motor>[].obs;
//   final locations = <LocationDropDown>[].obs;

//   final isLoading = true.obs;
//   var isRefreshing = false.obs;
//   final isFiltering = false.obs;
//   final isPageLoading = true.obs;
//   final isLoadingLocations = false.obs;
//   final hasLocationPermission = false.obs;
//   final isLoadingMore = false.obs;

//   final selectedLocationId = Rxn<int>();
//   final errorMessage = RxnString();

//   late MqttService mqttService;
//   bool mqttInitialized = false;

//   final Map<int, String> _motorIdToGroupId = {};
//   final connectivity = Connectivity();
//   var hasInternet = true.obs;
//   var totalPages = 1.obs;
//   var currentPage = 0.obs;
//   var page = 1.obs;
//   var limit = 10.obs;
//   Data? response;

//   @override
//   void onInit() {
//     super.onInit();
//     _initConnectivity();
//     _loadAllData();
//     _requestPermissionAndLoad();
//     final args = Get.arguments;
//     if (args?['refresh'] == true) {
//       fetchMotors();
//     }
//   }

//   Future<void> _requestPermissionAndLoad() async {
//     hasLocationPermission.value =
//         await PermissionService.requestLocationPermission();
//   }

//   void _initConnectivity() async {
//     final connectivityResult = await connectivity.checkConnectivity();
//     _updateConnectionStatus(connectivityResult.first);
//     connectivity.onConnectivityChanged.listen((results) {
//       _updateConnectionStatus(results.first);
//     });
//   }

//   void _updateConnectionStatus(ConnectivityResult result) {
//     hasInternet.value = result != ConnectivityResult.none;
//   }

//   Future<void> _loadAllData() async {
//     try {
//       isLoading.value = true;

//       await Future.wait([
//         fetchMotors(),
//         fetchLocationDropDown(),
//       ]);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   @override
//   void onClose() {
//     if (mqttInitialized) {
//       mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
//       mqttService.dispose();
//     }
//     super.onClose();
//   }

//   // FIXED: Complete motor map rebuild
//   Map<String, Motor> _buildMotorMap(List<Motor> motorsList) {
//     final motorMap = <String, Motor>{};
//     _motorIdToGroupId.clear();

//     for (var motor in motorsList) {
//       if (motor.starter != null) {
//         final mac = motor.starter!.macAddress;
//         final pcb = motor.starter!.pcbNumber;

//         for (int i = 1; i <= 4; i++) {
//           final groupId = 'G0$i';

//           if (mac != null && mac.isNotEmpty) {
//             final macKey = '$mac-$groupId';
//             motorMap[macKey] = motor;

//             if (i == 1) {
//               _motorIdToGroupId[motor.id!] = groupId;
//             }
//           }

//           if (pcb != null && pcb.isNotEmpty) {
//             final pcbKey = '$pcb-$groupId';
//             motorMap[pcbKey] = motor;

//             if (i == 1 && (mac == null || mac.isEmpty)) {
//               _motorIdToGroupId[motor.id!] = groupId;
//             }
//           }
//         }
//       }
//     }

//     return motorMap;
//   }

//   Future<void> refreshMotors() async {
//     isRefreshing.value = true;
//     page.value = 1;
//     currentPage.value = 1;

//     try {
//       final response =
//           await MotorsRepositoryImpl().getMotors(page.value, limit.value);

//       if (response != null && response.data != null) {
//         this.response = response.data;
//         final fetchedMotors = response.data!.records ?? [];
//         allMotors.value = fetchedMotors;

//         if (selectedLocationId.value != null) {
//           motors.value = allMotors
//               .where((m) => m.location?.id == selectedLocationId.value)
//               .toList();
//         } else {
//           motors.value = allMotors.toList();
//         }

//         currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
//         totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

//         // FIXED: Rebuild complete motor map and update MQTT
//         if (mqttInitialized) {
//           final motorMap = _buildMotorMap(allMotors);
//           mqttService.updateMotors(motorMap);
//           await mqttService.resubscribeToTopics();
//           await Future.delayed(const Duration(milliseconds: 500));
//           _onMqttUpdate();
//         }

//         motors.refresh();
//         allMotors.refresh();
//       } else {
//         errorMessage.value = 'Failed to refresh motors';
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   // FIXED: Load more motors with proper MQTT update
//   Future<void> loadMoreMotors() async {
//     if (isLoadingMore.value || currentPage.value >= totalPages.value) {
//       return;
//     }

//     isLoadingMore.value = true;

//     try {
//       page.value = currentPage.value + 1;
//       final response =
//           await MotorsRepositoryImpl().getMotors(page.value, limit.value);

//       if (response != null && response.data != null) {
//         this.response = response.data;
//         final fetchedMotors = response.data!.records ?? [];

//         // Add new motors to existing list
//         allMotors.addAll(fetchedMotors);

//         if (selectedLocationId.value != null) {
//           motors.value = allMotors
//               .where((m) => m.location?.id == selectedLocationId.value)
//               .toList();
//         } else {
//           motors.value = allMotors.toList();
//         }

//         currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
//         totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

//         // FIXED: Rebuild ENTIRE motor map including new motors
//         if (mqttInitialized) {
//           final motorMap = _buildMotorMap(allMotors);

//           // Update MQTT service with complete motor map
//           mqttService.updateMotors(motorMap);

//           // Subscribe to new topics
//           await mqttService.resubscribeToTopics();

//           // Force update
//           await Future.delayed(const Duration(milliseconds: 300));
//           _onMqttUpdate();
//         }

//         motors.refresh();
//         allMotors.refresh();
//       }
//     } catch (e) {
//       errorMessage.value = 'Error loading more: $e';
//       print('Error loading more motors: $e');
//     } finally {
//       isLoadingMore.value = false;
//     }
//   }

//   String _getGroupIdForMotor(Motor motor) {
//     if (_motorIdToGroupId.containsKey(motor.id)) {
//       return _motorIdToGroupId[motor.id]!;
//     }
//     return 'G01';
//   }

//   Future<void> fetchMotors() async {
//     try {
//       final response =
//           await MotorsRepositoryImpl().getMotors(page.value, limit.value);

//       if (response != null && response.data != null) {
//         this.response = response.data;
//         allMotors.value = response.data!.records ?? [];
//         motors.value = allMotors;

//         currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
//         totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

//         // Build motor map
//         final motorMap = _buildMotorMap(allMotors);

//         mqttService = MqttService(initialMotors: motorMap);
//         mqttInitialized = true;

//         await mqttService.initializeMqttClient();
//         mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

//         if (motorMap.isNotEmpty) {
//           _onMqttUpdate();
//         }
//       } else {
//         errorMessage.value = 'Failed to load motors';
//       }
//     } catch (e) {
//       errorMessage.value = 'Error: $e';
//       print('Error fetching motors: $e');
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   void _onMqttUpdate() {
//     int mqttDataCount = 0;
//     for (var key in mqttService.motorDataMap.keys) {
//       final data = mqttService.motorDataMap[key];
//       if (data?.hasReceivedData == true) {
//         mqttDataCount++;
//       }
//     }

//     print('✓ Total MQTT data entries: $mqttDataCount');

//     for (var motor in allMotors) {
//       if (motor.starter == null) continue;

//       final mac = motor.starter!.macAddress;
//       final pcb = motor.starter!.pcbNumber;
//       final currentGroupId = _getGroupIdForMotor(motor);

//       MotorData? currentMotorData;

//       // Check all groups for MQTT data
//       for (int i = 1; i <= 4; i++) {
//         if (currentMotorData != null) break;
//         final groupId = 'G0$i';

//         if (mac != null && mac.isNotEmpty) {
//           final key = '$mac-$groupId';
//           final data = mqttService.motorDataMap[key];
//           if (data?.hasReceivedData == true) {
//             currentMotorData = data;
//             break;
//           }
//         }

//         if (pcb != null && pcb.isNotEmpty) {
//           final key = '$pcb-$groupId';
//           final data = mqttService.motorDataMap[key];
//           if (data?.hasReceivedData == true) {
//             currentMotorData = data;
//             break;
//           }
//         }
//       }

//       if (currentMotorData != null && currentMotorData.hasReceivedData) {
//         motor.state = currentMotorData.state;
//         motor.mode = currentMotorData.motorMode;

//         if (currentMotorData.power != 0 && motor.starter != null) {
//           motor.starter!.power = currentMotorData.power;
//         }

//         if (motor.starter != null) {
//           if (motor.starter!.starterParameters == null) {
//             motor.starter!.starterParameters = [];
//           }

//           if (motor.starter!.starterParameters!.isEmpty) {
//             motor.starter!.starterParameters!.add(StarterParameter());
//           }

//           final params = motor.starter!.starterParameters!.first;

//           if (currentMotorData.voltageRed != '0') {
//             final newValue = double.tryParse(currentMotorData.voltageRed);
//             if (newValue != null && newValue > 0) {
//               params.lineVoltageR = newValue;
//             }
//           }
//           if (currentMotorData.voltageYellow != '0') {
//             final newValue = double.tryParse(currentMotorData.voltageYellow);
//             if (newValue != null && newValue > 0) {
//               params.lineVoltageY = newValue;
//             }
//           }
//           if (currentMotorData.voltageBlue != '0') {
//             final newValue = double.tryParse(currentMotorData.voltageBlue);
//             if (newValue != null && newValue > 0) {
//               params.lineVoltageB = newValue;
//             }
//           }

//           if (currentMotorData.currentRed != '0') {
//             final newValue = double.tryParse(currentMotorData.currentRed);
//             if (newValue != null && newValue > 0) {
//               params.currentR = newValue;
//             }
//           }
//           if (currentMotorData.currentYellow != '0') {
//             final newValue = double.tryParse(currentMotorData.currentYellow);
//             if (newValue != null && newValue > 0) {
//               params.currentY = newValue;
//             }
//           }
//           if (currentMotorData.currentBlue != '0') {
//             final newValue = double.tryParse(currentMotorData.currentBlue);
//             if (newValue != null && newValue > 0) {
//               params.currentB = newValue;
//             }
//           }

//           if (currentMotorData.fault != 0) {
//             params.fault = currentMotorData.fault;
//           }

//           params.timeStamp = DateTime.now();
//         }
//       }
//     }

//     motors.refresh();
//     allMotors.refresh();
//   }

//   Future<void> fetchLocationDropDown() async {
//     try {
//       isLoadingLocations.value = true;

//       final response = await LocationRepoImpl().getLocations();

//       if (response != null) {
//         locations.value = response.data ?? [];
//         locations.insert(0, LocationDropDown(id: null, name: 'All'));
//       }
//     } catch (e) {
//       print('Error fetching locations: $e');
//     } finally {
//       isLoadingLocations.value = false;
//     }
//   }

//   Future<void> filterMotorsByLocation(int? locationId) async {
//     selectedLocationId.value = locationId;
//     isFiltering.value = true;

//     try {
//       await Future.delayed(const Duration(milliseconds: 300));

//       if (locationId == null) {
//         motors.value = allMotors.toList();
//       } else {
//         motors.value =
//             allMotors.where((m) => m.location?.id == locationId).toList();
//       }

//       motors.refresh();
//     } finally {
//       isFiltering.value = false;
//     }
//   }

//   Future<void> toggleMotor(Motor motor, bool newState) async {
//     if (motor.starter == null) {
//       return;
//     }

//     final groupId = _getGroupIdForMotor(motor);

//     String? identifier;
//     if (motor.starter!.macAddress != null &&
//         motor.starter!.macAddress!.isNotEmpty) {
//       identifier = motor.starter!.macAddress;
//     } else if (motor.starter!.pcbNumber != null &&
//         motor.starter!.pcbNumber!.isNotEmpty) {
//       identifier = motor.starter!.pcbNumber;
//     }

//     if (identifier == null) {
//       return;
//     }

//     final motorId = '$identifier-$groupId';

//     try {
//       await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
//     } catch (e) {
//       errorMessage.value = 'Failed to toggle motor: $e';
//     }
//   }

//   Future<void> changeMotorMode(Motor motor, int modeIndex) async {
//     if (motor.starter == null) {
//       return;
//     }

//     final groupId = _getGroupIdForMotor(motor);

//     String? identifier;
//     if (motor.starter!.macAddress != null &&
//         motor.starter!.macAddress!.isNotEmpty) {
//       identifier = motor.starter!.macAddress;
//     } else if (motor.starter!.pcbNumber != null &&
//         motor.starter!.pcbNumber!.isNotEmpty) {
//       identifier = motor.starter!.pcbNumber;
//     }

//     if (identifier == null) {
//       return;
//     }

//     final motorId = '$identifier-$groupId';

//     try {
//       await mqttService.publishModeCommand(motorId, modeIndex);
//     } catch (e) {
//       errorMessage.value = 'Failed to change mode: $e';
//     }
//   }

//   MotorData? getMotorData(Motor motor) {
//     if (!mqttInitialized || motor.starter?.macAddress == null) {
//       return null;
//     }

//     final groupId = _getGroupIdForMotor(motor);
//     final motorId = '${motor.starter!.macAddress}-$groupId';
//     return mqttService.motorDataMap[motorId];
//   }
// }

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/weather_service/permission_handler.dart';

class DashboardController extends GetxController {
  final motors = <Motor>[].obs;
  final allMotors = <Motor>[].obs;
  final locations = <LocationDropDown>[].obs;

  final isLoading = true.obs;
  var isRefreshing = false.obs;
  final isFiltering = false.obs;
  final isPageLoading = true.obs;
  final isLoadingLocations = false.obs;
  final hasLocationPermission = false.obs;
  final isLoadingMore = false.obs;

  final selectedLocationId = Rxn<int>();
  final errorMessage = RxnString();

  late MqttService mqttService;
  bool mqttInitialized = false;

  // Cache for faster lookups
  final Map<String, Motor> _mqttKeyToMotor = {};
  final connectivity = Connectivity();
  var hasInternet = true.obs;
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var page = 1.obs;
  var limit = 10.obs;
  Data? response;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _loadAllData();
    _requestPermissionAndLoad();
    final args = Get.arguments;
    if (args?['refresh'] == true) {
      fetchMotors();
    }
  }

  Future<void> _requestPermissionAndLoad() async {
    hasLocationPermission.value =
        await PermissionService.requestLocationPermission();
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
    connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    hasInternet.value = result != ConnectivityResult.none;
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

  Map<String, Motor> _buildMotorMap(List<Motor> motorsList) {
    final motorMap = <String, Motor>{};
    _mqttKeyToMotor.clear();

    print('🔧 Building motor map for ${motorsList.length} motors');

    for (var motor in motorsList) {
      if (motor.starter == null) continue;

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;

      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';

        if (mac != null && mac.isNotEmpty) {
          final macKey = '$mac-$groupId';
          motorMap[macKey] = motor;
          _mqttKeyToMotor[macKey] = motor;
          print('  ✓ Mapped: $macKey -> ${motor.name} (ID: ${motor.id})');
        }

        if (pcb != null && pcb.isNotEmpty) {
          final pcbKey = '$pcb-$groupId';
          motorMap[pcbKey] = motor;
          _mqttKeyToMotor[pcbKey] = motor;
          print('  ✓ Mapped: $pcbKey -> ${motor.name} (ID: ${motor.id})');
        }
      }
    }

    print(
        '✅ Motor map built: ${motorMap.length} keys for ${motorsList.length} motors');
    return motorMap;
  }

  Future<void> refreshMotors() async {
    isRefreshing.value = true;
    page.value = 1;
    currentPage.value = 1;

    try {
      final response =
          await MotorsRepositoryImpl().getMotors(page.value, limit.value);

      if (response != null && response.data != null) {
        this.response = response.data;
        final fetchedMotors = response.data!.records ?? [];
        allMotors.value = fetchedMotors;

        if (selectedLocationId.value != null) {
          motors.value = allMotors
              .where((m) => m.location?.id == selectedLocationId.value)
              .toList();
        } else {
          motors.value = allMotors.toList();
        }

        currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
        totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

        if (mqttInitialized) {
          final motorMap = _buildMotorMap(allMotors);
          mqttService.updateMotors(motorMap);
          await mqttService.resubscribeToTopics();

          // CRITICAL FIX: Wait for subscriptions to complete
          await Future.delayed(const Duration(milliseconds: 1000));
          _forceUpdateAllMotors();
        }

        motors.refresh();
        allMotors.refresh();
      } else {
        errorMessage.value = 'Failed to refresh motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('❌ Error refreshing motors: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMoreMotors() async {
    if (isLoadingMore.value || currentPage.value >= totalPages.value) {
      return;
    }

    isLoadingMore.value = true;
    print('📥 Loading more motors - page ${currentPage.value + 1}');

    try {
      page.value = currentPage.value + 1;
      final response =
          await MotorsRepositoryImpl().getMotors(page.value, limit.value);

      if (response != null && response.data != null) {
        this.response = response.data;
        final fetchedMotors = response.data!.records ?? [];
        print('✓ Loaded ${fetchedMotors.length} new motors');

        allMotors.addAll(fetchedMotors);

        if (selectedLocationId.value != null) {
          motors.value = allMotors
              .where((m) => m.location?.id == selectedLocationId.value)
              .toList();
        } else {
          motors.value = allMotors.toList();
        }

        currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
        totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

        // CRITICAL FIX: Rebuild motor map and resubscribe
        if (mqttInitialized) {
          print('🔄 Rebuilding MQTT map with ${allMotors.length} motors');
          final motorMap = _buildMotorMap(allMotors);

          mqttService.updateMotors(motorMap);
          await mqttService.resubscribeToTopics();

          // Wait for subscriptions to complete
          await Future.delayed(const Duration(milliseconds: 1000));
          _forceUpdateAllMotors();
        }

        motors.refresh();
        allMotors.refresh();
      }
    } catch (e) {
      errorMessage.value = 'Error loading more: $e';
      print('❌ Error loading more motors: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchMotors() async {
    try {
      print('🚀 Fetching initial motors...');
      final response =
          await MotorsRepositoryImpl().getMotors(page.value, limit.value);

      if (response != null && response.data != null) {
        this.response = response.data;
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;

        currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
        totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

        print(
            '✓ Fetched ${allMotors.length} motors (page ${currentPage.value}/${totalPages.value})');

        // Build motor map
        final motorMap = _buildMotorMap(allMotors);

        // Initialize MQTT
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;

        // Connect to MQTT
        await mqttService.initializeMqttClient();

        // CRITICAL FIX: Add listener AFTER connection
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        // Wait for connection to stabilize and subscriptions to complete
        await Future.delayed(const Duration(milliseconds: 1500));

        // Initial force update
        _forceUpdateAllMotors();
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('❌ Error fetching motors: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  // CRITICAL FIX: Enhanced force update with better logging
  void _forceUpdateAllMotors() {
    if (!mqttInitialized) {
      print('⚠️ MQTT not initialized, skipping force update');
      return;
    }

    print('🔍 Force checking MQTT data for ${allMotors.length} motors');
    print('📊 Available MQTT data entries: ${mqttService.motorDataMap.length}');

    // Log all available MQTT data
    mqttService.motorDataMap.forEach((key, data) {
      if (data.hasReceivedData) {
        print(
            '  📡 MQTT data: $key -> state=${data.state}, V=${data.voltageRed}, hasData=${data.hasReceivedData}');
      }
    });

    int updated = 0;
    int notFound = 0;

    for (var motor in allMotors) {
      if (motor.starter == null) {
        notFound++;
        continue;
      }

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;
      MotorData? latestData;
      String? matchedKey;

      // Check all groups
      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';

        // Try MAC
        if (mac != null && mac.isNotEmpty) {
          final key = '$mac-$groupId';
          final data = mqttService.motorDataMap[key];
          if (data?.hasReceivedData == true) {
            latestData = data;
            matchedKey = key;
            break;
          }
        }

        // Try PCB
        if (pcb != null && pcb.isNotEmpty) {
          final key = '$pcb-$groupId';
          final data = mqttService.motorDataMap[key];
          if (data?.hasReceivedData == true) {
            latestData = data;
            matchedKey = key;
            break;
          }
        }
      }

      if (latestData != null) {
        print('  ✅ Updating motor: ${motor.name} from $matchedKey');
        _applyMqttDataToMotor(motor, latestData);
        updated++;
      } else {
        print('  ⚠️ No MQTT data for: ${motor.name} (MAC: $mac, PCB: $pcb)');
        notFound++;
      }
    }

    print('📊 Update complete: updated=$updated, notFound=$notFound');

    if (updated > 0) {
      motors.refresh();
      allMotors.refresh();
      print('✅ UI refreshed');
    }
  }

  // CRITICAL FIX: Better MQTT update handler
  void _onMqttUpdate() {
    print('🔔 MQTT data update notification received');

    // Use a small delay to batch rapid updates
    Future.delayed(const Duration(milliseconds: 100), () {
      _forceUpdateAllMotors();
    });
  }

  void _applyMqttDataToMotor(Motor motor, MotorData mqttData) {
    motor.state = mqttData.state;
    motor.mode = mqttData.motorMode;

    if (mqttData.power != 0 && motor.starter != null) {
      motor.starter!.power = mqttData.power;
    }

    if (motor.starter != null) {
      if (motor.starter!.starterParameters == null) {
        motor.starter!.starterParameters = [];
      }

      if (motor.starter!.starterParameters!.isEmpty) {
        motor.starter!.starterParameters!.add(StarterParameter());
      }

      final params = motor.starter!.starterParameters!.first;

      _updateIfValid(mqttData.voltageRed, (v) => params.lineVoltageR = v);
      _updateIfValid(mqttData.voltageYellow, (v) => params.lineVoltageY = v);
      _updateIfValid(mqttData.voltageBlue, (v) => params.lineVoltageB = v);
      _updateIfValid(mqttData.currentRed, (v) => params.currentR = v);
      _updateIfValid(mqttData.currentYellow, (v) => params.currentY = v);
      _updateIfValid(mqttData.currentBlue, (v) => params.currentB = v);

      if (mqttData.fault != 0) {
        params.fault = mqttData.fault;
      }

      params.timeStamp = DateTime.now();
    }
  }

  void _updateIfValid(String value, Function(double) setter) {
    if (value != '0' && value != '0.0' && value.isNotEmpty) {
      final numValue = double.tryParse(value);
      if (numValue != null && numValue > 0) {
        setter(numValue);
      }
    }
  }

  Future<void> fetchLocationDropDown() async {
    try {
      isLoadingLocations.value = true;
      final response = await LocationRepoImpl().getLocations();

      if (response != null) {
        locations.value = response.data ?? [];
        locations.insert(0, LocationDropDown(id: null, name: 'All'));
      }
    } catch (e) {
      print('❌ Error fetching locations: $e');
    } finally {
      isLoadingLocations.value = false;
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
    if (motor.starter == null) return;

    String? identifier;
    if (motor.starter!.macAddress != null &&
        motor.starter!.macAddress!.isNotEmpty) {
      identifier = motor.starter!.macAddress;
    } else if (motor.starter!.pcbNumber != null &&
        motor.starter!.pcbNumber!.isNotEmpty) {
      identifier = motor.starter!.pcbNumber;
    }

    if (identifier == null) return;

    final motorId = '$identifier-G01';

    try {
      await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
    } catch (e) {
      errorMessage.value = 'Failed to toggle motor: $e';
    }
  }

  Future<void> changeMotorMode(Motor motor, int modeIndex) async {
    if (motor.starter == null) return;

    String? identifier;
    if (motor.starter!.macAddress != null &&
        motor.starter!.macAddress!.isNotEmpty) {
      identifier = motor.starter!.macAddress;
    } else if (motor.starter!.pcbNumber != null &&
        motor.starter!.pcbNumber!.isNotEmpty) {
      identifier = motor.starter!.pcbNumber;
    }

    if (identifier == null) return;

    final motorId = '$identifier-G01';

    try {
      await mqttService.publishModeCommand(motorId, modeIndex);
    } catch (e) {
      errorMessage.value = 'Failed to change mode: $e';
    }
  }

  MotorData? getMotorData(Motor motor) {
    if (!mqttInitialized || motor.starter == null) return null;

    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';

      if (mac != null && mac.isNotEmpty) {
        final key = '$mac-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          return data;
        }
      }

      if (pcb != null && pcb.isNotEmpty) {
        final key = '$pcb-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          return data;
        }
      }
    }

    return null;
  }
}
