import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TimingConfigCard extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final ValueChanged<int>? onChanged;
  final ValueChanged<bool>? onOutOfRange;
  final bool hideHeading;

  const TimingConfigCard({
    super.key,
    this.initialValue = 100,
    this.minValue = 100,
    this.maxValue = 100,
    this.onChanged,
    this.onOutOfRange,
    this.hideHeading = false,
  });

  @override
  State<TimingConfigCard> createState() => TimingConfigCardState();
}

class TimingConfigCardState extends State<TimingConfigCard> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
    _errorText = _errorFor(widget.initialValue);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit();
      setState(() => _isEditing = _focusNode.hasFocus);
    });
  }

  void resetValue() {
    setState(() {
      _controller.text = widget.initialValue.toString();
      _errorText = _errorFor(widget.initialValue);
    });
    widget.onOutOfRange?.call(_errorText != null);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _errorFor(int? value) {
    if (value == null || value < widget.minValue) {
      return 'Minimum value is ${widget.minValue}';
    }
    if (value > widget.maxValue) {
      return 'Maximum value is ${widget.maxValue}';
    }
    return null;
  }

  void _onTextChanged(String text) {
    final parsed = int.tryParse(text.trim());
    final err = _errorFor(parsed);
    setState(() => _errorText = err);
    widget.onOutOfRange?.call(err != null);
    if (err == null && parsed != null) {
      widget.onChanged?.call(parsed);
    }
  }

  void _commit() {
    final parsed = int.tryParse(_controller.text.trim());
    final err = _errorFor(parsed);
    setState(() => _errorText = err);
    widget.onOutOfRange?.call(err != null);
    if (err == null && parsed != null) {
      _controller.text = parsed.toString();
      widget.onChanged?.call(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.hideHeading) ...[
            Text(
              'Timing Configuration',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFECECEC)),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Start Delay',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 56, maxWidth: 96),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: hasError
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0A0A0A),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: hasError
                                  ? const Color(0xFFEF4444)
                                  : _isEditing
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFFE5E5E5),
                              width: hasError || _isEditing ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: hasError
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _commit(),
                        onTapOutside: (_) => _focusNode.unfocus(),
                      ),
                    ),
                  ),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _errorText!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Min: ${widget.minValue}Sec',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Max: ${widget.maxValue}Sec',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
