import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom snackbar that summarises a multi-schedule publish:
/// - all acked → green "All schedules acknowledged"
/// - none acked → red "No response from device"
/// - partial   → orange "Partial acknowledgment — N succeeded, M failed"
void showScheduleResultSnackBar({
  required int total,
  required int successCount,
  required int failedCount,
}) {
  if (total <= 0) return;

  final allSuccess = failedCount == 0 && successCount > 0;
  final allFailed = successCount == 0 && failedCount > 0;

  final String title;
  final String message;
  final Color bgColor;
  final IconData icon;

  if (allSuccess) {
    title = 'All schedules acknowledged';
    message = '$successCount of $total schedules succeeded';
    bgColor = const Color(0xFF1AAA55);
    icon = Icons.check_circle_rounded;
  } else if (allFailed) {
    title = 'No response from device';
    message = '$failedCount of $total schedules failed';
    bgColor = const Color(0xFFDB3B2A);
    icon = Icons.error_rounded;
  } else {
    title = 'Partial acknowledgment';
    message = '$successCount succeeded, $failedCount failed';
    bgColor = const Color(0xFFEF9F27);
    icon = Icons.info_rounded;
  }

  Get.snackbar(
    '',
    '',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: bgColor,
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    borderRadius: 8,
    duration: const Duration(seconds: 3),
    icon: Icon(icon, color: Colors.white, size: 22),
    titleText: Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    messageText: Text(
      message,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
    ),
  );
}
