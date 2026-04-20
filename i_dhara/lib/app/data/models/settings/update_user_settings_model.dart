// To parse this JSON data, do
//
//     final updateUserSettingResponse = updateUserSettingResponseFromJson(jsonString);

import 'dart:convert';

UpdateUserSettingResponse updateUserSettingResponseFromJson(String str) =>
    UpdateUserSettingResponse.fromJson(json.decode(str));

String updateUserSettingResponseToJson(UpdateUserSettingResponse data) =>
    json.encode(data.toJson());

class UpdateUserSettingResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  UpdateUserSettingResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UpdateUserSettingResponse.fromJson(Map<String, dynamic> json) =>
      UpdateUserSettingResponse(
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
