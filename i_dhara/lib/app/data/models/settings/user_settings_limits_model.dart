// To parse this JSON data, do
//
//     final userSettingsLimitsResponse = userSettingsLimitsResponseFromJson(jsonString);

import 'dart:convert';

UserSettingsLimitsResponse userSettingsLimitsResponseFromJson(String str) =>
    UserSettingsLimitsResponse.fromJson(json.decode(str));

String userSettingsLimitsResponseToJson(UserSettingsLimitsResponse data) =>
    json.encode(data.toJson());

class UserSettingsLimitsResponse {
  int? status;
  bool? success;
  String? message;
  UserSettingsLimits? data;

  UserSettingsLimitsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UserSettingsLimitsResponse.fromJson(Map<String, dynamic> json) =>
      UserSettingsLimitsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : UserSettingsLimits.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class UserSettingsLimits {
  int? id;
  int? starterId;
  int? lvfMin;
  int? lvfMax;
  int? hvfMin;
  int? hvfMax;
  DateTime? createdAt;
  int? drfMin;
  int? drfMax;
  int? olfMin;
  int? olfMax;
  num? flcMin;
  num? flcMax;

  UserSettingsLimits(
      {this.id,
      this.starterId,
      this.lvfMin,
      this.lvfMax,
      this.hvfMin,
      this.hvfMax,
      this.createdAt,
      this.drfMin,
      this.drfMax,
      this.olfMin,
      this.olfMax,
      this.flcMin,
      this.flcMax});

  factory UserSettingsLimits.fromJson(Map<String, dynamic> json) =>
      UserSettingsLimits(
        id: json["id"],
        starterId: json["starter_id"],
        lvfMin: json["lvf_min"],
        lvfMax: json["lvf_max"],
        hvfMin: json["hvf_min"],
        hvfMax: json["hvf_max"],
        drfMin: json["drf_min"],
        drfMax: json["drf_max"],
        olfMin: json["olf_min"],
        olfMax: json["olf_max"],
        flcMin: json["flc_min"],
        flcMax: json["flc_max"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "starter_id": starterId,
        "lvf_min": lvfMin,
        "lvf_max": lvfMax,
        "hvf_min": hvfMin,
        "hvf_max": hvfMax,
        "created_at": createdAt?.toIso8601String(),
        "drf_min": drfMin,
        "drf_max": drfMax,
        "olf_min": olfMin,
        "olf_max": olfMax,
        'flc_min': flcMin,
        'flc_max': flcMax
      };
}
