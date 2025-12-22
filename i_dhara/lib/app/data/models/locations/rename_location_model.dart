// To parse this JSON data, do
//
//     final renameLocationResponse = renameLocationResponseFromJson(jsonString);

import 'dart:convert';

RenameLocationResponse renameLocationResponseFromJson(String str) =>
    RenameLocationResponse.fromJson(json.decode(str));

String renameLocationResponseToJson(RenameLocationResponse data) =>
    json.encode(data.toJson());

class RenameLocationResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Errors? errors;

  RenameLocationResponse(
      {this.status, this.success, this.message, this.data, this.errors});

  factory RenameLocationResponse.fromJson(Map<String, dynamic> json) =>
      RenameLocationResponse(
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
  String? name;

  Errors({
    this.name,
  });

  factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
      };
}
