import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MotorLogsTab extends StatelessWidget {
  const MotorLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Logs Available',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
