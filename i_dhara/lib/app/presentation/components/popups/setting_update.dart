import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Reusable Info Card
Widget infoCard(
    {required Color bgColor,
    required Color iconBg,
    required String svg,
    required String title,
    required String lowOld,
    required String lowNew,
    required String highOld,
    required String highNew,
    required Color valueColor,
    double widthofSvg = 24,
    double heightofSvg = 24,
    bool vmin = false,
    bool vmax = false,
    bool cmin = false,
    bool cmax = false}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SvgPicture.asset(
                svg,
                width: widthofSvg,
                height: heightofSvg,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: valueColor,
                fontFamily: 'DMSans',
                fontSize: 16,
                fontWeight: FontWeight.w400, // Regular
                height: 1.0, // 100% line height
                letterSpacing: 0,
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        if (vmin) rangeRow("Low:", lowOld, lowNew, valueColor),
        if (cmin) rangeRow("Low:", lowOld, lowNew, valueColor),
        const SizedBox(height: 6),
        if (vmax) rangeRow("High:", highOld, highNew, valueColor),
        if (cmax) rangeRow("High:", highOld, highNew, valueColor),
      ],
    ),
  );
}

Widget rangeRow(
  String label,
  String oldValue,
  String newValue,
  Color valueColor,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      SizedBox(
        width: 50,
        child: Text(
          label,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
      Row(
        children: [
          Text(
            oldValue,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_right_alt, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            newValue,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );
}
