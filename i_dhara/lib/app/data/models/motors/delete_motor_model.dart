// To parse this JSON data, do
//
//     final deleteStarterResponse = deleteStarterResponseFromJson(jsonString);

import 'dart:convert';

DeleteStarterResponse deleteStarterResponseFromJson(String str) =>
    DeleteStarterResponse.fromJson(json.decode(str));

String deleteStarterResponseToJson(DeleteStarterResponse data) =>
    json.encode(data.toJson());

class DeleteStarterResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  DeleteStarterResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory DeleteStarterResponse.fromJson(Map<String, dynamic> json) =>
      DeleteStarterResponse(
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
