import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  State<SettingsDualSlider> createState() => _SettingsDualSliderState();
}

class _SettingsDualSliderState extends State<SettingsDualSlider> {
  late double lowValue;
  late double highValue;
  String activeThumb = 'none';
  int temp = 0;
  int lowtemp = 0;

  bool isdragging = false;
  bool islowdragging = false;

  // Color feedback tracking
  bool isScrolling = false;
  String? scrollingThumb; // 'low' or 'high'

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

  Color _getColorForPosition(double position, String thumbType) {
    if (!isScrolling || scrollingThumb != thumbType) {
      return Colors.transparent;
    }

    if (thumbType == 'low') {
      // Safe zone: lowMinLimit to (lowMinLimit + 10)
      if (position >= widget.lowMinLimit &&
          position <= widget.lowMinLimit + 10) {
        return Colors.green;
      }
      // Unsafe zone: below lowMinLimit
      if (position < widget.lowMinLimit) {
        return Colors.red;
      }
      return Colors.transparent;
    } else {
      if (position >= widget.highMaxLimit - 10 &&
          position <= widget.highMaxLimit) {
        return Colors.green;
      }
      // Unsafe zone: above highMaxLimit
      if (position > widget.highMaxLimit) {
        return Colors.red;
      }
      return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("line 84 ------> $lowValue $highValue");
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
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFf0A0A0A),
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
                  color: const Color(0XFFFEF3C6),
                  // widget.lowColor.withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0XFFFFD230), width: 1),
                  borderRadius: BorderRadius.circular(8),
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
                      !isdragging
                          ? '${lowValue.toInt()}${widget.unit}'
                          : '$temp${widget.unit}',
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
                  color: const Color(0XFFFFE2E2),
                  border: Border.all(color: const Color(0XFFFFA2A2), width: 1),
                  // widget.highColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                      !islowdragging
                          ? '${highValue.toInt()}${widget.unit}'
                          : '$temp${widget.unit}',
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
                  // Track Background with Color Zones
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 27,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Stack(
                        children: [
                          // Default gray background
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Color zones overlay
                          if (isScrolling && scrollingThumb == 'low')
                            _buildLowThumbZones(constraints.maxWidth)
                          else if (isScrolling && scrollingThumb == 'high')
                            _buildHighThumbZones(constraints.maxWidth)
                        ],
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
                    onDragStart: () {
                      print("line 252 $displayMin $displayMax");
                      setState(() {
                        isdragging = false;
                        islowdragging = true;
                        temp = highValue.toInt();
                        highValue = displayMax + displayMax + 10;
                        print("line 257 $highValue $temp");
                        activeThumb = 'low';
                        isScrolling = true;
                        scrollingThumb = 'low';
                      });
                    },
                    onDragUpdate: (delta) {
                      setState(() {
                        print("line 264 $displayMin $displayMax $highValue");
                        final range = displayMax - displayMin;
                        final pxChange = delta * range;
                        var newValue = lowValue + pxChange;
                        newValue = newValue.clamp(
                            widget.lowMinLimit, widget.lowMaxLimit);
                        // Ensure low doesn't exceed high
                        highValue = displayMax + displayMax + 10;
                        newValue =
                            newValue.clamp(widget.lowMinLimit, highValue - 1);
                        lowValue = newValue;
                        widget.onChanged(lowValue, highValue);
                      });
                    },
                    onDragEnd: () {
                      setState(() {
                        activeThumb = 'none';
                        isdragging = false;
                        islowdragging = false;
                        highValue = temp.toDouble();
                        isScrolling = false;
                        scrollingThumb = null;
                        widget.onChanged(lowValue, highValue);
                      });
                    },
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
                    onDragStart: () {
                      setState(() {
                        activeThumb = 'high';
                        temp = lowValue.toInt();
                        lowValue = 0;
                        isdragging = true;
                        islowdragging = false;
                        isScrolling = true;
                        scrollingThumb = 'high';
                      });
                    },
                    onDragUpdate: (delta) {
                      print("line 308 $displayMin $displayMax $lowValue");

                      setState(() {
                        lowValue = 0;

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
                    onDragEnd: () {
                      setState(() {
                        activeThumb = 'none';
                        isdragging = false;
                        islowdragging = false;
                        lowValue = temp.toDouble();
                        isScrolling = false;
                        scrollingThumb = null;
                        widget.onChanged(lowValue, highValue);
                      });
                    },
                    maxWidth: constraints.maxWidth,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 4),

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
                    color: const Color(0xFF4F4F4F),
                  ),
                ),
                Text(
                  '${displayMax.toInt()}${widget.unit}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F4F4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowThumbZones(double maxWidth) {
    final safeMargin = widget.safetyMargin ?? 10.0;

    bool isInDangerZone = lowValue <
            widget.lowMinLimit + safeMargin || // Too close to lower limit
        lowValue > widget.lowMaxLimit - safeMargin; // Too close to upper limit

    // Show full slider in one color
    final sliderColor = isInDangerZone ? Colors.red : Colors.green;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: sliderColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHighThumbZones(double maxWidth) {
    final safeMargin = widget.safetyMargin ?? 10.0;

    bool isInDangerZone = highValue <
            widget.highMinLimit + safeMargin || // Too close to lower limit
        highValue >
            widget.highMaxLimit - safeMargin; // Too close to upper limit

    // Show full slider in one color
    final sliderColor = isInDangerZone ? Colors.red : Colors.green;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: sliderColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(3),
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
            color: label == "L"
                ? const Color(0xFFFEF3C6)
                : const Color(0xFFFFE2E2),
            shape: BoxShape.circle,
            border: label == "L"
                ? Border.all(color: const Color(0xFFE5B800), width: 2)
                : Border.all(color: const Color(0xFFFFA2A2), width: 2),
            // boxShadow: [
            //   BoxShadow(
            //     color: color.withValues(alpha: 0.3),
            //     blurRadius: 8,
            //     offset: const Offset(0, 2),
            //   ),
            // ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0XFF9F0712),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
