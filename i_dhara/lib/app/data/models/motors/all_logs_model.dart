// To parse this JSON data, do
//
//     final alllogsResponse = alllogsResponseFromJson(jsonString);

import 'dart:convert';

AlllogsResponse alllogsResponseFromJson(String str) =>
    AlllogsResponse.fromJson(json.decode(str));

String alllogsResponseToJson(AlllogsResponse data) =>
    json.encode(data.toJson());

class AlllogsResponse {
  int? status;
  bool? success;
  String? message;
  LogResponseData? data;

  AlllogsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory AlllogsResponse.fromJson(Map<String, dynamic> json) =>
      AlllogsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : LogResponseData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class LogResponseData {
  Pagination? pagination;
  List<LogResponse>? records;

  LogResponseData({
    this.pagination,
    this.records,
  });

  factory LogResponseData.fromJson(Map<String, dynamic> json) => LogResponseData(
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
        records: json["records"] == null
            ? []
            : List<LogResponse>.from(
                json["records"]!.map((x) => LogResponse.fromJson(x))),
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

class LogResponse {
  int? id;
  String? logType;
  String? action;
  String? message;
  int? code;
  String? description;
  int? performedBy;
  DateTime? timestamp;

  LogResponse({
    this.id,
    this.logType,
    this.action,
    this.message,
    this.code,
    this.description,
    this.performedBy,
    this.timestamp,
  });

  factory LogResponse.fromJson(Map<String, dynamic> json) => LogResponse(
        id: json["id"],
        logType: json["log_type"],
        action: json["action"],
        message: json["message"],
        code: json["code"],
        description: json["description"],
        performedBy: json["performed_by"],
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "log_type": logType,
        "action": action,
        "message": message,
        "code": code,
        "description": description,
        "performed_by": performedBy,
        "timestamp": timestamp?.toIso8601String(),
      };
}
