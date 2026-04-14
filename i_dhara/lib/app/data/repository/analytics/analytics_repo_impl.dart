import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

// Top-level function required by compute() — runs in a background isolate.
// Parses up to 20k Runtime records (5× DateTime.parse each) off the main thread.
MotorRunTimeResponse _parseMotorRunTime(Map<String, dynamic> json) =>
    MotorRunTimeResponse.fromJson(json);

class AnalyticsRepositoryImpl extends AnalyticsRepository {
  @override
  Future<CurrentResponse?> getCurrent(String fromDate, String toDate) async {
    Map<String, dynamic> queryParams = {
      'from_date': fromDate,
      'to_date': toDate,
      'motor_id': SharedPreference.getMotorId(),
      'parameter': 'current',
    };
    final response = await NetworkManager().get(
        '/starters/${SharedPreference.getStarterId()}/analytics',
        queryParameters: queryParams);
    if (response.statusCode == 200) {
      final data = CurrentResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }

  @override
  Future<VoltageResponse?> getVoltage(String fromDate, String toDate) async {
    Map<String, dynamic> queryParams = {
      'from_date': fromDate,
      'to_date': toDate,
      'motor_id': SharedPreference.getMotorId(),
      'parameter': 'voltage',
    };
    final response = await NetworkManager().get(
        '/starters/${SharedPreference.getStarterId()}/analytics',
        queryParameters: queryParams);
    if (response.statusCode == 200) {
      final data = VoltageResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }

  @override
  Future<MotorRunTimeResponse?> getMotorRunTime(String fromDate, String toDate,
      {String? state}) async {
    Map<String, dynamic> queryParams = {
      'from_date': fromDate,
      'to_date': toDate,
      'motor_id': SharedPreference.getMotorId(),
    };
    if (state != null) {
      queryParams['state'] = state;
    }
    final response = await NetworkManager().get(
        '/starters/${SharedPreference.getStarterId()}/run-time',
        queryParameters: queryParams);
    if (response.statusCode == 200) {
      // Offload JSON → Dart object mapping to a background isolate.
      // Without this, 20k records × 5 DateTime.parse() calls blocks the UI thread.
      final data = await compute(
        _parseMotorRunTime,
        Map<String, dynamic>.from(response.data as Map),
      );
      return data;
    } else {
      return null;
    }
  }
}
