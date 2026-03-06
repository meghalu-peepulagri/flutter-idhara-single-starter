class CreateScheduleDto {
  final int motorId;
  final int starterId;
  final String scheduleType;
  final String startTime;
  final String endTime;
  final List<int> daysOfWeek;
  final int runtimeMinutes;
  final bool powerLossRecovery;
  final int repeat;

  const CreateScheduleDto({
    required this.motorId,
    required this.starterId,
    required this.scheduleType,
    required this.startTime,
    required this.endTime,
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
      'end_time': endTime,
      'days_of_week': daysOfWeek,
      'runtime_minutes': runtimeMinutes,
      'power_loss_recovery': powerLossRecovery,
      'repeat': repeat,
    };
  }
}
