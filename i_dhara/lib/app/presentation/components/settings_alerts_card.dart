import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

class SettingsAlertsCard extends StatefulWidget {
  const SettingsAlertsCard({super.key});

  @override
  State<SettingsAlertsCard> createState() => _SettingsAlertsCardState();
}

class _SettingsAlertsCardState extends State<SettingsAlertsCard> {
  // Original values
  double originalLowVoltageValue = 180.0;
  double originalHighVoltageValue = 280.0;

  // Current values
  double lowVoltageValue = 180.0;
  double highVoltageValue = 280.0;

  // Check if there are any changes
  bool get hasChanges {
    return lowVoltageValue != originalLowVoltageValue ||
        highVoltageValue != originalHighVoltageValue;
  }

  void _handleCancel() {
    setState(() {
      lowVoltageValue = originalLowVoltageValue;
      highVoltageValue = originalHighVoltageValue;
    });
  }

  void _handleSave() {
    // Build success message
    List<String> changes = [];
    if (lowVoltageValue != originalLowVoltageValue) {
      changes.add('Low: ${lowVoltageValue.toStringAsFixed(0)}C');
    }
    if (highVoltageValue != originalHighVoltageValue) {
      changes.add('High: ${highVoltageValue.toStringAsFixed(0)}C');
    }

    // Update original values after saving
    setState(() {
      originalLowVoltageValue = lowVoltageValue;
      originalHighVoltageValue = highVoltageValue;
    });
  }

  Widget _buildVoltageRow({
    required String label,
    required double value,
    required double minValue,
    required double maxValue,
    required Color accentColor,
    required Color lightColor,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)}C',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Wider Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 28,
              ),
              activeTrackColor: accentColor,
              inactiveTrackColor: lightColor,
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: minValue,
              max: maxValue,
              divisions: ((maxValue - minValue) / 1).toInt(),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 6),
          // Min and Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minValue.toInt()}C',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${maxValue.toInt()}C',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Pump 1',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Text(
                              '3 HP',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF11608D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Low Voltage Setting
                _buildVoltageRow(
                  label: 'Low Current Fault',
                  value: lowVoltageValue,
                  minValue: 150.0,
                  maxValue: 220.0,
                  accentColor: const Color(0xFFE53935),
                  lightColor: const Color(0xFFFFEBEE),
                  onChanged: (value) {
                    setState(() {
                      lowVoltageValue = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // High Voltage Setting
                _buildVoltageRow(
                  label: 'High Current Fault',
                  value: highVoltageValue,
                  minValue: 240.0,
                  maxValue: 310.0,
                  accentColor: const Color(0xFFFF6F00),
                  lightColor: const Color(0xFFFFF3E0),
                  onChanged: (value) {
                    setState(() {
                      highVoltageValue = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        // Fixed Bottom Buttons
        // Container(
        //   padding: const EdgeInsets.all(20),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(12),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.08),
        //         blurRadius: 12,
        //         offset: const Offset(0, -2),
        //       ),
        //     ],
        //   ),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: OutlinedButton(
        //           onPressed: hasChanges ? _handleCancel : null,
        //           style: OutlinedButton.styleFrom(
        //             padding: const EdgeInsets.symmetric(vertical: 16),
        //             side: BorderSide(
        //               color: hasChanges
        //                   ? const Color(0xFF11608D)
        //                   : Colors.grey[300]!,
        //               width: 1.5,
        //             ),
        //             shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(8),
        //             ),
        //             backgroundColor: Colors.white,
        //           ),
        //           child: Text(
        //             'Cancel',
        //             style: GoogleFonts.dmSans(
        //               fontSize: 16,
        //               fontWeight: FontWeight.w600,
        //               color: hasChanges
        //                   ? const Color(0xFF11608D)
        //                   : Colors.grey[400],
        //             ),
        //           ),
        //         ),
        //       ),
        //       const SizedBox(width: 16),
        //       Expanded(
        //         child: ElevatedButton(
        //           onPressed: hasChanges ? _handleSave : null,
        //           style: ElevatedButton.styleFrom(
        //             padding: const EdgeInsets.symmetric(vertical: 16),
        //             backgroundColor:
        //                 hasChanges ? const Color(0xFF11608D) : Colors.grey[300],
        //             disabledBackgroundColor: Colors.grey[300],
        //             shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(8),
        //             ),
        //             elevation: hasChanges ? 2 : 0,
        //           ),
        //           child: Text(
        //             'Save',
        //             style: GoogleFonts.dmSans(
        //               fontSize: 16,
        //               fontWeight: FontWeight.w600,
        //               color: hasChanges ? Colors.white : Colors.grey[500],
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FFButtonWidget(
                  onPressed: hasChanges ? _handleCancel : null,
                  text: 'Cancel',
                  options: FFButtonOptions(
                    height: 45.0,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Manrope',
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                    elevation: 0.0,
                    borderSide: const BorderSide(color: Color(0x38000000)),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(width: 24.0),
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: hasChanges
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF004E7E),
                              Color(0xFF3686AF),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: hasChanges ? null : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FFButtonWidget(
                    onPressed: hasChanges ? _handleSave : null,
                    text: 'Save',
                    options: FFButtonOptions(
                      height: 45.0,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      color: Colors.transparent,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                fontFamily: 'Manrope',
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                fontWeight: FontWeight.w500,
                              ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(60.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
