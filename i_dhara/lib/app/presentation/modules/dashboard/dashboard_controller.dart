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

  // Periodically refreshes motor data from the API in the background.
  // This keeps API-only fields (fault description, run-time, etc.) in sync
  // without triggering any loading indicator.
  Timer? _backgroundRefreshTimer;

  final Map<int, String> _motorIdToGroupId = {};
  // Removed local connectivity logic, handled by ConnectivityMixin and ConnectivityService
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
      // MQTT is already connected with live motor data (e.g. navigating back
      // from Motor Details). Restore the motor list from the singleton and
      // skip the API call entirely — real-time updates come from MQTT.
      _restoreFromMqtt();
    } else {
      // First load after login, after logout+login, when MQTT has no data,
      // or when returning after a device add/delete (forceRefresh=true).
      _loadAllData();
    }
  }

  /// Returns true when the MQTT singleton already holds a live connection with
  /// motor data from a previous Dashboard session.
  bool _canRestoreFromMqtt() {
    final mqtt = MqttService();
    return mqtt.isConnected && mqtt.motors.isNotEmpty;
  }

  /// Restore the motor list from the MQTT singleton without hitting the API.
  ///
  /// The MQTT service is a singleton that persists across controller instances.
  /// Its [motors] map holds the full [Motor] objects updated in real time by
  /// [_onMqttUpdate]. By reading those objects we get the latest state, mode,
  /// voltage and current without a network round-trip.
  ///
  /// Crucially we do NOT call [MqttService(initialMotors: ...)] here because
  /// that would rebuild [motorDataMap] and reset [hasReceivedData] to false on
  /// every entry, losing live data. We only get the singleton reference and
  /// attach a fresh listener.
  Future<void> _restoreFromMqtt() async {
    try {
      isLoading.value = true;

      // Deduplicate motors: the MQTT motor map stores 4 entries per motor
      // (one per group G01–G04) pointing to the same Motor object.
      final seen = <int>{};
      final restored = <Motor>[];
      for (final motor in MqttService().motors.values) {
        if (motor.id != null && seen.add(motor.id!)) {
          restored.add(motor);
        }
      }

      allMotors.value = restored;
      motors.value = restored.toList();

      // Rebuild _motorIdToGroupId so toggleMotor / changeMotorMode work.
      // We intentionally discard the returned map — the MQTT service already
      // has its motorDataMap intact; rebuilding it would wipe live data.
      _buildMotorMap(allMotors);

      // Set pagination to a safe state: currentPage == totalPages prevents
      // the scroll listener from firing an unintended loadMoreMotors call.
      currentPage.value = 1;
      totalPages.value = 1;

      // Attach to the existing singleton connection.
      if (mqttInitialized) {
        mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
      }
      mqttService = MqttService(); // singleton reference — no rebuild
      mqttInitialized = true;
      mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

      // Sync the UI immediately with whatever MQTT has already received.
      _onMqttUpdate();

      // Locations are needed for the filter dropdown — fast, non-critical.
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
    Get.log('DashboardController: Retrying API calls after reconnection');
    await refreshDashboard();
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

  /// Fetches motors from the API and updates the UI silently (no loading indicator).
  /// Used after ACK operations like fault clear so the card updates without
  /// showing a full-screen loader.
  // Future<void> fetchMotorsSilently() async {
  //   try {
  //     final response = await MotorsRepositoryImpl().getMotors(1, limit.value);

  //     if (response != null && response.data != null) {
  //       this.response = response.data;
  //       final fetchedMotors = response.data!.records ?? [];
  //       allMotors.value = fetchedMotors;

  //       if (selectedLocationId.value != null) {
  //         motors.value = allMotors
  //             .where((m) => m.location?.id == selectedLocationId.value)
  //             .toList();
  //       } else {
  //         motors.value = allMotors.toList();
  //       }

  //       currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
  //       totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

  //       // Rebuild motor map and sync MQTT
  //       if (mqttInitialized) {
  //         final motorMap = _buildMotorMap(allMotors);
  //         mqttService.updateMotors(motorMap);
  //         await mqttService.resubscribeToTopics();
  //         await Future.delayed(const Duration(milliseconds: 300));
  //         _onMqttUpdate();
  //       }

  //       motors.refresh();
  //       allMotors.refresh();
  //       debugPrint('fetchMotorsSilently: UI refreshed silently.');
  //     }
  //   } catch (e) {
  //     debugPrint('Error in fetchMotorsSilently: $e');
  //   }
  // }

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

  /// Starts a periodic timer that silently fetches motors every 10 seconds.
  /// Cancels any previous timer first so there is never more than one running.
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

  /// Start test run - calls API with IN_TEST status
  Future<bool> startTestRun(int motorId) async {
    return await updateTestRunStatus(motorId, TestRunStatus.inTest);
  }

  /// Complete test run - calls API with COMPLETED status
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
        motors.value = allMotors;

        currentPage.value = response.data!.paginationInfo!.currentPage!.toInt();
        totalPages.value = response.data!.paginationInfo!.totalPages!.toInt();

        // Build motor map
        final motorMap = _buildMotorMap(allMotors);

        // Update the singleton motor map with the freshly fetched motors.
        // If the listener was already registered (e.g. after a refresh), remove
        // it first so we don't double-fire on every MQTT notification.
        if (mqttInitialized) {
          mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
        }
        mqttService = MqttService(initialMotors: motorMap);
        mqttInitialized = true;
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        if (mqttService.isConnected) {
          // MQTT is already connected (global connection established at login
          // or by a previous screen). Just sync the UI with current data.
          debugPrint('DASHBOARD: MQTT already connected — reusing connection');
          if (motorMap.isNotEmpty) _onMqttUpdate();
        } else {
          // Not connected yet (first launch or after logout+login). Establish
          // the connection in the background so the UI is not blocked.
          debugPrint('DASHBOARD: Initializing MQTT client...');
          mqttService.initializeMqttClient().then((_) {
            debugPrint('DASHBOARD: MQTT client initialized successfully');
            if (motorMap.isNotEmpty) _onMqttUpdate();
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

          // Only overwrite the API fault value when MQTT reports a non-zero
          // fault. Keeping 0 from MQTT would erase the real fault description
          // that was just fetched from the API via fetchMotorsSilently.
          if (currentMotorData.fault != 0) {
            params.fault = currentMotorData.fault;
            // Reset faultCleared so the UI shows the new fault even if a
            // previous fault was cleared via API.
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
      // Instantly refresh API data after toggle so fault description
      // and run-time update immediately without waiting for the timer.
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
      // Schedule UI index (2) → device code 6; Auto/Manual pass through.
      final deviceCode = modeIndex == 2 ? 6 : modeIndex;
      await mqttService.publishModeCommand(motorId, deviceCode);
      // Instantly refresh API data after mode change so description
      // updates immediately without waiting for the background timer.
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
