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
      this.onCancelAction});

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

    final isCompleted = normalizedStatus == 'completed';
    final toggleDisabled = disableToggle || isPending || isCompleted;

    final editDisabled = isRunning || isCompleted || isPending;
    final deleteDisabled = isRunning || isPending;
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
    final switchController = ValueNotifier<bool>(isActive);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFFE0E8F0) : const Color(0xFFE8E8E8),
        ),
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
              Icon(Icons.schedule_rounded,
                  size: 16,
                  color: isActive
                      ? const Color(0xFF004E7E)
                      : const Color(0xFF9E9E9E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_formatTo12h(startTime)} → ${_formatTo12h(endTime)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0XFF1A1A2E),
                  ),
                ),
              ),
              if (record.powerLossRecovery == true) ...[
                const _BlinkingPowerIcon(),
                const SizedBox(width: 6),
              ],
              _statusDot(status, isActive),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isCyclic
                ? _buildCyclicInfo(dH, dM, durationMin, onMin, offMin,
                    showRunTime, actualRunMin)
                : _buildTimeBasedInfo(dH, dM, showRunTime, actualRunMin),
          ),
          if (!disableToggle || showEditAction || showDeleteAction) ...[
            const Divider(height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!disableToggle) ...[
                  Text(isActive ? 'Stop' : 'Restart',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: toggleDisabled
                              ? const Color(0xFFB0B0B0)
                              : const Color(0xFF57636C))),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 25,
                    child: Tooltip(
                      message: toggleDisabled
                          ? (isPending
                              ? 'Pending — wait for device acknowledgement or republish from Manage'
                              : 'Schedule is completed')
                          : '',
                      triggerMode: toggleDisabled
                          ? TooltipTriggerMode.tap
                          : TooltipTriggerMode.manual,
                      showDuration: const Duration(seconds: 3),
                      preferBelow: false,
                      textStyle: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004E7E),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: toggleDisabled
                            ? null
                            : () async {
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
                            activeColor: toggleDisabled
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF34C759),
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
                  ),
                ],
                const Spacer(),
                if (showEditAction) ...[
                  Opacity(
                    opacity: editDisabled ? 0.4 : 1.0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: editDisabled ? null : () => onEdit?.call(record),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: editDisabled
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFEBF3FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.edit_outlined,
                            size: 16,
                            color: editDisabled
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFF004E7E)),
                      ),
                    ),
                  ),
                ],
                if (showEditAction && showDeleteAction)
                  const SizedBox(width: 8),
                if (showDeleteAction)
                  Opacity(
                    opacity: deleteDisabled ? 0.4 : 1.0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: deleteDisabled
                          ? null
                          : () async {
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
                          color: deleteDisabled
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16,
                            color: deleteDisabled
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFFE53935)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeBasedInfo(
      int dH, int dM, bool showRunTime, int actualRunMin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.all(Radius.circular(8)),
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
      int offMin, bool showRunTime, int actualRunMin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Duration + Run Time in one decoration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
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
    final normalizedStatus = status.toLowerCase();
    final isRunning = normalizedStatus == 'running';
    final isScheduled = normalizedStatus == 'scheduled';
    final isStopped = normalizedStatus == 'stopped';
    final isPending = normalizedStatus == 'pending';

    final badgeBgColor = isRunning // ← add this block
        ? const Color(0xFFE8F5E9)
        : isScheduled
            ? const Color(0xFFEBF3FE)
            : isPending
                ? const Color(0xFFFFF3E0)
                : isStopped
                    ? const Color(0xFFFFEBEE)
                    : isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5);

    final badgeFgColor = isRunning // ← add this block
        ? const Color(0xFF34C759)
        : isScheduled
            ? const Color(0xFF004E7E)
            : isPending
                ? const Color(0xFFFF9800)
                : isStopped
                    ? const Color(0xFFE53935)
                    : isActive
                        ? const Color(0xFF34C759)
                        : const Color(0xFF9E9E9E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: badgeFgColor),
          ),
          const SizedBox(width: 4),
          Text(
            _capitalize(status),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeFgColor,
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
