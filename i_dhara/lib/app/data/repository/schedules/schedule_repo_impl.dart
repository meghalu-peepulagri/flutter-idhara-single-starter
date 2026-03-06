import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/schedules/create_schedule_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  @override
  Future<ScheduleListResponse?> getScheduleList(int? page, int? limit) async {
    Map<String, dynamic> params = {
      'starter_id': SharedPreference.getStarterId(),
      'motor_id': SharedPreference.getMotorId(),
      'page': page,
      'limit': limit,
    };
    final response =
        await NetworkManager().get('/motor-schedules', queryParameters: params);
    if (response.statusCode == 200) {
      final res = ScheduleListResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<CreateScheduleResponse?> createschedule(CreateScheduleDto dto) async {
    final body = dto.toJson();
    final response =
        await NetworkManager().post('/motor-schedules', data: body, {});

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = CreateScheduleResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }
}
