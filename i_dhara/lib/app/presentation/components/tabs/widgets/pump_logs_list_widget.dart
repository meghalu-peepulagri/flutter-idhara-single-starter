import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/motors/motor_logs_model.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/empty_logs_widget.dart';
import 'package:intl/intl.dart';

class PumpLogsListWidget extends StatelessWidget {
  final List<MotorLogs> logs;
  // Empty string means multi-filter: derive color/icon per-log from log.action
  final String filterType;

  const PumpLogsListWidget({
    super.key,
    required this.logs,
    this.filterType = '',
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const EmptyLogsWidget(message: 'No pump logs available');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildPumpLogCard(log);
      },
    );
  }

  String logtype(MotorLogs log) {
    if (log.action == "FAULT" || log.action == "ALERT") {
      return log.action ?? '';
    } else {
      return log.message ?? '';
    }
  }

  Widget _buildPumpLogCard(MotorLogs log) {
    final String message = log.message ?? 'No message';
    final DateTime? createdAt = log.createdAt;
    // When filterType is empty (multi-select), derive color/icon from each log's action
    final String colorKey =
        filterType.isNotEmpty ? filterType : (logtype(log) ?? '');

    print("line 43 ------>$colorKey");

    final Color typeColor = _getFilterColor(colorKey);
    final IconData typeIcon = _getPumpIcon(colorKey);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  typeIcon,
                  size: 16,
                  color: typeColor,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: typeColor.withOpacity(0.25),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (createdAt != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(createdAt),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1F2937),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateTime utcTime = DateTime.utc(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
      timestamp.second,
    );

    final DateTime istTime = utcTime.add(const Duration(hours: 5, minutes: 30));

    return DateFormat('dd MMM yyyy • hh:mm a').format(istTime);
  }

  Color _getFilterColor(String filter) {
    String type = getCategoryFromMessage(filter) == "DEFAULT"
        ? filter
        : getCategoryFromMessage(filter);
    switch (type) {
      case 'Faults':
      case 'FAULT':
      case 'FAULTS':
        return const Color(0xFFEF4444);
      case 'Alerts':
      case 'ALERT':
      case 'ALERTS':
        return const Color(0xFFF59E0B);
      case 'PUMP ON':
      case 'ON':
        return const Color(0xFF10B981);
      case 'PUMP OFF':
      case 'OFF':
        return const Color(0xFFEF4444);
      case 'PUMP MODE':
      case 'MODE':
        return const Color(0xFF8B5CF6);

      default:
        return const Color(0xFF6B7280);
    }
  }

  String getCategoryFromMessage(String message) {
    final msg = message.toLowerCase();

    print("line 171 ---> $msg");

    // OFF category
    if (msg.contains("state updated to 'off'") ||
        msg.contains("pump is stopped in manual mode") ||
        msg.contains("pump is off in auto mode")) {
      return "OFF";
    }

    // ON category
    if (msg.contains("state updated to 'on'") ||
        msg.contains("pump is running in manual mode")) {
      return "ON";
    }

    // MODE category
    if (msg.contains("switched from manual to auto") ||
        msg.contains("switched from auto to manual") ||
        msg.contains("mode updated from 'manual' to 'auto'") ||
        msg.contains("mode updated from 'auto' to 'manual'")) {
      return "MODE";
    }

    return "DEFAULT";
  }

  IconData _getPumpIcon(String filter) {
    String type = getCategoryFromMessage(filter) == "DEFAULT"
        ? filter
        : getCategoryFromMessage(filter);
    switch (type) {
      case 'PUMP ON':
      case 'ON':
        return Icons.power_settings_new;
      case 'PUMP OFF':
      case 'OFF':
        return Icons.power_off;
      case 'PUMP MODE':
      case 'MODE':
        return Icons.refresh;
      case 'Faults':
      case 'FAULT':
      case 'FAULTS':
        return Icons.warning_amber_outlined;
      case 'Alerts':
      case 'ALERT':
      case 'ALERTS':
        return Icons.notifications_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
