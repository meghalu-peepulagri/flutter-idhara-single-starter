import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/mixins/connectivity_mixin.dart';
import 'package:i_dhara/app/core/utils/api_retry.dart';
import 'package:i_dhara/app/core/utils/mqtt_utils.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/weather_service/permission_handler.dart';

import '../../../data/dto/device_setting_dto.dart';
import '../../../data/models/settings/user_setting_limits2_model.dart';
import '../../../data/repository/devices/devices_repo_impl.dart';
import '../../../data/repository/devices/devices_repository.dart';
import '../../../data/repository/settings/settings_repo_impl.dart';
import '../../../data/services/storages/shared_preference.dart';

class DashboardController extends GetxController with ConnectivityMixin {
  final motors = <Motor>[].obs;
  final allMotors = <Motor>[].obs;
  final locations = <LocationDropDown>[].obs;
  final DevicesRepositoryImpl _repository = DevicesRepositoryImpl();
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

  static final List<Motor> _cachedMotors = [];
  static int _cachedCurrentPage = 1;
  static int _cachedTotalPages = 1;

  void _cacheMotors() {
    _cachedMotors
      ..clear()
      ..addAll(allMotors);
    _cachedCurrentPage = currentPage.value;
    _cachedTotalPages = totalPages.value;
  }

  static void clearMotorCache() {
    _cachedMotors.clear();
    _cachedCurrentPage = 1;
    _cachedTotalPages = 1;
  }

  Timer? _backgroundRefreshTimer;

  final Map<int, String> _motorIdToGroupId = {};
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var page = 1.obs;
  var limit = 10.obs;
  Data? response;

  final Rx<UserSettings2?> userSettings2 = Rx<UserSettings2?>(null);
  var pcbNumber = ''.obs;

  var macAddress = ''.obs;

  var isdisabled = false.obs;
  final RxMap<String, dynamic> updateSettingDto = <String, dynamic>{}.obs;
  var drf = 0.0.obs;
  var olf = 0.0.obs;
  var flc = 0.0.obs;
  var lrf = 0.0.obs;
  var olr = 0.0.obs;
  var lrr = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _requestPermissionAndLoad();
    final args = Get.arguments;
    final forceRefresh = args != null && args['refresh'] == true;
    if (!forceRefresh && _canRestoreFromMqtt()) {
      _restoreFromMqtt();
    } else {
      _loadAllData();
    }
  }

  bool _canRestoreFromMqtt() {
    return MqttService().isConnected && _cachedMotors.isNotEmpty;
  }

  Future<void> _restoreFromMqtt() async {
    try {
      isLoading.value = true;

      final seen = <int>{};
      final restored = <Motor>[];
      for (final motor in _cachedMotors) {
        if (motor.id == null || seen.add(motor.id!)) {
          restored.add(motor);
        }
      }

      allMotors.value = restored;
      if (selectedLocationId.value != null) {
        motors.value = restored
            .where((m) => m.location?.id == selectedLocationId.value)
            .toList();
      } else {
        motors.value = restored.toList();
      }

      final motorMap = _buildMotorMap(allMotors);
      MqttService().restoreMotorRegistry(motorMap);

      currentPage.value = _cachedCurrentPage;
      totalPages.value = _cachedTotalPages;
      page.value = _cachedCurrentPage;

      if (mqttInitialized) {
        mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
      }
      mqttService = MqttService();
      mqttInitialized = true;
      mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

      _onMqttUpdate();

      await fetchLocationDropDown();
    } finally {
      isLoading.value = false;
      // _startBackgroundRefresh();
    }
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

  @override
  Future<void> onRetry() async {
    // ConnectivityMixin calls this on every reconnect event, but
    // connectivity_plus fires those on plain wifi/mobile handoffs and DHCP
    // renewals too — not just real outages — which was reloading the whole
    // dashboard (loading skeleton and all) without the user ever pulling to
    // refresh. Live data keeps arriving over the existing MQTT connection
    // regardless, so there's nothing to recover here; only an explicit
    // pull-to-refresh should reload the dashboard now.
    Get.log(
        'DashboardController: Connectivity restored — skipping auto-refresh');
  }

  Future<void> clearFaultAck(Motor motor) async {
    isLoading.value = true;
    try {
      SharedPreference.setStarterId(motor.starter?.id ?? 0);
      SharedPreference.setMotorId(motor.id ?? 0);

      final response = await MotorsRepositoryImpl().clearFault();
      if (response != null) {
        debugPrint('Fault cleared via API successfully.');
      }
      page.value = 1;
      currentPage.value = 0;
      await fetchMotors();
      await fetchLocationDropDown();
    } catch (e) {
      debugPrint('Error in clearFaultAck: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchupdateSettingsAck() async {
    try {
      try {
        final response = await SettingsRepositoryImpl().updateSettingsAck();
        if (response?.status == 200 || response?.status == 201) {
        } else {
          errorMessage.value = response?.message ?? 'Failed to update settings';
        }
      } catch (e) {
        errorMessage.value = 'Error updating settings: $e';
        debugPrint('Error updating user settings: $e');
      }
    } finally {
      await fetchUserSettings2();
    }
  }

  Future<void> _loadAllData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        fetchMotors(enableRetry: true),
        fetchLocationDropDown(),
      ]);
    } finally {
      isLoading.value = false;
      // _startBackgroundRefresh();
    }
  }

  @override
  void onClose() {
    _backgroundRefreshTimer?.cancel();
    if (mqttInitialized) {
      mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
      // mqttService.dispose();
    }
    super.onClose();
  }

  // void _startBackgroundRefresh() {
  //   _backgroundRefreshTimer?.cancel();
  //   _backgroundRefreshTimer = Timer.periodic(
  //     const Duration(seconds: 10),
  //     (_) => fetchMotorsSilently(),
  //   );
  // }

  Map<String, Motor> _buildMotorMap(List<Motor> motorsList) {
    final motorMap = <String, Motor>{};
    _motorIdToGroupId.clear();

    for (var motor in motorsList) {
      if (motor.starter == null) continue;

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;

      final identifier = (mac != null && mac.isNotEmpty) ? mac : pcb;
      if (identifier == null || identifier.isEmpty) continue;

      const groupId = 'G01';
      _motorIdToGroupId[motor.id!] = groupId;

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
        _cacheMotors();

        if (mqttInitialized) {
          final motorMap = _buildMotorMap(allMotors);
          mqttService.updateMotors(motorMap);
          await mqttService.resubscribeToTopics();
          await Future.delayed(const Duration(milliseconds: 500));
          _onMqttUpdate();
        }

        motors.refresh();
        allMotors.refresh();

        await _publishLiveDataRequest();
      } else {
        errorMessage.value = 'Failed to refresh motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _publishLiveDataRequest() async {
    if (!mqttInitialized || !mqttService.isConnected) return;
    for (final motor in allMotors) {
      if (motor.starter == null) continue;
      final deviceAlloc = motor.starter!.deviceAllocation ?? 'false';
      final pcb = motor.starter!.pcbNumber?.trim() ?? '';
      final mac = motor.starter!.macAddress?.trim() ?? '';
      var identifier = getMotorIdentifier(deviceAlloc, pcb, mac);
      if (identifier.isEmpty) identifier = pcb.isNotEmpty ? pcb : mac;
      if (identifier.isEmpty) continue;
      final motorId = '$identifier-${_getGroupIdForMotor(motor)}';
      try {
        await mqttService.publishTestRunCommand(
          motorId,
          5,
          data: 1,
          type: MqttService.topicLiveDataRequest,
          motorReference: motor.motorReference,
        );
      } catch (e) {
        debugPrint('Refresh ping failed for $motorId: $e');
      }
    }
  }

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
        _cacheMotors();

        if (mqttInitialized) {
          final motorMap = _buildMotorMap(allMotors);

          mqttService.updateMotors(motorMap);

          await mqttService.resubscribeToTopics();

          await Future.delayed(const Duration(milliseconds: 300));
          _onMqttUpdate();
        }

        motors.refresh();
        allMotors.refresh();
      }
    } catch (e) {
      errorMessage.value = 'Error loading more: $e';
      debugPrint('Error loading more motors: $e');
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

  Future<void> fetchUserSettings2() async {
    try {
      // errorMessage.value = '';
      final response = await SettingsRepositoryImpl().getSettings2();
      if (response != null &&
          response.success == true &&
          response.data != null) {
        userSettings2.value = response.data;
        final deviceallow = userSettings2.value?.starter?.deviceAllocation;
        final pcb = userSettings2.value?.starter?.pcbNumber;
        final mac = userSettings2.value?.starter?.macAddress;

        pcbNumber.value = getMotorIdentifier(
            deviceallow.toString(), pcb.toString(), mac.toString());
        macAddress.value = response.data?.starter?.macAddress ?? '';
        flc.value = userSettings2.value?.flc?.toDouble() ?? 0.0;
        drf.value = userSettings2.value?.drf?.toDouble() ?? 0;
        olf.value = userSettings2.value?.olf?.toDouble() ?? 0.0;
        lrf.value = userSettings2.value?.lrf?.toDouble() ?? 0.0;
        olr.value = userSettings2.value?.olr?.toDouble() ?? 0.0;
        lrr.value = userSettings2.value?.lrr?.toDouble() ?? 0.0;

        updateSettingDto.assignAll(response.data!.toJson());
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");
      } else {
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
      debugPrint('Error fetching user settings: $e');
    }
  }

  Future<void> fetchupdateSettings() async {
    try {
      updateSettingDto['flc'] = flc.value;
      UserUpdateSettingsDto dto =
          UserUpdateSettingsDto.fromJson(updateSettingDto);
      final response = await SettingsRepositoryImpl().updateSettings(dto);
      if (response?.status == 200 || response?.status == 201) {
      } else {
        errorMessage.value = response?.message ?? 'Failed to update settings';
      }
    } catch (e) {
      errorMessage.value = 'Error updating settings: $e';
      debugPrint('Error updating user settings: $e');
    }
  }

  Future<bool> updateTestRunStatus(int motorId, TestRunStatus status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await _repository.testRun(motorId, status);
      if (response != null && response.success == true) {
        return true;
      } else {
        errorMessage.value =
            response?.message ?? 'Failed to update test run status';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> startTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.inTest);
  }

  Future<bool> completeTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.completed);
  }

  Future<void> fetchMotors({bool enableRetry = false}) async {
    try {
      final response = enableRetry
          ? await withRetry(
              call: () =>
                  MotorsRepositoryImpl().getMotors(page.value, limit.value),
              isSuccess: (r) => r != null && r.data != null,
            )
          : await MotorsRepositoryImpl().getMotors(page.value, limit.value);
      debugPrint('fetchMotors response: $response');

      if (response != null && response.data != null) {
        this.response = response.data;

        allMotors.value = response.data!.records ?? [];
        if (selectedLocationId.value != null) {
          motors.value = allMotors
              .where((m) => m.location?.id == selectedLocationId.value)
              .toList();
        } else {
          motors.value = allMotors.toList();
        }

        currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
        totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();
        _cacheMotors();

        final motorMap = _buildMotorMap(allMotors);

        if (mqttInitialized) {
          mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
        }
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        if (mqttService.isConnected) {
          debugPrint('DASHBOARD: MQTT already connected — reusing connection');
          if (motorMap.isNotEmpty) {
            _onMqttUpdate();
          }
        } else {
          debugPrint('DASHBOARD: Initializing MQTT client...');
          mqttService.initializeMqttClient().then((_) async {
            debugPrint('DASHBOARD: MQTT client initialized successfully');
            if (motorMap.isNotEmpty) {
              _onMqttUpdate();
            }
          }).catchError((e) {
            debugPrint('DASHBOARD: MQTT initialization failed: $e');
          });
        }
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint('Error fetching motors: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  void _onMqttUpdate() {
    for (var motor in allMotors) {
      if (motor.starter == null) continue;

      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;

      MotorData? currentMotorData;

      final ref = motor.motorReference;
      final suffix = (ref != null && ref.isNotEmpty) ? '-$ref' : '';

      for (int i = 1; i <= 4; i++) {
        if (currentMotorData != null) break;
        final groupId = 'G0$i';

        if (mac != null && mac.isNotEmpty) {
          final key = '$mac-$groupId$suffix';
          final data = mqttService.motorDataMap[key];
          if (data?.hasReceivedData == true) {
            currentMotorData = data;
            break;
          }
        }

        if (pcb != null && pcb.isNotEmpty) {
          final key = '$pcb-$groupId$suffix';
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
            params.faultCleared = false;
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
      debugPrint('Error fetching locations: $e');
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
      // fetchMotorsSilently();
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
      final deviceCode = modeIndex == 2 ? 6 : modeIndex;
      await mqttService.publishModeCommand(motorId, deviceCode);
      // fetchMotorsSilently();
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
