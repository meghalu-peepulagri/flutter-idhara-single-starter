import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  static late SharedPreferences preferences;

  static String accestoken = 'accesstoken';




   static Future<SharedPreferences> init() async {
    preferences = await SharedPreferences.getInstance();
    return preferences;
  }


  ///Method that saves the [accestoken].
  static Future<bool> setAccessToken(String value) async =>
      preferences.setString(accestoken, value);

  ///Method that returns the [accestoken].
  static String getAccessToken() => preferences.getString(accestoken) ?? '';
}