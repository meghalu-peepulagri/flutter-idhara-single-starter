import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_utils.dart';

class MotorScheduleTab extends StatelessWidget {
  final MotorDetails? motorDetails;
  const MotorScheduleTab({super.key, this.motorDetails});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MotorScheduleController());
    controller.setMotorDetails(motorDetails);

    return Stack(
      children: [
        Obx(() {
          final isLoading = controller.isLoading.value;
          final schedules = controller.schedules;
          final totalRecords = schedules.length;

          if (isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF004E7E)));
          }
          if (schedules.isEmpty) {
            return _buildEmptyState();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                child: Text(
                  '$totalRecords / $totalRecords schedules',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF57636C),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildScheduleCard(schedules[i]),
                ),
              ),
            ],
          );
        }),
        Positioned(
          right: 4,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'schedule_fab',
            onPressed: controller.navigateToCreateSchedule,
            backgroundColor: const Color(0xFF004E7E),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  Widget _buildScheduleCard(Record record) {
    final startTime = record.startTime ?? '--:--';
    final endTime = record.endTime ?? '--:--';
    final durationMin = record.runtimeMinutes ?? 0;
    final dH = durationMin ~/ 60;
    final dM = durationMin % 60;
    final status = record.scheduleStatus ?? 'unknown';
    final isActive = status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'scheduled';
    final isOneTime = record.scheduleType?.toLowerCase() == 'one_time';

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
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF14181B)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
              _statusDot(status, isActive),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
            thickness: 1,
          ),
          Row(
            children: [
              // Runtime
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 13, color: Color(0xFF57636C)),
                        const SizedBox(width: 4),
                        Text('Runtime',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: const Color(0xFF57636C))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${dH}h ${dM.toString().padLeft(2, '0')}m',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14181B))),
                  ],
                ),
              ),
              const Spacer(),
              const Expanded(child: SizedBox()),
              // Time type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: Color(0xFF57636C)),
                        const SizedBox(width: 4),
                        Text('Time',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: const Color(0xFF57636C))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(isOneTime ? 'One Time' : 'Time Based',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14181B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Days + Next run
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
              else
                const Expanded(child: SizedBox()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 14,
                      color: isActive
                          ? const Color(0xFFFFA500)
                          : const Color(0xFF9E9E9E)),
                  const SizedBox(width: 3),
                  Text(
                    isActive ? 'Next: ${_formatTo12h(startTime)}' : 'Paused',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF004E7E)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
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
                height: 24,
                child: Switch(
                  value: isActive,
                  onChanged: (_) {
                    // TODO: toggle schedule enable/disable
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF34C759),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  // TODO: delete schedule
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
