import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repo_impl.dart';

import '../../../data/dto/device_setting_dto.dart';
import '../../../data/models/settings/user_setting_limits2_model.dart';

class SettingsController extends GetxController {
  TabController? tabBarController;

  final Rx<UserSettings2?> userSettings2 = Rx<UserSettings2?>(null);

  // ✅ Typed reactive map
  final RxMap<String, dynamic> updateSettingDto = <String, dynamic>{}.obs;

  var lvf = 0.obs;
  var hvf = 0.obs;
  var drf = 0.obs;
  var olf = 0.obs;
  Map<String, dynamic> payload = {};
  var isrefreshing = false.obs;
  var pumpName = ''.obs;
  var pumpHP = ''.obs;
  var pcbNumber = ''.obs;
  var macAddress = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  var data = Rxn<UserSettingsLimits>();

  @override
  void onInit() {
    super.onInit();
    fetchdata();
  }

  String pcbnumberPass(Starter? starter) {
    print("line 190");
    print("line 191 ${starter!.toJson()}");
    try {
      if (starter.pcbNumber != null) {
        return starter.pcbNumber.toString();
      } else if (starter.macAddress != null) {
        return starter.macAddress.toString();
      } else {
        return '';
      }
    } catch (e) {
      print("error ---> $e");
      return '';
    }
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
    if (settings?.starter != null) {
      if (settings!.starter!.motors!.first.aliasName != null) {
        return settings.starter!.motors!.first.aliasName.toString();
      }
    } else {
      return "N/A";
    }

    return settings.starter!.motors!.first.name.toString();
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
        print("line 90");
        userSettings2.value = response.data;
        pumpName.value = motorName();
        pumpHP.value = motorHP();

        pcbNumber.value = pcbnumberPass(response.data?.starter);
        macAddress.value = response.data?.starter?.macAddress ?? '';
        print("line 101 pcb ${pcbNumber.value}");
        print("line 102 mac ${macAddress.value}");
        lvf.value = userSettings2.value?.lvf?.toInt() ?? 0;
        hvf.value = userSettings2.value?.hvf?.toInt() ?? 0;
        drf.value = userSettings2.value?.drf?.toInt() ?? 0;
        olf.value = userSettings2.value?.olf?.toInt() ?? 0;

        payload = {
          "dvc_c": {
            "lvf": lvf.value,
            "hvf": hvf.value,
            "drf": drf.value,
            "olf": olf.value,
          },
        };
        print("line 101 $payload");

        updateSettingDto.assignAll(response.data!.toJson());
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");

        print("line 185 ${updateSettingDto.toJson()}");
      } else {
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
      print('Error fetching user settings: $e');
    }
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

  Future<void> fetchupdateSettings() async {
    try {
      updateSettingDto['lvf'] = lvf.value;
      updateSettingDto['hvf'] = hvf.value;
      updateSettingDto['drf'] = drf.value;
      updateSettingDto['olf'] = olf.value;
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
        pcbNumber.value = pcbnumberPass(res?.data?.starter);
        macAddress.value = res?.data?.starter?.macAddress ?? '';
        lvf.value = userSettings2.value?.lvf ?? 0;
        hvf.value = userSettings2.value?.hvf ?? 0;
        drf.value = userSettings2.value?.drf?.toInt() ?? 0;
        olf.value = userSettings2.value?.olf?.toInt() ?? 0;

        payload = {
          "dvc_c": {
            "lvf": lvf.value,
            "hvf": hvf.value,
            "drf": drf.value,
            "olf": olf.value,
          },
        };
        print("line 101 $payload");

        updateSettingDto.assignAll(res!.data!.toJson());
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");
        print("line 185 ${updateSettingDto.toJson()}");
      }
    } catch (e) {
      print("error ---> $e");
    } finally {
      isLoading.value = false;
      Get.back();
    }
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    super.dispose();
  }
}
