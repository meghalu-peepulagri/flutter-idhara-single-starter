import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_logs_controller.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/all_logs_widget.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/empty_logs_widget.dart';
import 'package:i_dhara/app/presentation/components/tabs/widgets/pump_logs_list_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

const _kPrimary = Color(0xFF004E7E);
const _filterOptions = ['Faults', 'Alerts', 'PUMP ON', 'PUMP OFF', 'PUMP MODE'];

class MotorLogsTab extends StatefulWidget {
  final String? initialFilter;
  const MotorLogsTab({super.key, this.initialFilter});

  @override
  State<MotorLogsTab> createState() => _MotorLogsTabState();
}

class _MotorLogsTabState extends State<MotorLogsTab> {
  Set<String> selectedFilters = {};
  final MotorLogsController logsController = Get.put(MotorLogsController());

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter != 'All') {
      selectedFilters = {widget.initialFilter!};
    }
    logsController.selectedFilters
      ..clear()
      ..addAll(selectedFilters);
    logsController.resetPagination();
    if (selectedFilters.isEmpty) {
      logsController.fetchAllLogs();
    } else {
      logsController.fetchLogsWithFilters(selectedFilters);
    }
  }

  void _applyFilters(Set<String> newFilters) {
    setState(() => selectedFilters = newFilters);
    logsController.selectedFilters
      ..clear()
      ..addAll(newFilters);
    logsController.resetPagination();
    if (newFilters.isEmpty) {
      logsController.fetchAllLogs();
    } else {
      logsController.fetchLogsWithFilters(newFilters);
    }
  }

  void _removeFilter(String filter) {
    final updated = Set<String>.from(selectedFilters)..remove(filter);
    _applyFilters(updated);
  }

  void _showFilterSheet(BuildContext context) {
    Set<String> tempFilters = Set.from(selectedFilters);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Logs',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (tempFilters.isNotEmpty)
                      GestureDetector(
                        onTap: () => setModalState(() => tempFilters.clear()),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._filterOptions.map((option) {
                  final isSelected = tempFilters.contains(option);
                  final color = _getFilterColor(option);
                  return InkWell(
                    onTap: () => setModalState(() {
                      if (isSelected) {
                        tempFilters.remove(option);
                      } else {
                        tempFilters.add(option);
                      }
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          _buildCheckbox(isSelected, color),
                          const SizedBox(width: 12),
                          Text(
                            option,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? color
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _applyFilters(tempFilters);
                    },
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        border: Border.all(
          color: isSelected ? color : const Color(0xFFD1D5DB),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MotorLogsController>();

    return Obx(() {
      if (controller.isLoading.value &&
          controller.motorLogsList.isEmpty &&
          controller.logsData.isEmpty) {
        return const Padding(
            padding: EdgeInsets.only(bottom: 50, right: 50),
            child: Center(child: AppLottieLoading()));
      }

      return Column(
        children: [
          // Filter header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 4),
            child: Row(
              children: [
                // Selected filter chips
                Expanded(
                  child: selectedFilters.isEmpty
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: selectedFilters.map((f) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(f, () => _removeFilter(f)),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                // Filter icon button
                IconButton(
                  onPressed: () => _showFilterSheet(context),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: _kPrimary,
                        size: 26,
                      ),
                      if (selectedFilters.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${selectedFilters.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: Skeletonizer(
              enabled: controller.isRefreshing.value,
              child: ListView(
                controller: logsController.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (logsController.isLoading.value &&
                      !logsController.isLoadingMore.value)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 50, right: 50),
                        child: Center(child: AppLottieLoading()),
                      ),
                    )
                  else
                    _buildLogsContent(),

                  if (logsController.isLoadingMore.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  if (!logsController.isLoadingMore.value &&
                      logsController.hasMoreData.value)
                    const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLogsContent() {
    if (selectedFilters.isEmpty) {
      return AllLogsWidget(logs: logsController.logsData);
    }
    if (logsController.motorLogsList.isEmpty) {
      return const EmptyLogsWidget(message: 'No logs available');
    }
    return PumpLogsListWidget(
      logs: logsController.motorLogsList,
      // Pass single filter name only when exactly one is selected so the
      // widget uses a consistent colour; with multiple selections it derives
      // colour per-log from log.action.
      filterType: selectedFilters.length == 1 ? selectedFilters.first : '',
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    final color = _getFilterColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: color),
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
      case 'PUMP ON':
        return const Color(0xFF10B981);
      case 'PUMP OFF':
        return const Color(0xFFEF4444);
      case 'PUMP MODE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
