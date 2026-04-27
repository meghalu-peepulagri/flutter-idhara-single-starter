// To parse this JSON data, do
//
//     final scheduleHistoryLogsResponse = scheduleHistoryLogsResponseFromJson(jsonString);

import 'dart:convert';

ScheduleHistoryLogsResponse scheduleHistoryLogsResponseFromJson(String str) =>
    ScheduleHistoryLogsResponse.fromJson(json.decode(str));

String scheduleHistoryLogsResponseToJson(ScheduleHistoryLogsResponse data) =>
    json.encode(data.toJson());

class ScheduleHistoryLogsResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  ScheduleHistoryLogsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory ScheduleHistoryLogsResponse.fromJson(Map<String, dynamic> json) =>
      ScheduleHistoryLogsResponse(
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
  List<Record>? records;

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
            : List<Record>.from(
                json["records"]!.map((x) => Record.fromJson(x))),
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

class Record {
  int? id;
  int? scheduleId;
  int? motorId;
  int? starterId;
  String? scheduleType;
  String? scheduleStatus;
  String? startTime;
  String? endTime;
  int? scheduleStartDate;
  int? scheduleEndDate;
  int? repeat;
  DateTime? createdAt;
  List<Event>? events;

  Record({
    this.id,
    this.scheduleId,
    this.motorId,
    this.starterId,
    this.scheduleType,
    this.scheduleStatus,
    this.startTime,
    this.endTime,
    this.scheduleStartDate,
    this.scheduleEndDate,
    this.repeat,
    this.createdAt,
    this.events,
  });

  factory Record.fromJson(Map<String, dynamic> json) => Record(
        id: json["id"],
        scheduleId: json["schedule_id"],
        motorId: json["motor_id"],
        starterId: json["starter_id"],
        scheduleType: json["schedule_type"],
        scheduleStatus: json["schedule_status"],
        startTime: json["start_time"],
        endTime: json["end_time"],
        scheduleStartDate: json["schedule_start_date"],
        scheduleEndDate: json["schedule_end_date"],
        repeat: json["repeat"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        events: json["events"] == null
            ? []
            : List<Event>.from(json["events"]!.map((x) => Event.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "schedule_id": scheduleId,
        "motor_id": motorId,
        "starter_id": starterId,
        "schedule_type": scheduleType,
        "schedule_status": scheduleStatus,
        "start_time": startTime,
        "end_time": endTime,
        "schedule_start_date": scheduleStartDate,
        "schedule_end_date": scheduleEndDate,
        "repeat": repeat,
        "created_at": createdAt?.toIso8601String(),
        "events": events == null
            ? []
            : List<dynamic>.from(events!.map((x) => x.toJson())),
      };
}

class Event {
  String? event;
  DateTime? timestamp;

  Event({
    this.event,
    this.timestamp,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        event: json["event"],
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
      );

  Map<String, dynamic> toJson() => {
        "event": event,
        "timestamp": timestamp?.toIso8601String(),
      };
}
