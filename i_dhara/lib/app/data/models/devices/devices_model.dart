// To parse this JSON data, do
//
//     final devicesResponse = devicesResponseFromJson(jsonString);

import 'dart:convert';

DevicesResponse devicesResponseFromJson(String str) =>
    DevicesResponse.fromJson(json.decode(str));

String devicesResponseToJson(DevicesResponse data) =>
    json.encode(data.toJson());

class DevicesResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  DevicesResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory DevicesResponse.fromJson(Map<String, dynamic> json) =>
      DevicesResponse(
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
  List<Devices>? records;

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
            : List<Devices>.from(
                json["records"]!.map((x) => Devices.fromJson(x))),
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

class Devices {
  int? id;
  String? name;
  String? pcbNumber;
  String? macAddress;
  String? starterNumber;
  int? power;
  int? signalQuality;
  String? networkType;
  String? deviceAllocation;
  String? deviceMobileNumber;
  String? simRechargeExpire;
  String? deviceInstalledLocation;
  String? installationPhotoKey;
  String? installationPhotoUrl;
  String? motorSupportType;
  String? payloadVersion;
  String? starterType;
  List<Motor>? motors;

  bool get isMultiMotor =>
      (motorSupportType ?? '').toUpperCase().contains('MULTI');

  Devices(
      {this.id,
      this.name,
      this.pcbNumber,
      this.macAddress,
      this.starterNumber,
      this.power,
      this.signalQuality,
      this.networkType,
      this.motors,
      this.deviceAllocation,
      this.deviceMobileNumber,
      this.simRechargeExpire,
      this.deviceInstalledLocation,
      this.installationPhotoKey,
      this.installationPhotoUrl,
      this.motorSupportType,
      this.payloadVersion,
      this.starterType});

  factory Devices.fromJson(Map<String, dynamic> json) => Devices(
        id: json["id"],
        name: json["name"],
        pcbNumber: json["pcb_number"],
        macAddress: json["mac_address"],
        starterNumber: json["starter_number"],
        power: json["power"],
        signalQuality: json["signal_quality"],
        networkType: json["network_type"],
        deviceAllocation: json["device_allocation"],
        simRechargeExpire: json["sim_recharge_expires_at"],
        deviceMobileNumber: json["device_mobile_number"],
        deviceInstalledLocation: json["device_installed_location"],
        installationPhotoKey: json["installation_photo_key"],
        installationPhotoUrl: json["installation_photo_url"],
        motorSupportType: json["motor_support_type"],
        payloadVersion: json["payload_version"]?.toString(),
        starterType: json["starter_type"],
        motors: json["motors"] == null
            ? []
            : List<Motor>.from(json["motors"]!.map((x) => Motor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "pcb_number": pcbNumber,
        "mac_address": macAddress,
        "starter_number": starterNumber,
        "power": power,
        "signal_quality": signalQuality,
        "network_type": networkType,
        "device_allocation": deviceAllocation,
        "device_mobile_number": deviceMobileNumber,
        "sim_recharge_expires_at": simRechargeExpire,
        "device_installed_location": deviceInstalledLocation,
        "installation_photo_key": installationPhotoKey,
        "installation_photo_url": installationPhotoUrl,
        "motor_support_type": motorSupportType,
        "payload_version": payloadVersion,
        "starter_type": starterType,
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
  Location? location;
  String? testrunStatus;
  String? testRunCompletedAt;
  int? motorIndex;
  String? motorReference;

  Motor({
    this.id,
    this.name,
    this.hp,
    this.state,
    this.mode,
    this.aliasName,
    this.location,
    this.testrunStatus,
    this.testRunCompletedAt,
    this.motorIndex,
    this.motorReference,
  });

  factory Motor.fromJson(Map<String, dynamic> json) => Motor(
        id: json["id"],
        name: json["name"],
        hp: json["hp"],
        state: json["state"],
        mode: json["mode"],
        aliasName: json["alias_name"],
        location: json["location"] == null
            ? null
            : Location.fromJson(json["location"]),
        testrunStatus: json["test_run_status"],
        testRunCompletedAt: json["test_run_completed_at"],
        motorIndex: json["motor_index"],
        motorReference: json["motor_reference"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "hp": hp,
        "state": state,
        "mode": mode,
        "alias_name": aliasName,
        "location": location?.toJson(),
        "test_run_status": testrunStatus,
        "test_run_completed_at": testRunCompletedAt,
        "motor_index": motorIndex,
        "motor_reference": motorReference,
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
