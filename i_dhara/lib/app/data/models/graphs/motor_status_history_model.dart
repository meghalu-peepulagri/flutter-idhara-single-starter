// To parse this JSON data, do
//
//     final motorStatusHistoryResponse = motorStatusHistoryResponseFromJson(jsonString);

import 'dart:convert';

MotorStatusHistoryResponse motorStatusHistoryResponseFromJson(String str) =>
    MotorStatusHistoryResponse.fromJson(json.decode(str));

String motorStatusHistoryResponseToJson(MotorStatusHistoryResponse data) =>
    json.encode(data.toJson());

class MotorStatusHistoryResponse {
  int? status;
  bool? success;
  String? message;
  List<Motorstatus>? data;

  MotorStatusHistoryResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotorStatusHistoryResponse.fromJson(Map<String, dynamic> json) =>
      MotorStatusHistoryResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Motorstatus>.from(
                json["data"]!.map((x) => Motorstatus.fromJson(x))),
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

class Motorstatus {
  int? id;
  int? starterId;
  int? motorId;
  String? status;
  DateTime? timeStamp;
  DateTime? createdAt;

  Motorstatus({
    this.id,
    this.starterId,
    this.motorId,
    this.status,
    this.timeStamp,
    this.createdAt,
  });

  factory Motorstatus.fromJson(Map<String, dynamic> json) => Motorstatus(
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
