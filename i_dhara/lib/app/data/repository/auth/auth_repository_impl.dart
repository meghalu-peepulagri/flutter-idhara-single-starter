import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/auth/login_model.dart';
import 'package:i_dhara/app/data/models/auth/otp_model.dart';
import 'package:i_dhara/app/data/models/auth/register_model.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  @override
  Future<PhoneResponse?> login(String phone) async {
    final body = {"phone": phone};
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

  @override
  Future<OtpResponse?> verifyOtp(String phone, String otp) async {
    // final fcmtoken = await SharedPreferenceHelper.getFcmToken() ?? "";
    final body = {
      'phone': phone,
      'otp': otp,
      // 'fcm_token': fcmtoken
    };
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
  Future<RegisterResponse?> register(
      String fullName, String email, String phone) async {
    final queryparams = {"is_public": "true"};
    final body = {
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "user_type": "USER"
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
}
