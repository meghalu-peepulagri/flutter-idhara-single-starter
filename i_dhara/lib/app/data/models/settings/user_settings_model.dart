// To parse this JSON data, do
//
//     final userSettingsResponse = userSettingsResponseFromJson(jsonString);

import 'dart:convert';

UserSettingsResponse userSettingsResponseFromJson(String str) =>
    UserSettingsResponse.fromJson(json.decode(str));

String userSettingsResponseToJson(UserSettingsResponse data) =>
    json.encode(data.toJson());

class UserSettingsResponse {
  int? status;
  bool? success;
  String? message;
  UserSettings? data;

  UserSettingsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UserSettingsResponse.fromJson(Map<String, dynamic> json) =>
      UserSettingsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : UserSettings.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class UserSettings {
  int? id;
  int? starterId;
  int? lvf;
  int? hvf;
  DateTime? timeStamp;
  Starter? starter;

  UserSettings({
    this.id,
    this.starterId,
    this.lvf,
    this.hvf,
    this.timeStamp,
    this.starter,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        id: json["id"],
        starterId: json["starter_id"],
        lvf: json["lvf"],
        hvf: json["hvf"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        starter:
            json["starter"] == null ? null : Starter.fromJson(json["starter"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "starter_id": starterId,
        "lvf": lvf,
        "hvf": hvf,
        "time_stamp": timeStamp?.toIso8601String(),
        "starter": starter?.toJson(),
      };
}

class Starter {
  int? id;
  String? name;
  String? pcbNumber;
  String? macAddress;
  List<Motor>? motors;

  Starter({
    this.id,
    this.name,
    this.pcbNumber,
    this.macAddress,
    this.motors,
  });

  factory Starter.fromJson(Map<String, dynamic> json) => Starter(
        id: json["id"],
        name: json["name"],
        pcbNumber: json["pcb_number"],
        macAddress: json["mac_address"],
        motors: json["motors"] == null
            ? []
            : List<Motor>.from(json["motors"]!.map((x) => Motor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "pcb_number": pcbNumber,
        "mac_address": macAddress,
        "motors": motors == null
            ? []
            : List<dynamic>.from(motors!.map((x) => x.toJson())),
      };
}

class Motor {
  int? id;
  String? name;
  String? hp;

  Motor({
    this.id,
    this.name,
    this.hp,
  });

  factory Motor.fromJson(Map<String, dynamic> json) => Motor(
        id: json["id"],
        name: json["name"],
        hp: json["hp"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "hp": hp,
      };
}
