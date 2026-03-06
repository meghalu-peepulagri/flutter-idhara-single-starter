import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Scroll Wheel ──────────────────────────────────────────
Widget buildScrollWheel({
  required List<int> values,
  required int selected,
  required Function(int) onChanged,
  bool padZero = false,
}) {
  final controller = FixedExtentScrollController(
    initialItem: values.indexOf(selected),
  );
  return Container(
    width: 64,
    height: 140,
    decoration: BoxDecoration(
      color: const Color(0xFFEBF3FE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 40,
      perspective: 0.005,
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => onChanged(values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final isSelected = values[index] == selected;
          final display = padZero
              ? values[index].toString().padLeft(2, '0')
              : values[index].toString();
          return Center(
            child: Text(
              display,
              style: GoogleFonts.dmSans(
                fontSize: isSelected ? 24 : 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF004E7E)
                    : const Color(0xFF828282),
              ),
            ),
          );
        },
      ),
    ),
  );
}
