// To parse this JSON data, do
//
//     final deviceAssignResponse = deviceAssignResponseFromJson(jsonString);

import 'dart:convert';

DeviceAssignResponse deviceAssignResponseFromJson(String str) =>
    DeviceAssignResponse.fromJson(json.decode(str));

String deviceAssignResponseToJson(DeviceAssignResponse data) =>
    json.encode(data.toJson());

class DeviceAssignResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Errors? errors;

  DeviceAssignResponse(
      {this.status, this.success, this.message, this.data, this.errors});

  factory DeviceAssignResponse.fromJson(Map<String, dynamic> json) =>
      DeviceAssignResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"],
        errors: json["errors"] == null ? null : Errors.fromJson(json["errors"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data,
        "errors": errors?.toJson(),
      };
}

class Errors {
  bool? success;
  int? status;
  String? message;

  Errors({
    this.success,
    this.status,
    this.message,
  });

  factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        success: json["success"],
        status: json["status"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "status": status,
        "message": message,
      };
}
