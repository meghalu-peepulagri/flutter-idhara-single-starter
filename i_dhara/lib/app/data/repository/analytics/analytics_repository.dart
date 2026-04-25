import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/device_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/power_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';

abstract class AnalyticsRepository {
  Future<VoltageResponse?> getVoltage(String fromDate, String toDate);
  Future<CurrentResponse?> getCurrent(String fromDate, String toDate);
  Future<MotorRunTimeResponse?> getMotorRunTime(String fromDate, String toDate);
  Future<MotorStatusHistoryResponse?> getMotorStatusHistory(
      String fromDate, String toDate);
  Future<PowerStatusHistoryResponse?> getPowerStatusHistory(
      String fromDate, String toDate);
  Future<DeviceStatusHistoryResponse?> getDeviceStatusHistory(
      String fromDate, String toDate);
}
