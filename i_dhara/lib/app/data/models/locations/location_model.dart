// To parse this JSON data, do
//
//     final locationResponse = locationResponseFromJson(jsonString);

import 'dart:convert';

LocationResponse locationResponseFromJson(String str) =>
    LocationResponse.fromJson(json.decode(str));

String locationResponseToJson(LocationResponse data) =>
    json.encode(data.toJson());

class LocationResponse {
  int? status;
  bool? success;
  String? message;
  List<Location>? data;

  LocationResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) =>
      LocationResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Location>.from(
                json["data"]!.map((x) => Location.fromJson(x))),
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

class Location {
  int? id;
  String? name;
  String? status;
  int? locationsCount;
  int? totalMotors;
  int? onStateCount;
  int? autoModeCount;
  int? manualModeCount;
  List<Motor>? motors;

  Location({
    this.id,
    this.name,
    this.status,
    this.locationsCount,
    this.totalMotors,
    this.onStateCount,
    this.autoModeCount,
    this.manualModeCount,
    this.motors,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json["id"],
        name: json["name"],
        status: json["status"],
        locationsCount: json["locations_count"],
        totalMotors: json["total_motors"],
        onStateCount: json["on_state_count"],
        autoModeCount: json["auto_mode_count"],
        manualModeCount: json["manual_mode_count"],
        motors: json["motors"] == null
            ? []
            : List<Motor>.from(json["motors"]!.map((x) => Motor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "status": status,
        "locations_count": locationsCount,
        "total_motors": totalMotors,
        "on_state_count": onStateCount,
        "auto_mode_count": autoModeCount,
        "manual_mode_count": manualModeCount,
        "motors": motors == null
            ? []
            : List<dynamic>.from(motors!.map((x) => x.toJson())),
      };
}

class Motor {
  int? id;
  String? name;
  String? hp;
  int? state;
  String? mode;
  String? aliasName;

  Motor({
    this.id,
    this.name,
    this.hp,
    this.state,
    this.mode,
    this.aliasName,
  });

  factory Motor.fromJson(Map<String, dynamic> json) => Motor(
        id: json["id"],
        name: json["name"],
        hp: json["hp"],
        state: json["state"],
        mode: json["mode"],
        aliasName: json["alias_name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "hp": hp,
        "state": state,
        "mode": mode,
        "alias_name": aliasName,
      };
}
