import 'package:i_dhara/app/data/models/auth/login_model.dart';
import 'package:i_dhara/app/data/models/auth/otp_model.dart';
import 'package:i_dhara/app/data/models/auth/register_model.dart';

abstract class AuthRepository {
  Future<PhoneResponse?> login(String phone);
  Future<OtpResponse?> verifyOtp(String phone, String otp);
  Future<RegisterResponse?> register(
      String fullName, String email, String phone);
}
