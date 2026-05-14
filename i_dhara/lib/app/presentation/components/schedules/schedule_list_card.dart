import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_dialogs.dart';

class ScheduleCard extends StatelessWidget {
  final Record record;
  final Future<bool> Function(Record record)? onDelete;
  final Future<bool> Function(Record record, bool enabled)? onToggle;
  final void Function(Record record)? onEdit;
  final Widget? leading;
  final bool showEditAction;
  final bool showDeleteAction;
  final bool disableToggle;
  final void Function(Record record)? onCancelAction;
  // Optional date label rendered inside the card above the time row.
  // Used by the manage page to show each record's per-date date string
  // ("14 May 2026"). Motor schedule tab passes null since its list is
  // already grouped under a date selector.
  final String? dateLabel;
  const ScheduleCard(
      {super.key,
      required this.record,
      this.onDelete,
      this.onToggle,
      this.onEdit,
      this.leading,
      this.showEditAction = true,
      this.showDeleteAction = true,
      this.disableToggle = false,
      this.onCancelAction,
      this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final startTime = record.startTime ?? '--:--';
    final endTime = record.endTime ?? '--:--';
    final durationMin = record.runtimeMinutes ?? 0;
    final dH = durationMin ~/ 60;
    final dM = durationMin % 60;
    final status = record.scheduleStatus ?? 'unknown';

    final isActive = record.enabled ?? false;

    final normalizedStatus = status.toLowerCase();
    final isPending = normalizedStatus == 'pending';

    final isRunning = normalizedStatus == 'running';
    final isPartial = normalizedStatus == 'partial';
    final isMissed = normalizedStatus == 'missed';

    final isCompleted = normalizedStatus == 'completed';
    final isFailed = normalizedStatus == 'failed';
    // Card chrome stays the same regardless of status — the status
    // badge already communicates terminal states (FAILED / COMPLETED /
    // PARTIAL / MISSED), so no extra grey-out is applied to the card
    // body. Action buttons handle their own show/hide per status below.
    // Partial / missed are terminal device-side outcomes — the schedule
    // window is over, so Stop/Restart and Edit are meaningless. Delete is
    // still allowed so the user can clean them up.
    final toggleDisabled = disableToggle ||
        isPending ||
        isCompleted ||
        isFailed ||
        isPartial ||
        isMissed;

    final editDisabled = isRunning ||
        isCompleted ||
        isPending ||
        isFailed ||
        isPartial ||
        isMissed;
    // FAILED rows are read-only from the per-motor card — no actions
    // (including delete) are exposed there. The Schedule Manage page
    // already handles bulk cleanup of failed rows, so the per-card
    // delete is redundant. RUNNING and PENDING are also excluded:
    // running schedules shouldn't be deleted mid-execution, and
    // pending ones haven't been ACK'd by the device yet.
    final deleteDisabled = isRunning || isPending || isFailed;
    final isCyclic = record.scheduleType == ScheduleType.CYCLIC;
    final onMin = isCyclic ? (record.cycleOnMinutes as num?)?.toInt() ?? 0 : 0;
    final offMin =
        isCyclic ? (record.cycleOffMinutes as num?)?.toInt() ?? 0 : 0;
    // Backend returns actual_run_time as minutes once the device starts
    // running this schedule. Surface it for any status that has elapsed
    // run time on the device — running / partial / completed.
    final actualRunMin = record.actualRunTime ?? 0;
    final showRunTime =
        (isRunning || isPartial || isCompleted) && actualRunMin > 0;
    // Surface the device-reported actual start / end window once the
    // backend has captured at least the start time. End may still be
    // null while the schedule is running — render an em dash for it.
    final actualStartRaw = record.actualStartTime?.trim() ?? '';
    final actualEndRaw = record.actualEndTime?.trim() ?? '';
    final showActualWindow = actualStartRaw.isNotEmpty;
    final switchController = ValueNotifier<bool>(isActive);

    final cardBorder =
        isActive ? const Color(0xFFE0E8F0) : const Color(0xFFE8E8E8);
    final timeIconColor =
        isActive ? const Color(0xFF004E7E) : const Color(0xFF9E9E9E);
    const timeTextColor = Color(0XFF1A1A2E);
    const infoBoxBg = Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Time range + status
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 2),
              ],
              Icon(Icons.schedule_rounded, size: 16, color: timeIconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    // Time keeps its full intrinsic width — no Flexible/
                    // ellipsis on it, since the user always needs to read
                    // the exact start → end window. Date takes the
                    // leftover space and truncates instead if the row is
                    // narrow.
                    Text(
                      '${_formatTo12h(startTime)} → ${_formatTo12h(endTime)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: timeTextColor,
                      ),
                    ),
                    if (dateLabel != null && dateLabel!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          dateLabel!,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (record.powerLossRecovery == true) ...[
                const _BlinkingPowerIcon(),
                const SizedBox(width: 6),
              ],
              _statusDot(status, isActive),
            ],
          ),

          if (showActualWindow) ...[
            const SizedBox(height: 4),
            Padding(
              // Indent under the schedule icon so the "Act" row reads as a
              // sub-detail of the planned time range above it.
              padding: const EdgeInsets.only(left: 22),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Act',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF004E7E),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatTo12h(actualStartRaw)} → ${actualEndRaw.isEmpty ? '—' : _formatTo12h(actualEndRaw)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isCyclic
                ? _buildCyclicInfo(dH, dM, durationMin, onMin, offMin,
                    showRunTime, actualRunMin, infoBoxBg)
                : _buildTimeBasedInfo(
                    dH, dM, showRunTime, actualRunMin, infoBoxBg),
          ),
          // Visibility flags: a button is rendered only when it's enabled
          // for this record's current status. Disabled actions are
          // hidden rather than greyed out so the card surface stays
          // clean — e.g. a FAILED row shows only the Delete button (so
          // the user can clean it up); a PENDING row shows no actions
          // at all until the device ACK lands.
          () {
            final showToggle = !disableToggle && !toggleDisabled;
            final showEdit = showEditAction && !editDisabled;
            final showDelete = showDeleteAction && !deleteDisabled;
            if (!showToggle && !showEdit && !showDelete) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(
                    height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (showToggle) ...[
                      Text(
                        isActive ? 'Stop' : 'Restart',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF57636C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 25,
                        child: GestureDetector(
                          onTap: () async {
                            final newValue = !switchController.value;
                            final success =
                                await showScheduleActionConfirmDialog(
                              context: context,
                              title: newValue
                                  ? 'Restart Schedule'
                                  : 'Stop Schedule',
                              description: newValue
                                  ? 'Are you sure you want to restart this schedule?'
                                  : 'Are you sure you want to stop this schedule?',
                              iconAssetPath: 'assets/images/schedule.svg',
                              buttonLabel: newValue ? 'Restart' : 'Stop',
                              isActive: newValue,
                              onConfirm: () async =>
                                  await onToggle?.call(record, newValue) ??
                                  false,
                              onCancelWhileWaiting: () =>
                                  onCancelAction?.call(record),
                            );
                            if (success) switchController.value = newValue;
                          },
                          child: AbsorbPointer(
                            child: AdvancedSwitch(
                              controller: switchController,
                              initialValue: isActive,
                              activeColor: const Color(0xFF34C759),
                              inactiveColor: const Color(0xFFE0E0E0),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                              width: 46,
                              height: 24,
                              enabled: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (showEdit)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => onEdit?.call(record),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFF004E7E),
                          ),
                        ),
                      ),
                    if (showEdit && showDelete) const SizedBox(width: 8),
                    if (showDelete)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () async {
                          await showScheduleActionConfirmDialog(
                            context: context,
                            title: 'Delete Schedule',
                            description:
                                'This schedule will be deleted permanently. Do you wish to go ahead?',
                            iconAssetPath: 'assets/images/schedule.svg',
                            buttonLabel: 'Delete',
                            onConfirm: () async =>
                                await onDelete?.call(record) ?? false,
                            onCancelWhileWaiting: () =>
                                onCancelAction?.call(record),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }(),
        ],
      ),
    );
  }

  Widget _buildTimeBasedInfo(
      int dH, int dM, bool showRunTime, int actualRunMin, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          _infoItem('Duration', '${dH}h ${dM.toString().padLeft(2, '0')}m'),
          if (showRunTime) ...[
            const SizedBox(width: 12),
            _infoItem('Run Time', _formatRunTime(actualRunMin)),
          ],
        ],
      ),
    );
  }

  Widget _buildCyclicInfo(int dH, int dM, int durationMin, int onMin,
      int offMin, bool showRunTime, int actualRunMin, Color bg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Duration + Run Time in one decoration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            // border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _infoItem('Duration', '${dH}h ${dM.toString().padLeft(2, '0')}m'),
              if (showRunTime) ...[
                const SizedBox(width: 12),
                _infoItem('Run Time', _formatRunTime(actualRunMin)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(8),
            // border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ON side
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ON',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF34C759))),
                      const SizedBox(width: 4),
                      Text('$onMin min',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34C759))),
                    ],
                  ),
                ),
                // Center vertical divider
                const VerticalDivider(
                    width: 1, thickness: 1, color: Color(0xFFFFE0B2)),
                // OFF side
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('OFF',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444))),
                      const SizedBox(width: 4),
                      Text('$offMin min',
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          TextSpan(
            text: value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(String status, bool isActive) {
    // Tailwind-aligned palette: (badge bg, text, dot). Each status uses
    // a distinct hue with three shades — light bg, dark-700 text, mid
    // dot — for legibility against the white card.
    final (Color bg, Color fg, Color dot) = switch (status.toLowerCase()) {
      'running' => (
          const Color(0xFFDCFCE7), // green-100
          const Color(0xFF15803D), // green-700
          const Color(0xFF22C55E), // green-500
        ),
      'scheduled' => (
          const Color(0xFFDBEAFE), // blue-100
          const Color(0xFF1D4ED8), // blue-700
          const Color(0xFF3B82F6), // blue-500
        ),
      'pending' => (
          const Color(0xFFFFEDD5), // orange-100
          const Color(0xFFC2410C), // orange-700
          const Color(0xFFF97316), // orange-500
        ),
      'stopped' => (
          const Color(0xFFFEE2E2), // red-100
          const Color(0xFFB91C1C), // red-700
          const Color(0xFFEF4444), // red-500
        ),
      'completed' => (
          const Color(0xFFF3F4F6), // gray-100
          const Color(0xFF374151), // gray-700
          const Color(0xFF9CA3AF), // gray-400
        ),
      'missed' => (
          const Color(0xFFFEF3C7), // amber-100
          const Color(0xFFB45309), // amber-700
          const Color(0xFFF59E0B), // amber-500
        ),
      'partial' => (
          const Color(0xFFFEF9C3), // yellow-100
          const Color(0xFFA16207), // yellow-700
          const Color(0xFFFACC15), // yellow-400
        ),
      'failed' => (
          const Color(0xFFFFE4E6), // rose-100
          const Color(0xFFBE123C), // rose-700
          const Color(0xFFE11D48), // rose-600
        ),
      // Unknown status → fall back to neutral / active-aware grey-green.
      _ => isActive
          ? (
              const Color(0xFFDCFCE7),
              const Color(0xFF15803D),
              const Color(0xFF22C55E),
            )
          : (
              const Color(0xFFF3F4F6),
              const Color(0xFF6B7280),
              const Color(0xFF9CA3AF),
            ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 4),
          Text(
            _capitalize(status),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTo12h(String raw) {
    String h, m;
    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length < 2) return raw;
      h = parts[0].padLeft(2, '0');
      m = parts[1].length >= 2
          ? parts[1].substring(0, 2)
          : parts[1].padLeft(2, '0');
    } else if (raw.length >= 3) {
      m = raw.substring(raw.length - 2);
      h = raw.substring(0, raw.length - 2).padLeft(2, '0');
    } else {
      return raw;
    }
    return '$h:$m';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Renders [actual_run_time] (in minutes) as either `13m` (under an hour)
  /// or `1h 13m` (one hour or more) so short runs read naturally without a
  /// noisy `0h` prefix.
  String _formatRunTime(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _BlinkingPowerIcon extends StatefulWidget {
  const _BlinkingPowerIcon();

  @override
  State<_BlinkingPowerIcon> createState() => _BlinkingPowerIconState();
}

class _BlinkingPowerIconState extends State<_BlinkingPowerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SvgPicture.asset(
        'assets/images/power.svg',
        width: 16,
        height: 16,
        colorFilter: const ColorFilter.mode(
          Color(0xFFFF9800),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
