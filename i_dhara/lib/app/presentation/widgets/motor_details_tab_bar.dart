import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/motor_details/motor_details_controller.dart';

class MotorDetailsTabBar extends StatelessWidget {
  final AnalyticsController controller;

  const MotorDetailsTabBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            _buildTab(
              context,
              'Mode',
              0,
              'assets/images/Mode.svg',
            ),
            _buildTab(
              context,
              'Analytics',
              1,
              'assets/images/Graph.svg',
            ),
            _buildTab(
              context,
              'Logs',
              2,
              'assets/images/Logs.svg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
      BuildContext context, String label, int index, String svgPath) {
    return Expanded(
      child: InkWell(
        onTap: () => controller.onTabChanged(index),
        borderRadius: BorderRadius.circular(8.0),
        child: Obx(() {
          final isSelected = controller.selectedTabIndex.value == index;
          return Container(
            // duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF004E7E)
                        : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: isSelected
                        ? const Color(0xFF004E7E)
                        : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
