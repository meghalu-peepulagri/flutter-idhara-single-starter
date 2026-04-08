// To parse this JSON data, do
//
//     final scheduleStopAndRestartResponse = scheduleStopAndRestartResponseFromJson(jsonString);

import 'dart:convert';

ScheduleStopAndRestartResponse scheduleStopAndRestartResponseFromJson(
        String str) =>
    ScheduleStopAndRestartResponse.fromJson(json.decode(str));

String scheduleStopAndRestartResponseToJson(
        ScheduleStopAndRestartResponse data) =>
    json.encode(data.toJson());

class ScheduleStopAndRestartResponse {
  int? status;
  bool? success;
  String? message;

  ScheduleStopAndRestartResponse({
    this.status,
    this.success,
    this.message,
  });

  factory ScheduleStopAndRestartResponse.fromJson(Map<String, dynamic> json) =>
      ScheduleStopAndRestartResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
      };
}
