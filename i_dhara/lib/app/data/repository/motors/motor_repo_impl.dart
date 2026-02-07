import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/models/motors/faults_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_alerts_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_logs_model.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repository.dart';
import 'package:i_dhara/app/data/services/storages/hive_handler.dart';

class MotorsRepositoryImpl implements MotorsRepository {
  @override
  Future<MotorResponse?> getMotors(int? page, int? limit) async {
    Map<String, dynamic> params = {
      'page': page,
      'limit': limit,
    };
    final response =
        await NetworkManager().get('/motors', queryParameters: params);
    if (response.statusCode == 200) {
      final res = MotorResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<MotorDetailsResponse?> getMotorDetails() async {
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');
    final response = await NetworkManager().get('/motors/$motorId');
    if (response.statusCode == 200) {
      final res = MotorDetailsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<FaultsResponse?> getMotorFaults(int? page, int? limit) async {
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    Map<String, dynamic> params = {
      'type': 'fault',
      'page': page,
      'page_size': 15,
    };
    final response = await NetworkManager().get(
        '/starters/$starterId/motors/$motorId/alerts-faults',
        queryParameters: params);
    if (response.statusCode == 200) {
      final res = FaultsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<MotorAlertsResponse?> getMotorAlerts(int? page, int? limit) async {
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');
    final starterId = HiveHandler.getValue(Hivekeys.starterId, '');

    Map<String, dynamic> params = {
      'type': 'alert',
      'page': page,
      'page_size': 15,
    };
    final response = await NetworkManager().get(
        '/starters/$starterId/motors/$motorId/alerts-faults',
        queryParameters: params);
    if (response.statusCode == 200) {
      final res = MotorAlertsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<MotorLogsResponse?> getMotorLogs(
      int? page, int? limit, String action) async {
    final motorId = HiveHandler.getValue(Hivekeys.motorId, '');

    Map<String, dynamic> params = {
      'entity': 'MOTOR',
      'entity_id': motorId,
      'action': action,
      'page': page,
      'page_size': 15,
    };
    final response =
        await NetworkManager().get('/activities', queryParameters: params);
    if (response.statusCode == 200) {
      final res = MotorLogsResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
