import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

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
    print("line 268 -----------> ${response.data}");
    print("Query params: $queryParams");
    if (response.statusCode == 200) {
      final data = MotorRunTimeResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }
}
