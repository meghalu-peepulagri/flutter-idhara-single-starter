import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
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

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  var data = Rxn<UserSettingsLimits>();

  @override
  void onInit() {
    super.onInit();
    fetchdata();
  }

  Future<void> fetchdata() async {
    isLoading.value = true;
    await Future.wait([fetchUserSettings2(), fetchUserSettingsLimits()]);
    isLoading.value = false;
  }

  Future<void> fetchUserSettings2() async {
    try {
      errorMessage.value = '';
      final response = await SettingsRepositoryImpl().getSettings2();

      if (response != null &&
          response.success == true &&
          response.data != null) {
        userSettings2.value = response.data;

        print("line 63 ------> \n${response.data}");

        lvf.value = userSettings2.value?.lvf ?? 0;
        hvf.value = userSettings2.value?.hvf ?? 0;

        print("line 53 ----> \n${response.data}");
        // ✅ Proper assignment
        updateSettingDto.assignAll(response.data!.toJson());

        print("line 57 ----> \n$updateSettingDto");

        // ✅ Remove server-only fields
        updateSettingDto.removeWhere((key, value) =>
            key == "updated_at" || key == "created_at" || key == "created_by");

        print("line 66-----> \n$updateSettingDto");
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
      print("line 75");
      final response = await SettingsRepositoryImpl().getSettingsLimits();
      if (response?.status == 200 || response?.status == 201) {
        data.value = response?.data;
        print("line 78 ----->\n ${data.toJson()}");
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
    }
  }

  Future<void> fetchupdateSettings() async {
    try {
      print("line 100-----> \n$updateSettingDto");

      // ✅ update values
      updateSettingDto['lvf'] = lvf.value;
      updateSettingDto['hvf'] = hvf.value;

      print("line 103 ------> \n$updateSettingDto");

      UserUpdateSettingsDto dto =
          UserUpdateSettingsDto.fromJson(updateSettingDto);

      final response = await SettingsRepositoryImpl().updateSettings(dto);

      if (response?.status == 200 || response?.status == 201) {
        getsuccessSnackBar(response!.message.toString());
        // Get.offNamed(Routes.devices);
      } else {
        errorMessage.value = response?.message ?? 'Failed to update settings';
      }
    } catch (e) {
      errorMessage.value = 'Error updating settings: $e';
      print('Error updating user settings: $e');
    }
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    super.dispose();
  }
}
