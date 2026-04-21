import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/components/popups/setting_update.dart';

Future<void> showSettingsConfirmDialog(
  BuildContext context, {
  required bool isVoltageRange,
  required bool isCurrentRange,
  required bool flcChanged,
  required bool vmin,
  required bool vmax,
  required bool cmin,
  required bool cmax,
  required String? originalVoltageLow,
  required String currentLvf,
  required String? originalVoltageHigh,
  required String currentHvf,
  required String? originalCurrentLow,
  required String currentDrf,
  required String? originalCurrentHigh,
  required String currentOlf,
  required String originalFlc,
  required String currentFlc,
  required Future<void> Function() onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final dialogWidth = (screenWidth * 0.85).clamp(280.0, 400.0);
      final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
      final verticalPadding = screenHeight < 600 ? 16.0 : 20.0;

      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: (screenWidth - dialogWidth) / 2,
          vertical: 24.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          0,
        ),
        actionsPadding: EdgeInsets.all(horizontalPadding),
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm Setting Updates',
                style: GoogleFonts.dmSans(
                  fontSize: screenWidth < 360 ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004E7E),
                ),
              ),
              SizedBox(height: verticalPadding),
              if (isVoltageRange)
                infoCard(
                  bgColor: const Color(0xFFEAF3FF),
                  iconBg: const Color(0xFF3B82F6),
                  svg: 'assets/images/Voltage.svg',
                  title: "Voltage Fault",
                  lowOld: '${originalVoltageLow ?? currentLvf} V',
                  lowNew: '$currentLvf V',
                  highOld: '${originalVoltageHigh ?? currentHvf} V',
                  highNew: '$currentHvf V',
                  valueColor: const Color(0xFF2563EB),
                  vmin: vmin,
                  vmax: vmax,
                  cmin: false,
                  cmax: false,
                  lowLabel: 'Low Volts:',
                  highLabel: 'High Volts:',
                ),
              const SizedBox(height: 12),
              if (isCurrentRange)
                infoCard(
                  bgColor: const Color(0xFFFFF3E8),
                  iconBg: const Color(0xFFFF7A00),
                  svg: 'assets/images/Current.svg',
                  title: "Current Fault",
                  lowOld: originalCurrentLow ?? currentDrf,
                  lowNew: currentDrf,
                  highOld: originalCurrentHigh ?? currentOlf,
                  highNew: currentOlf,
                  valueColor: const Color(0xFFF97316),
                  vmin: false,
                  vmax: false,
                  cmin: cmin,
                  cmax: cmax,
                  lowLabel: 'Dry Run:',
                  highLabel: 'Overload:',
                ),
              const SizedBox(height: 12),
              if (flcChanged && !isCurrentRange && !isVoltageRange)
                infoCard(
                  widthofSvg: 32,
                  heightofSvg: 32,
                  bgColor: const Color(0xFFEAF3FF),
                  iconBg: Colors.transparent,
                  svg: 'assets/images/flc_icon.svg',
                  title: 'FLC',
                  lowOld: '$originalFlc A',
                  lowNew: '$currentFlc A',
                  highOld: '',
                  highNew: '',
                  valueColor: const Color(0xFF2563EB),
                  vmin: true,
                  vmax: false,
                  cmin: false,
                  cmax: false,
                ),
            ],
          ),
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
            width: dialogWidth * 0.35,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
