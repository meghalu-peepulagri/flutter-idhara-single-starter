import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/schedule_utils/schedule_utils.dart';
import 'package:i_dhara/app/data/models/schedules/single_schedule_model.dart'
    as logs;
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:intl/intl.dart';

const _kPrimary = Color(0xFF004E7E);

/// Opens a modal bottom sheet that fetches and renders one schedule's
/// run details via `GET /motor-schedules/{objectId}/history`. The
/// response carries the full schedule object plus its chronological
/// `events` array; we render them in the same layout the global
/// Schedule Logs page uses for a single history record (header with
/// type/time/status, then the events list).
Future<void> showSingleScheduleLogsSheet(
  BuildContext context, {
  required int objectId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SingleScheduleLogsSheet(objectId: objectId),
  );
}

class _SingleScheduleLogsSheet extends StatefulWidget {
  const _SingleScheduleLogsSheet({required this.objectId});
  final int objectId;

  @override
  State<_SingleScheduleLogsSheet> createState() =>
      _SingleScheduleLogsSheetState();
}

class _SingleScheduleLogsSheetState extends State<_SingleScheduleLogsSheet> {
  final _repo = ScheduleRepositoryImpl();
  late Future<logs.SingleScheduleLogsResponse?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getSingleScheduleLogs(widget.objectId);
  }

  void _retry() {
    setState(() {
      _future = _repo.getSingleScheduleLogs(widget.objectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Text(
                  'Schedule Logs',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
          ),
          const Divider(height: 1, color: Color(0xFFEEF4FB)),
          Expanded(
            child: FutureBuilder<logs.SingleScheduleLogsResponse?>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 50, right: 50),
                    child: Center(child: AppLottieLoading()),
                  );
                }
                if (snap.hasError || snap.data?.data == null) {
                  return _errorState(_retry);
                }
                final data = snap.data!.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _ScheduleRecordCard(data: data),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 30, color: Colors.red[600]),
          ),
          const SizedBox(height: 10),
          Text(
            'Couldn\'t load logs',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF14181B),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: _kPrimary),
            label: Text(
              'Retry',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Schedule record card (header + events in one card) ──────────────────────

class _ScheduleRecordCard extends StatelessWidget {
  const _ScheduleRecordCard({required this.data});
  final logs.Data data;

  static const _statusColors = <String, Color>{
    'RUNNING': Color(0xFF16A34A),
    'COMPLETED': Color(0xFF2563EB),
    'STOPPED': Color(0xFFDC2626),
    'PENDING': Color(0xFFD97706),
    'SCHEDULED': Color(0xFF7C3AED),
    'FAILED': Color(0xFFDC2626),
    'MISSED': Color(0xFF6B7280),
    'PARTIAL': Color(0xFFD97706),
  };

  Color _statusColor(String? status) =>
      _statusColors[(status ?? '').toUpperCase()] ?? const Color(0xFF6B7280);

  // Follows the phone's 12h/24h system setting via [formatScheduleClockRaw].
  static String _formatTime(BuildContext context, String? time) {
    if (time == null || time.isEmpty) return '--';
    return formatScheduleClockRaw(context, time);
  }

  /// Converts the backend's YYMMDD int (e.g. 260527 → 2026-05-27)
  /// to a local DateTime. Returns null for missing or malformed
  /// codes. Mirrors the card-side converter so the sheet header
  /// date matches the date label on the manage page card.
  static DateTime? _yymmddToDate(int? code) {
    if (code == null || code <= 0) return null;
    final yy = code ~/ 10000;
    final mm = (code % 10000) ~/ 100;
    final dd = code % 100;
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    return DateTime(2000 + yy, mm, dd);
  }

  @override
  Widget build(BuildContext context) {
    final status = (data.scheduleStatus ?? '').toUpperCase();
    final statusColor = _statusColor(status);
    // Header date = the schedule's RUN date (schedule_start_date),
    // not its creation timestamp. createdAt can fall on a different
    // calendar day than the run date (e.g. a schedule added late on
    // 26 May to run on 27 May), which made the sheet read "26 May"
    // while the card read "27 May". Falls back to createdAt only
    // when the run date is missing.
    final runDate = _yymmddToDate(data.scheduleStartDate);
    final String dateStr;
    if (runDate != null) {
      dateStr = DateFormat('dd MMM yyyy').format(runDate);
    } else if (data.createdAt != null) {
      dateStr = DateFormat('dd MMM yyyy').format(data.createdAt!.toLocal());
    } else {
      dateStr = '—';
    }

    // Oldest → newest so the chronological flow reads top-to-bottom,
    // matching the global history page layout.
    final events = [...(data.events ?? const <logs.Event>[])]..sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return -1;
        if (b.timestamp == null) return 1;
        return a.timestamp!.compareTo(b.timestamp!);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF4FB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 3,
            offset: const Offset(0, 1),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.scheduleType ?? '—',
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
                            '${_formatTime(context, data.startTime)} → ${_formatTime(context, data.endTime)}',
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
                    if (status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status == 'COMPLETED' ? 'ENDED' : status,
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
  final logs.Event event;

  static const _eventColors = <String, Color>{
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

  static String? _failureText(dynamic reason) {
    if (reason == null) return null;
    final text = reason.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  /// Turns raw event names like "CREATED" / "SCHEDULE_STARTED" into
  /// title case ("Created", "Schedule Started") for display.
  static String _titleCase(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    return raw
        .trim()
        .split(RegExp(r'[\s_]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.event);
    final failureText = _failureText(event.failureReason);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _titleCase(event.event),
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
          if (failureText != null)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 13, color: color),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      failureText,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
