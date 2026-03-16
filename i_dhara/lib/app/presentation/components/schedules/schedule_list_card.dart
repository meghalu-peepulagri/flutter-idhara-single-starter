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
  const ScheduleCard(
      {super.key,
      required this.record,
      this.onDelete,
      this.onToggle,
      this.onEdit});

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
          const SizedBox(height: 8),
          _buildDayChips(record),
          const SizedBox(height: 8),
          const Divider(
            height: 0,
            thickness: 1.0,
            color: Color(0xFFECECEC),
          ),
          Row(
            children: [
              // Duration (always on the left)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: Color(0xFF57636C)),
                      const SizedBox(width: 4),
                      Text('Duration',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${dH}h ${dM.toString().padLeft(2, '0')}m',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A2E))),
                ],
              ),
              if (isCyclic)
                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFFECECEC),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
              // Center section: ON+OFF for cyclic, empty for time-based
              if (isCyclic)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ON
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF34C759),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text('ON',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('${onMin}min',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF34C759))),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // OFF
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text('OFF',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text('${offMin}min',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEF4444))),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              if (isCyclic)
                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFFECECEC),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
              // Type + Repeat
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCyclic ? 'Cyclic' : 'Time Based',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E))),
                  // if (isRepeated) ...[
                  //   const SizedBox(height: 4),
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 6, vertical: 2),
                  //     decoration: BoxDecoration(
                  //       color: const Color(0xFFEBF3FE),
                  //       borderRadius: BorderRadius.circular(4),
                  //     ),
                  //     child: Text('Weekly',
                  //         style: GoogleFonts.dmSans(
                  //             fontSize: 10,
                  //             fontWeight: FontWeight.w600,
                  //             color: const Color(0xFF004E7E))),
                  //   ),
                  // ],
                ],
              ),
            ],
          ),
          if (record.powerLossRecovery == true) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.power_rounded,
                          size: 11, color: Color(0xFFFF9800)),
                      const SizedBox(width: 4),
                      Text('Power Recovery',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF9800))),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
          ),

          // Row 4: Enable toggle + actions
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
                    bool isProcessing = false;
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
                          isProcessing = true;
                          try {
                            final success =
                                await onToggle?.call(record, newValue) ?? false;
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (success) switchController.value = newValue;
                          } finally {
                            isProcessing = false;
                          }
                        },
                        onCancel: () {
                          if (!isProcessing) Navigator.pop(dialogCtx);
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
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
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
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                      onCancel: () => Navigator.pop(dialogCtx),
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

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Use daysOfWeek directly from the API response (1=Mon ... 7=Sun)
  Set<int> _activeDayNumbers(Record record) => record.daysOfWeek?.toSet() ?? {};

  Widget _buildDayChips(Record record) {
    final activeDays = _activeDayNumbers(record);
    return Row(
      children: List.generate(7, (i) {
        final dayNum = i + 1; // 1=Mon...7=Sun
        final isActive = activeDays.contains(dayNum);
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFFEBF3FE) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF3686AF)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Text(
              _dayLabels[i],
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF004E7E)
                    : const Color(0xFFB0B8C4),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _statusDot(String status, bool isActive) {
    final normalizedStatus = status.toLowerCase();
    final isScheduled = normalizedStatus == 'scheduled';
    final isStopped = normalizedStatus == 'stopped';
    final badgeBgColor = isScheduled
        ? const Color(0xFFEBF3FE)
        : isStopped
            ? const Color(0xFFFFEBEE)
            : isActive
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFF5F5F5);
    final badgeFgColor = isScheduled
        ? const Color(0xFF004E7E)
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeFgColor,
            ),
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

  // Returns time in 24h format e.g. "16:55"
  // Handles both "16:55" and "1655" from API
  String _formatTo12h(String raw) {
    String h, m;
    if (raw.contains(':')) {
      final parts = raw.split(':');
      if (parts.length < 2) return raw;
      h = parts[0].padLeft(2, '0');
      m = parts[1].length >= 2 ? parts[1].substring(0, 2) : parts[1].padLeft(2, '0');
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
