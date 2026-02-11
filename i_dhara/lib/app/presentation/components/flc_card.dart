import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FlcCard extends StatefulWidget {
  final String? iconAsset;
  final Color? iconBgColor;
  final Color? iconColor;
  final double initialValue;
  final String unit;
  final String label;
  final ValueChanged<double>? onValueChanged;
  final double minValue;
  final double maxValue;
  final double step;
  final int decimalPlaces;

  const FlcCard({
    super.key,
    this.iconAsset,
    this.iconBgColor,
    this.iconColor,
    this.initialValue = 1,
    this.unit = 'AMPS',
    this.label = 'RATED CURRENT (FLC)',
    this.onValueChanged,
    this.minValue = 1,
    this.maxValue = 25,
    this.step = 0.1,
    this.decimalPlaces = 1,
  });

  @override
  State<FlcCard> createState() => _FlcCardState();
}

class _FlcCardState extends State<FlcCard> {
  late double _currentValue;
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    _textController = TextEditingController(text: _formatValue(_currentValue));

    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    return value.toStringAsFixed(widget.decimalPlaces);
  }

  double _roundToStep(double value) {
    // Round to the nearest step to avoid floating point errors
    final factor = 1 / widget.step;
    return (value * factor).round() / factor;
  }

  void _increment() {
    if (_currentValue < widget.maxValue) {
      setState(() {
        _currentValue = _roundToStep(_currentValue + widget.step);
        _currentValue = _currentValue.clamp(widget.minValue, widget.maxValue);
        _textController.text = _formatValue(_currentValue);
      });
      widget.onValueChanged?.call(_currentValue);
    }
  }

  void _decrement() {
    if (_currentValue > widget.minValue) {
      setState(() {
        _currentValue = _roundToStep(_currentValue - widget.step);
        _currentValue = _currentValue.clamp(widget.minValue, widget.maxValue);
        _textController.text = _formatValue(_currentValue);
      });
      widget.onValueChanged?.call(_currentValue);
    }
  }

  void _onManualInput(String value) {
    if (value.isEmpty) return;

    final parsedValue = double.tryParse(value);
    if (parsedValue != null) {
      setState(() {
        _currentValue = parsedValue.clamp(widget.minValue, widget.maxValue);
        _textController.text = _formatValue(_currentValue);
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
      widget.onValueChanged?.call(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.iconBgColor ?? const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SvgPicture.asset(
              widget.iconAsset ?? 'assets/images/Voltage.svg',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              colorFilter: widget.iconColor != null
                  ? ColorFilter.mode(widget.iconColor!, BlendMode.srcIn)
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Value and Unit
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    spacing: 3,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      Text(
                        widget.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF999999),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Value Input and Unit
                      Row(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Editable Value
                          IntrinsicWidth(
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 60,
                                maxWidth: 120,
                              ),
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: false,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                style: GoogleFonts.dmSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0A0A0A),
                                  height: 1.0,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(
                                      color: _isEditing
                                          ? const Color(0xFF3B82F6)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3B82F6),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                onSubmitted: _onManualInput,
                                onTapOutside: (_) {
                                  _focusNode.unfocus();
                                  _onManualInput(_textController.text);
                                },
                              ),
                            ),
                          ),
                          // Unit
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              widget.unit,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                                height: 1.0,
                              ),
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

          // Increment/Decrement Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Increment Button
              InkWell(
                onTap: _currentValue < widget.maxValue ? _increment : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentValue < widget.maxValue
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: _currentValue < widget.maxValue
                        ? Colors.white
                        : const Color(0xFF999999),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Decrement Button
              InkWell(
                onTap: _currentValue > widget.minValue ? _decrement : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _currentValue > widget.minValue
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 20,
                    color: _currentValue > widget.minValue
                        ? Colors.white
                        : const Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
