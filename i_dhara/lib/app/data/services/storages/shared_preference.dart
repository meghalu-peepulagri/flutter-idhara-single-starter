import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  static late SharedPreferences preferences;

  static Future<SharedPreferences> init() async {
    preferences = await SharedPreferences.getInstance();
    return preferences;
  }

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
