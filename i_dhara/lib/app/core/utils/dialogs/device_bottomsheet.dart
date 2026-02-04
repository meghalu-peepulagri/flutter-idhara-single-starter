import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';

class DeviceOptionsBottomSheet extends StatefulWidget {
  final bool hasMotor;
  final bool hasLocation;
  final VoidCallback onRename;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final VoidCallback onTestRun;

  const DeviceOptionsBottomSheet({
    super.key,
    required this.hasMotor,
    required this.hasLocation,
    required this.onRename,
    required this.onReplace,
    required this.onDelete,
    required this.onTestRun,
  });

  @override
  State<DeviceOptionsBottomSheet> createState() =>
      _DeviceOptionsBottomSheetState();
}

class _DeviceOptionsBottomSheetState extends State<DeviceOptionsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Device Management',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0XFF1A1A1A),
                  ),
                ),
                InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Get.back();
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9E9E9),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 24.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMenuItem(
              svgAsset: 'assets/images/test_run.svg',
              text: 'Test Run',
              iconColor: const Color(0xFF4A4A6A),
              onTap: widget.onTestRun),
          _buildMenuItem(
            svgAsset: 'assets/images/edit.svg',
            text: 'Rename',
            enabled: widget.hasMotor,
            iconColor: Colors.black,
            onTap: widget.onRename,
          ),
          _buildMenuItem(
            svgAsset: 'assets/images/kdkr.svg',
            text: 'Replace',
            enabled: widget.hasLocation,
            iconColor: Colors.green,
            onTap: widget.onReplace,
          ),
          _buildMenuItem(
            svgAsset: 'assets/images/delete.svg',
            text: 'Delete',
            color: Colors.red,
            iconColor: Colors.red,
            onTap: widget.onDelete,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String svgAsset,
    required String text,
    required VoidCallback onTap,
    bool enabled = true,
    Color iconColor = Colors.black,
    Color color = Colors.black,
  }) {
    final effectiveIconColor = enabled ? iconColor : Colors.grey.shade400;
    final effectiveColor = enabled ? color : Colors.grey.shade400;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F9),
                    border: Border.all(
                      color: const Color(0xFFEAEAEF),
                    )),
                child: Center(
                  child: SvgPicture.asset(
                    svgAsset,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      effectiveIconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                )),
            const SizedBox(width: 16),
            Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
