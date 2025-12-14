import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';

class AppText extends StatelessWidget {
  final String text;
  final String? fontFamily;
  final TextAlign? textAlign;
  FontWeight? fontWeight = FontWeight.w500;
  double? fontSize = 14;
  Color? color = Colors.black;

  AppText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.color,
    this.fontFamily,
  });
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            useGoogleFonts: GoogleFonts.asMap()
                .containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
            lineHeight: 1,
          ),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}
