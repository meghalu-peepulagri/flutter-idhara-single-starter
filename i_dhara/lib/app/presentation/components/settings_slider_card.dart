import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsDualSlider extends StatefulWidget {
  final String heading;
  final double initialLowValue;
  final double initialHighValue;
  final double minLimit;
  final double maxLimit;
  final double lowMinLimit; // Add separate limits for low thumb
  final double lowMaxLimit;
  final double highMinLimit; // Add separate limits for high thumb
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
  });

  @override
  State<SettingsDualSlider> createState() => _SettingsDualSliderState();
}

class _SettingsDualSliderState extends State<SettingsDualSlider> {
  late double lowValue;
  late double highValue;
  String activeThumb = 'none';

  @override
  void initState() {
    super.initState();
    _resetValues();
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
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic min/max based on active thumb
    double displayMin;
    double displayMax;

    if (activeThumb == 'low') {
      displayMin = widget.lowMinLimit;
      displayMax = widget.lowMaxLimit;
    } else if (activeThumb == 'high') {
      displayMin = widget.highMinLimit;
      displayMax = widget.highMaxLimit;
    } else {
      // Default: show full range (low min to high max)
      displayMin = widget.minLimit;
      displayMax = widget.maxLimit;
    }

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
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (widget.leadingSvg != null)
                  Container(
                    // padding: const EdgeInsets.all(8),
                    // decoration: BoxDecoration(
                    //   color: widget.leadingSvgBgColor ?? Colors.grey.shade200,
                    //   borderRadius: BorderRadius.circular(8),
                    // ),
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
                if (widget.leadingSvg != null) const SizedBox(width: 8),
                Text(
                  widget.heading,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004E7E),
                  ),
                ),
              ],
            ),
          ),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Low Value Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.lowColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Low : ',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.lowColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${lowValue.toInt()}${widget.unit}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.lowColor,
                      ),
                    ),
                  ],
                ),
              ),

              // High Value Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.highColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'High : ',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.lowColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${highValue.toInt()}${widget.unit}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.highColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider Track
          SizedBox(
            height: 60,
            child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  // Track Background
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 27,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Low Thumb
                  _buildThumb(
                    value: lowValue,
                    min: displayMin,
                    max: displayMax,
                    color: widget.lowThumbColor,
                    isActive: activeThumb == 'low',
                    label: "L",
                    onDragStart: () => setState(() => activeThumb = 'low'),
                    onDragUpdate: (delta) {
                      setState(() {
                        final range = displayMax - displayMin;
                        final pxChange = delta * range;

                        var newValue = lowValue + pxChange;
                        newValue = newValue.clamp(
                            widget.lowMinLimit, widget.lowMaxLimit);
                        // Ensure low doesn't exceed high
                        newValue =
                            newValue.clamp(widget.lowMinLimit, highValue - 1);
                        lowValue = newValue;

                        widget.onChanged(lowValue, highValue);
                      });
                    },
                    onDragEnd: () => setState(() => activeThumb = 'none'),
                    maxWidth: constraints.maxWidth,
                  ),

                  // High Thumb
                  _buildThumb(
                    value: highValue,
                    min: displayMin,
                    max: displayMax,
                    color: widget.highThumbColor,
                    isActive: activeThumb == 'high',
                    label: "H",
                    onDragStart: () => setState(() => activeThumb = 'high'),
                    onDragUpdate: (delta) {
                      setState(() {
                        final range = displayMax - displayMin;
                        final pxChange = delta * range;

                        var newValue = highValue + pxChange;
                        newValue = newValue.clamp(
                            widget.highMinLimit, widget.highMaxLimit);
                        // Ensure high doesn't go below low
                        newValue =
                            newValue.clamp(lowValue + 1, widget.highMaxLimit);
                        highValue = newValue;

                        widget.onChanged(lowValue, highValue);
                      });
                    },
                    onDragEnd: () => setState(() => activeThumb = 'none'),
                    maxWidth: constraints.maxWidth,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 4),

          // Min/Max Labels - Dynamic based on active thumb
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${displayMin.toInt()}${widget.unit}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${displayMax.toInt()}${widget.unit}',
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

  Widget _buildThumb({
    required double value,
    required double min,
    required double max,
    required Color color,
    required bool isActive,
    required String label,
    required VoidCallback onDragStart,
    required Function(double deltaPct) onDragUpdate,
    required VoidCallback onDragEnd,
    required double? maxWidth,
  }) {
    // Calculate fractional position
    final fraction = (value - min) / (max - min);

    final availableWidth = (maxWidth ?? 0) - 32;
    final leftPos = availableWidth > 0 ? (fraction * availableWidth) : 0.0;

    return Positioned(
      left: leftPos,
      top: 10,
      child: GestureDetector(
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: (details) {
          if (availableWidth > 0) {
            onDragUpdate(details.delta.dx / availableWidth);
          }
        },
        onHorizontalDragEnd: (_) => onDragEnd(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: Colors.white, width: 3) : null,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
