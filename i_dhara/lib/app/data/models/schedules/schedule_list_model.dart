// To parse this JSON data, do
//
//     final scheduleListResponse = scheduleListResponseFromJson(jsonString);

import 'dart:convert';

ScheduleListResponse scheduleListResponseFromJson(String str) =>
    ScheduleListResponse.fromJson(json.decode(str));

String scheduleListResponseToJson(ScheduleListResponse data) =>
    json.encode(data.toJson());

class ScheduleListResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  ScheduleListResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory ScheduleListResponse.fromJson(Map<String, dynamic> json) =>
      ScheduleListResponse(
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
  List<Record>? records;

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
            : List<Record>.from(
                json["records"]!.map((x) => Record.fromJson(x))),
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

class Record {
  int? id;
  int? motorId;
  int? starterId;
  String? scheduleType;
  int? scheduleId;
  DateTime? scheduleDate;
  List<int>? daysOfWeek;
  String? startTime;
  String? endTime;
  int? runtimeMinutes;
  dynamic cycleOnMinutes;
  dynamic cycleOffMinutes;
  bool? powerLossRecovery;
  int? accumulatedOnSeconds;
  bool? manuallyStopped;
  int? repeat;
  String? scheduleStatus;
  int? acknowledgement;
  DateTime? createdAt;
  DateTime? updatedAt;

  Record({
    this.id,
    this.motorId,
    this.starterId,
    this.scheduleType,
    this.scheduleId,
    this.scheduleDate,
    this.daysOfWeek,
    this.startTime,
    this.endTime,
    this.runtimeMinutes,
    this.cycleOnMinutes,
    this.cycleOffMinutes,
    this.powerLossRecovery,
    this.accumulatedOnSeconds,
    this.manuallyStopped,
    this.repeat,
    this.scheduleStatus,
    this.acknowledgement,
    this.createdAt,
    this.updatedAt,
  });

  factory Record.fromJson(Map<String, dynamic> json) => Record(
        id: json["id"],
        motorId: json["motor_id"],
        starterId: json["starter_id"],
        scheduleType: json["schedule_type"],
        scheduleId: json["schedule_id"],
        scheduleDate: json["schedule_date"] == null
            ? null
            : DateTime.parse(json["schedule_date"]),
        daysOfWeek: json["days_of_week"] == null
            ? []
            : List<int>.from(json["days_of_week"]!.map((x) => x)),
        startTime: json["start_time"],
        endTime: json["end_time"],
        runtimeMinutes: json["runtime_minutes"],
        cycleOnMinutes: json["cycle_on_minutes"],
        cycleOffMinutes: json["cycle_off_minutes"],
        powerLossRecovery: json["power_loss_recovery"],
        accumulatedOnSeconds: json["accumulated_on_seconds"],
        manuallyStopped: json["manually_stopped"],
        repeat: json["repeat"],
        scheduleStatus: json["schedule_status"],
        acknowledgement: json["acknowledgement"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "motor_id": motorId,
        "starter_id": starterId,
        "schedule_type": scheduleType,
        "schedule_id": scheduleId,
        "schedule_date": scheduleDate?.toIso8601String(),
        "days_of_week": daysOfWeek == null
            ? []
            : List<dynamic>.from(daysOfWeek!.map((x) => x)),
        "start_time": startTime,
        "end_time": endTime,
        "runtime_minutes": runtimeMinutes,
        "cycle_on_minutes": cycleOnMinutes,
        "cycle_off_minutes": cycleOffMinutes,
        "power_loss_recovery": powerLossRecovery,
        "accumulated_on_seconds": accumulatedOnSeconds,
        "manually_stopped": manuallyStopped,
        "repeat": repeat,
        "schedule_status": scheduleStatus,
        "acknowledgement": acknowledgement,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
