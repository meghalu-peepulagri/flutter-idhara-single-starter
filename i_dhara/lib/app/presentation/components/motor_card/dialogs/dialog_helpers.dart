import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

/// Truncates a name to 16 chars with ellipsis and collapses whitespace.
String formatMotorName(String? name) {
  if (name == null || name.isEmpty) return 'Unknown';
  final formatted = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (formatted.length > 16) {
    return '${formatted.substring(0, 16)}...';
  }
  return formatted;
}

/// Formats a motor's alias (preferred) or name with capitalisation + 16-char cap.
String formatMotorNameShort(Motor motor) {
  final aliasName = motor.aliasName?.trim();
  final motorName = motor.name?.trim();
  String? name;
  if (aliasName != null && aliasName.isNotEmpty) {
    name = aliasName;
  } else {
    name = motorName;
  }
  if (name == null || name.isEmpty) return 'Unknown';
  final formatted = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (formatted.length > 16) {
    return '${formatted.substring(0, 16)}...';
  }
  return formatted.capitalizeFirst ?? formatted;
}

/// Returns the display name preferring aliasName over motor.name; capitalises +
/// truncates via [formatMotorName].
String getMotorDisplayName(Motor motor) {
  final aliasName = motor.aliasName?.trim();
  final motorName = motor.name?.trim();
  if (aliasName != null && aliasName.isNotEmpty) {
    return formatMotorName(aliasName.capitalizeFirst);
  }
  return formatMotorName(motorName?.capitalizeFirst);
}
