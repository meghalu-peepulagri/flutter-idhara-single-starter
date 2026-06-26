import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';

//  Section Label
Widget scheduleSectionLabel(String text) => Text(
      text,
      style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A)),
    );

//  Generic Toggle Row
Widget buildScheduleToggle({
  IconData? icon,
  required String title,
  String? subtitle,
  required ValueNotifier<bool> controller,
  required ValueChanged<bool> onChanged,
  bool enabled = true,
}) {
  return Opacity(
    opacity: enabled ? 1.0 : 0.4,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A))),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B))),
                ],
              ],
            ),
          ),
          AdvancedSwitch(
            controller: controller,
            initialValue: controller.value,
            activeColor: const Color(0xFF34C759),
            inactiveColor: const Color(0xFFE0E0E0),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            width: 46,
            height: 24,
            enabled: enabled,
            onChanged: enabled ? (v) => onChanged(v as bool) : null,
          ),
        ],
      ),
    ),
  );
}

//  Cyclic Card
class ScheduleCyclicCard extends StatelessWidget {
  final bool cyclicMode;
  final int cyclicOnMinutes;
  final int cyclicOffMinutes;
  final ValueNotifier<bool> cyclicController;
  final ValueChanged<bool> onCyclicChanged;
  final VoidCallback onOnDecrement;
  final VoidCallback onOnIncrement;
  final VoidCallback onOffDecrement;
  final VoidCallback onOffIncrement;
  final bool onIncrementEnabled;
  final bool offIncrementEnabled;
  final bool onDecrementEnabled;
  final bool offDecrementEnabled;
  final ValueChanged<int>? onOnChanged;
  final ValueChanged<int>? onOffChanged;

  const ScheduleCyclicCard({
    super.key,
    required this.cyclicMode,
    required this.cyclicOnMinutes,
    required this.cyclicOffMinutes,
    required this.cyclicController,
    required this.onCyclicChanged,
    required this.onOnDecrement,
    required this.onOnIncrement,
    required this.onOffDecrement,
    required this.onOffIncrement,
    this.onIncrementEnabled = true,
    this.offIncrementEnabled = true,
    this.onDecrementEnabled = true,
    this.offDecrementEnabled = true,
    this.onOnChanged,
    this.onOffChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded,
                  size: 18, color: Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cyclic Mode',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('Motor alternates ON / OFF',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              AdvancedSwitch(
                controller: cyclicController,
                initialValue: cyclicController.value,
                activeColor: const Color(0xFF34C759),
                inactiveColor: const Color(0xFFE0E0E0),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                width: 46,
                height: 24,
                enabled: true,
                onChanged: (v) => onCyclicChanged(v as bool),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: cyclicMode
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _CyclicDurationField(
                              label: 'ON Duration',
                              color: const Color(0xFF34C759),
                              minutes: cyclicOnMinutes,
                              onDecrement: onOnDecrement,
                              onIncrement: onOnIncrement,
                              onChanged: onOnChanged,
                              incrementEnabled: onIncrementEnabled,
                              decrementEnabled: onDecrementEnabled,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: const Color(0xFFE5E7EB),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          Expanded(
                            child: _CyclicDurationField(
                              label: 'OFF Duration',
                              color: const Color(0xFFEF4444),
                              minutes: cyclicOffMinutes,
                              onDecrement: onOffDecrement,
                              onIncrement: onOffIncrement,
                              onChanged: onOffChanged,
                              incrementEnabled: offIncrementEnabled,
                              decrementEnabled: offDecrementEnabled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

}

class _CyclicDurationField extends StatefulWidget {
  final String label;
  final Color color;
  final int minutes;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<int>? onChanged;
  final bool incrementEnabled;
  final bool decrementEnabled;

  const _CyclicDurationField({
    required this.label,
    required this.color,
    required this.minutes,
    required this.onDecrement,
    required this.onIncrement,
    this.onChanged,
    this.incrementEnabled = true,
    this.decrementEnabled = true,
  });

  @override
  State<_CyclicDurationField> createState() => _CyclicDurationFieldState();
}

class _CyclicDurationFieldState extends State<_CyclicDurationField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.minutes}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _syncText();
  }

  void _syncText() {
    final text = '${widget.minutes}';
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void didUpdateWidget(covariant _CyclicDurationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.minutes != oldWidget.minutes) {
      _syncText();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: const Color(0xFFEBF3FE),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: const Color(0xFF004E7E)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Row(
          children: [
            _stepButton(
              icon: Icons.remove_rounded,
              onTap: widget.onDecrement,
              enabled: widget.decrementEnabled,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.color),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    suffixText: 'min',
                    suffixStyle: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: widget.color, width: 1.4),
                    ),
                  ),
                  onChanged: (val) {
                    final v = int.tryParse(val);
                    if (v != null) widget.onChanged?.call(v);
                  },
                  onSubmitted: (_) => _syncText(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _stepButton(
              icon: Icons.add_rounded,
              onTap: widget.onIncrement,
              enabled: widget.incrementEnabled,
            ),
          ],
        ),
      ],
    );
  }
}

//  Bottom Bar
class ScheduleFormBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  final bool isEditMode;
  // When false, the Save/Update button greys out and ignores taps. Driven
  // by the form's durationMinutes — disables until the user picks valid
  // start/end times.
  final bool saveEnabled;

  const ScheduleFormBottomBar({
    super.key,
    required this.onBack,
    required this.onSave,
    this.isEditMode = false,
    this.saveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDCDCDC)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF000000))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: saveEnabled
                    ? const LinearGradient(
                        colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: saveEnabled ? null : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: saveEnabled
                    ? [
                        BoxShadow(
                            color:
                                const Color(0xFF004E7E).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: saveEnabled ? onSave : null,
                  child: Center(
                    child: Text(
                        isEditMode ? 'Update Schedule' : 'Save Schedule',
                        style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
