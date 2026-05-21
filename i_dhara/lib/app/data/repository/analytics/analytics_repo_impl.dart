import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/device_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_total_runtime_model.dart';
import 'package:i_dhara/app/data/models/graphs/power_status_history_model.dart';
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
      final data = await compute(
        _parseMotorRunTime,
        Map<String, dynamic>.from(response.data as Map),
      );
      return data;
    } else {
      return null;
    }
  }

  @override
  Future<MotortTotalRuntimeResponse?> getMotorTotalRuntime(
      String fromDate, String toDate) async {
    final response = await NetworkManager().get(
      '/status-history/motor/runtime',
      queryParameters: {
        'starter_id': SharedPreference.getStarterId(),
        'motor_id': SharedPreference.getMotorId(),
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    if (response.statusCode == 200) {
      return MotortTotalRuntimeResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    }
    return null;
  }

  @override
  Future<MotorStatusHistoryResponse?> getMotorStatusHistory(
      String fromDate, String toDate) async {
    final response = await NetworkManager().get(
      '/status-history/motor',
      queryParameters: {
        'starter_id': SharedPreference.getStarterId(),
        'motor_id': SharedPreference.getMotorId(),
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    if (response.statusCode == 200) {
      return MotorStatusHistoryResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    }
    return null;
  }

  @override
  Future<PowerStatusHistoryResponse?> getPowerStatusHistory(
      String fromDate, String toDate) async {
    final response = await NetworkManager().get(
      '/status-history/power',
      queryParameters: {
        'starter_id': SharedPreference.getStarterId(),
        'motor_id': SharedPreference.getMotorId(),
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    if (response.statusCode == 200) {
      return PowerStatusHistoryResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    }
    return null;
  }

  @override
  Future<DeviceStatusHistoryResponse?> getDeviceStatusHistory(
      String fromDate, String toDate) async {
    final response = await NetworkManager().get(
      '/status-history/device',
      queryParameters: {
        'starter_id': SharedPreference.getStarterId(),
        'from_date': fromDate,
        'to_date': toDate,
      },
    );
    if (response.statusCode == 200) {
      return DeviceStatusHistoryResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    }
    return null;
  }
}
