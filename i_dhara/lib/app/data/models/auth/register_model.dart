// To parse this JSON data, do
//
//     final registerResponse = registerResponseFromJson(jsonString);

import 'dart:convert';

RegisterResponse registerResponseFromJson(String str) =>
    RegisterResponse.fromJson(json.decode(str));

String registerResponseToJson(RegisterResponse data) =>
    json.encode(data.toJson());

class RegisterResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;
  Errors? errors;

  RegisterResponse({
    this.status,
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
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
  String? fullName;
  String? email;
  String? phone;

  Errors({
    this.fullName,
    this.email,
    this.phone,
  });

  factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        fullName: json["full_name"],
        email: json["email"],
        phone: json["phone"],
      );

  Map<String, dynamic> toJson() => {
        "full_name": fullName,
        "email": email,
        "phone": phone,
      };
}
