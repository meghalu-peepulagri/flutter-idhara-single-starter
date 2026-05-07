import 'package:flutter/material.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

import 'dialogs/auto_mode_off_warning_dialog.dart' as auto_off;
import 'dialogs/fault_clear_dialog.dart' as fault;
import 'dialogs/mode_change_dialog.dart' as mode;
import 'dialogs/switch_command_dialog.dart' as sw;
import 'dialogs/test_run_confirm_dialog.dart' as testrun_confirm;
import 'dialogs/test_run_dialog.dart' as testrun;

/// Thin facade kept for backward-compatibility with existing call sites
/// (`MotorCardDialogs.showXxxDialog(...)`). Each method delegates to a
/// dedicated file under `dialogs/`. Behaviour is unchanged.
class MotorCardDialogs {
  static void showSwitchCommandDialog(
    BuildContext context,
    Motor motor,
    bool newValue,
    Function(bool) onConfirm,
  ) =>
      sw.showSwitchCommandDialog(context, motor, newValue, onConfirm);

  static Future<void> showModeChangeDialog(
    BuildContext context,
    String motorName,
    int newModeIndex,
    Function(int) onConfirm,
  ) =>
      mode.showModeChangeDialog(context, motorName, newModeIndex, onConfirm);

  static void showFaultClearDialog(
    BuildContext context,
    Motor motor,
    VoidCallback onConfirm,
  ) =>
      fault.showFaultClearDialog(context, motor, onConfirm);

  static void showAutoModeOffWarningDialog(
    BuildContext context,
    Motor motor, {
    required VoidCallback onOffAnyway,
    required VoidCallback onModeChange,
  }) =>
      auto_off.showAutoModeOffWarningDialog(
        context,
        motor,
        onOffAnyway: onOffAnyway,
        onModeChange: onModeChange,
      );

  static void showTestRunDialog(
    BuildContext context,
    Motor motor,
    VoidCallback onConfirm,
  ) =>
      testrun.showTestRunDialog(context, motor, onConfirm);

  static void showTestRunConfirmDialog(
    BuildContext context,
    Motor motor,
    Function(int timeoutMinutes) onConfirm,
  ) =>
      testrun_confirm.showTestRunConfirmDialog(context, motor, onConfirm);
}
