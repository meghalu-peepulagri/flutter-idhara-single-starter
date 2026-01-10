import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

class SettingsFaultCard extends StatefulWidget {
  final double initialLowVoltage;
  final double initialHighVoltage;
  final String motorName;
  final String motorHp;
  final Function(double low, double high)? onSave;

  const SettingsFaultCard({
    super.key,
    this.initialLowVoltage = 180.0,
    this.initialHighVoltage = 280.0,
    this.motorName = 'Pump 1',
    this.motorHp = '3 HP',
    this.onSave,
  });

  @override
  State<SettingsFaultCard> createState() => _SettingsFaultCardState();
}

class _SettingsFaultCardState extends State<SettingsFaultCard> {
  late double lowVoltageValue;
  late double highVoltageValue;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    lowVoltageValue = widget.initialLowVoltage;
    highVoltageValue = widget.initialHighVoltage;
  }

  bool get hasChanges {
    return lowVoltageValue != widget.initialLowVoltage ||
        highVoltageValue != widget.initialHighVoltage;
  }

  void _handleCancel() {
    setState(() {
      _initializeValues();
    });
  }

  void _handleSave() {
    widget.onSave?.call(lowVoltageValue, highVoltageValue);
    
    // Optimistic UI update suggestion: The parent should ideally rebuild this widget with new initial values.
    // For now, we show a local success message as before.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _VoltageSliderRow(
                  label: 'Low Voltage Fault',
                  value: lowVoltageValue,
                  minValue: 150.0,
                  maxValue: 220.0,
                  accentColor: const Color(0xFFE53935), // Red
                  lightColor: const Color(0xFFFFEBEE),
                  onChanged: (value) => setState(() => lowVoltageValue = value),
                ),
                const SizedBox(height: 16),
                _VoltageSliderRow(
                  label: 'High Voltage Fault',
                  value: highVoltageValue,
                  minValue: 240.0,
                  maxValue: 310.0,
                  accentColor: const Color(0xFFFF6F00), // Orange
                  lightColor: const Color(0xFFFFF3E0),
                  onChanged: (value) => setState(() => highVoltageValue = value),
                ),
              ],
            ),
          ),
        ),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                widget.motorName,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF11608D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.motorHp,
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
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
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
              height: 45,
              decoration: BoxDecoration(
                gradient: hasChanges
                    ? const LinearGradient(
                        colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
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
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoltageSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double minValue;
  final double maxValue;
  final Color accentColor;
  final Color lightColor;
  final ValueChanged<double> onChanged;

  const _VoltageSliderRow({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.accentColor,
    required this.lightColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${value.toInt()}V',
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
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 16,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
              activeTrackColor: accentColor,
              inactiveTrackColor: lightColor,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: minValue,
              max: maxValue,
              divisions: (maxValue - minValue).toInt(),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${minValue.toInt()}V',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${maxValue.toInt()}V',
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
}
