import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class SettingsAppBar extends StatelessWidget {
  /// Called when the user taps the info icon.
  /// The parent decides what to show based on the active tab.
  final VoidCallback? onInfoTap;

  const SettingsAppBar({super.key, this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Center(
                  child: Text(
                    'Settings',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: const Color(0xFF004E7E),
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button — returns to the page that opened settings
                  InkWell(
                    onTap: () {
                      final args = Get.arguments;
                      final from = args is Map ? args['from'] as String? : null;
                      Get.offAllNamed(from ?? Routes.settingsDevices);
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF004E7E),
                      size: 20.0,
                    ),
                  ),
                  // Info button — only shown when onInfoTap is provided
                  if (onInfoTap != null)
                    InkWell(
                      onTap: onInfoTap,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF004E7E),
                          size: 22.0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
