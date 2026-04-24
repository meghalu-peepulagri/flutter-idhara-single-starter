// To parse this JSON data, do
//
//     final deviceImageChangeResponse = deviceImageChangeResponseFromJson(jsonString);

import 'dart:convert';

DeviceImageChangeResponse deviceImageChangeResponseFromJson(String str) =>
    DeviceImageChangeResponse.fromJson(json.decode(str));

String deviceImageChangeResponseToJson(DeviceImageChangeResponse data) =>
    json.encode(data.toJson());

class DeviceImageChangeResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  DeviceImageChangeResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory DeviceImageChangeResponse.fromJson(Map<String, dynamic> json) =>
      DeviceImageChangeResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  String? uploadUrl;
  String? key;

  Data({
    this.uploadUrl,
    this.key,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        uploadUrl: json["upload_url"],
        key: json["key"],
      );

  Map<String, dynamic> toJson() => {
        "upload_url": uploadUrl,
        "key": key,
      };
}
