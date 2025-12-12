import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repository.dart';

class DevicesRepositoryImpl extends DevicesRepository {
  @override
  Future<DevicesResponse?> getDevices() async {
    final response = await NetworkManager().get('/starters/mobile');
    if (response.statusCode == 200) {
      final res = DevicesResponse.fromJson(response.data);
      return res;
    }
    return null;
  }
}
