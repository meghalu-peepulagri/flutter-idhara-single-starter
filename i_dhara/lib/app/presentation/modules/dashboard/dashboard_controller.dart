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

  final selectedLocationId = Rxn<int>();
  final errorMessage = RxnString();

  late MqttService mqttService;
  bool mqttInitialized = false;

  final Map<int, String> _motorIdToGroupId = {};
  final connectivity = Connectivity();
  var hasInternet = true.obs;

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

  Future<void> refreshMotors() async {
    isRefreshing.value = true;

    try {
      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        final fetchedMotors = response.data!.records ?? [];
        allMotors.value = fetchedMotors;

        // Apply location filter
        if (selectedLocationId.value != null) {
          motors.value = allMotors
              .where((m) => m.location?.id == selectedLocationId.value)
              .toList();
        } else {
          motors.value = allMotors.toList();
        }

        // Update MQTT service with new motor data
        if (mqttInitialized) {
          final motorMap = <String, Motor>{};
          _motorIdToGroupId.clear();

          for (var motor in allMotors) {
            if (motor.starter != null) {
              final mac = motor.starter!.macAddress;
              final pcb = motor.starter!.pcbNumber;

              for (int i = 1; i <= 4; i++) {
                final groupId = 'G0$i';

                // Add entry with MAC address
                if (mac != null && mac.isNotEmpty) {
                  final macKey = '$mac-$groupId';
                  motorMap[macKey] = motor;

                  if (i == 1) {
                    _motorIdToGroupId[motor.id!] = groupId;
                  }
                }

                // Add entry with PCB number
                if (pcb != null && pcb.isNotEmpty) {
                  final pcbKey = '$pcb-$groupId';
                  motorMap[pcbKey] = motor;

                  if (i == 1 && (mac == null || mac.isEmpty)) {
                    _motorIdToGroupId[motor.id!] = groupId;
                  }
                }
              }
            }
          }

          // Update MQTT service motors
          mqttService.updateMotors(motorMap);

          // Resubscribe to new motor topics
          await mqttService.resubscribeToTopics();

          await Future.delayed(const Duration(milliseconds: 500));

          // UI update with fresh API data
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

  String _getGroupIdForMotor(Motor motor) {
    if (_motorIdToGroupId.containsKey(motor.id)) {
      return _motorIdToGroupId[motor.id]!;
    }
    return 'G01';
  }

  Future<void> fetchMotors() async {
    try {
      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;

        final motorMap = <String, Motor>{};
        _motorIdToGroupId.clear();

        for (var motor in allMotors) {
          if (motor.starter != null) {
            final mac = motor.starter!.macAddress;
            final pcb = motor.starter!.pcbNumber;

            // Create entries for both MAC and PCB if available
            for (int i = 1; i <= 4; i++) {
              final groupId = 'G0$i';

              // Add entry with MAC address
              if (mac != null && mac.isNotEmpty) {
                final macKey = '$mac-$groupId';
                motorMap[macKey] = motor;

                if (i == 1) {
                  _motorIdToGroupId[motor.id!] = groupId;
                }
              }

              // Add entry with PCB number
              if (pcb != null && pcb.isNotEmpty) {
                final pcbKey = '$pcb-$groupId';
                motorMap[pcbKey] = motor;

                // Only set default if MAC wasn't available
                if (i == 1 && (mac == null || mac.isEmpty)) {
                  _motorIdToGroupId[motor.id!] = groupId;
                }
              }
            }
          }
        }

        //  Always initialize MQTT service, even with empty motors
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;

        //  Initialize MQTT connection regardless of motor count
        await mqttService.initializeMqttClient();

        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        // Only update if we have motors
        if (motorMap.isNotEmpty) {
          _onMqttUpdate();
        }
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
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

    print(' Total MQTT data entries: $mqttDataCount');

    for (var motor in allMotors) {
      if (motor.starter == null) continue;

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;
      final currentGroupId = _getGroupIdForMotor(motor);

      // Try to find data with MAC first, then PCB
      String? currentKey;
      MotorData? currentMotorData;

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

      // Update state and mode from current group
      if (currentMotorData != null && currentMotorData.hasReceivedData) {
        motor.state = currentMotorData.state;
        motor.mode = currentMotorData.motorMode;

        // Update power from current group
        if (currentMotorData.power != 0 && motor.starter != null) {
          motor.starter!.power = currentMotorData.power;
        }

        // Update voltage and current from current group
        if (motor.starter != null) {
          if (motor.starter!.starterParameters == null) {
            motor.starter!.starterParameters = [];
          }

          if (motor.starter!.starterParameters!.isEmpty) {
            motor.starter!.starterParameters!.add(StarterParameter());
          }

          final params = motor.starter!.starterParameters!.first;

          // Update voltages
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

          // Update currents
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

          // Update fault
          if (currentMotorData.fault != 0) {
            params.fault = currentMotorData.fault;
          }

          params.timeStamp = DateTime.now();
        }
      } else {
        print(' No MQTT data for current group, keeping API data');
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

    // Prefer MAC, fall back to PCB
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

    // Prefer MAC, fall back to PCB
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
