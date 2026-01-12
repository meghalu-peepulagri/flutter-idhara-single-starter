import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repository.dart';

class SettingsRepositoryImpl extends SettingsRepository {
  @override
  Future<UserSettingsResponse?> getSettings() async {
    final response = await NetworkManager().get('/settings/starter/168');
    if (response.statusCode == 200) {
      final res = UserSettingsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<UserSettingsLimitsResponse?> getSettingsLimits() async {
    final response = await NetworkManager().get('/settings/limits/168');
    if (response.statusCode == 200) {
      final res = UserSettingsLimitsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
