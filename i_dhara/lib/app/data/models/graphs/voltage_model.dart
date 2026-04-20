// To parse this JSON data, do
//
//     final voltageResponse = voltageResponseFromJson(jsonString);

import 'dart:convert';

VoltageResponse voltageResponseFromJson(String str) =>
    VoltageResponse.fromJson(json.decode(str));

String voltageResponseToJson(VoltageResponse data) =>
    json.encode(data.toJson());

class VoltageResponse {
  int? status;
  bool? success;
  String? message;
  List<Voltage>? data;

  VoltageResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory VoltageResponse.fromJson(Map<String, dynamic> json) =>
      VoltageResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Voltage>.from(json["data"]!.map((x) => Voltage.fromJson(x))),
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

class Voltage {
  int? id;
  DateTime? timeStamp;
  double? lineVoltageR;
  double? lineVoltageY;
  double? lineVoltageB;

  Voltage({
    this.id,
    this.timeStamp,
    this.lineVoltageR,
    this.lineVoltageY,
    this.lineVoltageB,
  });

  factory Voltage.fromJson(Map<String, dynamic> json) => Voltage(
        id: json["id"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        lineVoltageR: json["line_voltage_r"]?.toDouble(),
        lineVoltageY: json["line_voltage_y"]?.toDouble(),
        lineVoltageB: json["line_voltage_b"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "time_stamp": timeStamp?.toIso8601String(),
        "line_voltage_r": lineVoltageR,
        "line_voltage_y": lineVoltageY,
        "line_voltage_b": lineVoltageB,
      };
}
