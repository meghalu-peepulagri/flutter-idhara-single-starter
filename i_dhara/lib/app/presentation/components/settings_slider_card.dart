import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../modules/settings/settings_controller.dart';

// Custom gradient track shape for dual slider
class GradientTrackShape extends SfTrackShape {
  final double lowValue;
  final double highValue;
  final double lowMinLimit;
  final double lowMaxLimit;
  final double highMinLimit;
  final double highMaxLimit;
  final double minLimit;
  final double maxLimit;
  final bool isDragging;

  GradientTrackShape({
    required this.lowValue,
    required this.highValue,
    required this.lowMinLimit,
    required this.lowMaxLimit,
    required this.highMinLimit,
    required this.highMaxLimit,
    required this.minLimit,
    required this.maxLimit,
    required this.isDragging,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Offset? thumbCenter,
    Offset? startThumbCenter,
    Offset? endThumbCenter, {
    required RenderBox parentBox,
    required SfSliderThemeData themeData,
    SfRangeValues? currentValues,
    dynamic currentValue,
    required Animation<double> enableAnimation,
    required Paint? inactivePaint,
    required Paint? activePaint,
    required TextDirection textDirection,
  }) {
    final canvas = context.canvas;
    final trackRect = getPreferredRect(
      parentBox,
      themeData,
      offset,
    );

    // Calculate color for low thumb based on its position
    Color getLowThumbColor(double value) {
      final normalizedValue =
          (value - lowMinLimit) / (lowMaxLimit - lowMinLimit);
      return Color.lerp(
        Colors.red,
        Colors.green,
        normalizedValue,
      )!;
    }

    // Calculate color for high thumb based on its position
    Color getHighThumbColor(double value) {
      final normalizedValue =
          (value - highMinLimit) / (highMaxLimit - highMinLimit);
      return Color.lerp(
        Colors.green,
        Colors.red,
        normalizedValue,
      )!;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = themeData.activeTrackHeight ?? 3;

    // Show gradient only while dragging
    if (isDragging) {
      final lowColor = getLowThumbColor(lowValue);
      final highColor = getHighThumbColor(highValue);

      // Draw the full track with gradient
      final totalWidth = trackRect.width;
      final valueRange = maxLimit - minLimit;

      // Calculate positions
      final lowPosition = ((lowValue - minLimit) / valueRange) * totalWidth;
      final highPosition = ((highValue - minLimit) / valueRange) * totalWidth;

      // Create gradient with multiple stops
      final gradient = ui.Gradient.linear(
        Offset(trackRect.left, trackRect.center.dy),
        Offset(trackRect.right, trackRect.center.dy),
        [
          lowColor,
          lowColor,
          Colors.grey.shade300,
          highColor,
          highColor,
        ],
        [
          0.0,
          lowPosition / totalWidth,
          (lowPosition + highPosition) / (2 * totalWidth),
          highPosition / totalWidth,
          1.0,
        ],
      );

      paint.shader = gradient;
    } else {
      // Normal gray color when not dragging
      paint.color = const Color(0xFFE8E8E8);
    }

    canvas.drawLine(
      Offset(trackRect.left, trackRect.center.dy),
      Offset(trackRect.right, trackRect.center.dy),
      paint,
    );
  }
}

class SettingsDualSlider extends StatefulWidget {
  final String heading;
  final double initialLowValue;
  final double initialHighValue;
  final double minLimit;
  final double maxLimit;
  final double lowMinLimit;
  final double lowMaxLimit;
  final double highMinLimit;
  final double highMaxLimit;
  final String unit;
  final Color lowColor;
  final Color highColor;
  final Color lowThumbColor;
  final Color highThumbColor;
  final String? leadingSvg;
  final Color? leadingSvgBgColor;
  final Color? leadingSvgColor;
  final Function(double low, double high) onChanged;

  final double? safetyMargin;
  final String cardType;

  const SettingsDualSlider({
    super.key,
    required this.heading,
    required this.initialLowValue,
    required this.initialHighValue,
    required this.minLimit,
    required this.maxLimit,
    required this.lowMinLimit,
    required this.lowMaxLimit,
    required this.highMinLimit,
    required this.highMaxLimit,
    required this.unit,
    required this.lowColor,
    required this.highColor,
    required this.lowThumbColor,
    required this.highThumbColor,
    required this.onChanged,
    this.leadingSvg,
    this.leadingSvgBgColor,
    this.leadingSvgColor,
    this.safetyMargin = 10.0,
    this.cardType = 'voltage',
  });

  @override
  State<SettingsDualSlider> createState() => SettingsDualSliderState();
}

class SettingsDualSliderState extends State<SettingsDualSlider> {
  late double lowValue;
  late double highValue;
  String activeThumb = 'none';

  final controller = Get.find<SettingsController>();

  // Temporary values for real-time display while dragging
  late double tempLowValue;
  late double tempHighValue;

  late double calculatedLow;
  late double calculatedHigh;

  bool isDragging = false;

  // Worker to listen to FLC changes
  late Worker flcWorker;

  @override
  void initState() {
    super.initState();
    _resetValues();

    // Listen to FLC value changes and recalculate
    flcWorker = ever(controller.flc, (_) {
      _recalculateFLC();
    });
  }

  @override
  void dispose() {
    flcWorker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SettingsDualSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLowValue != widget.initialLowValue ||
        oldWidget.initialHighValue != widget.initialHighValue) {
      _resetValues();
    }
  }

  void _resetValues() {
    lowValue = widget.initialLowValue.clamp(widget.minLimit, widget.maxLimit);
    highValue = widget.initialHighValue.clamp(widget.minLimit, widget.maxLimit);
    tempLowValue = lowValue;
    tempHighValue = highValue;

    // Calculate initial FLC values without setState (for initState)
    if (widget.unit.contains("A")) {
      final percentLow = lowValue.toInt() / 100;
      calculatedLow = percentLow * controller.flc.value;

      final percentHigh = highValue.toInt() / 100;
      calculatedHigh = percentHigh * controller.flc.value;
    } else {
      calculatedLow = lowValue;
      calculatedHigh = highValue;
    }
  }

  void _recalculateFLC() {
    if (widget.unit.contains("A")) {
      setState(() {
        final percentLow = lowValue.toInt() / 100;
        calculatedLow = percentLow * controller.flc.value;

        final percentHigh = highValue.toInt() / 100;
        calculatedHigh = percentHigh * controller.flc.value;
      });
    }
  }

  Map<String, double> getCalculatedValues() {
    return {
      'calculatedLow': calculatedLow,
      'calculatedHigh': calculatedHigh,
    };
  }

  void calculatedFlc1(double currentLow) {
    setState(() {
      final percent = currentLow.toInt() / 100;
      final res = percent * controller.flc.value;
      calculatedLow = res;
    });
  }

  void calculatedFlc2(double CurrentHigh) {
    setState(() {
      final percent = CurrentHigh.toInt() / 100;
      final res = percent * controller.flc.value;
      calculatedHigh = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    double displayMin;
    double displayMax;

    if (activeThumb == 'low') {
      displayMin = widget.lowMinLimit;
      displayMax = widget.lowMaxLimit;
    } else if (activeThumb == 'high') {
      displayMin = widget.highMinLimit;
      displayMax = widget.highMaxLimit;
    } else {
      displayMin = widget.minLimit;
      displayMax = widget.maxLimit;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon, Title, and Values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.leadingSvg != null)
                    Container(
                      child: SvgPicture.asset(
                        widget.leadingSvg!,
                        width: 24,
                        height: 24,
                        colorFilter: widget.leadingSvgColor != null
                            ? ColorFilter.mode(
                                widget.leadingSvgColor!,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                  if (widget.leadingSvg != null) const SizedBox(width: 12),
                  Text(
                    widget.heading,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 16,
                children: [
                  // Low Label and Value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'LOW ${widget.unit.contains("A") ? "AMPS" : "VOLTS"}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF999999),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.unit.contains("A")
                            ? '${calculatedLow.toStringAsFixed(2)}${widget.unit}'
                            : '${(isDragging ? tempLowValue : lowValue).toInt()}${widget.unit}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE5B800),
                        ),
                      ),
                    ],
                  ),
                  // High Label and Value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'HIGH ${widget.unit.contains("A") ? "AMPS" : "VOLTS"}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF999999),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.unit.contains("A")
                            ? '${calculatedHigh.toStringAsFixed(2)}${widget.unit}'
                            : '${(isDragging ? tempHighValue : highValue).toInt()}${widget.unit}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFA2A2),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),

          // Custom Slider with Tooltip Badges
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Slider
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: SfRangeSliderTheme(
                  data: const SfRangeSliderThemeData(
                    thumbRadius: 18,
                    overlayRadius: 0,
                    activeTrackHeight: 3,
                    inactiveTrackHeight: 3,
                  ),
                  child: SfRangeSlider(
                    min: widget.minLimit,
                    max: widget.maxLimit,
                    values: SfRangeValues(lowValue, highValue),
                    enableTooltip: false,
                    inactiveColor: const Color(0xFFE8E8E8),
                    activeColor: const Color(0xFFE8E8E8),
                    trackShape: GradientTrackShape(
                      lowValue: isDragging ? tempLowValue : lowValue,
                      highValue: isDragging ? tempHighValue : highValue,
                      lowMinLimit: widget.lowMinLimit,
                      lowMaxLimit: widget.lowMaxLimit,
                      highMinLimit: widget.highMinLimit,
                      highMaxLimit: widget.highMaxLimit,
                      minLimit: widget.minLimit,
                      maxLimit: widget.maxLimit,
                      isDragging: isDragging,
                    ),
                    overlayShape: const SfOverlayShape(),
                    startThumbIcon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFEF3C6),
                        border: Border.all(
                            color: const Color(0xFFE5B800), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0XFFFFD230).withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'L',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    endThumbIcon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFE2E2),
                        border: Border.all(
                            color: const Color(0xFFFFA2A2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0XFFFFA2A2).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'H',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    onChanged: (SfRangeValues newValues) {
                      double start = (newValues.start as double)
                          .clamp(widget.lowMinLimit, widget.lowMaxLimit);
                      double end = (newValues.end as double)
                          .clamp(widget.highMinLimit, widget.highMaxLimit);
                      setState(() {
                        isDragging = true;
                        tempLowValue = start;
                        tempHighValue = end;
                        lowValue = start;
                        highValue = end;

                        // Calculate FLC values in real-time during dragging
                        final percentLow = start.toInt() / 100;
                        calculatedLow = percentLow * controller.flc.value;

                        final percentHigh = end.toInt() / 100;
                        calculatedHigh = percentHigh * controller.flc.value;
                      });
                      widget.onChanged(start, end);
                    },
                    onChangeEnd: (SfRangeValues newValues) {
                      double start = (newValues.start as double)
                          .clamp(widget.lowMinLimit, widget.lowMaxLimit);
                      double end = (newValues.end as double)
                          .clamp(widget.highMinLimit, widget.highMaxLimit);
                      setState(() {
                        final percentLow = start.toInt() / 100;
                        calculatedLow = percentLow * controller.flc.value;
                        final percentHigh = end.toInt() / 100;
                        calculatedHigh = percentHigh * controller.flc.value;
                        isDragging = false;
                      });
                    },
                  ),
                ),
              ),

              // Tooltip-style badges above thumbs
              Positioned(
                left: 15 +
                    _calculatePosition(isDragging ? tempLowValue : lowValue,
                        widget.minLimit, widget.maxLimit),
                top: 0,
                child: _buildTooltipBadge(
                  '${(isDragging ? tempLowValue : lowValue).toInt()}${widget.unit.contains("A") ? "%" : widget.unit}',
                  const Color(0xFFE5B800),
                ),
              ),
              Positioned(
                left: _calculatePosition(isDragging ? tempHighValue : highValue,
                        widget.minLimit, widget.maxLimit) -
                    10,
                top: 0,
                child: _buildTooltipBadge(
                  '${(isDragging ? tempHighValue : highValue).toInt()}${widget.unit.contains("A") ? "%" : widget.unit}',
                  const Color(0xFFFFA2A2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Min/Max Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${displayMin.toInt()}${widget.unit.contains("A") ? "%" : widget.unit}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF999999),
                  ),
                ),
                Text(
                  '${displayMax.toInt()}${widget.unit.contains("A") ? "%" : widget.unit}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calculate position for tooltip badge
  double _calculatePosition(double value, double min, double max) {
    // Get the percentage position
    double percentage = (value - min) / (max - min);

    // Calculate pixel position (assuming the slider width, account for padding)
    // Subtract half the badge width (approximately 30) to center it
    double sliderWidth =
        MediaQuery.of(context).size.width - 80; // Account for container padding
    return (percentage * sliderWidth) - 25;
  }

  // Build tooltip badge widget
  Widget _buildTooltipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
