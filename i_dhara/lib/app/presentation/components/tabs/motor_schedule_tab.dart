import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MotorScheduleTab extends StatelessWidget {
  const MotorScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MotorScheduleController());

    return Stack(
      children: [
        Obx(() {
          final isLoading = controller.isLoading.value;
          final isRefreshing = controller.isRefreshing.value;
          final schedules = controller.schedules;
          final totalRecords = controller.totalRecords.value;

          // First load — show lottie
          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 50, right: 50),
              child: Center(child: AppLottieLoading()),
            );
          }

          if (schedules.isEmpty) {
            return _buildEmptyState();
          }

          return Skeletonizer(
            enabled: isRefreshing,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                  child: Text(
                    '${schedules.length} / $totalRecords schedules',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF57636C),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final isLoadingMore = controller.isHasMoreLoading.value;
                    return ListView.separated(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                      itemCount: schedules.length + (isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i == schedules.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          );
                        }
                        return ScheduleCard(
                          key: ValueKey(
                              schedules[i].scheduleId ?? schedules[i].id ?? i),
                          record: schedules[i],
                          onDelete: controller.deleteSchedule,
                          onToggle: controller.toggleSchedule,
                          onEdit: controller.navigateToEditSchedule,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        }),
        Positioned(
          right: 4,
          bottom: 16,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF004E7E),
                    Color(0xFF3686AF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'schedule_fab',
                onPressed: controller.navigateToCreateSchedule,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded,
              size: 56, color: const Color(0xFF004E7E).withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('No Schedules',
              style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF14181B))),
          const SizedBox(height: 4),
          Text('Tap + to create a new schedule',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: const Color(0xFF57636C))),
        ],
      ),
    );
  }
}
