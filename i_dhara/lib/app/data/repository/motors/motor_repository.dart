import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/models/motors/faults_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_alerts_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_logs_model.dart';

abstract class MotorsRepository {
  Future<MotorResponse?> getMotors(int? page, int? limit);
  Future<MotorDetailsResponse?> getMotorDetails();

  Future<FaultsResponse?> getMotorFaults(int? page, int? limit);
  Future<MotorAlertsResponse?> getMotorAlerts(int? page, int? limit);
  Future<MotorLogsResponse?> getMotorLogs(int? page, int? limit, String action);
}
