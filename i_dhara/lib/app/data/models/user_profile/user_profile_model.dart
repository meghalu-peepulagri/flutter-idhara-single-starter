// To parse this JSON data, do
//
//     final userProfileResponse = userProfileResponseFromJson(jsonString);

import 'dart:convert';

UserProfileResponse userProfileResponseFromJson(String str) =>
    UserProfileResponse.fromJson(json.decode(str));

String userProfileResponseToJson(UserProfileResponse data) =>
    json.encode(data.toJson());

class UserProfileResponse {
  int? status;
  bool? success;
  String? message;
  UserProfile? data;

  UserProfileResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) =>
      UserProfileResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : UserProfile.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class UserProfile {
  int? id;
  String? fullName;
  String? email;
  String? phone;
  String? userType;
  String? address;
  String? status;
  dynamic createdBy;
  dynamic referredBy;
  List<dynamic>? notificationsEnabled;
  bool? userVerified;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfile({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.userType,
    this.address,
    this.status,
    this.createdBy,
    this.referredBy,
    this.notificationsEnabled,
    this.userVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json["id"],
        fullName: json["full_name"],
        email: json["email"],
        phone: json["phone"],
        userType: json["user_type"],
        address: json["address"],
        status: json["status"],
        createdBy: json["created_by"],
        referredBy: json["referred_by"],
        notificationsEnabled: json["notifications_enabled"] == null
            ? []
            : List<dynamic>.from(json["notifications_enabled"]!.map((x) => x)),
        userVerified: json["user_verified"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "user_type": userType,
        "address": address,
        "status": status,
        "created_by": createdBy,
        "referred_by": referredBy,
        "notifications_enabled": notificationsEnabled == null
            ? []
            : List<dynamic>.from(notificationsEnabled!.map((x) => x)),
        "user_verified": userVerified,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
