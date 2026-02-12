import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

Future<bool?> showDeviceSettingConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String yesText = "Confirm",
  String noText = "Cancel",
  required Function()? onConfirm,
  String? svgPath,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final screenSize = MediaQuery.of(context).size;
      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;

      // Responsive values based on screen size
      final isSmallScreen = screenWidth < 360;
      final isMediumScreen = screenWidth >= 360 && screenWidth < 400;

      // Dialog width: 85% of screen width, max 320, min 260
      final dialogWidth = (screenWidth * 0.85).clamp(260.0, 320.0);

      // Responsive padding
      final dialogPadding =
          isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);

      // Responsive icon size
      final iconContainerSize =
          isSmallScreen ? 40.0 : (isMediumScreen ? 45.0 : 50.0);
      final iconSize = isSmallScreen ? 24.0 : (isMediumScreen ? 27.0 : 30.0);

      // Responsive font sizes
      final titleFontSize =
          isSmallScreen ? 16.0 : (isMediumScreen ? 17.0 : 18.0);
      final messageFontSize =
          isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 14.0);

      // Responsive spacing
      final iconToTitleSpacing =
          isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
      final titleToMessageSpacing = isSmallScreen ? 6.0 : 8.0;
      final messageToButtonSpacing =
          isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);
      final buttonSpacing = isSmallScreen ? 8.0 : 10.0;

      // Responsive button height
      final buttonHeight =
          isSmallScreen ? 36.0 : (isMediumScreen ? 38.0 : 40.0);

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.075,
          vertical: screenHeight * 0.05,
        ),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: Container(
          width: dialogWidth,
          padding: EdgeInsets.all(dialogPadding + 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Icon with background
              SizedBox(
                height: iconContainerSize + 14,
                width: iconContainerSize + 14,
                child: Center(
                  child: svgPath != null
                      ? SvgPicture.asset(
                          svgPath,
                          width: 100,
                          height: 100,
                        )
                      : const Icon(
                          Icons.settings_backup_restore_rounded,
                          color: Colors.black,
                          size: 50,
                        ),
                ),
              ),

              SizedBox(height: iconToTitleSpacing + 4),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),

              SizedBox(height: titleToMessageSpacing + 2),

              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: messageFontSize,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ),

              SizedBox(height: messageToButtonSpacing + 4),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight + 4,
                      child: FFButtonWidget(
                        showLoadingIndicator: true,
                        text: noText,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        options: FFButtonOptions(
                          height: buttonHeight + 4,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          color: const Color(0xFFF5F5F5),
                          textStyle: GoogleFonts.dmSans(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          elevation: 0.0,
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: buttonSpacing + 2),
                  // Confirm Button
                  Expanded(
                    child: Container(
                      height: buttonHeight + 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF004E7E),
                            Color(0xFF3686AF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF004E7E).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: FFButtonWidget(
                        showLoadingIndicator: true,
                        text: yesText,
                        onPressed: onConfirm,
                        options: FFButtonOptions(
                          color: Colors.transparent,
                          textStyle: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          elevation: 0,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );
}
