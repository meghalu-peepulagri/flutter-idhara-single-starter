import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';

void main() {
  group('ScheduleListResponse', () {
    test('fromJson parses complete response', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Schedules fetched',
        'data': {
          'pagination_info': {
            'total_records': 10,
            'total_pages': 2,
            'page_size': 5,
            'current_page': 1,
            'next_page': 2,
            'prev_page': null,
          },
          'schedule_summary': {
            'total_schedules': 10,
            'running_count': 3,
          },
          'records': [],
        },
      };

      final response = ScheduleListResponse.fromJson(json);

      expect(response.status, 200);
      expect(response.data, isNotNull);
      expect(response.data!.paginationInfo!.totalRecords, 10);
      expect(response.data!.paginationInfo!.totalPages, 2);
      expect(response.data!.paginationInfo!.currentPage, 1);
      expect(response.data!.paginationInfo!.nextPage, 2);
      expect(response.data!.paginationInfo!.prevPage, isNull);
      expect(response.data!.scheduleSummary!.totalSchedules, 10);
      expect(response.data!.scheduleSummary!.runningCount, 3);
    });

    test('Record fromJson parses TIME_BASED schedule', () {
      final json = {
        'id': 1,
        'motor_id': 5,
        'starter_id': 10,
        'schedule_type': 'TIME_BASED',
        'schedule_id': 100,
        'bit_wise_days': 62,
        'schedule_start_date': 1711411200,
        'schedule_end_date': 1711497600,
        'days_of_week': [1, 2, 3, 4, 5],
        'start_time': '08:00',
        'end_time': '17:00',
        'runtime_minutes': 540,
        'cycle_on_minutes': null,
        'cycle_off_minutes': null,
        'power_loss_recovery': false,
        'accumulated_on_seconds': 0,
        'manually_stopped': false,
        'repeat': 1,
        'enabled': true,
        'schedule_status': 'RUNNING',
        'acknowledgement': 1,
        'acknowledged_at': '2026-03-26T08:00:00.000Z',
        'last_started_at': null,
        'last_stopped_at': null,
        'created_by': 1,
        'deleted_by': null,
        'status': 'ACTIVE',
        'priority': 1,
        'created_at': '2026-03-25T10:00:00.000Z',
        'updated_at': '2026-03-26T08:00:00.000Z',
      };

      final record = Record.fromJson(json);

      expect(record.id, 1);
      expect(record.scheduleType, ScheduleType.TIME_BASED);
      expect(record.status, Status.ACTIVE);
      expect(record.startTime, '08:00');
      expect(record.endTime, '17:00');
      expect(record.runtimeMinutes, 540);
      expect(record.daysOfWeek, [1, 2, 3, 4, 5]);
      expect(record.enabled, true);
      expect(record.acknowledgedAt!.year, 2026);
    });

    test('Record fromJson parses CYCLIC schedule', () {
      final json = {
        'id': 2,
        'motor_id': 3,
        'starter_id': 4,
        'schedule_type': 'CYCLIC',
        'schedule_id': 200,
        'bit_wise_days': 127,
        'days_of_week': [0, 1, 2, 3, 4, 5, 6],
        'start_time': '06:00',
        'end_time': '18:00',
        'runtime_minutes': 720,
        'cycle_on_minutes': 20,
        'cycle_off_minutes': 15,
        'power_loss_recovery': true,
        'accumulated_on_seconds': 3600,
        'manually_stopped': false,
        'repeat': 0,
        'enabled': true,
        'schedule_status': 'RUNNING',
        'acknowledgement': 1,
        'status': 'ACTIVE',
        'created_at': '2026-03-20T08:00:00.000Z',
        'updated_at': '2026-03-20T08:00:00.000Z',
      };

      final record = Record.fromJson(json);

      expect(record.scheduleType, ScheduleType.CYCLIC);
      expect(record.cycleOnMinutes, 20);
      expect(record.cycleOffMinutes, 15);
      expect(record.powerLossRecovery, true);
    });

    test('Record toJson serializes enums correctly', () {
      final record = Record(
        id: 1,
        scheduleType: ScheduleType.TIME_BASED,
        status: Status.ACTIVE,
      );

      final json = record.toJson();

      expect(json['schedule_type'], 'TIME_BASED');
      expect(json['status'], 'ACTIVE');
    });
  });

  group('PaginationInfo', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'total_records': 50,
        'total_pages': 5,
        'page_size': 10,
        'current_page': 1,
        'next_page': 2,
        'prev_page': null,
      };

      final pagination = PaginationInfo.fromJson(json);
      expect(pagination.totalRecords, 50);
      expect(pagination.pageSize, 10);

      final output = pagination.toJson();
      expect(output['total_records'], 50);
      expect(output['next_page'], 2);
      expect(output['prev_page'], isNull);
    });
  });

  group('ScheduleSummary', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'total_schedules': 8,
        'running_count': 2,
      };

      final summary = ScheduleSummary.fromJson(json);
      expect(summary.totalSchedules, 8);
      expect(summary.runningCount, 2);

      final output = summary.toJson();
      expect(output['total_schedules'], 8);
      expect(output['running_count'], 2);
    });
  });

  group('EnumValues', () {
    test('scheduleTypeValues maps correctly', () {
      expect(scheduleTypeValues.map['CYCLIC'], ScheduleType.CYCLIC);
      expect(scheduleTypeValues.map['TIME_BASED'], ScheduleType.TIME_BASED);
    });

    test('scheduleTypeValues reverse maps correctly', () {
      expect(scheduleTypeValues.reverse[ScheduleType.CYCLIC], 'CYCLIC');
      expect(
          scheduleTypeValues.reverse[ScheduleType.TIME_BASED], 'TIME_BASED');
    });

    test('statusValues maps correctly', () {
      expect(statusValues.map['ACTIVE'], Status.ACTIVE);
      expect(statusValues.reverse[Status.ACTIVE], 'ACTIVE');
    });
  });
}
