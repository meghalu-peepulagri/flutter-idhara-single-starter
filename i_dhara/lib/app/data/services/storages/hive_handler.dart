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

  // Test Run completed motors storage

  /// Add a motor ID to the list of completed test runs
  static Future<void> addCompletedTestRunMotor(int motorId) async {
    final List<dynamic> motors =
        _box.get(Hivekeys.completedTestRunMotors, defaultValue: <String>[]);
    final motorIdStr = motorId.toString();
    if (!motors.contains(motorIdStr)) {
      motors.add(motorIdStr);
      await _box.put(Hivekeys.completedTestRunMotors, motors);
    }
  }

  /// Get list of motor IDs that have completed test run
  static List<String> getCompletedTestRunMotors() {
    final List<dynamic> motors =
        _box.get(Hivekeys.completedTestRunMotors, defaultValue: <String>[]);
    return motors.cast<String>();
  }

  /// Check if a motor has completed test run
  static bool hasCompletedTestRun(int motorId) {
    final motors = getCompletedTestRunMotors();
    return motors.contains(motorId.toString());
  }

  /// Remove a motor from completed test runs
  static Future<void> removeCompletedTestRunMotor(int motorId) async {
    final List<dynamic> motors =
        _box.get(Hivekeys.completedTestRunMotors, defaultValue: <String>[]);
    motors.remove(motorId.toString());
    await _box.put(Hivekeys.completedTestRunMotors, motors);
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
  static String completedTestRunMotors = 'completed_test_run_motors';
}
