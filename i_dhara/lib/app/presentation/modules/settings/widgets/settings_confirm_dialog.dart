import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    barrierDismissible: false,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final dialogWidth = (screenWidth * 0.85).clamp(280.0, 400.0);
      final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
      final verticalPadding = screenHeight < 600 ? 16.0 : 20.0;

      bool isLoading = false;

      return StatefulBuilder(builder: (context, setStateDialog) {
        return WillPopScope(
          onWillPop: () async => !isLoading,
          child: AlertDialog(
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
              if (flcChanged)
                _flcCard(
                  oldFlc: originalFlc,
                  newFlc: currentFlc,
                ),
              if (flcChanged && (isVoltageRange || isCurrentRange))
                const SizedBox(height: 12),
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
              if (isVoltageRange && isCurrentRange) const SizedBox(height: 12),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: isLoading ? Colors.grey.shade400 : Colors.grey,
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
              onPressed: isLoading
                  ? null
                  : () async {
                      setStateDialog(() => isLoading = true);
                      try {
                        await onConfirm();
                      } finally {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
          ),
        );
      });
    },
  );
}

/// Compact single-line FLC card shown at the top of the confirm dialog.
Widget _flcCard({required String oldFlc, required String newFlc}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        SvgPicture.asset(
          'assets/images/flc_icon.svg',
          width: 28,
          height: 28,
        ),
        const SizedBox(width: 10),
        const Text(
          'FLC',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$oldFlc A',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_right_alt,
                    size: 18, color: Colors.black45),
              ),
              Text(
                '$newFlc A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
