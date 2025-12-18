// To parse this JSON data, do
//
//     final motorDetailsResponse = motorDetailsResponseFromJson(jsonString);

import 'dart:convert';

MotorDetailsResponse motorDetailsResponseFromJson(String str) =>
    MotorDetailsResponse.fromJson(json.decode(str));

String motorDetailsResponseToJson(MotorDetailsResponse data) =>
    json.encode(data.toJson());

class MotorDetailsResponse {
  int? status;
  bool? success;
  String? message;
  MotorDetails? data;

  MotorDetailsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotorDetailsResponse.fromJson(Map<String, dynamic> json) =>
      MotorDetailsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : MotorDetails.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class MotorDetails {
  int? id;
  String? name;
  String? hp;
  int? state;
  String? mode;
  int? createdBy;
  Location? location;
  Starter? starter;

  MotorDetails({
    this.id,
    this.name,
    this.hp,
    this.state,
    this.mode,
    this.createdBy,
    this.location,
    this.starter,
  });

  factory MotorDetails.fromJson(Map<String, dynamic> json) => MotorDetails(
        id: json["id"],
        name: json["name"],
        hp: json["hp"],
        state: json["state"],
        mode: json["mode"],
        createdBy: json["created_by"],
        location: json["location"] == null
            ? null
            : Location.fromJson(json["location"]),
        starter:
            json["starter"] == null ? null : Starter.fromJson(json["starter"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "hp": hp,
        "state": state,
        "mode": mode,
        "created_by": createdBy,
        "location": location?.toJson(),
        "starter": starter?.toJson(),
      };
}

class Location {
  int? id;
  String? name;

  Location({
    this.id,
    this.name,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Starter {
  int? id;
  String? name;
  String? status;
  String? macAddress;
  int? signalQuality;
  int? power;
  String? networkType;

  Starter({
    this.id,
    this.name,
    this.status,
    this.macAddress,
    this.signalQuality,
    this.power,
    this.networkType,
  });

  factory Starter.fromJson(Map<String, dynamic> json) => Starter(
        id: json["id"],
        name: json["name"],
        status: json["status"],
        macAddress: json["mac_address"],
        signalQuality: json["signal_quality"],
        power: json["power"],
        networkType: json["network_type"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "status": status,
        "mac_address": macAddress,
        "signal_quality": signalQuality,
        "power": power,
        "network_type": networkType,
      };
}
