import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/schedules/create_schedule_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_acknowledment_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_delete_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_stop_restart_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_update_model.dart';

abstract class ScheduleRepository {
  Future<ScheduleListResponse?> getScheduleList(int? page, int? limit,
      {String? scheduleStatus, int? scheduleStartDate, int? scheduleEndDate});
  Future<CreateScheduleResponse?> createschedule(List<CreateScheduleDto> dtos);
  Future<ScheduleAcknowledgement?> scheduleAcknowledgement(List<int> ids);
  Future<ScheduleDeleteResponse?> scheduleDelete();
  Future<ScheduleUpdateResponse?> scheduleupdate(CreateScheduleDto dto);
  Future<ScheduleStopAndRestartResponse?> scheduleStopAndRestart(int cmd);
}
