import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/dialogs/popup_dialog.dart';
import 'package:i_dhara/app/core/utils/schedule_utils/schedule_utils.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class ScheduleCard extends StatelessWidget {
  final Record record;
  final VoidCallback? onDelete;
  const ScheduleCard({super.key, required this.record, this.onDelete});

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
    final isCyclic = record.scheduleType?.toLowerCase() == 'cyclic';
    final isRepeated = record.repeat == 1;
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
          const SizedBox(height: 10),
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
                  if (isRepeated) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Weekly',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF004E7E))),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Days
          Row(
            children: [
              if (record.daysOfWeek != null && record.daysOfWeek!.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: record.daysOfWeek!.map((d) {
                      final label =
                          (d >= 0 && d < dayLabels.length) ? dayLabels[d] : '?';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FE),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                const Color(0xFF004E7E).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(label,
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004E7E))),
                      );
                    }).toList(),
                  ),
                )
            ],
          ),

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
                    // TODO: toggle schedule enable/disable
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
                onTap: () {
                  // TODO: edit schedule
                },
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
                    builder: (_) => PopupDialog(
                      title: 'Delete Schedule',
                      description:
                          'This schedule will be deleted permanently. Do you wish to go ahead?',
                      iconAssetPath: 'assets/images/schedule.svg',
                      buttonlable: 'Delete',
                      onDelete: () {
                        Navigator.pop(context);
                        SharedPreference.setscheduleid(record.id ?? 0);
                        onDelete?.call();
                      },
                      onCancel: () => Navigator.pop(context),
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

  Widget _statusDot(String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
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
              color:
                  isActive ? const Color(0xFF34C759) : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _capitalize(status),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  isActive ? const Color(0xFF34C759) : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTo12h(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    return '$hour:$min $period';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
