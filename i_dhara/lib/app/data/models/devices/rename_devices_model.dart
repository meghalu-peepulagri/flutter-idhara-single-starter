// To parse this JSON data, do
//
//     final renameDeviceResponse = renameDeviceResponseFromJson(jsonString);

import 'dart:convert';

RenameDeviceResponse renameDeviceResponseFromJson(String str) =>
    RenameDeviceResponse.fromJson(json.decode(str));

String renameDeviceResponseToJson(RenameDeviceResponse data) =>
    json.encode(data.toJson());

class RenameDeviceResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Errors? errors;

  RenameDeviceResponse({
    this.status,
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory RenameDeviceResponse.fromJson(Map<String, dynamic> json) =>
      RenameDeviceResponse(
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
