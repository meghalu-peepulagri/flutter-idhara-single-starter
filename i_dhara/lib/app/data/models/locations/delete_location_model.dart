// To parse this JSON data, do
//
//     final deleteLocationResponse = deleteLocationResponseFromJson(jsonString);

import 'dart:convert';

DeleteLocationResponse deleteLocationResponseFromJson(String str) =>
    DeleteLocationResponse.fromJson(json.decode(str));

String deleteLocationResponseToJson(DeleteLocationResponse data) =>
    json.encode(data.toJson());

class DeleteLocationResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Errors? errors;

  DeleteLocationResponse(
      {this.status, this.success, this.message, this.data, this.errors});

  factory DeleteLocationResponse.fromJson(Map<String, dynamic> json) =>
      DeleteLocationResponse(
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
