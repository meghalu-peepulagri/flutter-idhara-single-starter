// To parse this JSON data, do
//
//     final motorControlResponse = motorControlResponseFromJson(jsonString);

import 'dart:convert';

MotorControlResponse motorControlResponseFromJson(String str) =>
    MotorControlResponse.fromJson(json.decode(str));

String motorControlResponseToJson(MotorControlResponse data) =>
    json.encode(data.toJson());

class MotorControlRequest {
  final List<MotorControlItem> motors;

  MotorControlRequest({required this.motors});

  Map<String, dynamic> toJson() => {
        "motors": List<dynamic>.from(motors.map((x) => x.toJson())),
      };
}

class MotorControlItem {
  final int motorId;
  final int state;

  MotorControlItem({required this.motorId, required this.state});

  Map<String, dynamic> toJson() => {
        "motor_id": motorId,
        "state": state,
      };
}

class MotorControlResponse {
  String? status;
  List<MotorControlResult>? results;

  MotorControlResponse({
    this.status,
    this.results,
  });

  factory MotorControlResponse.fromJson(Map<String, dynamic> json) =>
      MotorControlResponse(
        status: json["status"],
        results: json["results"] == null
            ? []
            : List<MotorControlResult>.from(
                json["results"]!.map((x) => MotorControlResult.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "results": results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class MotorControlResult {
  int? motorId;
  int? motorIndex;
  int? requestedState;
  bool? acked;
  int? ackCode;
  String? ackStatus;

  MotorControlResult({
    this.motorId,
    this.motorIndex,
    this.requestedState,
    this.acked,
    this.ackCode,
    this.ackStatus,
  });

  factory MotorControlResult.fromJson(Map<String, dynamic> json) =>
      MotorControlResult(
        motorId: json["motor_id"],
        motorIndex: json["motor_index"],
        requestedState: json["requested_state"],
        acked: json["acked"],
        ackCode: json["ack_code"],
        ackStatus: json["ack_status"],
      );

  Map<String, dynamic> toJson() => {
        "motor_id": motorId,
        "motor_index": motorIndex,
        "requested_state": requestedState,
        "acked": acked,
        "ack_code": ackCode,
        "ack_status": ackStatus,
      };
}
