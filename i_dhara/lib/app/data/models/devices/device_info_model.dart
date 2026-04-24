// To parse this JSON data, do
//
//     final deviceLocationEditResponse = deviceLocationEditResponseFromJson(jsonString);

import 'dart:convert';

DeviceLocationEditResponse deviceLocationEditResponseFromJson(String str) =>
    DeviceLocationEditResponse.fromJson(json.decode(str));

String deviceLocationEditResponseToJson(DeviceLocationEditResponse data) =>
    json.encode(data.toJson());

class DeviceLocationEditResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Errors? errors;

  DeviceLocationEditResponse({
    this.status,
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory DeviceLocationEditResponse.fromJson(Map<String, dynamic> json) =>
      DeviceLocationEditResponse(
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
  String? deviceInstalledLocation;

  Errors({
    this.deviceInstalledLocation,
  });

  factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        deviceInstalledLocation: json["device_installed_location"],
      );

  Map<String, dynamic> toJson() => {
        "device_installed_location": deviceInstalledLocation,
      };
}
