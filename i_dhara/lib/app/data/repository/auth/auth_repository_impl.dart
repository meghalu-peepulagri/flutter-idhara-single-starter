

import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/models/auth/login_model.dart';
import 'package:i_dhara/app/data/models/auth/otp_model.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
 @override
  Future<PhoneResponse?> login(String phone) async {
    final body = {"phone": phone};
    final response =
        await NetworkManager().post('/auth/signin-phone', data: body, {});
    if (response.statusCode == 200 || response.statusCode == 422) {
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
    final response = await NetworkManager()
        .post('/auth/verify-otp', data: body, {});
    if (response.statusCode == 200 || response.statusCode == 422) {
      final res = OtpResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }
}