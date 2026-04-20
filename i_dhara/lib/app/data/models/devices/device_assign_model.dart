// To parse this JSON data, do
//
//     final deviceAssignResponse = deviceAssignResponseFromJson(jsonString);

import 'dart:convert';

DeviceAssignResponse deviceAssignResponseFromJson(String str) =>
    DeviceAssignResponse.fromJson(json.decode(str));

String deviceAssignResponseToJson(DeviceAssignResponse data) =>
    json.encode(data.toJson());

class DeviceAssignResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;
  Errors? errors;

  DeviceAssignResponse({
    this.status,
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory DeviceAssignResponse.fromJson(Map<String, dynamic> json) =>
      DeviceAssignResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        errors: json["errors"] == null ? null : Errors.fromJson(json["errors"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
        "errors": errors?.toJson(),
      };
}

class Errors {
  String? pcbNumber;
  String? motorName;
  String? locationId;
  String? hp;

  Errors({
    this.pcbNumber,
    this.motorName,
    this.locationId,
    this.hp,
  });

  factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        pcbNumber: json["pcb_number"],
        motorName: json["motor_name"],
        locationId: json["location_id"],
        hp: json["hp"],
      );

  Map<String, dynamic> toJson() => {
        "pcb_number": pcbNumber,
        "motor_name": motorName,
        "location_id": locationId,
        "hp": hp,
      };
}

class Data {
  int? starterId;

  Data({this.starterId});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        starterId: json["starter_id"],
      );

  Map<String, dynamic> toJson() => {
        "starter_id": starterId,
      };
}
