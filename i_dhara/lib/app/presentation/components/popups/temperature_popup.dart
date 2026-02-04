import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';

class TemperaturePopup extends StatelessWidget {
  final dynamic Function() onSaved;
  final String oldVal;
  final String newVal;
  const TemperaturePopup(
      {super.key,
      required this.onSaved,
      required this.oldVal,
      required this.newVal});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(vertical: 24),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: Color(0xFFDBDBDB),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 24,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 12,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFEF3C6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15339142),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(),
                        child: const Stack(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 340,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: ' ',
                          style: TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 20,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'U',
                          style: TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 20,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'pdate safety values ?',
                          style: TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 20,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        const SizedBox(
                          width: 340,
                          child: Text(
                            'Changing the maximum temperature threshold will affect how the system automatically protects the motor. If the temperature exceeds this value, the pump will stop to prevent overheating.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF354152),
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.63,
                            ),
                          ),
                        ),
                        Container(
                          width: 340,
                          padding: const EdgeInsets.all(12),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFF7ED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 71,
                                  children: [
                                    const Text(
                                      'Max Threshold',
                                      style: TextStyle(
                                        color: Color(0xFFF97316),
                                        fontSize: 14,
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w400,
                                        height: 1,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      spacing: 5,
                                      children: [
                                        Text(
                                          '$oldVal°c',
                                          style: const TextStyle(
                                            color: Color(0xFF90A1B8),
                                            fontSize: 14,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w400,
                                            height: 1,
                                          ),
                                        ),
                                        const Text(
                                          '→',
                                          style: TextStyle(
                                            color: Color(0xFFCAD5E2),
                                            fontSize: 14,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w400,
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          '$newVal°c',
                                          style: const TextStyle(
                                            color: Color(0xFF314157),
                                            fontSize: 14,
                                            fontFamily: 'DM Sans',
                                            fontWeight: FontWeight.w500,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 340,
                          child: Text(
                            'This change applies immediately while the pump is running.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF90A1B8),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 337,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 24,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 8),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF828282),
                                fontSize: 16,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FFButtonWidget(
                      showLoadingIndicator: true,
                      onPressed: () {
                        Navigator.pop(context);
                        onSaved();
                      },
                      text: 'Save',
                      options: FFButtonOptions(
                        height: 40,
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                        iconPadding:
                            const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        color: const Color(0xFF004E7E),
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.duruSans(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
