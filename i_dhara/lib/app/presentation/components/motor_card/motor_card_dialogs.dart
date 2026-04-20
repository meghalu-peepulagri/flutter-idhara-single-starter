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

  static Future<void> showModeChangeDialog(
    BuildContext context,
    String motorName,
    int newModeIndex,
    Function(int) onConfirm,
  ) {
    final modeName = newModeIndex == 1 ? 'Auto' : 'Manual';
    return showDialog(
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
                            _formatMotorName(motorName),
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
                            color: newModeIndex == 1
                                ? const Color(0xFFFFA500)
                                : const Color(0xFF2F80ED),
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
                onConfirm(newModeIndex);
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
