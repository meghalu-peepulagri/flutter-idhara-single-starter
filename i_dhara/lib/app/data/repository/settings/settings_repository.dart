import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';

abstract class SettingsRepository {
  Future<UserSettingsResponse?> getSettings();
  Future<UserSettingsLimitsResponse?> getSettingsLimits();
}
