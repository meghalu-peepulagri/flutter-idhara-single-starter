import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/schedules/create_schedule_model.dart';

void main() {
  group('CreateScheduleResponse', () {
    test('fromJson parses full response', () {
      final json = {
        'status': 201,
        'success': true,
        'message': 'Schedule created',
        'data': {
          'id': 10,
          'motor_id': 1,
          'starter_id': 2,
          'schedule_type': 'TIME_BASED',
          'schedule_id': 100,
          'schedule_date': '2026-03-26T00:00:00.000Z',
          'days_of_week': [1, 3, 5],
          'start_time': '10:00',
          'end_time': '12:00',
          'runtime_minutes': 120,
          'cycle_on_minutes': null,
          'cycle_off_minutes': null,
          'power_loss_recovery': true,
          'accumulated_on_seconds': 0,
          'manually_stopped': false,
          'repeat': 1,
          'schedule_status': 'PENDING',
          'acknowledgement': 0,
          'created_at': '2026-03-26T10:00:00.000Z',
          'updated_at': '2026-03-26T10:00:00.000Z',
        },
        'errors': null,
      };

      final response = CreateScheduleResponse.fromJson(json);

      expect(response.status, 201);
      expect(response.success, true);
      expect(response.data, isNotNull);
      expect(response.data!.id, 10);
      expect(response.data!.motorId, 1);
      expect(response.data!.starterId, 2);
      expect(response.data!.scheduleType, 'TIME_BASED');
      expect(response.data!.startTime, '10:00');
      expect(response.data!.endTime, '12:00');
      expect(response.data!.runtimeMinutes, 120);
      expect(response.data!.daysOfWeek, [1, 3, 5]);
      expect(response.data!.powerLossRecovery, true);
      expect(response.data!.manuallyStopped, false);
    });

    test('Data parses schedule_date as DateTime', () {
      final json = {
        'schedule_date': '2026-04-01T00:00:00.000Z',
        'created_at': '2026-03-26T10:00:00.000Z',
      };

      final data = Data.fromJson(json);
      expect(data.scheduleDate, isNotNull);
      expect(data.scheduleDate!.year, 2026);
      expect(data.scheduleDate!.month, 4);
      expect(data.scheduleDate!.day, 1);
    });

    test('Data handles null DateTime fields', () {
      final data = Data.fromJson(<String, dynamic>{});
      expect(data.scheduleDate, isNull);
      expect(data.createdAt, isNull);
      expect(data.updatedAt, isNull);
    });

    test('Data handles null daysOfWeek as empty list', () {
      final data = Data.fromJson({'days_of_week': null});
      expect(data.daysOfWeek, isEmpty);
    });

    test('fromJson parses error with daysOfWeek', () {
      final json = {
        'status': 422,
        'success': false,
        'message': 'Validation failed',
        'errors': {'days_of_week': 'At least one day is required'},
      };

      final response = CreateScheduleResponse.fromJson(json);
      expect(response.errors, isNotNull);
      expect(response.errors!.daysOfWeek, 'At least one day is required');
    });

    test('toJson → fromJson round-trip', () {
      final original = CreateScheduleResponse(
        status: 201,
        success: true,
        message: 'Created',
        data: Data(
          id: 5,
          motorId: 1,
          startTime: '08:00',
          endTime: '09:00',
          runtimeMinutes: 60,
          daysOfWeek: [1, 2],
        ),
      );

      final json = original.toJson();
      final restored = CreateScheduleResponse.fromJson(json);

      expect(restored.data!.id, 5);
      expect(restored.data!.startTime, '08:00');
      expect(restored.data!.daysOfWeek, [1, 2]);
    });
  });
}
