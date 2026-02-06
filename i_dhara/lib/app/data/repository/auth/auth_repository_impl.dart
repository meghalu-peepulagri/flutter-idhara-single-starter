import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/auth/login_model.dart';
import 'package:i_dhara/app/data/models/auth/logout_model.dart';
import 'package:i_dhara/app/data/models/auth/otp_model.dart';
import 'package:i_dhara/app/data/models/auth/register_model.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<PhoneResponse?> login(String phone, String signId) async {
    final body = {"phone": phone, "signature_id": signId};
    final response =
        await NetworkManager().post('/auth/signin-phone', data: body, {});
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422) {
      final res = PhoneResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  Future<UserLogoutResponse?> fetchlogout() async {
    final token = SharedPreference.getFcmToken();
    final body = {"fcm_token": token};
    final response = await NetworkManager()
        .post('/users/${SharedPreference.getUserId()}/log-out', data: body, {});
    try {
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 422) {
        final res = UserLogoutResponse.fromJson(response.data);
        return res;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<OtpResponse?> verifyOtp(String phone, String otp) async {
    final fcmtoken = SharedPreference.getFcmToken() ?? "";
    print("line 42 $fcmtoken");
    final body = {'phone': phone, 'otp': otp, 'fcm_token': fcmtoken};
    final response =
        await NetworkManager().post('/auth/verify-otp', data: body, {});
    if (response.statusCode == 200 || response.statusCode == 422) {
      final res = OtpResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<RegisterResponse?> register(String fullName, String? email,
      String phone, String signId, String? address) async {
    final queryparams = {"is_public": "true"};
    final body = {
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "address": address,
      "user_type": "USER",
      "signature_id": signId
    };
    final response =
        await NetworkManager().post('/auth/register', data: body, queryparams);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422) {
      final res = RegisterResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<PhoneResponse?> resendOtp(String phone, String sid) async {
    final body = {"phone": phone, "signature_id": sid};
    final response =
        await NetworkManager().post('/auth/signin-phone', data: body, {});
    if (response.statusCode == 200 || response.statusCode == 422) {
      final res = PhoneResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }
}
