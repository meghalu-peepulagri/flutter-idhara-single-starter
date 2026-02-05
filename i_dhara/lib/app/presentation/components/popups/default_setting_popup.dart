import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
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
      final buttonVerticalPadding = isSmallScreen ? 10.0 : 12.0;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.075,
          vertical: screenHeight * 0.05,
        ),
        child: Container(
          width: dialogWidth,
          padding: EdgeInsets.all(dialogPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ❗ Icon
              SizedBox(
                height: iconContainerSize,
                width: iconContainerSize,
                // decoration: BoxDecoration(
                //   color: Colors.red.withValues(alpha: 0.1),
                //   shape: BoxShape.circle,
                // ),
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath,
                        width: iconSize,
                        height: iconSize,
                      )
                    : Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: iconSize,
                      ),
              ),

              SizedBox(height: iconToTitleSpacing),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: titleToMessageSpacing),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: messageFontSize,
                  color: const Color(0xFF364153),
                ),
              ),

              SizedBox(height: messageToButtonSpacing),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      showLoadingIndicator: true,
                      text: noText,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        color: Colors.white38,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Manrope',
                                  color: const Color(0XFF828282),
                                  fontWeight: FontWeight.w500,
                                ),
                        elevation: 0.0,
                        borderSide: const BorderSide(color: Color(0x38000000)),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      // options: FFButtonOptions(
                      //   textStyle: const TextStyle(color: Colors.red),
                      //   padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                      //   color: Colors.red.withValues(alpha: 0.15),
                      //   elevation: 0,
                      //   borderRadius: BorderRadius.circular(8),
                      // )
                    ),
                  ),
                  SizedBox(width: buttonSpacing),
                  // YES Button
                  Expanded(
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF004E7E),
                            Color(0xFF3686AF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FFButtonWidget(
                        showLoadingIndicator: true,
                        text: yesText,
                        onPressed: onConfirm,
                        options: FFButtonOptions(
                          color: Colors.transparent,
                          elevation: 0,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}
