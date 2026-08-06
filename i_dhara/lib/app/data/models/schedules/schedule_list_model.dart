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
  ScheduleType? scheduleType;
  int? scheduleId;
  int? deviceScheduleId;
  int? deviceScheduleStatus;
  int? bitWiseDays;
  int? scheduleStartDate;
  int? scheduleEndDate;
  List<int>? daysOfWeek;
  String? startTime;
  String? endTime;
  int? runtimeMinutes;
  int? cycleOnMinutes;
  int? cycleOffMinutes;
  bool? powerLossRecovery;
  int? accumulatedOnSeconds;
  bool? manuallyStopped;
  int? actualRunTime;
  String? actualStartTime;
  String? actualEndTime;
  int? repeat;
  bool? enabled;
  String? scheduleStatus;
  int? acknowledgement;
  DateTime? acknowledgedAt;
  dynamic lastStartedAt;
  DateTime? lastStoppedAt;
  int? createdBy;
  dynamic deletedBy;
  Status? status;
  int? priority;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? motorReference;
  String? motorSupportType;
  String? payloadVersion;

  /// Schedule-action (T:24) payload shape. From payload version 2.0 a starter
  /// uses the motor-scoped form even with a single motor, so the version
  /// decides — falling back to the motor count for records that predate it.
  bool get isMultiMotorSchedule {
    final major =
        int.tryParse((payloadVersion ?? '').split('.').first.trim());
    if (major != null) return major >= 2;
    return (motorSupportType ?? '').toUpperCase().contains('MULTI');
  }

  String get motorKey => motorReference == 'm2' ? 'm2' : 'm1';

  Record({
    this.id,
    this.motorId,
    this.starterId,
    this.scheduleType,
    this.scheduleId,
    this.deviceScheduleId,
    this.deviceScheduleStatus,
    this.bitWiseDays,
    this.scheduleStartDate,
    this.scheduleEndDate,
    this.daysOfWeek,
    this.startTime,
    this.endTime,
    this.actualRunTime,
    this.actualStartTime,
    this.actualEndTime,
    this.runtimeMinutes,
    this.cycleOnMinutes,
    this.cycleOffMinutes,
    this.powerLossRecovery,
    this.accumulatedOnSeconds,
    this.manuallyStopped,
    this.repeat,
    this.enabled,
    this.scheduleStatus,
    this.acknowledgement,
    this.acknowledgedAt,
    this.lastStartedAt,
    this.lastStoppedAt,
    this.createdBy,
    this.deletedBy,
    this.status,
    this.priority,
    this.createdAt,
    this.updatedAt,
    this.motorReference,
    this.motorSupportType,
    this.payloadVersion,
  });

  factory Record.fromJson(Map<String, dynamic> json) => Record(
        id: json["id"],
        motorId: json["motor_id"],
        starterId: json["starter_id"],
        scheduleType: scheduleTypeValues.map[json["schedule_type"]]!,
        scheduleId: json["schedule_id"],
        deviceScheduleId: json["device_schedule_id"],
        deviceScheduleStatus: json["device_schedule_status"],
        bitWiseDays: json["bit_wise_days"],
        scheduleStartDate: json["schedule_start_date"],
        scheduleEndDate: json["schedule_end_date"],
        daysOfWeek: json["days_of_week"] == null
            ? []
            : List<int>.from(json["days_of_week"]!.map((x) => x)),
        startTime: json["start_time"],
        endTime: json["end_time"],
        runtimeMinutes: json["runtime_minutes"],
        cycleOnMinutes: json["cycle_on_minutes"],
        cycleOffMinutes: json["cycle_off_minutes"],
        powerLossRecovery: json["power_loss_recovery"],
        actualRunTime: json["actual_run_time"],
        actualStartTime: json["actual_start_time"],
        actualEndTime: json["actual_end_time"],
        accumulatedOnSeconds: json["accumulated_on_seconds"],
        manuallyStopped: json["manually_stopped"],
        repeat: json["repeat"],
        enabled: json["enabled"],
        scheduleStatus: json["schedule_status"],
        acknowledgement: json["acknowledgement"],
        acknowledgedAt: json["acknowledged_at"] == null
            ? null
            : DateTime.parse(json["acknowledged_at"]),
        lastStartedAt: json["last_started_at"],
        lastStoppedAt: json["last_stopped_at"] == null
            ? null
            : DateTime.parse(json["last_stopped_at"]),
        createdBy: json["created_by"],
        deletedBy: json["deleted_by"],
        status: statusValues.map[json["status"]]!,
        priority: json["priority"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        motorReference: json["motor_reference"],
        motorSupportType: json["motor_support_type"],
        payloadVersion: json["payload_version"]?.toString(),
      );

  Record copyWith({
    int? runtimeMinutes,
    String? startTime,
    String? endTime,
    int? accumulatedOnSeconds,
    String? scheduleStatus,
    int? actualRunTime,
    String? actualStartTime,
    String? actualEndTime,
    int? deviceScheduleStatus,
  }) =>
      Record(
        id: id,
        motorId: motorId,
        starterId: starterId,
        scheduleType: scheduleType,
        scheduleId: scheduleId,
        deviceScheduleId: deviceScheduleId,
        deviceScheduleStatus:
            deviceScheduleStatus ?? this.deviceScheduleStatus,
        bitWiseDays: bitWiseDays,
        scheduleStartDate: scheduleStartDate,
        scheduleEndDate: scheduleEndDate,
        daysOfWeek: daysOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        actualRunTime: actualRunTime ?? this.actualRunTime,
        actualStartTime: actualStartTime ?? this.actualStartTime,
        actualEndTime: actualEndTime ?? this.actualEndTime,
        runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
        cycleOnMinutes: cycleOnMinutes,
        cycleOffMinutes: cycleOffMinutes,
        powerLossRecovery: powerLossRecovery,
        accumulatedOnSeconds: accumulatedOnSeconds ?? this.accumulatedOnSeconds,
        manuallyStopped: manuallyStopped,
        repeat: repeat,
        enabled: enabled,
        scheduleStatus: scheduleStatus ?? this.scheduleStatus,
        acknowledgement: acknowledgement,
        acknowledgedAt: acknowledgedAt,
        lastStartedAt: lastStartedAt,
        lastStoppedAt: lastStoppedAt,
        createdBy: createdBy,
        deletedBy: deletedBy,
        status: status,
        priority: priority,
        createdAt: createdAt,
        updatedAt: updatedAt,
        motorReference: motorReference,
        motorSupportType: motorSupportType,
        payloadVersion: payloadVersion,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "motor_id": motorId,
        "starter_id": starterId,
        "schedule_type": scheduleTypeValues.reverse[scheduleType],
        "schedule_id": scheduleId,
        "device_schedule_id": deviceScheduleId,
        "device_schedule_status": deviceScheduleStatus,
        "bit_wise_days": bitWiseDays,
        "schedule_start_date": scheduleStartDate,
        "schedule_end_date": scheduleEndDate,
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
        "actual_run_time": actualRunTime,
        "actual_start_time": actualStartTime,
        "actual_end_time": actualEndTime,
        "repeat": repeat,
        "enabled": enabled,
        "schedule_status": scheduleStatus,
        "acknowledgement": acknowledgement,
        "acknowledged_at": acknowledgedAt?.toIso8601String(),
        "last_started_at": lastStartedAt,
        "last_stopped_at": lastStoppedAt?.toIso8601String(),
        "created_by": createdBy,
        "deleted_by": deletedBy,
        "status": statusValues.reverse[status],
        "priority": priority,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "motor_reference": motorReference,
        "motor_support_type": motorSupportType,
        "payload_version": payloadVersion,
      };
}

enum ScheduleType { CYCLIC, TIME_BASED }

final scheduleTypeValues = EnumValues(
    {"CYCLIC": ScheduleType.CYCLIC, "TIME_BASED": ScheduleType.TIME_BASED});

enum Status { ACTIVE }

final statusValues = EnumValues({"ACTIVE": Status.ACTIVE});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
