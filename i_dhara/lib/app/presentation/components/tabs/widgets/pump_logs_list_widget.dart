import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/motors/motor_logs_model.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/empty_logs_widget.dart';
import 'package:intl/intl.dart';

class PumpLogsListWidget extends StatelessWidget {
  final List<MotorLogs> logs;
  final String filterType;

  const PumpLogsListWidget({
    super.key,
    required this.logs,
    required this.filterType,
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

  Widget _buildPumpLogCard(MotorLogs log) {
    final String message = log.message ?? 'No message';
    final DateTime? createdAt = log.createdAt;
    final Color typeColor = _getFilterColor(filterType);
    final IconData typeIcon = _getPumpIcon(filterType);

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
                    fontWeight: FontWeight.w500,
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
    return DateFormat('dd MMM yyyy • hh:mm a').format(timestamp);
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Faults':
        return const Color(0xFFEF4444);
      case 'Alerts':
        return const Color(0xFFF59E0B);
      case 'ON':
        return const Color(0xFF10B981);
      case 'OFF':
        return const Color(0xFFEF4444);
      case 'MODE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getPumpIcon(String filter) {
    switch (filter) {
      case 'ON':
        return Icons.power_settings_new;
      case 'OFF':
        return Icons.power_off;
      case 'MODE':
        return Icons.refresh;
      default:
        return Icons.info_outline;
    }
  }
}
