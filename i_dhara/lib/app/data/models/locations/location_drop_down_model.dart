// To parse this JSON data, do
//
//     final locationDropDownResponse = locationDropDownResponseFromJson(jsonString);

import 'dart:convert';

LocationDropDownResponse locationDropDownResponseFromJson(String str) =>
    LocationDropDownResponse.fromJson(json.decode(str));

String locationDropDownResponseToJson(LocationDropDownResponse data) =>
    json.encode(data.toJson());

class LocationDropDownResponse {
  int? status;
  bool? success;
  String? message;
  List<LocationDropDown>? data;

  LocationDropDownResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory LocationDropDownResponse.fromJson(Map<String, dynamic> json) =>
      LocationDropDownResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<LocationDropDown>.from(
                json["data"]!.map((x) => LocationDropDown.fromJson(x))),
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

class LocationDropDown {
  int? id;
  String? name;

  LocationDropDown({
    this.id,
    this.name,
  });

  factory LocationDropDown.fromJson(Map<String, dynamic> json) =>
      LocationDropDown(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
