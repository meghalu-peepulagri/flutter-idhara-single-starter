class CreateScheduleDto {
  final int motorId;
  final int starterId;
  final String scheduleType;
  final String startTime;
  final String? endTime;
  final String? scheduleDate;
  final int? cycleOnMinutes;
  final int? cycleOffMinutes;
  final List<int> daysOfWeek;
  final int runtimeMinutes;
  final bool powerLossRecovery;
  final int repeat;

  const CreateScheduleDto({
    required this.motorId,
    required this.starterId,
    required this.scheduleType,
    required this.startTime,
    this.endTime,
    this.scheduleDate,
    this.cycleOnMinutes,
    this.cycleOffMinutes,
    required this.daysOfWeek,
    required this.runtimeMinutes,
    required this.powerLossRecovery,
    required this.repeat,
  });

  Map<String, dynamic> toJson() {
    return {
      'motor_id': motorId,
      'starter_id': starterId,
      'schedule_type': scheduleType,
      'start_time': startTime,
      if (scheduleDate != null) 'schedule_date': scheduleDate,
      'end_time': endTime,
      if (cycleOnMinutes != null) 'cycle_on_minutes': cycleOnMinutes,
      if (cycleOffMinutes != null) 'cycle_off_minutes': cycleOffMinutes,
      'days_of_week': daysOfWeek,
      'runtime_minutes': runtimeMinutes,
      'power_loss_recovery': powerLossRecovery,
      'repeat': repeat,
    };
  }
}
