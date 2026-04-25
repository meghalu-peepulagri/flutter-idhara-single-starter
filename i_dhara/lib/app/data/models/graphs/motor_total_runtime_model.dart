// To parse this JSON data, do
//
//     final motortTotalRuntimeResponse = motortTotalRuntimeResponseFromJson(jsonString);

import 'dart:convert';

MotortTotalRuntimeResponse motortTotalRuntimeResponseFromJson(String str) =>
    MotortTotalRuntimeResponse.fromJson(json.decode(str));

String motortTotalRuntimeResponseToJson(MotortTotalRuntimeResponse data) =>
    json.encode(data.toJson());

class MotortTotalRuntimeResponse {
  int? status;
  bool? success;
  String? message;
  MotorRuntime? data;

  MotortTotalRuntimeResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotortTotalRuntimeResponse.fromJson(Map<String, dynamic> json) =>
      MotortTotalRuntimeResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : MotorRuntime.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class MotorRuntime {
  String? totalOnDurationFormatted;

  MotorRuntime({
    this.totalOnDurationFormatted,
  });

  factory MotorRuntime.fromJson(Map<String, dynamic> json) => MotorRuntime(
        totalOnDurationFormatted: json["total_on_duration_formatted"],
      );

  Map<String, dynamic> toJson() => {
        "total_on_duration_formatted": totalOnDurationFormatted,
      };
}
