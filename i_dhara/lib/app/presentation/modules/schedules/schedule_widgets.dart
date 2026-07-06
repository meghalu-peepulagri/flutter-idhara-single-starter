import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── String Scroll Wheel (for month names, etc.) ───────────
Widget buildStringScrollWheel({
  Key? key,
  required List<String> values,
  required int selectedIndex,
  required Function(int) onChanged,
  double width = 72,
  double height = 140,
}) {
  final controller = FixedExtentScrollController(
    initialItem: selectedIndex.clamp(0, values.length - 1),
  );
  return Container(
    key: key,
    width: width,
    height: height,
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
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: Text(
              values[index],
              style: GoogleFonts.dmSans(
                fontSize: isSelected ? 20 : 14,
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

// ─── Scroll Wheel ──────────────────────────────────────────
Widget buildScrollWheel({
  Key? key,
  required List<int> values,
  required int selected,
  required Function(int) onChanged,
  bool padZero = false,
  double width = 64,
  // Infinite alarm-style loop: scrolling past the last value wraps to the
  // first (e.g. 23 → 00, or 11 PM → 12 AM in a 12h wheel).
  bool loop = false,
  // Optional label override — lets a value render as a different label.
  String Function(int value)? labelBuilder,
}) {
  final controller = FixedExtentScrollController(
    initialItem: values.indexOf(selected).clamp(0, values.length - 1),
  );

  final children = <Widget>[
    for (final value in values)
      Builder(builder: (_) {
        final isSelected = value == selected;
        final display = labelBuilder != null
            ? labelBuilder(value)
            : (padZero ? value.toString().padLeft(2, '0') : value.toString());
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
      }),
  ];

  return Container(
    key: key,
    width: width,
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
      onSelectedItemChanged: (index) =>
          onChanged(values[index % values.length]),
      childDelegate: loop
          ? ListWheelChildLoopingListDelegate(children: children)
          : ListWheelChildListDelegate(children: children),
    ),
  );
}
