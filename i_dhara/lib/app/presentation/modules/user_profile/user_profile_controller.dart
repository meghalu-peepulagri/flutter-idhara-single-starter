import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/mixins/connectivity_mixin.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:i_dhara/app/data/models/user_profile/user_profile_model.dart';
import 'package:i_dhara/app/data/repository/user_profile/user_profile_repo_impl.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

import '../../../data/repository/auth/auth_repository_impl.dart';
import '../../../data/services/mqtt_manager/mqtt_service.dart';
import '../../../data/services/storages/shared_preference.dart';
import '../dashboard/dashboard_controller.dart';
import '../devices/devices_controller.dart';
import '../locations/locations_controller.dart';

class UserProfileController extends GetxController with ConnectivityMixin {
  final Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final appVersion = ''.obs;
  final appBuildNumber = ''.obs;

  @override
  Future<void> onRetry() async {
    Get.log('UserProfileController: Retrying API calls after reconnection');
    await fetchUserProfile();
  }

  @override
  void onInit() {
    fetchUserProfile();
    _fetchAppVersion();
    super.onInit();
  }

  Future<void> _fetchAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = info.version;
    appBuildNumber.value = info.buildNumber;
  }

  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await fetchUserProfile(showLoader: false);
    isRefreshing.value = false;
  }

  Future<void> fetchUserProfile({bool showLoader = true}) async {
    try {
      if (showLoader) isLoading.value = true;
      final response = await UserProfileRepoImpl().getUserProfile();
      if (response != null) {
        userProfile.value = response.data;
      }
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  Future<void> fetchFcmToken() async {
    final response = await AuthRepositoryImpl().fetchlogout();
    if (response?.status == 200 || response?.status == 201) {
      MqttService().disconnectOnly();
      DashboardController.clearMotorCache();
      await SharedPreference.clear();
      FirebaseMessaging.instance.getToken().then((value) {
        SharedPreference.setFcmToken(value!);
      });
      Get.deleteAll(force: true);
      if (Get.isRegistered<DashboardController>()) {
        Get.delete<DashboardController>(force: true);
      }
      Get.delete<LocationsController>(force: true);
      Get.delete<DevicesController>(force: true);
      Get.offAllNamed(Routes.loginwithmobile);
      SharedPreference.clear();
    }
  }
}
