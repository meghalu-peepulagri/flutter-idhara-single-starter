import 'package:hive_flutter/hive_flutter.dart';

const String fcmtoken = "fcmtoken";

class HiveHandler {
  static final fcmToken = Hive.box(fcmtoken);
  static createfcmToken(String token) {
    fcmToken.add(token);
  }
  static String getFcmToken() {
    return fcmToken.get(fcmToken);
  }

  static deleteFcmToken() {
    return fcmToken.delete(fcmtoken);
  }
}
