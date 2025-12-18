// To parse this JSON data, do
//
//     final currentResponse = currentResponseFromJson(jsonString);

import 'dart:convert';

CurrentResponse currentResponseFromJson(String str) =>
    CurrentResponse.fromJson(json.decode(str));

String currentResponseToJson(CurrentResponse data) =>
    json.encode(data.toJson());

class CurrentResponse {
  int? status;
  bool? success;
  String? message;
  List<Current>? data;

  CurrentResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory CurrentResponse.fromJson(Map<String, dynamic> json) =>
      CurrentResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Current>.from(json["data"]!.map((x) => Current.fromJson(x))),
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

class Current {
  int? id;
  DateTime? timeStamp;
  double? currentR;
  double? currentY;
  double? currentB;

  Current({
    this.id,
    this.timeStamp,
    this.currentR,
    this.currentY,
    this.currentB,
  });

  factory Current.fromJson(Map<String, dynamic> json) => Current(
        id: json["id"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        currentR: json["current_r"]?.toDouble(),
        currentY: json["current_y"]?.toDouble(),
        currentB: json["current_b"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "time_stamp": timeStamp?.toIso8601String(),
        "current_r": currentR,
        "current_y": currentY,
        "current_b": currentB,
      };
}
