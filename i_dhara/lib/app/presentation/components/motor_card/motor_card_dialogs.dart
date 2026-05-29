import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

class MotorCardDialogs {
  static String _formatMotorName(String? name) {
    if (name == null || name.isEmpty) return 'Unknown';
    final formatted = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (formatted.length > 16) {
      return '${formatted.substring(0, 16)}...';
    }
    return formatted;
  }

  static String _formatMotorNameShort(Motor motor) {
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

  static String _getMotorDisplayName(Motor motor) {
    final aliasName = motor.aliasName?.trim();
    final motorName = motor.name?.trim();
    if (aliasName != null && aliasName.isNotEmpty) {
      return _formatMotorName(aliasName.capitalizeFirst);
    }
    return _formatMotorName(motorName?.capitalizeFirst);
  }

  static void showSwitchCommandDialog(
    BuildContext context,
    Motor motor,
    bool newValue,
    Function(bool) onConfirm,
  ) {
    final stateName = newValue ? 'ON' : 'OFF';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to control the motor?',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Motor: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _getMotorDisplayName(motor),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'New State: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Text(
                          stateName,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: newValue
                                ? const Color(0xFF2F80ED) // ON
                                : const Color(0xFFDB3B2A), // OFF
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm(newValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// [isWaitingForModeAck] — when supplied, the dialog stays open after
  /// Confirm, swaps the body for an indeterminate spinner + "Waiting
  /// for Response..." caption, and (on success) transitions to a
  /// "Mode updated successfully" state for 2 seconds before auto-
  /// closing. When omitted (e.g. dashboard motor card, which uses a
  /// plain `bool` for its waiting state), the dialog behaves like
  /// before: pops immediately on Confirm and fires the callback in
  /// fire-and-forget style.
  ///
  /// [onCancelWhileWaiting] — invoked when the user taps Cancel
  /// during the wait. Caller should use this to stop the MQTT retry
  /// loop and flip [isWaitingForModeAck] back to false (the dialog
  /// pops itself afterwards). Ignored when [isWaitingForModeAck] is
  /// null.
  ///
  /// [currentModeIndex] — controller's current mode rx. Used purely
  /// to distinguish a real ACK from a timeout / device-error / cancel
  /// when the wait resolves: ACK keeps the controller's optimistic
  /// mode at `newModeIndex`, the failure paths revert it. The dialog
  /// only shows the "Mode updated successfully" state when this rx
  /// still reads `newModeIndex` after the wait flips. Omit to skip
  /// success-detection (dialog will simply close on flip, no green
  /// state).
  static Future<void> showModeChangeDialog(
    BuildContext context,
    String motorName,
    int newModeIndex,
    Function(int) onConfirm, {
    RxBool? isWaitingForModeAck,
    VoidCallback? onCancelWhileWaiting,
    Rx<int>? currentModeIndex,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ModeChangeDialog(
        motorName: motorName,
        newModeIndex: newModeIndex,
        onConfirm: onConfirm,
        isWaitingForModeAck: isWaitingForModeAck,
        onCancelWhileWaiting: onCancelWhileWaiting,
        currentModeIndex: currentModeIndex,
      ),
    );
  }

  /// Dialog shown when farmer tries to start a motor that is in fault state.
  /// Asks for confirmation to clear the fault before starting the motor.
  static void showFaultClearDialog(
    BuildContext context,
    Motor motor,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDB3B2A), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Motor Fault Detected',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This motor stopped due to a fault. Clear the fault to start it again.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDCA)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Motor: ',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDB3B2A),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getMotorDisplayName(motor),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB3B2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Clear Fault',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showAutoModeOffWarningDialog(
    BuildContext context,
    Motor motor, {
    required VoidCallback onOffAnyway,
    required VoidCallback onModeChange,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // ✅ Remove default title padding so we can use our custom header
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          title: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 48, 0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFFA500), size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motor is in Auto Mode',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ Cancel/Close icon in top-right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Motor: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Expanded(
                          child: Builder(
                            builder: (_) {
                              // First preference: alias name.
                              // Fallback: motor name when alias is null/empty.
                              final alias = motor.aliasName?.trim();
                              final hasAlias =
                                  alias != null && alias.isNotEmpty;
                              final displayName = hasAlias
                                  ? _formatMotorName(alias.capitalizeFirst)
                                  : _formatMotorName(motor.starter?.name
                                      ?.trim()
                                      .capitalizeFirst);
                              return Text(
                                displayName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Current Mode: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Text(
                          'Auto',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFA500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.power_settings_new,
                      color: Color(0xFFDB3B2A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Off anyway → ',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          TextSpan(
                            text:
                                'Motor turns OFF now. It will turn ON automatically after power cycle.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz,
                      color: Color(0xFF2F80ED), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mode change → ',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          TextSpan(
                            text:
                                'Switch to Manual Mode. It will stay OFF even after power cycle. You must turn it ON manually.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOffAnyway();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFDB3B2A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Off anyway',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFDB3B2A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onModeChange();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E7E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Mode change',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Dialog shown in dashboard to navigate to test run page
  static void showTestRunDialog(
    BuildContext context,
    Motor motor,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Test Run?',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will turn the motor ON for 5 seconds and then automatically turn it OFF.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Motor: ',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004E7E),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getMotorDisplayName(motor),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      'Start Test',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showTestRunConfirmDialog(
    BuildContext context,
    Motor motor,
    Function(int timeoutMinutes) onConfirm,
  ) {
    int selectedTimeout = 3;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 400 ? screenWidth * 0.9 : 340.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenWidth < 400 ? 16 : 40,
                vertical: 24,
              ),
              child: Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Test Run',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Motor: ',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF004E7E),
                                ),
                              ),
                              Text(
                                _formatMotorNameShort(motor),
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Time: ',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF004E7E),
                                ),
                              ),
                              // const Spacer(),
                              const SizedBox(width: 10),

                              _buildTimeChip(
                                context,
                                1,
                                selectedTimeout,
                                (value) =>
                                    setState(() => selectedTimeout = value),
                              ),
                              const SizedBox(width: 20),
                              _buildTimeChip(
                                context,
                                2,
                                selectedTimeout,
                                (value) =>
                                    setState(() => selectedTimeout = value),
                              ),
                              // const SizedBox(width: 6),
                              // _buildTimeChip(
                              //   context,
                              //   3,
                              //   selectedTimeout,
                              //   (value) =>
                              //       setState(() => selectedTimeout = value),
                              // ),
                              // const SizedBox(width: 6),
                              // _buildTimeChip(
                              //   context,
                              //   4,
                              //   selectedTimeout,
                              //   (value) =>
                              //       setState(() => selectedTimeout = value),
                              // ),
                              // const SizedBox(width: 6),
                              // _buildTimeChip(
                              //   context,
                              //   5,
                              //   selectedTimeout,
                              //   (value) =>
                              //       setState(() => selectedTimeout = value),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFDCDCDC)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onConfirm(selectedTimeout);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Confirm',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build time selection chip for test run dialog
  static Widget _buildTimeChip(
    BuildContext context,
    int minutes,
    int selectedMinutes,
    Function(int) onSelect,
  ) {
    final isSelected = minutes == selectedMinutes;
    return GestureDetector(
      onTap: () => onSelect(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFDCDCDC),
          ),
        ),
        child: Text(
          '${minutes}m',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

/// Stateful dialog body for [MotorCardDialogs.showModeChangeDialog].
/// Three phases:
///   • idle       — confirmation question + motor/new-mode card
///   • processing — indeterminate spinner + "Waiting for Response..."
///   • success    — green check + "Mode updated successfully"
///                  (auto-closes after 2s)
///
/// Cancel during processing still works the same — calls
/// [onCancelWhileWaiting] and pops without showing the success state.
class _ModeChangeDialog extends StatefulWidget {
  const _ModeChangeDialog({
    required this.motorName,
    required this.newModeIndex,
    required this.onConfirm,
    required this.isWaitingForModeAck,
    required this.onCancelWhileWaiting,
    required this.currentModeIndex,
  });

  final String motorName;
  final int newModeIndex;
  final Function(int) onConfirm;
  // Null = caller (e.g. dashboard motor card) doesn't expose a
  // reactive waiting flag, so fall back to the legacy pop-and-fire
  // behaviour. Non-null = stay open until the rx flips false.
  final RxBool? isWaitingForModeAck;
  // Invoked when the user taps Cancel during the wait. Caller is
  // expected to stop the MQTT retry loop AND flip
  // isWaitingForModeAck false; the dialog pops itself once the rx
  // flips. Null = no cancel hook; the Cancel button still works but
  // it only closes the dialog without stopping retries.
  final VoidCallback? onCancelWhileWaiting;
  // Controller's current mode rx. Read once the wait resolves to
  // distinguish a real ACK (mode == newModeIndex) from timeout /
  // device error / cancel (mode was reverted). Optional — when
  // null, the dialog just pops on flip without a success state.
  final Rx<int>? currentModeIndex;

  @override
  State<_ModeChangeDialog> createState() => _ModeChangeDialogState();
}

class _ModeChangeDialogState extends State<_ModeChangeDialog> {
  bool _isProcessing = false;
  // Briefly true between the ACK landing and the dialog auto-popping
  // 2 seconds later. Hides the buttons and renders the green
  // confirmation body in their place.
  bool _showSuccess = false;
  Worker? _ackWorker;
  Timer? _dotsTimer;
  // Counts down 2s before popping in the success phase. Stored on
  // the state so it can be cancelled if the widget tears down early.
  Timer? _autoCloseTimer;
  // Cycles '', '.', '..', '...' to animate the "Waiting for
  // Response" caption.
  String _dotPattern = '';

  @override
  void dispose() {
    _ackWorker?.dispose();
    _dotsTimer?.cancel();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _handleConfirm() {
    if (_isProcessing) return;

    // Legacy path: no rx provided → close the dialog immediately and
    // fire the callback in fire-and-forget style. Used by the
    // dashboard motor card, which owns its own waiting flag and
    // doesn't need the spinner-and-wait flow.
    final ackRx = widget.isWaitingForModeAck;
    if (ackRx == null) {
      Navigator.of(context).pop();
      widget.onConfirm(widget.newModeIndex);
      return;
    }

    setState(() {
      _isProcessing = true;
      _dotPattern = '';
    });

    // Dots animation — cycles '' → '.' → '..' → '...' → '' so the
    // user has a visible sign of life while the publish is in flight.
    _dotsTimer?.cancel();
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _dotPattern =
            _dotPattern.length >= 3 ? '' : '$_dotPattern.';
      });
    });

    // Subscribe BEFORE calling onConfirm so the very first
    // false→true→false sequence isn't missed in the rare fast-ack
    // case. The `waiting` callback skips the true edge and routes
    // the false edge into success-detection.
    _ackWorker = ever<bool>(ackRx, (waiting) {
      if (waiting || !mounted) return;
      _onAckResolved();
    });

    widget.onConfirm(widget.newModeIndex);

    // handleModeChange has early-return paths (mqtt not initialised,
    // motor id empty) that exit before flipping isWaitingForModeAck.
    // In those cases the worker above will never fire and the dialog
    // would stay stuck on the spinner. handleModeChange's pre-publish
    // block runs synchronously, so re-reading the rx right after the
    // call tells us whether the request actually started.
    if (!ackRx.value && _ackWorker != null && mounted) {
      _onAckResolved();
    }
  }

  // Wait has resolved (rx flipped false). Tear down the listeners
  // first so we own the next state change, then decide between
  // success-flash-then-close and immediate-close based on whether
  // the controller's mode actually matches what we asked for.
  void _onAckResolved() {
    _ackWorker?.dispose();
    _ackWorker = null;
    _dotsTimer?.cancel();
    _dotsTimer = null;

    if (!mounted) return;

    // ACK keeps the controller's optimistic localModeIndex at
    // `newModeIndex`. Timeout / device-error / cancel paths all
    // revert it. So a match here means the device confirmed the
    // change; a mismatch (or a null rx) means we should close
    // quietly instead of flashing a misleading success state.
    final modeRx = widget.currentModeIndex;
    final wasSuccess =
        modeRx != null && modeRx.value == widget.newModeIndex;

    if (!wasSuccess) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isProcessing = false;
      _showSuccess = true;
    });

    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // Cancel-while-waiting handler. Dispose the worker FIRST so the rx
  // flip from `onCancelWhileWaiting` (which the callback is expected
  // to perform inside the controller) doesn't trigger a duplicate
  // pop via our `ever()` listener — we own the pop here. Then ask
  // the controller to stop retries / revert state, and finally pop
  // ourselves.
  void _handleCancelWhileWaiting() {
    _ackWorker?.dispose();
    _ackWorker = null;
    _dotsTimer?.cancel();
    _dotsTimer = null;
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
    widget.onCancelWhileWaiting?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Mode index: 0 = Manual, 1 = Auto, 2 = Schedule.
    final modeName = widget.newModeIndex == 1
        ? 'Auto'
        : widget.newModeIndex == 2
            ? 'Schedule'
            : 'Manual';
    // Match the toggle's per-mode accent: orange (Auto), deep-blue
    // (Schedule), light-blue (Manual).
    final modeColor = widget.newModeIndex == 1
        ? const Color(0xFFFFA500)
        : widget.newModeIndex == 2
            ? const Color(0xFF004E7E)
            : const Color(0xFF2F80ED);

    final Widget body;
    if (_showSuccess) {
      body = _buildSuccessBody();
    } else if (_isProcessing) {
      body = _buildProcessingBody();
    } else {
      body = _buildIdleBody(modeName, modeColor);
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Fixed width across all phases so the dialog never grows or
      // shrinks horizontally. Vertical sizing follows the body's
      // natural height — the idle layout (question + motor/mode
      // card) used to pad out to a 150px minimum and that padding
      // showed up as empty space between the card and the Cancel /
      // Confirm row. Title slot is null across all three phases so
      // the outer chrome stays identical.
      content: SizedBox(
        width: 260,
        child: body,
      ),
      actions: _showSuccess
          ? null
          : _isProcessing
              ? [
                  // Cancel is rendered but disabled (`onPressed: null`),
                  // per request. The user can't dismiss mid-retry; the
                  // dialog only closes on ACK / timeout / device error.
                  // `_handleCancelWhileWaiting` is intentionally kept on
                  // the state class so it stays available if Cancel is
                  // re-enabled later.
                  TextButton(
                    onPressed: null,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                      ),
                    ),
                  ),
                ]
              : [
                  // Idle-phase Cancel is live — taps close the dialog
                  // before any publish happens. Only the processing-
                  // phase Cancel above is disabled.
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E7E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
    );
  }

  // ── Phase bodies ────────────────────────────────────────────────

  Widget _buildIdleBody(String modeName, Color modeColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Are you sure you want to change the motor mode?',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Motor: ",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      MotorCardDialogs._formatMotorName(widget.motorName),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "New Mode: ",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                  Text(
                    modeName,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: modeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Changing Mode',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 14),
        // Indeterminate spinner — no value/countdown, no attempt
        // breadcrumb. Spins until the ACK lands (or the controller's
        // own ACK timer fires + reverts).
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004E7E)),
          ),
        ),
        const SizedBox(height: 14),
        // "Waiting for Response" stays put; only the dots animate.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting for Response',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(
              width: 14,
              child: Text(
                _dotPattern,
                textAlign: TextAlign.start,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF22C55E),
            size: 32,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Mode updated successfully',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
