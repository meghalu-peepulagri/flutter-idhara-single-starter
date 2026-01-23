import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class SettingsRepositoryImpl extends SettingsRepository {
  @override
  Future<UserSettingsResponse?> getSettings() async {
    final id = SharedPreference.getStarterId();
    final response = await NetworkManager().get('/settings/acknowledged/$id');
    if (response.statusCode == 200) {
      final res = UserSettingsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<UserSettingsLimitsResponse?> getSettingsLimits() async {
    final id = SharedPreference.getStarterId();
    final response = await NetworkManager().get('/settings/limits-mobile/$id');
    if (response.statusCode == 200) {
      final res = UserSettingsLimitsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
