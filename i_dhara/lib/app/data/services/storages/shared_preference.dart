import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  static late SharedPreferences preferences;

  static String accestoken = 'accesstoken';

  static String phone = 'phone';
  static String userId = 'userId';
  static String peepulagri = 'PEEPUL_AGRI_01';
  static String motorname = 'motorname';
  static String locationid = 'locationid';
  static String motorid = 'motorid';
  static String starterid = 'starterid';
  static String locationName = 'locationName';
  static String devicesettings = 'devicesettings';

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

  ///Method that saves the [motorname].
  static Future<bool> setMotorName(String value) async =>
      preferences.setString(motorname, value);

  ///Method that returns the [motorname].
  static String getMotorName() => preferences.getString(motorname) ?? '';

  ///Method that saves the [location name ].
  static Future<bool> setLocationName(String value) async =>
      preferences.setString(locationName, value);

  ///Method that returns the [locationName].
  static String getLocationName() => preferences.getString(locationName) ?? '';

  ///Method that saves the [locationid].
  static Future<bool> setLocationId(String value) async =>
      preferences.setString(locationid, value);

  ///Method that returns the [locationid].
  static String getLocationId() => preferences.getString(locationid) ?? '';

  ///Method that saves the [motorid].
  static Future<bool> setMotorId(int value) async =>
      preferences.setInt(motorid, value);

  ///Method that returns the [motorid].
  static int getMotorId() => preferences.getInt(motorid) ?? 0;

  ///Method that saves the [devicesettings].
  static Future<bool> setdeviceSettings(int value) async =>
      preferences.setInt(devicesettings, value);

  ///Method that returns the [devicesettings].
  static int getdeviceSettings() => preferences.getInt(devicesettings) ?? 0;

  ///Method that saves the [deviceId].
  static Future<bool> setStarterId(int value) async =>
      preferences.setInt(starterid, value);

  ///Method that returns the [deviceId].
  static int getStarterId() => preferences.getInt(starterid) ?? 0;

  static Future<bool> setUserId(int? value) async =>
      preferences.setInt(userId, value!);

  static int? getUserId() => preferences.getInt(userId);

  static Future<void> clear() async => await preferences.clear();

  // Test Run completed motors storage
  static const String _completedTestRunMotors = 'completed_test_run_motors';

  /// Add a motor ID to the list of completed test runs
  static Future<bool> addCompletedTestRunMotor(int motorId) async {
    final List<String> motors = getCompletedTestRunMotors();
    final motorIdStr = motorId.toString();
    if (!motors.contains(motorIdStr)) {
      motors.add(motorIdStr);
      return preferences.setStringList(_completedTestRunMotors, motors);
    }
    return true;
  }

  /// Get list of motor IDs that have completed test run
  static List<String> getCompletedTestRunMotors() {
    return preferences.getStringList(_completedTestRunMotors) ?? [];
  }

  /// Check if a motor has completed test run
  static bool hasCompletedTestRun(int motorId) {
    final motors = getCompletedTestRunMotors();
    return motors.contains(motorId.toString());
  }

  /// Remove a motor from completed test runs (if needed)
  static Future<bool> removeCompletedTestRunMotor(int motorId) async {
    final List<String> motors = getCompletedTestRunMotors();
    motors.remove(motorId.toString());
    return preferences.setStringList(_completedTestRunMotors, motors);
  }
}
