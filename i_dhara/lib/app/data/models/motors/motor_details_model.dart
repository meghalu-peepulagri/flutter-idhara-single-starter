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
  String? aliasName;
  Location? location;
  Starter? starter;

  MotorDetails({
    this.id,
    this.name,
    this.hp,
    this.state,
    this.mode,
    this.aliasName,
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
        aliasName: json["alias_name"],
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
        "alias_name": aliasName,
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
  List<StarterParameter>? starterParameters;

  Starter({
    this.id,
    this.name,
    this.status,
    this.macAddress,
    this.signalQuality,
    this.power,
    this.networkType,
    this.starterParameters,
  });

  factory Starter.fromJson(Map<String, dynamic> json) => Starter(
        id: json["id"],
        name: json["name"],
        status: json["status"],
        macAddress: json["mac_address"],
        signalQuality: json["signal_quality"],
        power: json["power"],
        networkType: json["network_type"],
        starterParameters: json["starterParameters"] == null
            ? []
            : List<StarterParameter>.from(json["starterParameters"]!
                .map((x) => StarterParameter.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "status": status,
        "mac_address": macAddress,
        "signal_quality": signalQuality,
        "power": power,
        "network_type": networkType,
        "starterParameters": starterParameters == null
            ? []
            : List<dynamic>.from(starterParameters!.map((x) => x.toJson())),
      };
}

class StarterParameter {
  int? id;
  int? lineVoltageR;
  double? lineVoltageY;
  double? lineVoltageB;
  int? currentR;
  int? currentY;
  double? currentB;
  DateTime? timeStamp;
  int? fault;
  String? faultDescription;

  StarterParameter({
    this.id,
    this.lineVoltageR,
    this.lineVoltageY,
    this.lineVoltageB,
    this.currentR,
    this.currentY,
    this.currentB,
    this.timeStamp,
    this.fault,
    this.faultDescription,
  });

  factory StarterParameter.fromJson(Map<String, dynamic> json) =>
      StarterParameter(
        id: json["id"],
        lineVoltageR: json["line_voltage_r"],
        lineVoltageY: json["line_voltage_y"]?.toDouble(),
        lineVoltageB: json["line_voltage_b"]?.toDouble(),
        currentR: json["current_r"],
        currentY: json["current_y"],
        currentB: json["current_b"]?.toDouble(),
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        fault: json["fault"],
        faultDescription: json["fault_description"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "line_voltage_r": lineVoltageR,
        "line_voltage_y": lineVoltageY,
        "line_voltage_b": lineVoltageB,
        "current_r": currentR,
        "current_y": currentY,
        "current_b": currentB,
        "time_stamp": timeStamp?.toIso8601String(),
        "fault": fault,
        "fault_description": faultDescription,
      };
}
