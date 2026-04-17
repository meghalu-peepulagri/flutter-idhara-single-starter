import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/schedules/create_schedule_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_acknowledment_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_delete_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_stop_restart_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_update_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  @override
  Future<ScheduleListResponse?> getScheduleList(int? page, int? limit,
      {String? scheduleStatus,
      int? scheduleStartDate,
      int? scheduleEndDate}) async {
    Map<String, dynamic> params = {
      'starter_id': SharedPreference.getStarterId(),
      'motor_id': SharedPreference.getMotorId(),
      'page': page,
      'limit': limit,
    };
    if (scheduleStatus != null && scheduleStatus.isNotEmpty) {
      params['schedule_status'] = scheduleStatus;
    }
    if (scheduleStartDate != null) {
      params['schedule_start_date'] = scheduleStartDate;
    }
    if (scheduleEndDate != null) {
      params['schedule_end_date'] = scheduleEndDate;
    }
    final response =
        await NetworkManager().get('/motor-schedules', queryParameters: params);
    if (response.statusCode == 200) {
      final res = ScheduleListResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<CreateScheduleResponse?> createschedule(
      List<CreateScheduleDto> dtos) async {
    // Always send as an array — single schedule becomes [{ ... }],
    // multiple schedules become [{ ... }, { ... }, ...]
    final body = dtos.map((d) => d.toJson()).toList();
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

  @override
  Future<ScheduleAcknowledgement?> scheduleAcknowledgement(
      List<int> ids) async {
    final body = {'schedule_ids': ids};
    final response =
        await NetworkManager().patch('/motor-schedules/bulk/ack', data: body);

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = ScheduleAcknowledgement.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<ScheduleDeleteResponse?> scheduleDelete() async {
    final response = await NetworkManager()
        .delete('/motor-schedules/${SharedPreference.getscheduleid()}');

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = ScheduleDeleteResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<ScheduleUpdateResponse?> scheduleupdate(CreateScheduleDto dto) async {
    final body = dto.toJson();
    final response = await NetworkManager().patch(
        '/motor-schedules/${SharedPreference.getscheduleid()}',
        data: body);

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = ScheduleUpdateResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<ScheduleStopAndRestartResponse?> scheduleStopAndRestart(
      int cmd) async {
    final body = {"cmd": cmd};
    final response = await NetworkManager().post(
        '/motor-schedules/update-status/${SharedPreference.getscheduleid()}',
        data: body,
        {});

    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = ScheduleStopAndRestartResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }
}
