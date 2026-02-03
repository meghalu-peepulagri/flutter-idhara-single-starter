import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';

void showThresholdBottomSheet(
    BuildContext context, dynamic Function(double value)? onSaved) {
  double value = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Maximum Threshold',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                /// Minus - Value - Plus
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _circleButton(
                      icon: Icons.remove,
                      onTap: () {
                        setState(() {
                          if (value > 0) value -= 0.5;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6D5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${value.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _circleButton(
                      icon: Icons.add,
                      onTap: () {
                        setState(() {
                          if (value < 150) value += 0.5;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Min - Max labels
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Min: 0'),
                    Text('Max: 150'),
                  ],
                ),

                /// Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFE1F0FF),
                    inactiveTrackColor:
                        const Color(0xFFE1F0FF).withOpacity(0.4),
                    thumbColor: Colors.white,
                    overlayColor: const Color(0xFFE1F0FF).withOpacity(0.2),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 150,
                    onChanged: (v) {
                      print("line 113 $v");
                      setState(() => value = v);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                /// Buttons
                Container(
                  padding: const EdgeInsets.only(
                    top: 12,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: const ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x1E000000),
                        blurRadius: 6,
                        offset: Offset(0, -1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 14),
                                        decoration: ShapeDecoration(
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              width: 1,
                                              color: Colors.black
                                                  .withValues(alpha: 0.10),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          spacing: 12,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              spacing: 4,
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration:
                                                      const BoxDecoration(),
                                                  child: const Stack(),
                                                ),
                                                const Text(
                                                  'Cancel',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontFamily: 'DM Sans',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1,
                                                    letterSpacing: -0.41,
                                                  ),
                                                ),
                                              ],
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
                                        onSaved!(value);
                                      },
                                      text: 'Save',
                                      options: FFButtonOptions(
                                        height: 40,
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(16, 0, 16, 0),
                                        iconPadding: const EdgeInsetsDirectional
                                            .fromSTEB(0, 0, 0, 0),
                                        color: const Color(0xFF004E7E),
                                        textStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.duruSans(
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                        elevation: 0,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    // child: Container(
                                    //   padding: const EdgeInsets.symmetric(
                                    //       horizontal: 24, vertical: 14),
                                    //   decoration: ShapeDecoration(
                                    //     gradient: const LinearGradient(
                                    //       begin: Alignment(1.13, 0.40),
                                    //       end: Alignment(-2.66, 3.01),
                                    //       colors: [
                                    //         Color(0xFF3686AE),
                                    //         Color(0xFF004E7E)
                                    //       ],
                                    //     ),
                                    //     shape: RoundedRectangleBorder(
                                    //       borderRadius:
                                    //           BorderRadius.circular(12),
                                    //     ),
                                    //   ),
                                    //   child: Row(
                                    //     mainAxisSize: MainAxisSize.min,
                                    //     mainAxisAlignment:
                                    //         MainAxisAlignment.center,
                                    //     crossAxisAlignment:
                                    //         CrossAxisAlignment.center,
                                    //     spacing: 4,
                                    //     children: [
                                    //       Container(
                                    //         width: 16,
                                    //         height: 16,
                                    //         clipBehavior: Clip.antiAlias,
                                    //         decoration: const BoxDecoration(),
                                    //         child: const Stack(),
                                    //       ),
                                    //       const Text(
                                    //         'Save Changes',
                                    //         textAlign: TextAlign.center,
                                    //         style: TextStyle(
                                    //           color: Colors.white,
                                    //           fontSize: 16,
                                    //           fontFamily: 'DM Sans',
                                    //           fontWeight: FontWeight.w500,
                                    //           height: 1,
                                    //           letterSpacing: -0.41,
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Reusable circle button
Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(50),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(icon),
    ),
  );
}
