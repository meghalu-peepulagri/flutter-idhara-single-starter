import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:i_dhara/app/presentation/components/graphs/motor_run_time_graph_card.dart';
import '../../modules/motor_details/motor_details_controller.dart';

class MotorRuntimeTab extends StatelessWidget {
  final AnalyticsController controller;

  const MotorRuntimeTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      shrinkWrap: true,
      children: [
        _buildDateCard(context),
        const SizedBox(height: 12),
        MotorRuntimeGraphWidget(
          selectedDateRange: controller.daterange,
        ),
        // const SizedBox(height: 16),
        // PowerGraphWidget(
        //   selectedDateRange: controller.daterange,
        // ),
      ],
    );
  }

  Widget _buildDateCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => controller.leftClick(),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF004E7E),
                  size: 18.0,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final selectedDate =
                    controller.daterange.first ?? DateTime.now();
                return Column(
                  children: [
                    Text(
                      DateFormat('EEEE').format(selectedDate),
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF6B7280),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF004E7E),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }),
            ),
            Obx(() {
              final selectedDate = controller.daterange.first ?? DateTime.now();
              final today = DateTime.now();
              final isToday = selectedDate.year == today.year &&
                  selectedDate.month == today.month &&
                  selectedDate.day == today.day;

              return GestureDetector(
                onTap: isToday ? null : () => controller.rightClick(),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: isToday
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF004E7E),
                    size: 18.0,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
