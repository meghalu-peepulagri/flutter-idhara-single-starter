// To parse this JSON data, do
//
//     final motorRunTimeResponse = motorRunTimeResponseFromJson(jsonString);

import 'dart:convert';

MotorRunTimeResponse motorRunTimeResponseFromJson(String str) =>
    MotorRunTimeResponse.fromJson(json.decode(str));

String motorRunTimeResponseToJson(MotorRunTimeResponse data) =>
    json.encode(data.toJson());

class MotorRunTimeResponse {
  int? status;
  bool? success;
  String? message;
  List<Runtime>? data;

  MotorRunTimeResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotorRunTimeResponse.fromJson(Map<String, dynamic> json) =>
      MotorRunTimeResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Runtime>.from(json["data"]!.map((x) => Runtime.fromJson(x))),
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

class Runtime {
  int? id;
  DateTime? startTime;
  DateTime? endTime;
  String? duration;
  DateTime? timeStamp;
  int? motorState;

  Runtime({
    this.id,
    this.startTime,
    this.endTime,
    this.duration,
    this.timeStamp,
    this.motorState,
  });

  factory Runtime.fromJson(Map<String, dynamic> json) => Runtime(
        id: json["id"],
        startTime: json["start_time"] == null
            ? null
            : DateTime.parse(json["start_time"]),
        endTime:
            json["end_time"] == null ? null : DateTime.parse(json["end_time"]),
        duration: json["duration"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        motorState: json["motor_state"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "start_time": startTime?.toIso8601String(),
        "end_time": endTime?.toIso8601String(),
        "duration": duration,
        "time_stamp": timeStamp?.toIso8601String(),
        "motor_state": motorState,
      };
}
