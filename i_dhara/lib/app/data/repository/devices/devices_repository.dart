import 'package:i_dhara/app/data/dto/device_assign_dto.dart';
import 'package:i_dhara/app/data/models/devices/device_assign_model.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/models/devices/location_replace_model.dart';
import 'package:i_dhara/app/data/models/devices/rename_devices_model.dart';
import 'package:i_dhara/app/data/models/motors/delete_motor_model.dart';

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
}
