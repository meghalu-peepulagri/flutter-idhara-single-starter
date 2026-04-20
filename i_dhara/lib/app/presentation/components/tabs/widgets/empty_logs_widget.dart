import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyLogsWidget extends StatelessWidget {
  final String message;

  const EmptyLogsWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: const Color(0xFF6B7280).withOpacity(0.5),
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
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF6B7280),
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
