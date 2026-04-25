// To parse this JSON data, do
//
//     final powerStatusHistoryResponse = powerStatusHistoryResponseFromJson(jsonString);

import 'dart:convert';

PowerStatusHistoryResponse powerStatusHistoryResponseFromJson(String str) =>
    PowerStatusHistoryResponse.fromJson(json.decode(str));

String powerStatusHistoryResponseToJson(PowerStatusHistoryResponse data) =>
    json.encode(data.toJson());

class PowerStatusHistoryResponse {
  int? status;
  bool? success;
  String? message;
  List<Powerstatus>? data;

  PowerStatusHistoryResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory PowerStatusHistoryResponse.fromJson(Map<String, dynamic> json) =>
      PowerStatusHistoryResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Powerstatus>.from(
                json["data"]!.map((x) => Powerstatus.fromJson(x))),
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

class Powerstatus {
  int? id;
  int? starterId;
  int? motorId;
  String? status;
  DateTime? timeStamp;
  DateTime? createdAt;

  Powerstatus({
    this.id,
    this.starterId,
    this.motorId,
    this.status,
    this.timeStamp,
    this.createdAt,
  });

  factory Powerstatus.fromJson(Map<String, dynamic> json) => Powerstatus(
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
