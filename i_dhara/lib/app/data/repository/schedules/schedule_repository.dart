import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';

abstract class ScheduleRepository {
  Future<ScheduleListResponse?> getScheduleList(int? page, int? limit);
}
