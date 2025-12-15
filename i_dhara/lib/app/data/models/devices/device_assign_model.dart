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
  dynamic data;
  ErrorsClass? errors;

  DeviceAssignResponse(
      {this.status, this.success, this.message, this.data, this.errors});

  factory DeviceAssignResponse.fromJson(Map<String, dynamic> json) =>
      DeviceAssignResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"],
        errors: json["errors"] == null
            ? null
            : ErrorsClass.fromJson(json["errors"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data,
        "errors": errors?.toJson(),
      };
}

class ErrorsClass {
  String? pcbNumber;
  String? motorName;
  String? locationId;
  String? hp;

  ErrorsClass({
    this.pcbNumber,
    this.motorName,
    this.locationId,
    this.hp,
  });

  factory ErrorsClass.fromJson(Map<String, dynamic> json) => ErrorsClass(
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
