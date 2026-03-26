import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';

void main() {
  group('CreateScheduleDto', () {
    test('toJson includes all required fields', () {
      final dto = CreateScheduleDto(
        motorId: 1,
        starterId: 2,
        scheduleType: 'TIME_BASED',
        startTime: '10:00',
        daysOfWeek: [1, 2, 3],
        bitwiseDays: 14,
        runtimeMinutes: 60,
        powerLossRecovery: false,
        repeat: 1,
        enabled: true,
      );

      final json = dto.toJson();

      expect(json['motor_id'], 1);
      expect(json['starter_id'], 2);
      expect(json['schedule_type'], 'TIME_BASED');
      expect(json['start_time'], '10:00');
      expect(json['days_of_week'], [1, 2, 3]);
      expect(json['bit_wise_days'], 14);
      expect(json['runtime_minutes'], 60);
      expect(json['power_loss_recovery'], false);
      expect(json['repeat'], 1);
      expect(json['enabled'], true);
    });

    test('toJson excludes null optional fields', () {
      final dto = CreateScheduleDto(
        motorId: 1,
        starterId: 2,
        scheduleType: 'TIME_BASED',
        startTime: '10:00',
        daysOfWeek: [],
        bitwiseDays: 0,
        runtimeMinutes: 30,
        powerLossRecovery: false,
        repeat: 0,
        enabled: true,
      );

      final json = dto.toJson();

      expect(json.containsKey('schedule_date'), false);
      expect(json.containsKey('cycle_on_minutes'), false);
      expect(json.containsKey('cycle_off_minutes'), false);
      expect(json.containsKey('power_loss_recovery_time'), false);
    });

    test('toJson includes optional fields when provided', () {
      final dto = CreateScheduleDto(
        motorId: 1,
        starterId: 2,
        scheduleType: 'CYCLIC',
        startTime: '08:00',
        endTime: '10:00',
        scheduleDate: '2026-03-26',
        scheduleStartDate: 1711411200,
        scheduleEndDate: 1711497600,
        cycleOnMinutes: 20,
        cycleOffMinutes: 15,
        daysOfWeek: [1, 3, 5],
        bitwiseDays: 42,
        runtimeMinutes: 120,
        powerLossRecovery: true,
        powerLossRecoveryTime: 30,
        repeat: 1,
        enabled: true,
      );

      final json = dto.toJson();

      expect(json['end_time'], '10:00');
      expect(json['schedule_date'], '2026-03-26');
      expect(json['schedule_start_date'], 1711411200);
      expect(json['schedule_end_date'], 1711497600);
      expect(json['cycle_on_minutes'], 20);
      expect(json['cycle_off_minutes'], 15);
      expect(json['power_loss_recovery'], true);
      expect(json['power_loss_recovery_time'], 30);
    });

    test('toJson always includes end_time even when null', () {
      final dto = CreateScheduleDto(
        motorId: 1,
        starterId: 2,
        scheduleType: 'TIME_BASED',
        startTime: '10:00',
        daysOfWeek: [],
        bitwiseDays: 0,
        runtimeMinutes: 30,
        powerLossRecovery: false,
        repeat: 0,
        enabled: true,
      );

      final json = dto.toJson();
      // end_time is always included (not conditional)
      expect(json.containsKey('end_time'), true);
    });
  });
}
