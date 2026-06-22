import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_logs_sheet.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
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

  // Inline cap-reached label visibility. Only flips to true on FAB tap when
  // the per-date schedule cap is hit, then auto-hides after ~1.5s.
  bool _showCapMessage = false;
  Timer? _capMessageTimer;

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  @override
  void initState() {
    super.initState();
    _controller = Get.put(MotorScheduleController());
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    _dateRange = List.generate(30, (i) => todayNorm.add(Duration(days: i - 7)));

    // Always reset to today + clear filter when this tab mounts so that
    // tab-switch and page-refresh always show today's unfiltered schedules.
    final needsReset = _controller.selectedDate.value != todayNorm ||
        _controller.selectedFilter.value.isNotEmpty;
    if (needsReset) {
      _controller.selectedDate.value = todayNorm;
      _controller.selectedFilter.value = '';
      _controller.fetchSchedules();
    }

    // Scroll to selected date + rebuild dots on every fetch (loading path)
    ever(_controller.isLoading, (bool loading) {
      if (!loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedDate();
          _updateDateBars();
        });
      }
    });

    // Scroll to selected date + rebuild dots on refresh path
    ever(_controller.isRefreshing, (bool refreshing) {
      if (!refreshing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedDate();
          _updateDateBars();
        });
      }
    });

    // Handle case where controller already has data when widget mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
      _updateDateBars();
    });

    // Every time the user lands on the schedule tab from another tab,
    // reset to today's date with no filter so the list shows everything.
    // The controller has its own ever() that fires fetchSchedules() on
    // tab switch — and it's registered before this one, so it would run
    // with the stale filter. Clearing first AND firing our own fetch
    // ensures the very next fetch sees the cleared state and the list
    // refreshes to "all" on the first switch back, not the second.
    ever(Get.find<AnalyticsController>().selectedTabIndex, (int index) {
      if (!mounted || index != 1) return;
      final now = DateTime.now();
      final nowNorm = DateTime(now.year, now.month, now.day);
      if (_controller.selectedDate.value != nowNorm ||
          _controller.selectedFilter.value.isNotEmpty) {
        _controller.selectedDate.value = nowNorm;
        _controller.selectedFilter.value = '';
        _controller.fetchSchedules();
      }
    });
  }

  void _updateDateBars() {
    if (!mounted) return;
    setState(() {
      // Clear stale dots so deleted/updated schedules don't leave ghost colors.
      _controller.dateBars.clear();
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

  /// The device only holds a rolling 3-day window — today, today+1, today+2.
  /// A PENDING schedule dated beyond that window is "locked": it can't be
  /// synced until the earlier dates complete and the window rolls forward.
  /// The card uses this to show the locked note and hide the Resync action.
  bool _isResyncLocked(record) {
    final code = record.scheduleStartDate as int?;
    if (code == null || code <= 0) return false;
    final now = DateTime.now();
    final windowEnd = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 2));
    return _yymmddToDate(code).isAfter(windowEnd);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return const Color(0xFF228B22); // green
      case 'PENDING':
        return const Color(0xFFEF9F27); // orange
      case 'SCHEDULED':
        return const Color(0xFF85B7EB); // light blue
      case 'STOPPED':
        return const Color(0xFFE24B4A); // red
      case 'COMPLETED':
        return const Color(0xFF2563EB); // strong blue (success / done)
      case 'PARTIAL':
        return const Color(0xFFF59E0B); // amber (distinct from Scheduled blue)
      case 'MISSED':
        return const Color(0xFF94A3B8); // gray (inactive / skipped)
      case 'FAILED':
        return const Color(0xFFB91C1C); // dark red (distinct from Stopped's bright red)
      default:
        // Unknown / not-yet-set status → neutral gray so it doesn't
        // collide with any other legend color.
        return const Color(0xFFCBD5E1);
    }
  }

  void _scrollToDate(int index) {
    if (!mounted || !_dateScrollController.hasClients) return;
    const itemWidth = 58.0; // 48 width + ~10 margin/padding
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _dateScrollController.animateTo(
      offset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSelectedDate() {
    if (!mounted) return;
    final selected = _controller.selectedDate.value;
    final index = _dateRange.indexWhere((d) => d == selected);
    if (index != -1) {
      _scrollToDate(index);
    } else {
      // Fallback: scroll to today (index 7)
      _scrollToDate(7);
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _capMessageTimer?.cancel();
    super.dispose();
  }

  /// Handler for the per-card Resync action on PENDING rows. Calls the
  /// backend `/motor-schedules/bulk/republish` API (the same endpoint the
  /// manage page's bulk resync uses) with this record's object id; the
  /// backend publishes to the device. Returns true once the POST completes
  /// so the card's confirm dialog can close itself.
  Future<bool> _resyncSingleSchedule(record) async {
    return _controller.republishSchedulesViaApi([record]);
  }

  /// Briefly surface the "Max 4 reached" label next to the FAB. Each tap
  /// resets the timer so consecutive taps keep the label visible without
  /// stacking it. Auto-hides after 1.5s.
  void _flashCapMessage() {
    _capMessageTimer?.cancel();
    setState(() => _showCapMessage = true);
    _capMessageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showCapMessage = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEAF2FB),
            Color(0xFFF5F7FA),
          ],
        ),
      ),
      child: Stack(
        children: [
          Obx(() {
            final isLoading = _controller.isLoading.value;
            final isRefreshing = _controller.isRefreshing.value;
            final isLoadingMore = _controller.isHasMoreLoading.value;
            final schedules = _controller.schedules;
            final totalRecords = _controller.totalRecords.value;
            final selectedDate = _controller.selectedDate.value;

            // Header (count + Manage + filter) and the date strip stay
            // mounted across loads. Only the schedule-list area below
            // swaps between the lottie loader, empty state, and list —
            // so picking a date doesn't unmount the strip the user just
            // tapped on.

            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Row(
                      children: [
                        Text(
                          '$totalRecords schedules',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF57636C),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _controller.navigateToScheduleManage,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF004E7E)
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: Color(0xFF004E7E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Manage',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF004E7E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final hasFilter =
                              _controller.selectedFilter.value.isNotEmpty;
                          return GestureDetector(
                            onTap: () => _showFilterSheet(context),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: hasFilter
                                        ? const Color(0xFF004E7E)
                                        : const Color(0xFFEBF3FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: hasFilter
                                        ? Colors.white
                                        : const Color(0xFF004E7E),
                                  ),
                                ),
                                if (hasFilter)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '1',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  _buildDateStrip(selectedDate),
                  Expanded(
                    child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 50, right: 50),
                          child: Center(child: AppLottieLoading()),
                        )
                      : Skeletonizer(
                      enabled: isRefreshing,
                      child: schedules.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                child: _buildEmptyState(),
                              ),
                            ],
                          )
                        : ListView.separated(
                            controller: _controller.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                            itemCount:
                                schedules.length + (isLoadingMore ? 1 : 0),
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
                                // Beyond the device's rolling 3-day window →
                                // show the locked note + hide Resync until the
                                // earlier dates complete.
                                isResyncLocked:
                                    _isResyncLocked(schedules[i]),
                                // Tapping the card body (away from the
                                // action pills) opens the per-schedule
                                // logs bottom sheet.
                                onTap: (r) {
                                  final oid = r.id ?? 0;
                                  if (oid <= 0) return;
                                  showSingleScheduleLogsSheet(
                                    context,
                                    objectId: oid,
                                  );
                                },
                                onDelete: (record) {
                                  final s = (record.scheduleStatus ?? '')
                                      .toUpperCase();
                                  // PENDING / FAILED never reached the
                                  // device, so skip MQTT and call the
                                  // backend DELETE directly.
                                  if (s == 'PENDING' || s == 'FAILED') {
                                    return _controller
                                        .deleteScheduleApiOnly(record);
                                  }
                                  return _controller.deleteSchedule(record);
                                },
                                onToggle: _controller.toggleSchedule,
                                onEdit: _controller.navigateToEditSchedule,
                                onSync: (record) => _resyncSingleSchedule(record),
                                onCancelAction: (record) =>
                                    _controller
                                        .cancelPendingScheduleAction(record),
                                // Cancel during a Resync stops the T:23
                                // republish retry loop instead of the
                                // T:24 action loop.
                                onCancelSync: (_) => _controller
                                    .cancelInFlightScheduleOperation(),
                              );
                            },
                          ),
                    ),
                  ),
                ],
              );
          }),
          Positioned(
            right: 4,
            bottom: 16,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Obx(() {
                // Touch the schedules list so Obx rebuilds when status
                // changes flip rows in/out of the "active" count.
                final _ = _controller.schedules.length;
                final isCapReached = _controller.activeScheduleCount >=
                    MotorScheduleController.kMaxSchedulesPerDate;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Inline cap label — only visible for ~1.5s after the
                    // user taps the FAB while the cap is reached.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: (isCapReached && _showCapMessage)
                          ? Padding(
                              key: const ValueKey('cap-msg'),
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Max ${MotorScheduleController.kMaxSchedulesPerDate} schedules per date reached',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDB3B2A),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('cap-msg-empty')),
                    ),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCapReached
                              ? const [
                                  Color(0xFFB0B8C4),
                                  Color(0xFF94A3B8),
                                ]
                              : const [
                                  Color(0xFF004E7E),
                                  Color(0xFF3686AF),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isCapReached ? 0.12 : 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        heroTag: 'schedule_fab',
                        onPressed: isCapReached
                            ? _flashCapMessage
                            : _controller.navigateToCreateSchedule,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    const filters = [
      {'label': 'All', 'value': ''},
      {'label': 'Pending', 'value': 'PENDING'},
      {'label': 'Scheduled', 'value': 'SCHEDULED'},
      {'label': 'Running', 'value': 'RUNNING'},
      {'label': 'Stopped', 'value': 'STOPPED'},
      {'label': 'Partial', 'value': 'PARTIAL'},
      {'label': 'Completed', 'value': 'COMPLETED'},
      {'label': 'Missed', 'value': 'MISSED'},
      {'label': 'Failed', 'value': 'FAILED'},
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
              // Title + close button row. Close icon mirrors the
              // motor_mode_info_sheet / schedule_manage_page bottom sheets
              // so the dismiss control is consistent across the app.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter by Status',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Flexible + scroll so the now-9 filter rows scroll inside the
              // sheet's existing height instead of overflowing it.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
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
                ),
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
                // Without `opaque`, the GestureDetector only catches taps
                // on the small day-name text and the 32-wide circle — the
                // empty padding inside the 48-wide cell silently swallows
                // taps, which is why tapping a date sometimes needs 3–4
                // tries to register.
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_controller.selectedDate.value == date) {
                    _scrollToDate(i);
                    return;
                  }
                  _controller.selectedDate.value = date;
                  _controller.fetchSchedules();
                  _scrollToDate(i);
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
              _legendItem(const Color(0xFFEF9F27), 'Pending'),
              const SizedBox(width: 12),
              _legendItem(const Color(0xFF85B7EB), 'Scheduled'),
              const SizedBox(width: 12),
              _legendItem(const Color(0xFF228B22), 'Running'),
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
