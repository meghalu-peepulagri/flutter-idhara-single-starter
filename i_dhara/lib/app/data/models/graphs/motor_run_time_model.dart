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
  Data? data;

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
  String? totalRunOnTime;
  List<Runtime>? records;

  Data({
    this.totalRunOnTime,
    this.records,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        totalRunOnTime: json["total_run_on_time"],
        records: json["records"] == null
            ? []
            : List<Runtime>.from(
                json["records"]!.map((x) => Runtime.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total_run_on_time": totalRunOnTime,
        "records": records == null
            ? []
            : List<dynamic>.from(records!.map((x) => x.toJson())),
      };
}

class Runtime {
  int? id;
  DateTime? startTime;
  DateTime? endTime;
  String? duration;
  DateTime? timeStamp;
  int? motorState;
  DateTime? powerStart;
  DateTime? powerEnd;
  String? powerDuration;
  int? powerState;

  Runtime({
    this.id,
    this.startTime,
    this.endTime,
    this.duration,
    this.timeStamp,
    this.motorState,
    this.powerStart,
    this.powerEnd,
    this.powerDuration,
    this.powerState,
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
        powerStart: json["power_start"] == null
            ? null
            : DateTime.parse(json["power_start"]),
        powerEnd: json["power_end"] == null
            ? null
            : DateTime.parse(json["power_end"]),
        powerDuration: json["power_duration"],
        powerState: json["power_state"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "start_time": startTime?.toIso8601String(),
        "end_time": endTime?.toIso8601String(),
        "duration": duration,
        "time_stamp": timeStamp?.toIso8601String(),
        "motor_state": motorState,
        "power_start": powerStart?.toIso8601String(),
        "power_end": powerEnd?.toIso8601String(),
        "power_duration": powerDuration,
        "power_state": powerState,
      };
}
