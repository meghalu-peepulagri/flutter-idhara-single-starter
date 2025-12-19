import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

class SettingsButtonCard extends StatelessWidget {
  const SettingsButtonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        FFButtonWidget(
          onPressed: () {
            print('Button pressed ...');
          },
          text: 'Edit Profile',
          icon: const FaIcon(
            FontAwesomeIcons.edit,
            size: 18,
          ),
          options: FFButtonOptions(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
            color: Colors.white,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
                  color: const Color(0xFF364153),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                ),
            elevation: 0,
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        FFButtonWidget(
          onPressed: () {
            print('Button pressed ...');
          },
          text: 'App Setting',
          icon: const Icon(
            Icons.settings_outlined,
            size: 18,
          ),
          options: FFButtonOptions(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
            color: Colors.white,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
                  color: const Color(0xFF364153),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                ),
            elevation: 0,
            borderSide: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ].divide(const SizedBox(height: 8)),
    );
  }
}
