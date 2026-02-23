import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/mixins/connectivity_mixin.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repo_impl.dart';

import '../../../core/utils/mqtt_utils.dart';
import '../../../data/dto/device_setting_dto.dart';
import '../../../data/models/settings/user_setting_limits2_model.dart';

class SettingsController extends GetxController with ConnectivityMixin {
  TabController? tabBarController;

  final Rx<UserSettings2?> userSettings2 = Rx<UserSettings2?>(null);

  // ✅ Typed reactive map
  final RxMap<String, dynamic> updateSettingDto = <String, dynamic>{}.obs;
  Map<String, dynamic> defaultSettingspayload = {};

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
    print("line 103");

    try {
      // errorMessage.value = '';
      final response = await SettingsRepositoryImpl().getSettings2();
      if (response != null &&
          response.success == true &&
          response.data != null) {
        userSettings2.value = response.data;

        print("line 114 ${userSettings2.value?.toJson()}");

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
      print('Error fetching user settings: $e');
    }
  }

  double calculatedFlc(double val, double flcVal) {
    final percentLow = val.toInt() / 100;
    final res = percentLow * flcVal;
    final newRes = double.parse(res.toStringAsFixed(2)) ?? 0.0;
    return newRes;
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
      print('Error updating user settings: $e');
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

      UserUpdateSettingsDto dto =
          UserUpdateSettingsDto.fromJson(updateSettingDto);
      final response = await SettingsRepositoryImpl().updateSettings(dto);
      if (response?.status == 200 || response?.status == 201) {
      } else {
        errorMessage.value = response?.message ?? 'Failed to update settings';
      }
    } catch (e) {
      errorMessage.value = 'Error updating settings: $e';
      print('Error updating user settings: $e');
    }
  }

  Future<void> fetchdefaultSettings() async {
    try {
      isLoading.value = true;
      final res = await SettingsRepositoryImpl().getDefaultSettings();
      if (res?.status == 200 || res?.status == 201) {
        userSettings2.value = res?.data;
        macAddress.value = res?.data?.starter?.macAddress ?? '';
        lvf.value = userSettings2.value?.lvf ?? 0;
        hvf.value = userSettings2.value?.hvf ?? 0;
        drf.value = userSettings2.value?.drf?.toInt() ?? 0;
        olf.value = userSettings2.value?.olf?.toInt() ?? 0;
        final data = userSettings2.value;
        final hvr = (data?.hvf?.toDouble() ?? 0) - 10;
        final lvr = (data?.lvf?.toDouble() ?? 0) + 10;

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
            "olf":
                calculatedFlc(data.olf?.toDouble() ?? 0, data.flc!.toDouble()),
            "lrf":
                calculatedFlc(data.lrf?.toDouble() ?? 0, data.flc!.toDouble()),
            "opf": data.opf ?? 0,
            "cif": data.cir ?? 0,
            "olr":
                calculatedFlc(data.olr?.toDouble() ?? 0, data.flc!.toDouble()),
            "lrr":
                calculatedFlc(data.lrr?.toDouble() ?? 0, data.flc!.toDouble()),
            "cir": data.cir ?? 0,
            "pr_flt_en": data.prFltEn ?? 0
          }
        };

        updateSettingDto.assignAll(res!.data!.toJson());
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");
      }
    } catch (e) {
      print("error ---> $e");
    } finally {
      isLoading.value = false;
      Get.back();
    }
  }

  Future<void> fetchupdateSettingsAck() async {
    print("line 230");
    try {
      try {
        final response = await SettingsRepositoryImpl().updateSettingsAck();
        if (response?.status == 200 || response?.status == 201) {
        } else {
          errorMessage.value = response?.message ?? 'Failed to update settings';
        }
      } catch (e) {
        errorMessage.value = 'Error updating settings: $e';
        print('Error updating user settings: $e');
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
