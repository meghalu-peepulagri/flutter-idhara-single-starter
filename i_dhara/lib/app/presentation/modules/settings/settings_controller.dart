import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/mixins/connectivity_mixin.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repo_impl.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

import '../../../core/utils/mqtt_utils.dart';
import '../../../data/dto/device_setting_dto.dart';
import '../../../data/models/settings/user_setting_limits2_model.dart';

class SettingsController extends GetxController with ConnectivityMixin {
  TabController? tabBarController;

  final Rx<UserSettings2?> userSettings2 = Rx<UserSettings2?>(null);

  // ✅ Typed reactive map
  final RxMap<String, dynamic> updateSettingDto = <String, dynamic>{}.obs;
  Map<String, dynamic> defaultSettingspayload = {};

  // Per-motor config to attach to the POST body for multi-motor saves.
  Map<String, dynamic>? pendingMultiMotorConfig;

  var lvf = 0.obs;
  var hvf = 0.obs;
  var drf = 0.obs;
  var olf = 0.obs;
  var lvr = 0.obs;
  var hvr = 0.obs;
  var lrf = 0.0.obs;
  var olr = 0.0.obs;
  var lrr = 0.0.obs;
  var orignolFlc = 0.0.obs;

  var calculatedLrf = 0.0.obs;
  var calculatedOlr = 0.0.obs;
  var calculatedLrr = 0.0.obs;

  Map<String, dynamic> payload = {};
  var isrefreshing = false.obs;
  var pumpName = ''.obs;
  var pumpHP = ''.obs;
  var pcbNumber = ''.obs;
  var macAddress = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  var data = Rxn<UserSettingsLimits>();
  // Removed local connectivity logic, handled by ConnectivityMixin and ConnectivityService
  bool mqttInitialized = false;
  var flc = 0.0.obs;
  var asDly = 0.obs;

  /// Star-delta changeover time (multi_motor_config.sd_time). Only meaningful
  /// when the starter reports motor_starter_type STAR_DELTA.
  var sdTime = 0.obs;

  int get sdTimeMin => data.value?.startTimeMin ?? 0;
  int get sdTimeMax => data.value?.startTimeMax ?? 0;

  bool get isStarDelta =>
      (userSettings2.value?.starter?.motorStarterType ?? '')
          .toUpperCase()
          .replaceAll(' ', '_') ==
      'STAR_DELTA';

  // Per-motor FLC (multi-motor), keyed by motor_reference.
  final RxMap<String, double> motorFlc = <String, double>{}.obs;

  void initMotorFlc() {
    motorFlc.clear();
    for (final m in motorConfigsForUi()) {
      final ref = m.motorReference ?? 'm${m.motorIndex ?? ''}';
      if (ref.isNotEmpty) motorFlc[ref] = (m.flc ?? 0).toDouble();
    }
  }

  double originalMotorFlc(String ref) {
    for (final m in motorConfigsForUi()) {
      final r = m.motorReference ?? 'm${m.motorIndex ?? ''}';
      if (r == ref) return (m.flc ?? 0).toDouble();
    }
    return 0.0;
  }

  @override
  Future<void> onRetry() async {
    Get.log('SettingsController: Retrying API calls after reconnection');
    await fetchdata();
  }

  Future<void> fetchdata() async {
    if (!isrefreshing.value) isLoading.value = true;
    try {
      await Future.wait([fetchUserSettings2(), fetchUserSettingsLimits()]);
    } finally {
      isrefreshing.value = false;
      isLoading.value = false;
    }
  }

  String motorName() {
    final settings = userSettings2.value;
    if (settings?.starter == null) {
      return "N/A";
    }

    final motor = settings!.starter!.motors?.first;
    if (motor == null) {
      return "N/A";
    }

    // Return aliasName if it exists and is not empty, otherwise return name
    final aliasName = motor.aliasName?.toString().trim() ?? '';
    if (aliasName.isNotEmpty) {
      return aliasName;
    }

    return motor.name?.toString() ?? 'N/A';
  }

  String motorHP() {
    final settings = userSettings2.value;
    if (settings?.starter != null) {
      if (settings!.starter!.motors!.first.hp != null) {
        return settings.starter!.motors!.first.hp.toString();
      }
    } else {
      return "0";
    }
    return settings.starter!.motors!.first.hp.toString();
  }

  Future<void> fetchUserSettings2() async {
    try {
      // errorMessage.value = '';
      final response = await SettingsRepositoryImpl().getSettings2();
      if (response != null &&
          response.success == true &&
          response.data != null) {
        userSettings2.value = response.data;
        final deviceallocate = userSettings2.value?.starter?.deviceAllocation;
        final pcb = userSettings2.value?.starter?.pcbNumber;
        final mac = userSettings2.value?.starter?.macAddress;

        pumpName.value = motorName();
        pumpHP.value = motorHP();
        pcbNumber.value = getMotorIdentifier(
            deviceallocate ?? 'true', pcb.toString(), mac.toString());

        macAddress.value = response.data?.starter?.macAddress ?? '';
        flc.value = userSettings2.value?.flc?.toDouble() ?? 0.0;
        orignolFlc.value = userSettings2.value?.flc?.toDouble() ?? 0.0;
        asDly.value = userSettings2.value?.asDly ?? 0;
        sdTime.value =
            (userSettings2.value?.multiMotorConfig?.sdTime ?? 0).toInt();

        initMotorFlc();
        if (isMultiMotorDevice) {
          final configs = motorConfigsForUi();
          if (configs.isNotEmpty) {
            flc.value = (configs.first.flc ?? 0).toDouble();
          }
        }
        lvf.value = userSettings2.value?.lvf?.toInt() ?? 0;
        hvf.value = userSettings2.value?.hvf?.toInt() ?? 0;
        drf.value = userSettings2.value?.drf?.toInt() ?? 0;
        olf.value = userSettings2.value?.olf?.toInt() ?? 0;
        lvr.value = userSettings2.value?.lvr?.toInt() ?? 0;
        hvr.value = userSettings2.value?.hvr?.toInt() ?? 0;
        lrf.value = userSettings2.value?.lrf?.toDouble() ?? 0.0;
        olr.value = userSettings2.value?.olr?.toDouble() ?? 0.0;
        lrr.value = userSettings2.value?.lrr?.toDouble() ?? 0.0;

        payload = {
          "dvc_c": {
            "lvf": lvf.value,
            "hvf": hvf.value,
            "drf": drf.value,
            "olf": olf.value,
          },
        };

        updateSettingDto.assignAll(response.data!.toJson());
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");
      } else {
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
    }
  }

  double calculatedFlc(double val, double flcVal) {
    final percentLow = val.toInt() / 100;
    final res = percentLow * flcVal;
    final newRes = double.parse(res.toStringAsFixed(2)) ?? 0.0;
    return newRes;
  }

  bool get isMultiMotor =>
      (userSettings2.value?.multiMotorConfig?.motors?.isNotEmpty ?? false);

  bool get isMultiMotorDevice =>
      SharedPreference.getIsMultiMotor() || isMultiMotor;

  String headerTitle() {
    if (isMultiMotorDevice) {
      final sn = SharedPreference.getStarterNumber();
      if (sn.trim().isNotEmpty) return '#$sn';
    }
    return pumpName.value;
  }

  List<MotorSettingConfig> orderedMotorConfigs() {
    final motors = List<MotorSettingConfig>.from(
        userSettings2.value?.multiMotorConfig?.motors ?? const []);
    motors.sort(
        (a, b) => (a.motorIndex ?? 99).compareTo(b.motorIndex ?? 99));
    return motors;
  }

  // One config per starter motor (the reliable motor list). Uses the real
  // per-motor config when present, else falls back to the flat limits so a
  // multi-motor device always shows every motor even if the settings API
  // omits multi_motor_config for some motors.
  List<MotorSettingConfig> motorConfigsForUi() {
    final configs = orderedMotorConfigs();
    final starterMotors = userSettings2.value?.starter?.motors ?? const [];

    if (starterMotors.isEmpty) return configs;
    if (configs.length >= starterMotors.length) return configs;

    final byId = {for (final c in configs) c.motorId: c};
    final result = <MotorSettingConfig>[];
    for (var i = 0; i < starterMotors.length; i++) {
      final sm = starterMotors[i];
      final existing = byId[sm.id];
      if (existing != null) {
        result.add(existing);
      } else {
        result.add(MotorSettingConfig(
          motorId: sm.id,
          motorIndex: i + 1,
          motorReference: 'm${i + 1}',
          drf: drf.value,
          olf: olf.value,
          flc: flc.value,
        ));
      }
    }
    return result;
  }

  String? currentMotorReference() {
    final motors = userSettings2.value?.multiMotorConfig?.motors;
    if (motors == null || motors.isEmpty) return null;
    final currentMotorId = SharedPreference.getMotorId();
    for (final m in motors) {
      if (m.motorId == currentMotorId) return m.motorReference;
    }
    return motors.first.motorReference;
  }

  void wrapPayloadForMultiMotor(Map<String, dynamic> payload) {
    final ref = currentMotorReference();
    if (ref == null || ref.isEmpty) return;
    final dvc = payload["dvc_c"];
    if (dvc is! Map<String, dynamic>) return;
    final deviceLevel = <String, dynamic>{};
    for (final k in const ['as_dly']) {
      if (dvc.containsKey(k)) deviceLevel[k] = dvc.remove(k);
    }
    payload["dvc_c"] = {...deviceLevel, ref: dvc};
  }

  Future<void> fetchUserSettingsLimits() async {
    try {
      final response = await SettingsRepositoryImpl().getSettingsLimits();
      if (response?.status == 200 || response?.status == 201) {
        data.value = response?.data;
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
    }
  }

  Future<void> fetchDefaultupdateSettings() async {
    try {
      UserUpdateSettingsDto dto =
          UserUpdateSettingsDto.fromJson(updateSettingDto);
      final response = await SettingsRepositoryImpl().updateSettings(dto);
      if (response?.status == 200 || response?.status == 201) {
      } else {
        errorMessage.value = response?.message ?? 'Failed to update settings';
      }
    } catch (e) {
      errorMessage.value = 'Error updating settings: $e';
    }
  }

  Future<void> fetchupdateSettings() async {
    try {
      updateSettingDto['lvf'] = lvf.value;
      updateSettingDto['hvf'] = hvf.value;
      updateSettingDto['drf'] = drf.value;
      updateSettingDto['olf'] = olf.value;
      updateSettingDto['lvr'] = lvr.value;
      updateSettingDto['hvr'] = hvr.value;
      updateSettingDto['flc'] = flc.value;
      updateSettingDto['as_dly'] = asDly.value;
      if (isMultiMotorDevice && isStarDelta) {
        updateSettingDto['start_time'] = sdTime.value;
      }

      if (isMultiMotorDevice && pendingMultiMotorConfig != null) {
        updateSettingDto['multi_motor_config'] = pendingMultiMotorConfig;
      } else {
        updateSettingDto.remove('multi_motor_config');
      }

      UserUpdateSettingsDto dto =
          UserUpdateSettingsDto.fromJson(updateSettingDto);
      final response = await SettingsRepositoryImpl().updateSettings(dto);
      if (response?.status == 200 || response?.status == 201) {
      } else {
        errorMessage.value = response?.message ?? 'Failed to update settings';
      }
    } catch (e) {
      errorMessage.value = 'Error updating settings: $e';
    }
  }

  Future<void> fetchdefaultSettings() async {
    try {
      isLoading.value = true;
      final res = await SettingsRepositoryImpl().getDefaultSettings();
      if (res?.status == 200 || res?.status == 201) {
        // Capture motor count before the generic default overwrites userSettings2.
        final int motorCount = motorConfigsForUi().length;
        final bool multi = isMultiMotorDevice;
        final origConfig = userSettings2.value?.multiMotorConfig;
        final origStarter = userSettings2.value?.starter;
        userSettings2.value = res?.data;
        // The generic default has no per-motor config — keep the device's motor
        // structure so the multi-motor UI keeps rendering after "Default".
        if (multi) {
          userSettings2.value?.multiMotorConfig = origConfig;
          userSettings2.value?.starter = origStarter;
        }
        macAddress.value = res?.data?.starter?.macAddress ?? '';
        lvf.value = userSettings2.value?.lvf ?? 0;
        hvf.value = userSettings2.value?.hvf ?? 0;
        drf.value = userSettings2.value?.drf?.toInt() ?? 0;
        olf.value = userSettings2.value?.olf?.toInt() ?? 0;
        asDly.value = userSettings2.value?.asDly ?? 0;
        final data = userSettings2.value;
        final hvr = (data?.hvf?.toDouble() ?? 0) - 10;
        final lvr = (data?.lvf?.toDouble() ?? 0) + 10;

        if (multi) {
          final flcVal = data?.flc?.toDouble() ?? 0;
          final perMotor = <String, dynamic>{
            "flt_en": data?.prFltEn ?? 0,
            "flc": data?.flc ?? 0,
            "drf": calculatedFlc(data?.drf?.toDouble() ?? 0, flcVal),
            "olf": calculatedFlc(data?.olf?.toDouble() ?? 0, flcVal),
            "lrf": calculatedFlc(data?.lrf?.toDouble() ?? 0, flcVal),
            "opf": data?.opf ?? 0,
            "cif": data?.cif ?? 0,
          };
          defaultSettingspayload = {
            "dvc_c": {
              "allflt_en": data?.allfltEn ?? 0,
              "n_mtr": motorCount,
              "on_dly": data?.asDly,
              "ipf": data?.ipf ?? 0,
              "lvf": data?.lvf ?? 0,
              "hvf": data?.hvf ?? 0,
              "vif": data?.vif ?? 0,
              "m1": perMotor,
              "m2": Map<String, dynamic>.from(perMotor),
            }
          };

          // Reflect the same default values in each motor of the UI list so the
          // screen matches the published payload (drf/olf stored as amps).
          final uiMotors = userSettings2.value?.multiMotorConfig?.motors;
          if (uiMotors != null) {
            for (final m in uiMotors) {
              m.flc = data?.flc;
              m.drf = perMotor['drf'] as num?;
              m.olf = perMotor['olf'] as num?;
              m.lrf = perMotor['lrf'] as num?;
              m.opf = data?.opf;
              m.cif = data?.cif;
              m.fltEn = data?.prFltEn;
            }
          }
          initMotorFlc();
        } else {
          defaultSettingspayload = {
            "dvc_c": {
              "allflt_en": data?.allfltEn ?? 0,
              "flc": data?.flc ?? 0,
              "as_dly": data?.asDly,
              "ipf": data?.ipf ?? 0,
              "lvf": data?.lvf ?? 0,
              "hvf": data?.hvf ?? 0,
              "vif": data?.vif ?? 0,
              "paminf": data?.paminf ?? 0,
              "pamaxf": data?.pamaxf ?? 0,
              "lvr": lvr ?? 0.0,
              "hvr": hvr ?? 0.0,
              "drf": calculatedFlc(
                  data?.drf?.toDouble() ?? 0, data!.flc!.toDouble()),
              "olf": calculatedFlc(
                  data.olf?.toDouble() ?? 0, data.flc!.toDouble()),
              "lrf": calculatedFlc(
                  data.lrf?.toDouble() ?? 0, data.flc!.toDouble()),
              "opf": data.opf ?? 0,
              "cif": data.cir ?? 0,
              "olr": calculatedFlc(
                  data.olr?.toDouble() ?? 0, data.flc!.toDouble()),
              "lrr": calculatedFlc(
                  data.lrr?.toDouble() ?? 0, data.flc!.toDouble()),
              "cir": data.cir ?? 0,
              "pr_flt_en": data.prFltEn ?? 0
            }
          };

          wrapPayloadForMultiMotor(defaultSettingspayload);
        }

        updateSettingDto.assignAll(res!.data!.toJson());
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");
      }
    } finally {
      isLoading.value = false;
      Get.back();
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
      }
    } finally {
      await fetchUserSettings2();
    }
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    super.dispose();
  }
}
