import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repository.dart';

import '../../services/storages/hive_handler.dart';

class AnalyticsRepositoryImpl extends AnalyticsRepository {
  @override
  Future<CurrentResponse?> getCurrent(String fromDate, String toDate) async {
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    Map<String, dynamic> queryParams = {
      'from_date': fromDate,
      'to_date': toDate,
      'motor_id': motorId,
      'parameter': 'current',
    };
    final response = await NetworkManager()
        .get('/starters/$starterId/analytics', queryParameters: queryParams);
    if (response.statusCode == 200) {
      final data = CurrentResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }

  @override
  Future<VoltageResponse?> getVoltage(String fromDate, String toDate) async {
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    Map<String, dynamic> queryParams = {
      'from_date': fromDate,
      'to_date': toDate,
      'motor_id': motorId,
      'parameter': 'voltage',
    };
    final response = await NetworkManager()
        .get('/starters/$starterId/analytics', queryParameters: queryParams);
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
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    Map<String, dynamic> queryParams = {
      'from_date': fromDate,
      'to_date': toDate,
      'motor_id': motorId,
    };
    if (state != null) {
      queryParams['state'] = state;
    }
    final response = await NetworkManager()
        .get('/starters/$starterId/run-time', queryParameters: queryParams);
    if (response.statusCode == 200) {
      final data = MotorRunTimeResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }
}
