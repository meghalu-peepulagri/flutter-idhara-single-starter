import 'dart:convert';

PhoneResponse phoneResponseFromJson(String str) => PhoneResponse.fromJson(json.decode(str));

String phoneResponseToJson(PhoneResponse data) => json.encode(data.toJson());

class PhoneResponse {
    int? status;
    bool? success;
    String? message;
    dynamic data;
    Errors? errors;

    PhoneResponse({
        this.status,
        this.success,
        this.message,
        this.data,
        this.errors,
    });

    factory PhoneResponse.fromJson(Map<String, dynamic> json) => PhoneResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"],
        errors: json["errors"] == null ? null : Errors.fromJson(json["errors"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data,
        "errors": errors?.toJson(),
    };
}
class Errors {
    String? phone;
 
    Errors({
        this.phone,
    });
 
    factory Errors.fromJson(Map<String, dynamic> json) => Errors(
        phone: json["phone"],
    );
 
    Map<String, dynamic> toJson() => {
        "phone": phone,
    };
}