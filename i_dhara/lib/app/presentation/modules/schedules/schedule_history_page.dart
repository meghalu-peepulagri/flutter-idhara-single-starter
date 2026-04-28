import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_history_model.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_history_controller.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _kPrimary = Color(0xFF004E7E);
const _kBg = Color(0xFFEBF3FE);

class ScheduleHistoryPage extends StatefulWidget {
  const ScheduleHistoryPage({super.key});

  @override
  State<ScheduleHistoryPage> createState() => _ScheduleHistoryPageState();
}

class _ScheduleHistoryPageState extends State<ScheduleHistoryPage> {
  late final String _tag;
  late final ScheduleHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _tag = 'schedule_history_${DateTime.now().microsecondsSinceEpoch}';
    _controller = Get.put(ScheduleHistoryController(), tag: _tag, permanent: false);
  }

  @override
  void dispose() {
    if (Get.isRegistered<ScheduleHistoryController>(tag: _tag)) {
      Get.delete<ScheduleHistoryController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildDateSelector(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                final isLoading = _controller.isLoading.value;
                final isRefreshing = _controller.isRefreshing.value;
                final isLoadingMore = _controller.isLoadingMore.value;
                final records = _controller.records;

                if (isLoading) {
                  return const Center(child: AppLottieLoading());
                }

                return Skeletonizer(
                  enabled: isRefreshing,
                  child: RefreshIndicator(
                    color: _kPrimary,
                    backgroundColor: Colors.white,
                    onRefresh: () => _controller.fetchHistory(isRefresh: true),
                    child: ListView(
                      controller: _controller.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      children: [
                        if (records.isEmpty)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(),
                          )
                        else ...[
                          ...records.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _HistoryRecordCard(record: r),
                              )),
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'Schedule Logs',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back_rounded, color: _kPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Obx(() {
      final fromDate = _controller.fromDate.value;
      final toDate = _controller.toDate.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB8CCE4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Date Range',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF005A96),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: _kPrimary),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: 'From Date',
                    date: fromDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(DateTime.now().year + 2),
                    onPicked: (d) => _controller.updateDateRange(from: d),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: _kPrimary),
                ),
                Expanded(
                  child: _DatePickerTile(
                    label: 'To Date',
                    date: toDate,
                    firstDate: fromDate,
                    lastDate: DateTime(DateTime.now().year + 2),
                    onPicked: (d) => _controller.updateDateRange(to: d),
                    labelColor: const Color(0xFF93A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE3EEF9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 40, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'No logs found',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF14181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try changing the date range',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date picker tile ────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onPicked,
    this.labelColor = const Color(0xFF004E7E),
  });

  final String label;
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onPicked;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF94A9C2), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        firstDate: firstDate,
        lastDate: lastDate,
        selectedDayHighlightColor: _kPrimary,
        selectedDayTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        todayTextStyle: const TextStyle(
            color: _kPrimary, fontWeight: FontWeight.w600),
        dayTextStyle: const TextStyle(
            color: Color(0xFF0F172A), fontWeight: FontWeight.w400),
        disabledDayTextStyle: const TextStyle(color: Color(0xFFB0B8C4)),
        weekdayLabelTextStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
            fontSize: 12),
        controlsTextStyle: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            fontSize: 14),
        lastMonthIcon:
            const Icon(Icons.chevron_left_rounded, color: _kPrimary),
        nextMonthIcon:
            const Icon(Icons.chevron_right_rounded, color: _kPrimary),
        okButtonTextStyle: const TextStyle(
            color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        cancelButtonTextStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 14),
      ),
      dialogSize: const Size(340, 350),
      value: [date],
      borderRadius: BorderRadius.circular(16),
    );
    if (results == null || results.isEmpty || results.first == null) return;
    onPicked(results.first!);
  }
}

// ─── History record card ──────────────────────────────────────────────────────

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({required this.record});
  final Record record;

  static const _statusColors = {
    'RUNNING': Color(0xFF16A34A),
    'COMPLETED': Color(0xFF2563EB),
    'STOPPED': Color(0xFFDC2626),
    'PENDING': Color(0xFFD97706),
    'SCHEDULED': Color(0xFF7C3AED),
  };

  Color _statusColor(String? status) =>
      _statusColors[(status ?? '').toUpperCase()] ?? const Color(0xFF6B7280);

  static String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--';
    final t = time.replaceAll(':', '');
    if (t.length == 4) return '${t.substring(0, 2)}:${t.substring(2)}';
    if (t.length == 3) return '${t.substring(0, 1)}:${t.substring(1)}';
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final status = (record.scheduleStatus ?? '').toUpperCase();
    final statusColor = _statusColor(status);
    final dateStr = record.createdAt != null
        ? DateFormat('dd MMM yyyy').format(record.createdAt!.toLocal())
        : '—';

    // Sort events chronologically
    final events = [...(record.events ?? [])]
      ..sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return -1;
        if (b.timestamp == null) return 1;
        return a.timestamp!.compareTo(b.timestamp!);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: type + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.scheduleType ?? '—',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text(
                            '${_formatTime(record.startTime)} → ${_formatTime(record.endTime)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: date + status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateStr,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Events list (always visible) ──
          if (events.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFEEF4FB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: events.map((e) => _EventRow(event: e)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final Event event;

  static const _eventColors = {
    'start': Color(0xFF16A34A),
    'stop': Color(0xFFDC2626),
    'complete': Color(0xFF2563EB),
    'error': Color(0xFFDC2626),
    'pause': Color(0xFFD97706),
  };

  Color _eventColor(String? name) {
    final key = (name ?? '').toLowerCase();
    for (final entry in _eventColors.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.event);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.event ?? '—',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          if (event.timestamp != null)
            Text(
              DateFormat('hh:mm:ss a').format(event.timestamp!.toLocal()),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}
