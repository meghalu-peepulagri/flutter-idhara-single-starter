// To parse this JSON data, do
//
//     final temperatureResponse = temperatureResponseFromJson(jsonString);

import 'dart:convert';

TemperatureResponse temperatureResponseFromJson(String str) =>
    TemperatureResponse.fromJson(json.decode(str));

String temperatureResponseToJson(TemperatureResponse data) =>
    json.encode(data.toJson());

class TemperatureResponse {
  int? status;
  bool? success;
  String? message;
  List<TemperatureData>? data;

  TemperatureResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory TemperatureResponse.fromJson(Map<String, dynamic> json) =>
      TemperatureResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<TemperatureData>.from(
                json["data"]!.map((x) => TemperatureData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class TemperatureData {
  int? id;
  int? deviceId;
  num? temperature;
  DateTime? timeStamp;

  TemperatureData({
    this.id,
    this.deviceId,
    this.temperature,
    this.timeStamp,
  });

  factory TemperatureData.fromJson(Map<String, dynamic> json) =>
      TemperatureData(
        id: json["id"],
        deviceId: json["device_id"],
        temperature: json["temperature"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "device_id": deviceId,
        "temperature": temperature,
        "time_stamp": timeStamp?.toIso8601String(),
      };
}
