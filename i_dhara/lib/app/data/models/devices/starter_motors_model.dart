// To parse this JSON data, do
//
//     final starterMotorsResponse = starterMotorsResponseFromJson(jsonString);

import 'dart:convert';

StarterMotorsResponse starterMotorsResponseFromJson(String str) =>
    StarterMotorsResponse.fromJson(json.decode(str));

String starterMotorsResponseToJson(StarterMotorsResponse data) =>
    json.encode(data.toJson());

class StarterMotorsResponse {
  int? status;
  bool? success;
  String? message;
  StarterMotorsData? data;

  StarterMotorsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory StarterMotorsResponse.fromJson(Map<String, dynamic> json) =>
      StarterMotorsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : StarterMotorsData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class StarterMotorsData {
  int? id;
  String? pcbNumber;
  String? starterNumber;
  String? macAddress;
  String? starterType;
  String? motorStarterType;
  String? motorSupportType;
  List<StarterMotor>? motors;

  StarterMotorsData({
    this.id,
    this.pcbNumber,
    this.starterNumber,
    this.macAddress,
    this.starterType,
    this.motorStarterType,
    this.motorSupportType,
    this.motors,
  });

  factory StarterMotorsData.fromJson(Map<String, dynamic> json) =>
      StarterMotorsData(
        id: json["id"],
        pcbNumber: json["pcb_number"],
        starterNumber: json["starter_number"],
        macAddress: json["mac_address"],
        starterType: json["starter_type"],
        motorStarterType: json["motor_starter_type"],
        motorSupportType: json["motor_support_type"],
        motors: json["motors"] == null
            ? []
            : List<StarterMotor>.from(
                json["motors"]!.map((x) => StarterMotor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "pcb_number": pcbNumber,
        "starter_number": starterNumber,
        "mac_address": macAddress,
        "starter_type": starterType,
        "motor_starter_type": motorStarterType,
        "motor_support_type": motorSupportType,
        "motors": motors == null
            ? []
            : List<dynamic>.from(motors!.map((x) => x.toJson())),
      };
}

class StarterMotor {
  int? id;
  String? name;
  String? hp;
  int? state;
  String? mode;
  String? aliasName;
  int? motorIndex;
  DateTime? testRunCompletedAt;

  StarterMotor({
    this.id,
    this.name,
    this.hp,
    this.state,
    this.mode,
    this.aliasName,
    this.motorIndex,
    this.testRunCompletedAt,
  });

  factory StarterMotor.fromJson(Map<String, dynamic> json) => StarterMotor(
        id: json["id"],
        name: json["name"],
        hp: json["hp"]?.toString(),
        state: json["state"],
        mode: json["mode"],
        aliasName: json["alias_name"],
        motorIndex: json["motor_index"],
        testRunCompletedAt: json["test_run_completed_at"] == null
            ? null
            : DateTime.tryParse(json["test_run_completed_at"].toString()),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "hp": hp,
        "state": state,
        "mode": mode,
        "alias_name": aliasName,
        "motor_index": motorIndex,
        "test_run_completed_at": testRunCompletedAt?.toIso8601String(),
      };
}
