import 'package:i_dhara/app/data/models/auth/login_model.dart';
import 'package:i_dhara/app/data/models/auth/otp_model.dart';

abstract class AuthRepository {
  Future<PhoneResponse?> login(String phone);
  Future<OtpResponse?> verifyOtp(String phone, String otp);
}