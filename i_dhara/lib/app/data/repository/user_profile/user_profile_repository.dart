import 'package:i_dhara/app/data/models/user_profile/user_profile_model.dart';

abstract class UserProfileRepository {
  Future<UserProfileResponse?> getUserProfile();
}
