import 'package:i_dhara/app/data/dto/device_assign_dto.dart';
import 'package:i_dhara/app/data/models/devices/device_assign_model.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/models/devices/location_replace_model.dart';
import 'package:i_dhara/app/data/models/devices/rename_devices_model.dart';
import 'package:i_dhara/app/data/models/motors/delete_motor_model.dart';
import 'package:i_dhara/app/data/models/test_run/test_run_model.dart';

enum TestRunStatus {
  inTest('IN_TEST'),
  completed('COMPLETED'),
  failed('FAILED');

  final String value;
  const TestRunStatus(this.value);
}

abstract class DevicesRepository {
  Future<DevicesResponse?> getDevices(int? page, String? search, int? limit);
  Future<DeviceAssignResponse?> deviceassign(
    StarterCreateDto dto,
  );
  Future<DeleteStarterResponse?> deletestarter(int starterId);
  Future<RenameDeviceResponse?> renameDevice(
      int motorId, String name, double hp);
  Future<LocationReplaceResponse?> locationreplace(
      int starterId, int locationId, int motorId);

  Future<TestRunResponse?> testRun(int motorId, TestRunStatus status);
}
