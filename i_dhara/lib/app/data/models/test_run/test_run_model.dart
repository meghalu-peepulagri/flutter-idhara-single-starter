// To parse this JSON data, do
//
//     final testRunResponse = testRunResponseFromJson(jsonString);

import 'dart:convert';

TestRunResponse testRunResponseFromJson(String str) =>
    TestRunResponse.fromJson(json.decode(str));

String testRunResponseToJson(TestRunResponse data) =>
    json.encode(data.toJson());

class TestRunResponse {
  int? status;
  bool? success;
  String? message;
  dynamic data;

  TestRunResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory TestRunResponse.fromJson(Map<String, dynamic> json) =>
      TestRunResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data,
      };
}
