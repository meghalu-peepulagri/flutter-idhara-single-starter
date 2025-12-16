import 'dart:convert';

DeleteStarterResponse deletePondResponseFromJson(String str) =>
    DeleteStarterResponse.fromJson(json.decode(str));

String deletePondResponseToJson(DeleteStarterResponse data) =>
    json.encode(data.toJson());

class DeleteStarterResponse {
  final bool success;
  final String message;
  final int status;

  DeleteStarterResponse({
    required this.success,
    required this.message,
    required this.status,
  });

  factory DeleteStarterResponse.fromJson(Map<String, dynamic> json) =>
      DeleteStarterResponse(
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
