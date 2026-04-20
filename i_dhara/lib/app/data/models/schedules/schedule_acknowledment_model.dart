// To parse this JSON data, do
//
//     final scheduleAcknowledgement = scheduleAcknowledgementFromJson(jsonString);

import 'dart:convert';

ScheduleAcknowledgement scheduleAcknowledgementFromJson(String str) =>
    ScheduleAcknowledgement.fromJson(json.decode(str));

String scheduleAcknowledgementToJson(ScheduleAcknowledgement data) =>
    json.encode(data.toJson());

class ScheduleAcknowledgement {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  ScheduleAcknowledgement({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory ScheduleAcknowledgement.fromJson(Map<String, dynamic> json) =>
      ScheduleAcknowledgement(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data,
      };
}
