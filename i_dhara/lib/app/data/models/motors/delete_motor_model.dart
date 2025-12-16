import 'dart:convert';

DeleteMotorResponse deletePondResponseFromJson(String str) =>
    DeleteMotorResponse.fromJson(json.decode(str));

String deletePondResponseToJson(DeleteMotorResponse data) =>
    json.encode(data.toJson());

class DeleteMotorResponse {
  final bool success;
  final String message;
  final int status;

  DeleteMotorResponse({
    required this.success,
    required this.message,
    required this.status,
  });

  factory DeleteMotorResponse.fromJson(Map<String, dynamic> json) =>
      DeleteMotorResponse(
        success: json["success"] ?? false,
        message: json["message"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "status": status,
      };
}
