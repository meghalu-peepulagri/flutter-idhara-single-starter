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

  DeleteLocationResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory DeleteLocationResponse.fromJson(Map<String, dynamic> json) =>
      DeleteLocationResponse(
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
