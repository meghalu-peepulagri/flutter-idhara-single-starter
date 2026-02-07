import 'dart:convert';

import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_limits_model.dart';
import 'package:i_dhara/app/data/models/settings/user_settings_model.dart';
import 'package:i_dhara/app/data/repository/settings/settings_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

import '../../dto/device_setting_dto.dart';
import '../../models/settings/update_user_settings_model.dart';
import '../../models/settings/user_setting_limits2_model.dart';
import '../../services/storages/hive_handler.dart';

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
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    final response = await NetworkManager().get('/settings/acknowledged/$starterId');
    if (response.statusCode == 200) {
      final res = UserSettingsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<UserSettingsResponse2?> getSettings2() async {
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    final response = await NetworkManager().get('/settings/starter/$starterId');
    if (response.statusCode == 200) {
      final res = UserSettingsResponse2.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<UserSettingsLimitsResponse?> getSettingsLimits() async {
    final Map<String, dynamic> query = {
      "columns": "drf_min,drf_max,olf_min,olf_max" // ✅ no spaces
    };

    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    final response = await NetworkManager()
        .get('/settings/limits-mobile/$starterId', queryParameters: query);
    try {
      if (response.statusCode == 200) {
        final res = UserSettingsLimitsResponse.fromJson(response.data);
        return res;
      }
    } catch (e) {
      print("line 61  $e");
      return null;
    }
    return null;
  }

  @override
  Future<UpdateUserSettingResponse?> updateSettings(
      UserUpdateSettingsDto dto) async {
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    final response = await NetworkManager().post(
      '/settings/starter/$starterId',
      {},
      data: jsonEncode(dto.toJson()),
    );
    print("line 68 ----------->  ${response.statusCode}----->");

    if (response.statusCode == 200) {
      final res = UpdateUserSettingResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
