import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  static late SharedPreferences preferences;

  static String accestoken = 'accesstoken';

  static String phone = 'phone';
  static String userId = 'userId';
  static String peepulagri = 'PEEPUL_AGRI_01';

  static Future<SharedPreferences> init() async {
    preferences = await SharedPreferences.getInstance();
    return preferences;
  }

  ///Method that saves the [accestoken].
  static Future<bool> setAccessToken(String value) async =>
      preferences.setString(accestoken, value);

  ///Method that returns the [accestoken].
  static String getAccessToken() => preferences.getString(accestoken) ?? '';

  ///Method that saves the [phone].
  static Future<bool> setPhone(String value) async =>
      preferences.setString(phone, value);

  ///Method that returns the [phone].
  static String getPhone() => preferences.getString(phone) ?? '';

  ///Method that saves the [peepulagri].
  static Future<bool> setpeepulagri(String value) async =>
      preferences.setString(peepulagri, value);

  ///Method that returns the [gatewaytitle].
  static String getpeepulagri() => preferences.getString(peepulagri) ?? '';

  static Future<bool> setUserId(int? value) async =>
      preferences.setInt(userId, value!);

  static int? getUserId() => preferences.getInt(userId);
}
