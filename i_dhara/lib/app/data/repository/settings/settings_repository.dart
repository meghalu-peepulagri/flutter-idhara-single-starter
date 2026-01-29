import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';

import '../../dto/device_setting_dto.dart';
import '../../models/settings/update_user_settings_model.dart';
import '../../models/settings/user_setting_limits2_model.dart';

abstract class SettingsRepository {
  Future<UserSettingsResponse?> getSettings();
  Future<UserSettingsResponse2?> getSettings2();
  Future<UserSettingsLimitsResponse?> getSettingsLimits();
  Future<UpdateUserSettingResponse?> updateSettings(UserUpdateSettingsDto dto);
  Future<UserSettingsResponse2?> getDefaultSettings();
}
