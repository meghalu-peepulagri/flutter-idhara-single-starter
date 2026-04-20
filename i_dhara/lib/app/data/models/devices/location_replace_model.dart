// To parse this JSON data, do
//
//     final locationReplaceResponse = locationReplaceResponseFromJson(jsonString);

import 'dart:convert';

LocationReplaceResponse locationReplaceResponseFromJson(String str) =>
    LocationReplaceResponse.fromJson(json.decode(str));

String locationReplaceResponseToJson(LocationReplaceResponse data) =>
    json.encode(data.toJson());

class LocationReplaceResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  LocationReplaceResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory LocationReplaceResponse.fromJson(Map<String, dynamic> json) =>
      LocationReplaceResponse(
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
