import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/dialogs/popup_dialog.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';

class ScheduleCard extends StatelessWidget {
  final Record record;
  final Future<bool> Function(Record record)? onDelete;
  final Future<bool> Function(Record record, bool enabled)? onToggle;
  final void Function(Record record)? onEdit;
  final Widget? leading;
  final bool showEditAction;
  final bool showDeleteAction;
  // Called when the user taps Cancel in the confirm dialog. Used to abort
  // any in-flight MQTT retry loop for this schedule's stop/restart/delete.
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
      this.onCancelAction});

  @override
  Widget build(BuildContext context) {
    final startTime = record.startTime ?? '--:--';
    final endTime = record.endTime ?? '--:--';
    final durationMin = record.runtimeMinutes ?? 0;
    final dH = durationMin ~/ 60;
    final dM = durationMin % 60;
    final status = record.scheduleStatus ?? 'unknown';
    final isActive = status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'scheduled';
    final isCyclic = record.scheduleType == ScheduleType.CYCLIC;
    final onMin = isCyclic ? (record.cycleOnMinutes as num?)?.toInt() ?? 0 : 0;
    final offMin =
        isCyclic ? (record.cycleOffMinutes as num?)?.toInt() ?? 0 : 0;
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
              _statusDot(status, isActive),
            ],
          ),
          // const SizedBox(height: 8),
          // const Divider(height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
          // ── Info section ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isCyclic
                ? _buildCyclicInfo(dH, dM, durationMin, onMin, offMin)
                : _buildTimeBasedInfo(dH, dM, durationMin),
          ),
          const Divider(height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
          const SizedBox(height: 8),

          Row(
            children: [
              Text('Enable',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF57636C))),
              const SizedBox(width: 8),
              SizedBox(
                height: 25,
                child: GestureDetector(
                  onTap: () {
                    final newValue = !switchController.value;
                    // Single-pop guard: cancel-tap and confirm-completion both
                    // try to pop the dialog. Without this flag the second pop
                    // fires after the dialog is already gone and tears down
                    // the underlying schedules screen → black screen.
                    bool dismissed = false;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => PopupDialog(
                        title: newValue ? 'Restart Schedule' : 'Stop Schedule',
                        description: newValue
                            ? 'Are you sure you want to restart this schedule?'
                            : 'Are you sure you want to stop this schedule?',
                        iconAssetPath: 'assets/images/schedule.svg',
                        buttonlable: newValue ? 'Restart' : 'Stop',
                        isactive: newValue,
                        onDelete: () async {
                          final success =
                              await onToggle?.call(record, newValue) ?? false;
                          if (dismissed) return;
                          dismissed = true;
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (success) switchController.value = newValue;
                        },
                        onCancel: () {
                          if (dismissed) return;
                          dismissed = true;
                          // Abort the in-flight MQTT retry loop before
                          // dismissing — otherwise stop/restart payloads keep
                          // being republished after the user backs out.
                          onCancelAction?.call(record);
                          Navigator.pop(dialogCtx);
                        },
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    child: AdvancedSwitch(
                      controller: switchController,
                      initialValue: isActive,
                      activeColor: const Color(0xFF34C759),
                      inactiveColor: const Color(0xFFE0E0E0),
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      width: 46,
                      height: 24,
                      enabled: true,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (showEditAction) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => onEdit?.call(record),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: Color(0xFF004E7E)),
                  ),
                ),
              ],
              if (showEditAction && showDeleteAction) const SizedBox(width: 8),
              if (showDeleteAction)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    // Single-pop guard: cancel-tap and confirm-completion both
                    // try to pop the dialog. Without this flag the second pop
                    // fires after the dialog is already gone and tears down
                    // the underlying schedules screen → black screen.
                    bool dismissed = false;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => PopupDialog(
                        title: 'Delete Schedule',
                        description:
                            'This schedule will be deleted permanently. Do you wish to go ahead?',
                        iconAssetPath: 'assets/images/schedule.svg',
                        buttonlable: 'Delete',
                        onDelete: () async {
                          await onDelete?.call(record);
                          if (dismissed) return;
                          dismissed = true;
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                        },
                        onCancel: () {
                          if (dismissed) return;
                          dismissed = true;
                          // Abort the in-flight MQTT retry loop before
                          // dismissing — otherwise the delete payload keeps
                          // being republished after the user backs out.
                          onCancelAction?.call(record);
                          Navigator.pop(dialogCtx);
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Color(0xFFE53935)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBasedInfo(int dH, int dM, int durationMin) {
    final accSec = record.accumulatedOnSeconds ?? 0;
    final remainingMin = (durationMin - (accSec ~/ 60)).clamp(0, durationMin);
    final rH = remainingMin ~/ 60;
    final rM = remainingMin % 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Row(
            children: [
              _infoItem('Duration', '${dH}h ${dM.toString().padLeft(2, '0')}m'),
              const SizedBox(width: 12),
              _infoItem(
                  'Remaining', '${rH}h ${rM.toString().padLeft(2, '0')}m'),
            ],
          ),
        ),
        if (record.powerLossRecovery == true) ...[
          const SizedBox(height: 6),
          _powerRecoveryBadge(),
        ],
      ],
    );
  }

  Widget _buildCyclicInfo(
      int dH, int dM, int durationMin, int onMin, int offMin) {
    final accSec = record.accumulatedOnSeconds ?? 0;
    final runMin = accSec ~/ 60;
    final runH = runMin ~/ 60;
    final runM = runMin % 60;
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
              const SizedBox(width: 12),
              _infoItem(
                  'Run Time', '${runH}h ${runM.toString().padLeft(2, '0')}m'),
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
                      const Icon(Icons.local_fire_department_rounded,
                          size: 14, color: Color(0xFFFF9800)),
                      const SizedBox(width: 4),
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

  Widget _powerRecoveryBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.power_rounded, size: 11, color: Color(0xFFFF9800)),
            const SizedBox(width: 2),
            Text('Power Recovery',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9800))),
          ],
        ),
      );

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
}
