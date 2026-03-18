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
  late final List<DateTime> _dateRange;
  final ScrollController _dateScrollController = ScrollController();

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  @override
  void initState() {
    super.initState();
    _controller = Get.put(MotorScheduleController());
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    _dateRange = List.generate(30, (i) => todayNorm.add(Duration(days: i - 7)));

    // Scroll to today + rebuild dots on every fetch (loading path)
    ever(_controller.isLoading, (bool loading) {
      if (!loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToToday();
          _updateDateBars();
        });
      }
    });

    // Scroll to today + rebuild dots on refresh path
    ever(_controller.isRefreshing, (bool refreshing) {
      if (!refreshing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToToday();
          _updateDateBars();
        });
      }
    });

    // Handle case where controller already has data when widget mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
      _updateDateBars();
    });
  }

  void _updateDateBars() {
    if (!mounted) return;
    setState(() {
      for (final record in _controller.schedules) {
        final startV = record.scheduleStartDate;
        final endV = record.scheduleEndDate;
        if (startV == null) continue;
        final start = _yymmddToDate(startV);
        final end = endV != null ? _yymmddToDate(endV) : start;
        final color = _statusColor(record.scheduleStatus ?? '');
        var d = start;
        while (!d.isAfter(end)) {
          (_controller.dateBars[d] ??= {}).add(color);
          d = d.add(const Duration(days: 1));
        }
      }
    });
  }

  DateTime _yymmddToDate(int v) {
    final yy = v ~/ 10000;
    final mm = (v % 10000) ~/ 100;
    final dd = v % 100;
    return DateTime(2000 + yy, mm, dd);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return const Color(0xFF228B22); // green
      case 'PENDING':
        return const Color(0xFFEF9F27); // orange
      case 'SCHEDULED':
        return const Color(0xFF85B7EB); // blue
      case 'STOPPED':
        return const Color(0xFFE24B4A); // red
      case 'COMPLETED':
        return const Color(0xFFEF9F27); // yellow
      default:
        return const Color(0xFF85B7EB);
    }
  }

  void _scrollToToday() {
    if (!mounted || !_dateScrollController.hasClients) return;
    const todayIndex = 7; // _dateRange starts 7 days before today
    const itemWidth = 58.0; // 52 width + 6 margin
    final screenWidth = MediaQuery.of(context).size.width;
    final offset =
        (todayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _dateScrollController.jumpTo(
      offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
    );
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
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
          final selectedDate = _controller.selectedDate.value;

          if (isLoading) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 50, right: 50),
              child: Center(child: AppLottieLoading()),
            );
          }

          return Skeletonizer(
            enabled: isRefreshing,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                  child: Row(
                    children: [
                      Text(
                        '${schedules.length} / $totalRecords schedules',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF57636C),
                        ),
                      ),
                      const Spacer(),
                      Obx(() {
                        final hasFilter =
                            _controller.selectedFilter.value.isNotEmpty;
                        return GestureDetector(
                          onTap: () => _showFilterSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: hasFilter
                                  ? const Color(0xFF004E7E)
                                  : const Color(0xFFEBF3FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: hasFilter
                                  ? Colors.white
                                  : const Color(0xFF004E7E),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                _buildDateStrip(selectedDate),
                Expanded(
                  child: schedules.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: _buildEmptyState(),
                            ),
                          ],
                        )
                      : ListView.separated(
                          controller: _controller.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                          itemCount: schedules.length + (isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
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
                              key: ValueKey(schedules[i].scheduleId ??
                                  schedules[i].id ??
                                  i),
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

  void _showFilterSheet(BuildContext context) {
    const filters = [
      {'label': 'All', 'value': ''},
      {'label': 'Pending', 'value': 'PENDING'},
      {'label': 'Running', 'value': 'RUNNING'},
      {'label': 'Stopped', 'value': 'STOPPED'},
      {'label': 'Scheduled', 'value': 'SCHEDULED'},
      {'label': 'Completed', 'value': 'COMPLETED'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Obx(() {
        final current = _controller.selectedFilter.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Filter by Status',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 14),
              Column(
                children: filters.map((f) {
                  final isSelected = current == f['value'];
                  return InkWell(
                    onTap: () {
                      _controller.selectedFilter.value = f['value']!;
                      _controller.fetchSchedules();
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              f['label']!,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF004E7E)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded,
                                size: 18, color: Color(0xFF004E7E)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateStrip(DateTime selectedDate) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        SizedBox(
          height: 74,
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _dateRange.length,
            itemBuilder: (ctx, i) {
              final date = _dateRange[i];
              final isSelected = date == selectedDate;
              final isToday = date == todayNorm;

              // All non-selected/non-today dates: same neutral color
              final labelColor = isSelected
                  ? const Color(0xFF185FA5)
                  : isToday
                      ? const Color(0xFFEF9F27)
                      : const Color(0xFF94A3B8);

              final numColor = isSelected
                  ? const Color(0xFF185FA5)
                  : isToday
                      ? const Color(0xFFEF9F27)
                      : const Color(0xFF0F172A);

              return GestureDetector(
                onTap: () {
                  _controller.selectedDate.value = date;
                  _controller.fetchSchedules();
                },
                child: SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[date.weekday % 7],
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: isSelected
                            ? const BoxDecoration(
                                color: Color(0xFF185FA5),
                                shape: BoxShape.circle,
                              )
                            : isToday
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFEF9F27),
                                      width: 2,
                                    ),
                                  )
                                : null,
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : numColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Dots: one per unique status color on this date
                      Builder(builder: (_) {
                        final colors = _controller.dateBars[date];
                        if (colors == null || colors.isEmpty) {
                          return const SizedBox(height: 5);
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: colors
                              .take(4)
                              .map((c) => Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1.5),
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                    ),
                                  ))
                              .toList(),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              _legendItem(const Color(0xFF228B22), 'Running'),
              const SizedBox(width: 12),
              _legendItem(const Color(0xFFEF9F27), 'Pending'),
              const SizedBox(width: 12),
              _legendItem(const Color(0xFF85B7EB), 'Scheduled'),
              const SizedBox(width: 12),
              _legendItem(const Color(0xFFE24B4A), 'Stopped'),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
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
