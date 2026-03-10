// To parse this JSON data, do
//
//     final scheduleUpdateResponse = scheduleUpdateResponseFromJson(jsonString);

import 'dart:convert';

ScheduleUpdateResponse scheduleUpdateResponseFromJson(String str) =>
    ScheduleUpdateResponse.fromJson(json.decode(str));

String scheduleUpdateResponseToJson(ScheduleUpdateResponse data) =>
    json.encode(data.toJson());

class ScheduleUpdateResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  ScheduleUpdateResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory ScheduleUpdateResponse.fromJson(Map<String, dynamic> json) =>
      ScheduleUpdateResponse(
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
