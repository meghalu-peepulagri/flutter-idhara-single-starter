import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/user_profile/user_profile_model.dart';
import 'package:i_dhara/app/data/repository/user_profile/user_profile_repo_impl.dart';

class UserProfileController extends GetxController {
  final Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  final isLoading = true.obs;
  final isRefreshing = false.obs;

  @override
  void onInit() {
    fetchUserProfile();
    super.onInit();
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
}
