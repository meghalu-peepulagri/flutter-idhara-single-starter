// To parse this JSON data, do
//
//     final deviceStatusHistoryResponse = deviceStatusHistoryResponseFromJson(jsonString);

import 'dart:convert';

DeviceStatusHistoryResponse deviceStatusHistoryResponseFromJson(String str) =>
    DeviceStatusHistoryResponse.fromJson(json.decode(str));

String deviceStatusHistoryResponseToJson(DeviceStatusHistoryResponse data) =>
    json.encode(data.toJson());

class DeviceStatusHistoryResponse {
  int? status;
  bool? success;
  String? message;
  List<Devicestatus>? data;

  DeviceStatusHistoryResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory DeviceStatusHistoryResponse.fromJson(Map<String, dynamic> json) =>
      DeviceStatusHistoryResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Devicestatus>.from(
                json["data"]!.map((x) => Devicestatus.fromJson(x))),
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

class Devicestatus {
  int? id;
  int? starterId;
  dynamic motorId;
  String? status;
  DateTime? timeStamp;
  DateTime? createdAt;

  Devicestatus({
    this.id,
    this.starterId,
    this.motorId,
    this.status,
    this.timeStamp,
    this.createdAt,
  });

  factory Devicestatus.fromJson(Map<String, dynamic> json) => Devicestatus(
        id: json["id"],
        starterId: json["starter_id"],
        motorId: json["motor_id"],
        status: json["status"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "starter_id": starterId,
        "motor_id": motorId,
        "status": status,
        "time_stamp": timeStamp?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
      };
}
