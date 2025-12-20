// To parse this JSON data, do
//
//     final motorResponse = motorResponseFromJson(jsonString);

import 'dart:convert';

MotorResponse motorResponseFromJson(String str) =>
    MotorResponse.fromJson(json.decode(str));

String motorResponseToJson(MotorResponse data) => json.encode(data.toJson());

class MotorResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  MotorResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotorResponse.fromJson(Map<String, dynamic> json) => MotorResponse(
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
  PaginationInfo? paginationInfo;
  List<Motor>? records;

  Data({
    this.paginationInfo,
    this.records,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        paginationInfo: json["pagination_info"] == null
            ? null
            : PaginationInfo.fromJson(json["pagination_info"]),
        records: json["records"] == null
            ? []
            : List<Motor>.from(json["records"]!.map((x) => Motor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "pagination_info": paginationInfo?.toJson(),
        "records": records == null
            ? []
            : List<dynamic>.from(records!.map((x) => x.toJson())),
      };
}

class PaginationInfo {
  int? totalRecords;
  int? totalPages;
  int? pageSize;
  int? currentPage;
  dynamic nextPage;
  dynamic prevPage;

  PaginationInfo({
    this.totalRecords,
    this.totalPages,
    this.pageSize,
    this.currentPage,
    this.nextPage,
    this.prevPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => PaginationInfo(
        totalRecords: json["total_records"],
        totalPages: json["total_pages"],
        pageSize: json["page_size"],
        currentPage: json["current_page"],
        nextPage: json["next_page"],
        prevPage: json["prev_page"],
      );

  Map<String, dynamic> toJson() => {
        "total_records": totalRecords,
        "total_pages": totalPages,
        "page_size": pageSize,
        "current_page": currentPage,
        "next_page": nextPage,
        "prev_page": prevPage,
      };
}

class Motor {
  int? id;
  String? name;
  String? hp;
  String? mode;
  int? state;
  String? aliasName;
  Location? location;
  Starter? starter;

  Motor({
    this.id,
    this.name,
    this.hp,
    this.mode,
    this.state,
    this.location,
    this.aliasName,
    this.starter,
  });

  factory Motor.fromJson(Map<String, dynamic> json) => Motor(
        id: json["id"],
        name: json["name"],
        hp: json["hp"],
        mode: json["mode"],
        state: json["state"],
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
        "mode": mode,
        "state": state,
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
  DateTime? timeStamp;
  int? fault;
  String? faultDescription;
  num? lineVoltageR;
  num? lineVoltageY;
  num? lineVoltageB;
  num? currentR;
  num? currentY;
  num? currentB;

  StarterParameter({
    this.id,
    this.timeStamp,
    this.fault,
    this.faultDescription,
    this.lineVoltageR,
    this.lineVoltageY,
    this.lineVoltageB,
    this.currentR,
    this.currentY,
    this.currentB,
  });

  factory StarterParameter.fromJson(Map<String, dynamic> json) =>
      StarterParameter(
        id: json["id"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        fault: json["fault"],
        faultDescription: json["fault_description"],
        lineVoltageR: json["line_voltage_r"],
        lineVoltageY: json["line_voltage_y"]?.toDouble(),
        lineVoltageB: json["line_voltage_b"]?.toDouble(),
        currentR: json["current_r"],
        currentY: json["current_y"],
        currentB: json["current_b"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "time_stamp": timeStamp?.toIso8601String(),
        "fault": fault,
        "fault_description": faultDescription,
        "line_voltage_r": lineVoltageR,
        "line_voltage_y": lineVoltageY,
        "line_voltage_b": lineVoltageB,
        "current_r": currentR,
        "current_y": currentY,
        "current_b": currentB,
      };
}
