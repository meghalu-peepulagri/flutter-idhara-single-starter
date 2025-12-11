import 'dart:convert';

OtpResponse otpResponseFromJson(String str) => OtpResponse.fromJson(json.decode(str));

String otpResponseToJson(OtpResponse data) => json.encode(data.toJson());

class OtpResponse {
    int? status;
    bool? success;
    String? message;
    Data? data;
    Errors? errors;
    OtpResponse({
        this.status,
        this.success,
        this.message,
        this.data,
        this.errors,
    });

    factory OtpResponse.fromJson(Map<String, dynamic> json) => OtpResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        errors: json["errors"] == null ? null : Errors.fromJson(json["errors"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
        "errors": errors?.toJson(),
    };
}

class Data {
    UserDetails? userDetails;
    String? accessToken;
    String? refreshToken;

    Data({
        this.userDetails,
        this.accessToken,
        this.refreshToken,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        userDetails: json["user_details"] == null ? null : UserDetails.fromJson(json["user_details"]),
        accessToken: json["access_token"],
        refreshToken: json["refresh_token"],
    );

    Map<String, dynamic> toJson() => {
        "user_details": userDetails?.toJson(),
        "access_token": accessToken,
        "refresh_token": refreshToken,
    };
}

class UserDetails {
    int? id;
    String? fullName;
    String? email;
    String? phone;
    String? userType;
    String? address;
    String? status;
    dynamic createdBy;
    bool? userVerified;
    DateTime? createdAt;
    DateTime? updatedAt;

    UserDetails({
        this.id,
        this.fullName,
        this.email,
        this.phone,
        this.userType,
        this.address,
        this.status,
        this.createdBy,
        this.userVerified,
        this.createdAt,
        this.updatedAt,
    });

    factory UserDetails.fromJson(Map<String, dynamic> json) => UserDetails(
        id: json["id"],
        fullName: json["full_name"],
        email: json["email"],
        phone: json["phone"],
        userType: json["user_type"],
        address: json["address"],
        status: json["status"],
        createdBy: json["created_by"],
        userVerified: json["user_verified"],
        createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
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
        "user_verified": userVerified,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
    };
}

class Errors {
  String? phone;
  String? otp;
  Errors({
    this.phone,
    this.otp,
  });
  factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        phone: json["phone"],
        otp: json["otp"],
      );
  Map<String, dynamic> toJson() => {
        "phone": phone,
        "otp": otp,
      };
}