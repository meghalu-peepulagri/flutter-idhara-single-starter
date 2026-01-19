import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MotorLogsTab extends StatefulWidget {
  const MotorLogsTab({super.key});

  @override
  State<MotorLogsTab> createState() => _MotorLogsTabState();
}

class _MotorLogsTabState extends State<MotorLogsTab> {
  String? selectedFilter; // Single selection across all filters

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 36,
              child: selectedFilter != null
                  ? _buildSelectedFilterInlineChip(
                      _isPumpFilter(selectedFilter!)
                          ? 'Pump: $selectedFilter'
                          : selectedFilter!,
                      _getFilterColor(selectedFilter!),
                      () {
                        setState(() {
                          selectedFilter = null;
                        });
                      },
                    )
                  : const SizedBox(),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.filter_list,
                color: const Color(0xFF004E7E),
                size: 26,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 40),
              onSelected: (value) {
                setState(() {
                  if (selectedFilter == value) {
                    selectedFilter = null;
                  } else {
                    selectedFilter = value;
                  }
                });
              },
              itemBuilder: (context) => [
                _buildMainMenuItem('Faults', selectedFilter == 'Faults'),
                _buildMainMenuItem('Alerts', selectedFilter == 'Alerts'),
                PopupMenuItem<String>(
                  enabled: false,
                  // height: 6,
                  padding: EdgeInsets.zero,
                  child: _buildPumpsMenuItemWithSubmenu(context),
                ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Logs Available',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedFilter == null
                      ? 'Select filters to view logs'
                      : 'No logs match your filters',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isPumpFilter(String filter) {
    return filter == 'ON' || filter == 'OFF' || filter == 'MODE';
  }

  Widget _buildPumpsMenuItemWithSubmenu(BuildContext context) {
    bool isPumpSelected =
        selectedFilter != null && _isPumpFilter(selectedFilter!);

    return PopupMenuButton<String>(
      offset: const Offset(-120, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        setState(() {
          if (selectedFilter == value) {
            selectedFilter = null;
          } else {
            selectedFilter = value;
          }
        });
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isPumpSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                border: Border.all(
                  color: isPumpSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isPumpSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Pump',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPumpSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPumpMenuItem('ON', selectedFilter == 'ON'),
        _buildPumpMenuItem('OFF', selectedFilter == 'OFF'),
        _buildPumpMenuItem('MODE', selectedFilter == 'MODE'),
      ],
    );
  }

  Widget _buildSelectedFilterInlineChip(
    String label,
    Color color,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  PopupMenuItem<String> _buildMainMenuItem(String value, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSelected ? _getFilterColor(value) : Colors.transparent,
            border: Border.all(
              color:
                  isSelected ? _getFilterColor(value) : const Color(0xFFD1D5DB),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? _getFilterColor(value) : const Color(0xFF1F2937),
          ),
        ),
      ]),
    );
  }

  PopupMenuItem<String> _buildPumpMenuItem(String value, bool isSelected) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isSelected ? _getFilterColor(value) : const Color(0xFF1F2937),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 18,
              color: _getFilterColor(value),
            ),
        ],
      ),
    );
  }
}
