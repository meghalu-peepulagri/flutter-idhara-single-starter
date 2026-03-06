import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart'
    as motor_model;
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_utils.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class MotorScheduleTab extends StatefulWidget {
  final MotorDetails? motorDetails;
  const MotorScheduleTab({super.key, this.motorDetails});

  @override
  State<MotorScheduleTab> createState() => _MotorScheduleTabState();
}

class _MotorScheduleTabState extends State<MotorScheduleTab> {
  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;

  List<Record> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _listenScheduleAck();
  }

  @override
  void dispose() {
    _scheduleAckSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await _scheduleRepo.getScheduleList(1, 50);
      if (mounted) {
        setState(() {
          _schedules = response?.data?.records ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolveIdentifier() {
    final starter = widget.motorDetails?.starter;
    final mac = starter?.macAddress?.trim() ?? '';
    if (mac.isNotEmpty) return mac;
    return starter?.pcbNumber?.trim() ?? '';
  }

  void _listenScheduleAck() {
    _scheduleAckSubscription = _mqttService.scheduleAckStream.listen((ack) {
      if (!mounted) return;
      final currentId = _resolveIdentifier();
      final ackId = (ack['topic'] ?? '').toString();
      if (currentId.isNotEmpty && ackId != currentId) return;

      final status = ack['status'] as int? ?? 0;
      if (status == 1) {
        getsuccessSnackBar('Schedule created successfully');
        _fetchSchedules();
      } else {
        geterrorSnackBar('Schedule creation failed');
      }
    });
  }

  void _navigateToCreateSchedule() {
    final details = widget.motorDetails;
    final motor = motor_model.Motor(
      id: details?.id,
      name: details?.name,
      aliasName: details?.aliasName,
      starter: details?.starter != null
          ? motor_model.Starter(
              id: details!.starter!.id,
              name: details.starter!.name,
              macAddress: details.starter!.macAddress,
              pcbNumber: details.starter!.pcbNumber,
              starterNumber: details.starter!.starterNumber,
            )
          : null,
    );
    Get.toNamed(
      Routes.schedule,
      arguments: {'motor': motor},
    )?.then((_) {
      _fetchSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildListView();
  }

  Widget _buildListView() {
    return Stack(
      children: [
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF004E7E)))
            : _schedules.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _fetchSchedules,
                    color: const Color(0xFF004E7E),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                      itemCount: _schedules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildScheduleCard(_schedules[i]),
                    ),
                  ),
        Positioned(
          right: 4,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'schedule_fab',
            onPressed: _navigateToCreateSchedule,
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
    final isOneTime = record.scheduleType?.toLowerCase() == 'one_time';
    final typeLabel = isOneTime ? 'One Time' : 'Cyclic';
    final typeColor =
        isOneTime ? const Color(0xFF2F80ED) : const Color(0xFFFFA500);
    final startTime = record.startTime ?? '--:--';
    final endTime = record.endTime ?? '--:--';
    final durationMin = record.runtimeMinutes ?? 0;
    final dH = durationMin ~/ 60;
    final dM = durationMin % 60;
    final powerOn = record.powerLossRecovery == true;
    final status = record.scheduleStatus ?? 'unknown';
    final isActive = status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'scheduled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? typeColor.withValues(alpha: 0.3)
              : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _typeBadge(typeLabel, typeColor, isOneTime),
              _statusBadge(status, isActive),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _infoTile(Icons.play_circle_outline_rounded, 'Start',
                    _formatApiTime(startTime), const Color(0xFF004E7E))),
            const SizedBox(width: 10),
            Expanded(
                child: _infoTile(Icons.stop_circle_outlined, 'End',
                    _formatApiTime(endTime), const Color(0xFF004E7E))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _infoTile(
                    Icons.timer_outlined,
                    'Duration',
                    '${dH}h ${dM.toString().padLeft(2, '0')}m',
                    const Color(0xFF004E7E))),
            const SizedBox(width: 10),
            Expanded(
                child: _infoTile(
                    Icons.power_settings_new_rounded,
                    'Power Recovery',
                    powerOn ? 'ON' : 'OFF',
                    powerOn ? Colors.green : Colors.red)),
          ]),
          if (!isOneTime &&
              record.daysOfWeek != null &&
              record.daysOfWeek!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              children: record.daysOfWeek!.map((d) {
                final label =
                    (d >= 0 && d < dayLabels.length) ? dayLabels[d] : '?';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF004E7E))),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeBadge(String label, Color color, bool isOneTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isOneTime ? Icons.event_outlined : Icons.repeat_rounded,
            size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _statusBadge(String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _capitalize(status),
        style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.green : Colors.grey),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 10, color: const Color(0xFF57636C))),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF14181B))),
        ]),
      ]),
    );
  }

  String _formatApiTime(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
