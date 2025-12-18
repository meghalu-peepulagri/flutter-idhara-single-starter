import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';

abstract class AnalyticsRepository {
  Future<VoltageResponse?> getVoltage(String fromDate, String toDate);
  Future<CurrentResponse?> getCurrent(String fromDate, String toDate);
  Future<MotorRunTimeResponse?> getMotorRunTime(String fromDate, String toDate);
}
