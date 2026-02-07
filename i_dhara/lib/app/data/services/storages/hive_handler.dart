import 'package:hive_flutter/hive_flutter.dart';

class HiveHandler {
  static const String _boxname = 'appbox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxname);
  }

  static Box get _box => Hive.box(_boxname);
  //save value
  static Future<void> setValue(String key, value) async {
    await _box.put(key, value);
  }

  //read value

  static T getValue<T>(String key, T? defaultvalue) {
    return _box.get(key, defaultValue: defaultvalue);
  }

  //delete value

  static Future<void> delete(String key) async {
    await _box.delete(key);
  }

  //clear hive
  static Future<void> clearHive() async {
    await _box.clear();
  }
}

class Hivekeys {
  static const String accessToken = 'accessToken';
  static const String fcmToken = 'fcmToken';
  static String userPhone = 'phone';
  static String userId = 'userId';
  static String motorName = 'motorname';
  static String motorId = 'motorid';
  static String locationName = 'locationName';
  static String locationId = 'locationid';
  static String starterId = 'starterid';
  static String testrunStatus = 'testrunStatus';
}
