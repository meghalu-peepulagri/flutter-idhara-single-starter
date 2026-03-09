// To parse this JSON data, do
//
//     final scheduleDeleteResponse = scheduleDeleteResponseFromJson(jsonString);

import 'dart:convert';

ScheduleDeleteResponse scheduleDeleteResponseFromJson(String str) =>
    ScheduleDeleteResponse.fromJson(json.decode(str));

String scheduleDeleteResponseToJson(ScheduleDeleteResponse data) =>
    json.encode(data.toJson());

class ScheduleDeleteResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  ScheduleDeleteResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory ScheduleDeleteResponse.fromJson(Map<String, dynamic> json) =>
      ScheduleDeleteResponse(
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
