// To parse this JSON data, do
//
//     final addNewLocationResponse = addNewLocationResponseFromJson(jsonString);

import 'dart:convert';

AddNewLocationResponse addNewLocationResponseFromJson(String str) =>
    AddNewLocationResponse.fromJson(json.decode(str));

String addNewLocationResponseToJson(AddNewLocationResponse data) =>
    json.encode(data.toJson());

class AddNewLocationResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Error? errors;

  AddNewLocationResponse({
    this.status,
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory AddNewLocationResponse.fromJson(Map<String, dynamic> json) =>
      AddNewLocationResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"],
        errors: json["errors"] == null ? null : Error.fromJson(json["errors"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data,
        "errors": errors?.toJson(),
      };
}

class Error {
  String? name;

  Error({
    this.name,
  });

  factory Error.fromJson(Map<String, dynamic> json) => Error(
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
      };
}
