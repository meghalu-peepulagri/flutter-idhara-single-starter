import 'dart:convert';

import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

import '../../dto/device_setting_dto.dart';
import '../../models/settings/update_user_settings_model.dart';
import '../../models/settings/user_setting_limits2_model.dart';

class SettingsRepositoryImpl extends SettingsRepository {
  @override
  Future<UserSettingsResponse2?> getDefaultSettings() async {
    final response = await NetworkManager().get('/settings/default');
    if (response.statusCode == 200) {
      final res = UserSettingsResponse2.fromJson(response.data);
      return res;
    }
    return null;
  }

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
  Future<UserSettingsResponse2?> getSettings2() async {
    final id = SharedPreference.getStarterId();
    final response = await NetworkManager().get('/settings/starter/$id');
    if (response.statusCode == 200) {
      final res = UserSettingsResponse2.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<UserSettingsLimitsResponse?> getSettingsLimits() async {
    final Map<String, dynamic> query = {
      "columns":
          "drf_min,drf_max,olf_min,olf_max,flc_min,flc_max" // ✅ no spaces
    };
    final id = SharedPreference.getStarterId();
    final response = await NetworkManager()
        .get('/settings/limits-mobile/$id', queryParameters: query);
    try {
      if (response.statusCode == 200) {
        final res = UserSettingsLimitsResponse.fromJson(response.data);
        return res;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Future<UpdateUserSettingResponse?> updateSettings(
      UserUpdateSettingsDto dto) async {
    final id = SharedPreference.getStarterId();
    final response = await NetworkManager().post(
      '/settings/starter/$id',
      {},
      data: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200) {
      final res = UpdateUserSettingResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<UpdateUserSettingResponse?> updateSettingsAck() async {
    final id = SharedPreference.getStarterId();
    final response = await NetworkManager().patch(
      '/settings/starter/$id/acknowledgement-update',
    );

    if (response.statusCode == 200) {
      final res = UpdateUserSettingResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
