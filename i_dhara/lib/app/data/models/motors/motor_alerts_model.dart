// To parse this JSON data, do
//
//     final motorAlertsResponse = motorAlertsResponseFromJson(jsonString);

import 'dart:convert';

MotorAlertsResponse motorAlertsResponseFromJson(String str) =>
    MotorAlertsResponse.fromJson(json.decode(str));

String motorAlertsResponseToJson(MotorAlertsResponse data) =>
    json.encode(data.toJson());

class MotorAlertsResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  MotorAlertsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotorAlertsResponse.fromJson(Map<String, dynamic> json) =>
      MotorAlertsResponse(
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
  Pagination? pagination;
  List<MotorAlerts>? records;

  Data({
    this.pagination,
    this.records,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
        records: json["records"] == null
            ? []
            : List<MotorAlerts>.from(
                json["records"]!.map((x) => MotorAlerts.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "pagination": pagination?.toJson(),
        "records": records == null
            ? []
            : List<dynamic>.from(records!.map((x) => x.toJson())),
      };
}

class Pagination {
  int? totalRecords;
  int? totalPages;
  int? pageSize;
  int? currentPage;
  dynamic nextPage;
  dynamic prevPage;

  Pagination({
    this.totalRecords,
    this.totalPages,
    this.pageSize,
    this.currentPage,
    this.nextPage,
    this.prevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
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

class MotorAlerts {
  int? id;
  int? starterId;
  int? motorId;
  int? code;
  String? description;
  DateTime? timestamp;

  MotorAlerts({
    this.id,
    this.starterId,
    this.motorId,
    this.code,
    this.description,
    this.timestamp,
  });

  factory MotorAlerts.fromJson(Map<String, dynamic> json) => MotorAlerts(
        id: json["id"],
        starterId: json["starter_id"],
        motorId: json["motor_id"],
        code: json["code"],
        description: json["description"],
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "starter_id": starterId,
        "motor_id": motorId,
        "code": code,
        "description": description,
        "timestamp": timestamp?.toIso8601String(),
      };
}
