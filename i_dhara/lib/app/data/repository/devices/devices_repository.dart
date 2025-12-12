import 'package:i_dhara/app/data/models/devices/devices_model.dart';

abstract class DevicesRepository {
  Future<DevicesResponse?> getDevices();
}
