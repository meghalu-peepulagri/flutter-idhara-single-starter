import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class SettingsDeviceCard extends StatelessWidget {
  final Devices device;

  const SettingsDeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final motor =
        device.motors?.isNotEmpty == true ? device.motors!.first : null;
    final alias = motor?.aliasName;
    final pumpName = (alias != null && alias.trim().isNotEmpty)
        ? alias.replaceAll(RegExp(r'\s+'), ' ').trim()
        : (motor?.name ?? 'No Motor').replaceAll(RegExp(r'\s+'), ' ').trim();
    final serialNumber = device.starterNumber ?? 'N/A';

    return GestureDetector(
      onTap: () {
        SharedPreference.setStarterId(device.id ?? 0);
        Get.offNamed(Routes.usersettings,
            arguments: {'from': Routes.settingsDevices});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pump name & serial number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pumpName,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'S/N: ',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '#$serialNumber',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
