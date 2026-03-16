import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MotorScheduleTab extends StatefulWidget {
  const MotorScheduleTab({super.key});

  @override
  State<MotorScheduleTab> createState() => _MotorScheduleTabState();
}

class _MotorScheduleTabState extends State<MotorScheduleTab> {
  late final MotorScheduleController _controller;
  late final Rx<DateTime> _selectedDate;
  late final List<DateTime> _dateRange;

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MotorScheduleController());
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    _selectedDate = todayNorm.obs;
    _dateRange = List.generate(30, (i) => todayNorm.add(Duration(days: i - 7)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          final isLoading = _controller.isLoading.value;
          final isRefreshing = _controller.isRefreshing.value;
          final isLoadingMore = _controller.isHasMoreLoading.value;
          final schedules = _controller.schedules;
          final totalRecords = _controller.totalRecords.value;
          final selectedDate = _selectedDate.value;

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
                _buildDateStrip(selectedDate),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
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
                  child: ListView.separated(
                    controller: _controller.scrollController,
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
                        onDelete: _controller.deleteSchedule,
                        onToggle: _controller.toggleSchedule,
                        onEdit: _controller.navigateToEditSchedule,
                      );
                    },
                  ),
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
                onPressed: _controller.navigateToCreateSchedule,
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

  Widget _buildDateStrip(DateTime selectedDate) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        itemCount: _dateRange.length,
        itemBuilder: (ctx, i) {
          final date = _dateRange[i];
          final isSelected = date == selectedDate;
          final isToday = date == todayNorm;
          final isPast = date.isBefore(todayNorm);

          return GestureDetector(
            onTap: () => _selectedDate.value = date,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected
                    ? null
                    : isToday
                        ? const Color(0xFFEBF3FE)
                        : isPast
                            ? const Color(0xFFF8FAFC)
                            : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isToday
                            ? const Color(0xFFBFD9F0)
                            : isPast
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFDCE8F5),
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF004E7E).withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayNames[date.weekday % 7],
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white70
                          : isPast
                              ? const Color(0xFFB0B8C4)
                              : isToday
                                  ? const Color(0xFF3686AF)
                                  : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.dmSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isPast
                              ? const Color(0xFFB0B8C4)
                              : const Color(0xFF004E7E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthNames[date.month - 1],
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white60
                          : isPast
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded,
              size: 56,
              color: const Color(0xFF004E7E).withValues(alpha: 0.3)),
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
