// To parse this JSON data, do
//
//     final userLogoutResponse = userLogoutResponseFromJson(jsonString);

import 'dart:convert';

UserLogoutResponse userLogoutResponseFromJson(String str) =>
    UserLogoutResponse.fromJson(json.decode(str));

String userLogoutResponseToJson(UserLogoutResponse data) =>
    json.encode(data.toJson());

class UserLogoutResponse {
  int? status;
  bool? success;
  String? message;

  UserLogoutResponse({
    this.status,
    this.success,
    this.message,
  });

  factory UserLogoutResponse.fromJson(Map<String, dynamic> json) =>
      UserLogoutResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
      };
}
