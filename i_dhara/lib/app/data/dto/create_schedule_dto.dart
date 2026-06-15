class CreateScheduleDto {
  final int motorId;
  final int starterId;
  final String scheduleType;
  final String startTime;
  final String? endTime;
  final String? scheduleDate;
  final int? scheduleStartDate;
  final int? scheduleEndDate;
  final int? cycleOnMinutes;
  final int? cycleOffMinutes;
  final List<int> daysOfWeek;
  final int bitwiseDays;
  final int runtimeMinutes;
  final bool powerLossRecovery;
  final int repeat;
  final bool enabled;
  final int scheduleId;
  final int? deviceScheduleId;

  const CreateScheduleDto({
    required this.motorId,
    required this.starterId,
    required this.scheduleType,
    required this.startTime,
    this.endTime,
    this.scheduleDate,
    this.scheduleStartDate,
    this.scheduleEndDate,
    this.cycleOnMinutes,
    this.cycleOffMinutes,
    required this.daysOfWeek,
    required this.bitwiseDays,
    required this.runtimeMinutes,
    required this.powerLossRecovery,
    required this.repeat,
    required this.enabled,
    required this.scheduleId,
    this.deviceScheduleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'motor_id': motorId,
      'starter_id': starterId,
      'schedule_type': scheduleType,
      'start_time': startTime,
      if (scheduleDate != null) 'schedule_date': scheduleDate,
      'schedule_start_date': scheduleStartDate,
      'schedule_end_date': scheduleEndDate,
      'end_time': endTime,
      if (cycleOnMinutes != null) 'cycle_on_minutes': cycleOnMinutes,
      if (cycleOffMinutes != null) 'cycle_off_minutes': cycleOffMinutes,
      'days_of_week': daysOfWeek,
      'bit_wise_days': bitwiseDays,
      'runtime_minutes': runtimeMinutes,
      'power_loss_recovery': powerLossRecovery,
      'repeat': repeat,
      'enabled': enabled,
      'schedule_id': scheduleId,
      'device_schedule_id': deviceScheduleId ?? scheduleId,
    };
  }
}
