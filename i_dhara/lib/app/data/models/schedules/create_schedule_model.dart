// To parse this JSON data, do
//
//     final createScheduleResponse = createScheduleResponseFromJson(jsonString);

import 'dart:convert';

CreateScheduleResponse createScheduleResponseFromJson(String str) =>
    CreateScheduleResponse.fromJson(json.decode(str));

String createScheduleResponseToJson(CreateScheduleResponse data) =>
    json.encode(data.toJson());

class CreateScheduleResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  CreateScheduleResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory CreateScheduleResponse.fromJson(Map<String, dynamic> json) =>
      CreateScheduleResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  int? id;
  int? motorId;
  int? starterId;
  String? scheduleType;
  int? scheduleId;
  DateTime? scheduleDate;
  List<int>? daysOfWeek;
  String? startTime;
  String? endTime;
  int? runtimeMinutes;
  dynamic cycleOnMinutes;
  dynamic cycleOffMinutes;
  bool? powerLossRecovery;
  int? accumulatedOnSeconds;
  bool? manuallyStopped;
  int? repeat;
  String? scheduleStatus;
  int? acknowledgement;
  DateTime? createdAt;
  DateTime? updatedAt;

  Data({
    this.id,
    this.motorId,
    this.starterId,
    this.scheduleType,
    this.scheduleId,
    this.scheduleDate,
    this.daysOfWeek,
    this.startTime,
    this.endTime,
    this.runtimeMinutes,
    this.cycleOnMinutes,
    this.cycleOffMinutes,
    this.powerLossRecovery,
    this.accumulatedOnSeconds,
    this.manuallyStopped,
    this.repeat,
    this.scheduleStatus,
    this.acknowledgement,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        motorId: json["motor_id"],
        starterId: json["starter_id"],
        scheduleType: json["schedule_type"],
        scheduleId: json["schedule_id"],
        scheduleDate: json["schedule_date"] == null
            ? null
            : DateTime.parse(json["schedule_date"]),
        daysOfWeek: json["days_of_week"] == null
            ? []
            : List<int>.from(json["days_of_week"]!.map((x) => x)),
        startTime: json["start_time"],
        endTime: json["end_time"],
        runtimeMinutes: json["runtime_minutes"],
        cycleOnMinutes: json["cycle_on_minutes"],
        cycleOffMinutes: json["cycle_off_minutes"],
        powerLossRecovery: json["power_loss_recovery"],
        accumulatedOnSeconds: json["accumulated_on_seconds"],
        manuallyStopped: json["manually_stopped"],
        repeat: json["repeat"],
        scheduleStatus: json["schedule_status"],
        acknowledgement: json["acknowledgement"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "motor_id": motorId,
        "starter_id": starterId,
        "schedule_type": scheduleType,
        "schedule_id": scheduleId,
        "schedule_date": scheduleDate?.toIso8601String(),
        "days_of_week": daysOfWeek == null
            ? []
            : List<dynamic>.from(daysOfWeek!.map((x) => x)),
        "start_time": startTime,
        "end_time": endTime,
        "runtime_minutes": runtimeMinutes,
        "cycle_on_minutes": cycleOnMinutes,
        "cycle_off_minutes": cycleOffMinutes,
        "power_loss_recovery": powerLossRecovery,
        "accumulated_on_seconds": accumulatedOnSeconds,
        "manually_stopped": manuallyStopped,
        "repeat": repeat,
        "schedule_status": scheduleStatus,
        "acknowledgement": acknowledgement,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
