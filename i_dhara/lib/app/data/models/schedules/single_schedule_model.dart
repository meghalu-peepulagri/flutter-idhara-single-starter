// To parse this JSON data, do
//
//     final singleScheduleLogsResponse = singleScheduleLogsResponseFromJson(jsonString);

import 'dart:convert';

SingleScheduleLogsResponse singleScheduleLogsResponseFromJson(String str) =>
    SingleScheduleLogsResponse.fromJson(json.decode(str));

String singleScheduleLogsResponseToJson(SingleScheduleLogsResponse data) =>
    json.encode(data.toJson());

class SingleScheduleLogsResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  SingleScheduleLogsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory SingleScheduleLogsResponse.fromJson(Map<String, dynamic> json) =>
      SingleScheduleLogsResponse(
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
  int? scheduleId;
  int? motorId;
  int? starterId;
  String? scheduleType;
  String? scheduleStatus;
  String? startTime;
  String? endTime;
  int? scheduleStartDate;
  int? scheduleEndDate;
  dynamic actualStartTime;
  dynamic actualEndTime;
  int? runtimeMinutes;
  dynamic actualRunTime;
  dynamic failureReason;
  int? missedMinutes;
  dynamic failureAt;
  int? repeat;
  DateTime? createdAt;
  List<Event>? events;

  Data({
    this.id,
    this.scheduleId,
    this.motorId,
    this.starterId,
    this.scheduleType,
    this.scheduleStatus,
    this.startTime,
    this.endTime,
    this.scheduleStartDate,
    this.scheduleEndDate,
    this.actualStartTime,
    this.actualEndTime,
    this.runtimeMinutes,
    this.actualRunTime,
    this.failureReason,
    this.missedMinutes,
    this.failureAt,
    this.repeat,
    this.createdAt,
    this.events,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        scheduleId: json["schedule_id"],
        motorId: json["motor_id"],
        starterId: json["starter_id"],
        scheduleType: json["schedule_type"],
        scheduleStatus: json["schedule_status"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        scheduleStartDate: json["schedule_start_date"],
        scheduleEndDate: json["schedule_end_date"],
        actualStartTime: json["actual_start_time"],
        actualEndTime: json["actual_end_time"],
        runtimeMinutes: json["runtime_minutes"],
        actualRunTime: json["actual_run_time"],
        failureReason: json["failure_reason"],
        missedMinutes: json["missed_minutes"],
        failureAt: json["failure_at"],
        repeat: json["repeat"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        events: json["events"] == null
            ? []
            : List<Event>.from(json["events"]!.map((x) => Event.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "schedule_id": scheduleId,
        "motor_id": motorId,
        "starter_id": starterId,
        "schedule_type": scheduleType,
        "schedule_status": scheduleStatus,
        "start_time": startTime,
        "end_time": endTime,
        "schedule_start_date": scheduleStartDate,
        "schedule_end_date": scheduleEndDate,
        "actual_start_time": actualStartTime,
        "actual_end_time": actualEndTime,
        "runtime_minutes": runtimeMinutes,
        "actual_run_time": actualRunTime,
        "failure_reason": failureReason,
        "missed_minutes": missedMinutes,
        "failure_at": failureAt,
        "repeat": repeat,
        "created_at": createdAt?.toIso8601String(),
        "events": events == null
            ? []
            : List<dynamic>.from(events!.map((x) => x.toJson())),
      };
}

class Event {
  String? event;
  DateTime? timestamp;

  Event({
    this.event,
    this.timestamp,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        event: json["event"],
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "event": event,
        "timestamp": timestamp?.toIso8601String(),
      };
}
