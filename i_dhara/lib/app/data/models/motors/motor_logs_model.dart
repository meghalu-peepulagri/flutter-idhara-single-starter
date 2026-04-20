// To parse this JSON data, do
//
//     final motorLogsResponse = motorLogsResponseFromJson(jsonString);

import 'dart:convert';

MotorLogsResponse motorLogsResponseFromJson(String str) =>
    MotorLogsResponse.fromJson(json.decode(str));

String motorLogsResponseToJson(MotorLogsResponse data) =>
    json.encode(data.toJson());

class MotorLogsResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  MotorLogsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory MotorLogsResponse.fromJson(Map<String, dynamic> json) =>
      MotorLogsResponse(
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
  List<MotorLogs>? records;

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
            : List<MotorLogs>.from(
                json["records"]!.map((x) => MotorLogs.fromJson(x))),
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

class MotorLogs {
  int? id;
  int? performedBy;
  String? action;
  String? entityType;
  int? entityId;
  String? message;
  DateTime? createdAt;
  DateTime? timestamp;

  MotorLogs(
      {this.id,
      this.performedBy,
      this.action,
      this.entityType,
      this.entityId,
      this.message,
      this.createdAt,
      this.timestamp});

  factory MotorLogs.fromJson(Map<String, dynamic> json) => MotorLogs(
        id: json["id"],
        performedBy: json["performed_by"],
        action: json["action"],
        entityType: json["entity_type"],
        entityId: json["entity_id"],
        message: json["message"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "performed_by": performedBy,
        "action": action,
        "entity_type": entityType,
        "entity_id": entityId,
        "message": message,
        "created_at": createdAt?.toIso8601String(),
        "timestamp": timestamp?.toIso8601String(),
      };
}
