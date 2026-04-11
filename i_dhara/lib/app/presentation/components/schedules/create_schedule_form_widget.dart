import 'package:flutter/material.dart';
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
  required IconData icon,
  required String title,
  required String subtitle,
  required ValueNotifier<bool> controller,
  required ValueChanged<bool> onChanged,
  bool enabled = true,
}) {
  return Opacity(
    opacity: enabled ? 1.0 : 0.4,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B))),
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
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
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDurationField(
                              label: 'ON Duration',
                              color: const Color(0xFF34C759),
                              minutes: cyclicOnMinutes,
                              onDecrement: onOnDecrement,
                              onIncrement: onOnIncrement,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: const Color(0xFFE5E7EB),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          Expanded(
                            child: _buildDurationField(
                              label: 'OFF Duration',
                              color: const Color(0xFFEF4444),
                              minutes: cyclicOffMinutes,
                              onDecrement: onOffDecrement,
                              onIncrement: onOffIncrement,
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

  Widget _buildDurationField({
    required String label,
    required Color color,
    required int minutes,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.remove_rounded,
                    size: 16, color: Color(0xFF004E7E)),
              ),
            ),
            const SizedBox(width: 8),
            Text('${minutes}min',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.add_rounded,
                    size: 16, color: Color(0xFF004E7E)),
              ),
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

  const ScheduleFormBottomBar(
      {super.key,
      required this.onBack,
      required this.onSave,
      this.isEditMode = false});

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
                gradient: const LinearGradient(
                    colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF004E7E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onSave,
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
