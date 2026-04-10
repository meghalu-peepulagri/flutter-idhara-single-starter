// To parse this JSON data, do
//
//     final faultClearResponse = faultClearResponseFromJson(jsonString);

import 'dart:convert';

FaultClearResponse faultClearResponseFromJson(String str) =>
    FaultClearResponse.fromJson(json.decode(str));

String faultClearResponseToJson(FaultClearResponse data) =>
    json.encode(data.toJson());

class FaultClearResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  FaultClearResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory FaultClearResponse.fromJson(Map<String, dynamic> json) =>
      FaultClearResponse(
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
