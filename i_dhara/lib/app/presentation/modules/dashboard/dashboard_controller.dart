import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
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

  final Map<int, String> _motorIdToGroupId = {};
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
  }

  Future<void> refreshDashboard() async {
    isLoading.value = true;
    page.value = 1;
    currentPage.value = 0;

    try {
      await fetchMotors();
      await fetchLocationDropDown();
    } finally {
      isLoading.value = false;
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
      // mqttService.dispose();
    }
    super.onClose();
  }

  /// Build motor map - creates entries for ALL groups (G01-G04) for each identifier
  /// This ensures any MQTT data on any group can be matched to the motor
  Map<String, Motor> _buildMotorMap(List<Motor> motorsList) {
    final motorMap = <String, Motor>{};
    _motorIdToGroupId.clear();

    for (var motor in motorsList) {
      if (motor.starter == null) continue;

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;

      // Determine primary identifier (prefer MAC over PCB)
      final identifier = (mac != null && mac.isNotEmpty) ? mac : pcb;
      if (identifier == null || identifier.isEmpty) continue;

      // Default to G01 for each motor
      const groupId = 'G01';
      _motorIdToGroupId[motor.id!] = groupId;

      // Create entries for ALL groups (G01-G04) so MQTT data on any group is matched
      for (int i = 1; i <= 4; i++) {
        final group = 'G0$i';

        if (mac != null && mac.isNotEmpty) {
          motorMap['$mac-$group'] = motor;
        }

        if (pcb != null && pcb.isNotEmpty) {
          motorMap['$pcb-$group'] = motor;
        }
      }

      debugPrint('✓ Motor ${motor.id} (${motor.name}): identifier=$identifier');
    }

    debugPrint(
        '✓ Motor map: ${motorMap.length} entries for ${motorsList.length} motors');
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

        // FIXED: Rebuild complete motor map and update MQTT
        if (mqttInitialized) {
          final motorMap = _buildMotorMap(allMotors);
          mqttService.updateMotors(motorMap);
          await mqttService.resubscribeToTopics();
          await Future.delayed(const Duration(milliseconds: 500));
          _onMqttUpdate();
        }

        motors.refresh();
        allMotors.refresh();
      } else {
        errorMessage.value = 'Failed to refresh motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isRefreshing.value = false;
    }
  }

  // FIXED: Load more motors with proper MQTT update
  Future<void> loadMoreMotors() async {
    if (isLoadingMore.value || currentPage.value >= totalPages.value) {
      return;
    }

    isLoadingMore.value = true;

    try {
      page.value = currentPage.value + 1;
      final response =
          await MotorsRepositoryImpl().getMotors(page.value, limit.value);

      if (response != null && response.data != null) {
        this.response = response.data;
        final fetchedMotors = response.data!.records ?? [];

        // Add new motors to existing list
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

        // FIXED: Rebuild ENTIRE motor map including new motors
        if (mqttInitialized) {
          final motorMap = _buildMotorMap(allMotors);

          // Update MQTT service with complete motor map
          mqttService.updateMotors(motorMap);

          // Subscribe to new topics
          await mqttService.resubscribeToTopics();

          // Force update
          await Future.delayed(const Duration(milliseconds: 300));
          _onMqttUpdate();
        }

        motors.refresh();
        allMotors.refresh();
      }
    } catch (e) {
      errorMessage.value = 'Error loading more: $e';
      print('Error loading more motors: $e');
    } finally {
      isLoadingMore.value = false;
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
      final response =
          await MotorsRepositoryImpl().getMotors(page.value, limit.value);

      if (response != null && response.data != null) {
        this.response = response.data;
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;

        currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
        totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

        // Build motor map
        final motorMap = _buildMotorMap(allMotors);

        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;

        await mqttService.initializeMqttClient();
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        if (motorMap.isNotEmpty) {
          _onMqttUpdate();
        }
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      print('Error fetching motors: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  void _onMqttUpdate() {
    int mqttDataCount = 0;
    for (var key in mqttService.motorDataMap.keys) {
      final data = mqttService.motorDataMap[key];
      if (data?.hasReceivedData == true) {
        mqttDataCount++;
      }
    }

    print('✓ Total MQTT data entries: $mqttDataCount');

    for (var motor in allMotors) {
      if (motor.starter == null) continue;

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;
      final currentGroupId = _getGroupIdForMotor(motor);

      MotorData? currentMotorData;

      // Check all groups for MQTT data
      for (int i = 1; i <= 4; i++) {
        if (currentMotorData != null) break;
        final groupId = 'G0$i';

        if (mac != null && mac.isNotEmpty) {
          final key = '$mac-$groupId';
          final data = mqttService.motorDataMap[key];
          if (data?.hasReceivedData == true) {
            currentMotorData = data;
            break;
          }
        }

        if (pcb != null && pcb.isNotEmpty) {
          final key = '$pcb-$groupId';
          final data = mqttService.motorDataMap[key];
          if (data?.hasReceivedData == true) {
            currentMotorData = data;
            break;
          }
        }
      }

      if (currentMotorData != null && currentMotorData.hasReceivedData) {
        motor.state = currentMotorData.state;
        motor.mode = currentMotorData.motorMode;

        if (currentMotorData.power != 0 && motor.starter != null) {
          motor.starter!.power = currentMotorData.power;
        }

        if (motor.starter != null) {
          if (motor.starter!.starterParameters == null) {
            motor.starter!.starterParameters = [];
          }

          if (motor.starter!.starterParameters!.isEmpty) {
            motor.starter!.starterParameters!.add(StarterParameter());
          }

          final params = motor.starter!.starterParameters!.first;

          if (currentMotorData.voltageRed != '0') {
            final newValue = double.tryParse(currentMotorData.voltageRed);
            if (newValue != null && newValue > 0) {
              params.lineVoltageR = newValue;
            }
          }
          if (currentMotorData.voltageYellow != '0') {
            final newValue = double.tryParse(currentMotorData.voltageYellow);
            if (newValue != null && newValue > 0) {
              params.lineVoltageY = newValue;
            }
          }
          if (currentMotorData.voltageBlue != '0') {
            final newValue = double.tryParse(currentMotorData.voltageBlue);
            if (newValue != null && newValue > 0) {
              params.lineVoltageB = newValue;
            }
          }

          if (currentMotorData.currentRed != '0') {
            final newValue = double.tryParse(currentMotorData.currentRed);
            if (newValue != null && newValue > 0) {
              params.currentR = newValue;
            }
          }
          if (currentMotorData.currentYellow != '0') {
            final newValue = double.tryParse(currentMotorData.currentYellow);
            if (newValue != null && newValue > 0) {
              params.currentY = newValue;
            }
          }
          if (currentMotorData.currentBlue != '0') {
            final newValue = double.tryParse(currentMotorData.currentBlue);
            if (newValue != null && newValue > 0) {
              params.currentB = newValue;
            }
          }

          if (currentMotorData.fault != 0) {
            params.fault = currentMotorData.fault;
          }

          params.timeStamp = DateTime.now();
        }
      }
    }

    motors.refresh();
    allMotors.refresh();
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
      print('Error fetching locations: $e');
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
    if (motor.starter == null) {
      return;
    }

    final groupId = _getGroupIdForMotor(motor);

    String? identifier;
    if (motor.starter!.macAddress != null &&
        motor.starter!.macAddress!.isNotEmpty) {
      identifier = motor.starter!.macAddress;
    } else if (motor.starter!.pcbNumber != null &&
        motor.starter!.pcbNumber!.isNotEmpty) {
      identifier = motor.starter!.pcbNumber;
    }

    if (identifier == null) {
      return;
    }

    final motorId = '$identifier-$groupId';

    try {
      await mqttService.publishMotorCommand(motorId, newState ? 1 : 0);
    } catch (e) {
      errorMessage.value = 'Failed to toggle motor: $e';
    }
  }

  Future<void> changeMotorMode(Motor motor, int modeIndex) async {
    if (motor.starter == null) {
      return;
    }

    final groupId = _getGroupIdForMotor(motor);

    String? identifier;
    if (motor.starter!.macAddress != null &&
        motor.starter!.macAddress!.isNotEmpty) {
      identifier = motor.starter!.macAddress;
    } else if (motor.starter!.pcbNumber != null &&
        motor.starter!.pcbNumber!.isNotEmpty) {
      identifier = motor.starter!.pcbNumber;
    }

    if (identifier == null) {
      return;
    }

    final motorId = '$identifier-$groupId';

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
