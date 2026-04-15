import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MotorModeInfoSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF004E7E), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'How Motor Modes Work',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
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
                ],
              ),
              const SizedBox(height: 20),
              // Auto Mode
              _buildModeInfoCard(
                icon: Icons.autorenew_rounded,
                iconColor: const Color(0xFFFFA500),
                bgColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFE082),
                title: 'AUTO MODE',
                titleColor: const Color(0xFFFFA500),
                bullets: [
                  'Auto ON/OFF with power.',
                  'Power present → Motor ON',
                  'Power lost → Motor OFF',
                  'After a power cycle, it resumes Auto behavior.',
                ],
              ),
              const SizedBox(height: 12),
              // Manual Mode
              _buildModeInfoCard(
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFF2F80ED),
                bgColor: const Color(0xFFEBF3FE),
                borderColor: const Color(0xFFBBDEFB),
                title: 'MANUAL MODE',
                titleColor: const Color(0xFF2F80ED),
                bullets: [
                  'Full control via app or buttons.',
                  'Motor stays OFF until you turn it ON manually.',
                  'After a power cycle, it remains OFF (no automatic start).',
                ],
              ),
              // const SizedBox(height: 12),
              // Schedule Mode
              // _buildModeInfoCard(
              //   icon: Icons.schedule_rounded,
              //   iconColor: const Color(0xFF27AE60),
              //   bgColor: const Color(0xFFE8F5E9),
              //   borderColor: const Color(0xFFA5D6A7),
              //   title: 'SCHEDULE MODE',
              //   titleColor: const Color(0xFF27AE60),
              //   bullets: [
              //     'Motor follows your preset ON/OFF schedule.',
              //     'Set daily or weekly timings easily.',
              //   ],
              // ),
              // const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildModeInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required Color titleColor,
    required List<String> bullets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
