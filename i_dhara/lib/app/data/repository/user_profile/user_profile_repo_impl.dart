import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/user_profile/user_profile_model.dart';
import 'package:i_dhara/app/data/repository/user_profile/user_profile_repository.dart';

class UserProfileRepoImpl extends UserProfileRepository {
  @override
  Future<UserProfileResponse?> getUserProfile() async {
    final response = await NetworkManager().get('/users/profile');
    if (response.statusCode == 200) {
      final res = UserProfileResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
