import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repo_impl.dart';

class SettingsController extends GetxController {
  // State field(s) for TabBar widget.
  TabController? tabBarController;

  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  final Rx<UserSettings?> userSettings = Rx<UserSettings?>(null);
  final Rx<UserSettingsLimits?> userSettingsLimits =
      Rx<UserSettingsLimits?>(null);

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  UserSettingsLimits? data;

  @override
  void onInit() {
    super.onInit();
    fetchUserSettings();
    fetchUserSettingsLimits();
  }

  @override
  void dispose() {
    tabBarController?.dispose();
    super.dispose();
  }

  Future<void> fetchUserSettings() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await SettingsRepositoryImpl().getSettings();

      if (response != null &&
          response.success == true &&
          response.data != null) {
        userSettings.value = response.data;
      } else {
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
      print('Error fetching user settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserSettingsLimits() async {
    try {
      final response = await SettingsRepositoryImpl().getSettingsLimits();

      if (response != null &&
          response.success == true &&
          response.data != null) {
        data = response.data;
      } else {
        errorMessage.value = response?.message ?? 'Failed to load settings';
      }
    } catch (e) {
      errorMessage.value = 'Error loading settings: $e';
      print('Error fetching user settings: $e');
    } finally {
      // isLoading.value = false;
    }
  }
}
