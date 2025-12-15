import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/dto/device_assign_dto.dart';
import 'package:i_dhara/app/data/models/devices/device_assign_model.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repository.dart';

class DevicesRepositoryImpl extends DevicesRepository {
  @override
  Future<DevicesResponse?> getDevices(
      int? page, String? search, int? limit) async {
    Map<String, dynamic> params = {
      'page': page,
      'limit': limit,
    };

    if (search != null && search.isNotEmpty) {
      params['search_string'] = search;
    }

    final response =
        await NetworkManager().get('/starters/mobile', queryParameters: params);
    if (response.statusCode == 200) {
      final res = DevicesResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<DeviceAssignResponse?> deviceassign(
    StarterCreateDto dto,
  ) async {
    final body = dto.toJson();
    final response =
        await NetworkManager().patch('/starters/assign', data: body);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422) {
      final data = DeviceAssignResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }
}
