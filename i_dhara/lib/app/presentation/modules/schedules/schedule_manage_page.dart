import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/dialogs/popup_dialog.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_manage_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ScheduleManagePage extends StatefulWidget {
  const ScheduleManagePage({super.key});

  @override
  State<ScheduleManagePage> createState() => _ScheduleManagePageState();
}

enum _BulkScheduleAction { delete, stop, restart }

class _ScheduleManagePageState extends State<ScheduleManagePage> {
  late final String _controllerTag;
  late final ScheduleManageController _controller;
  late final MotorScheduleController _motorScheduleController;
  _BulkScheduleAction _selectedAction = _BulkScheduleAction.delete;
  bool _isRunningBulkAction = false;

  static const _filters = [
    {'label': 'All', 'value': ''},
    {'label': 'Pending', 'value': 'PENDING'},
    {'label': 'Running', 'value': 'RUNNING'},
    {'label': 'Stopped', 'value': 'STOPPED'},
    {'label': 'Scheduled', 'value': 'SCHEDULED'},
    {'label': 'Completed', 'value': 'COMPLETED'},
  ];

  @override
  void initState() {
    super.initState();
    _controllerTag = 'schedule_manage_${DateTime.now().microsecondsSinceEpoch}';
    _controller = Get.put(
      ScheduleManageController(),
      tag: _controllerTag,
      permanent: false,
    );
    _motorScheduleController = Get.find<MotorScheduleController>();
  }

  List<Record> _getActionFilteredSchedules(List<Record> schedules) {
    switch (_selectedAction) {
      case _BulkScheduleAction.stop:
        return schedules.where((r) {
          final s = (r.scheduleStatus ?? '').toUpperCase();
          return s == 'RUNNING' || s == 'PENDING' || s == 'SCHEDULED';
        }).toList();
      case _BulkScheduleAction.restart:
        return schedules.where((r) {
          final s = (r.scheduleStatus ?? '').toUpperCase();
          return s == 'STOPPED';
        }).toList();
      case _BulkScheduleAction.delete:
        return schedules; // all schedules
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<ScheduleManageController>(tag: _controllerTag)) {
      Get.delete<ScheduleManageController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Fixed sticky section — never scrolls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 12),
                  _buildActionSelector(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // Only the schedule list scrolls
            Expanded(
              child: ClipRect(
                child: Obx(() {
                  final isLoading = _controller.isLoading.value;
                  final isRefreshing = _controller.isRefreshing.value;
                  final allSchedules = _controller.schedules;
                  final schedules = _getActionFilteredSchedules(allSchedules);
                  // final schedules = _controller.schedules;
                  final isLoadingMore = _controller.isLoadingMore.value;

                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 50, right: 50),
                      child: Center(child: AppLottieLoading()),
                    );
                  }

                  return Skeletonizer(
                    enabled: isRefreshing,
                    child: RefreshIndicator(
                      color: const Color(0xFF004E7E),
                      backgroundColor: Colors.white,
                      onRefresh: () =>
                          _controller.fetchSchedules(isRefresh: true),
                      child: ListView(
                        controller: _controller.scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        children: [
                          if (schedules.isEmpty)
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.42,
                              child: _buildEmptyState(),
                            )
                          else
                            ..._buildScheduleList(schedules, isLoadingMore),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBulkActionBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFEBF3FE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'Schedule Manage',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004E7E),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF004E7E),
                  size: 20,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.toNamed(Routes.scheduleHistory),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF004E7E).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF004E7E).withValues(alpha: 0.3),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 14, color: Color(0xFF004E7E)),
                    const SizedBox(width: 4),
                    Text(
                      'Logs',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004E7E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Obx(() {
      final fromDate = _controller.fromDate.value;
      final toDate = _controller.toDate.value;

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB8CCE4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading + single calendar icon
            Row(
              children: [
                Text(
                  'Date Range',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF005A96),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Color(0xFF004E7E),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Start → End date row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openDateDialog(
                      initialDate: fromDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(DateTime.now().year + 2),
                      onPicked: (date) =>
                          _controller.updateDateRange(from: date),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF94A9C2), width: 1.4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF004E7E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCardDate(fromDate),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Color(0xFF004E7E)),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _openDateDialog(
                      initialDate: toDate,
                      firstDate: fromDate,
                      lastDate: DateTime(DateTime.now().year + 2),
                      onPicked: (date) => _controller.updateDateRange(to: date),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF94A9C2), width: 1.4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF93A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCardDate(toDate),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Action',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              // Filter icon button in top-right corner
              Obx(() {
                final current = _controller.selectedFilter.value;
                final isFiltered = current.isNotEmpty;
                return InkWell(
                  onTap: () => _showFilterSheet(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFiltered
                          ? const Color(0xFF004E7E).withValues(alpha: 0.08)
                          : const Color(0xFFF4F8FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFiltered
                            ? const Color(0xFF004E7E)
                            : const Color(0xFFD7E3F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: isFiltered
                              ? const Color(0xFF004E7E)
                              : const Color(0xFF7C8DA1),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isFiltered
                              ? _filters.firstWhere(
                                  (f) => f['value'] == current,
                                  orElse: () => _filters.first,
                                )['label']!
                              : 'Filter',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isFiltered
                                ? const Color(0xFF004E7E)
                                : const Color(0xFF7C8DA1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          // const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionRadioTile(
                  label: 'Stop',
                  value: _BulkScheduleAction.stop,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionRadioTile(
                  label: 'Resume',
                  value: _BulkScheduleAction.restart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionRadioTile(
                  label: 'Delete',
                  value: _BulkScheduleAction.delete,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 10),
          Obx(() {
            final selectedCount = _controller.selectedRecordIds.length;
            return Text(
              selectedCount > 0
                  ? '$selectedCount schedules selected'
                  : 'Select schedules, then confirm the chosen action.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Obx(() {
      final current = _controller.selectedFilter.value;
      final currentLabel = _filters.firstWhere(
        (filter) => filter['value'] == current,
        orElse: () => _filters.first,
      )['label']!;

      return InkWell(
        onTap: () => _showFilterSheet(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFF004E7E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter: $currentLabel',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF7C8DA1),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionRadioTile({
    required String label,
    required _BulkScheduleAction value,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = value;
          _controller.clearSelection();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedAction == value
              ? const Color(0xFFF4F9FF)
              : const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAction == value
                ? const Color(0xFF004E7E)
                : const Color(0xFFD7E3F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedAction == value
                      ? const Color(0xFF004E7E)
                      : const Color(0xFFB8C7D6),
                  width: 1.6,
                ),
              ),
              child: _selectedAction == value
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF004E7E),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScheduleList(List<Record> schedules, bool isLoadingMore) {
    return [
      ...schedules.map(
        (record) => Obx(() {
          final isSelected = _controller.isSelected(record);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ScheduleCard(
              key: ValueKey(record.scheduleId ?? record.id),
              record: record,
              showEditAction: false,
              showDeleteAction: false,
              disableToggle: true,
              leading: Checkbox(
                value: isSelected,
                onChanged: (_) => _controller.toggleSelection(record),
                activeColor: const Color(0xFF004E7E),
                checkColor: Colors.white,
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(
                  color: Color(0xFFB8C7D6),
                  width: 1.4,
                ),
              ),
              onDelete: (item) async {
                final success =
                    await _motorScheduleController.deleteSchedule(item);
                if (success) {
                  await _controller.fetchSchedules();
                }
                return success;
              },
              onToggle: (item, enabled) async {
                final success = await _motorScheduleController.toggleSchedule(
                    item, enabled);
                if (success) {
                  await _controller.fetchSchedules();
                }
                return success;
              },
              onEdit: (item) {
                _motorScheduleController.navigateToEditSchedule(item);
              },
              onCancelAction: (item) => _motorScheduleController
                  .cancelPendingScheduleAction(item.scheduleId ?? 0),
            ),
          );
        }),
      ),
      if (isLoadingMore)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
    ];
  }

  Widget _buildBulkActionBar() {
    return Obx(() {
      final selectedCount = _controller.selectedRecordIds.length;
      if (selectedCount == 0) {
        return const SizedBox.shrink();
      }

      return SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _controller.clearSelection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004E7E),
                    side: const BorderSide(color: Color(0xFF004E7E)),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showBulkActionConfirm(_selectedAction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004E7E),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEBF3FE),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                  width: 45, height: 45, 'assets/images/schedule.svg')),
          const SizedBox(height: 4),
          Text(
            'No schedules',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF14181B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDateDialog({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    // final today = DateTime.now();
    // final todayNorm = DateTime(today.year, today.month, today.day);

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        firstDate: firstDate,
        lastDate: lastDate,
        selectedDayHighlightColor: const Color(0xFF004E7E),
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        todayTextStyle: const TextStyle(
          color: Color(0xFF004E7E),
          fontWeight: FontWeight.w600,
        ),
        dayTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w400,
        ),
        disabledDayTextStyle: const TextStyle(color: Color(0xFFB0B8C4)),
        weekdayLabelTextStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        controlsTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        lastMonthIcon:
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF004E7E)),
        nextMonthIcon:
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF004E7E)),
        okButtonTextStyle: const TextStyle(
          color: Color(0xFF004E7E),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        cancelButtonTextStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      dialogSize: const Size(340, 350),
      value: [initialDate],
      borderRadius: BorderRadius.circular(16),
    );

    if (results == null ||
        results.isEmpty ||
        results.first == null ||
        !mounted) {
      return;
    }
    onPicked(results.first!);
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Obx(() {
        final current = _controller.selectedFilter.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter by Status',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              ..._filters.map((filter) {
                final isSelected = current == filter['value'];
                return InkWell(
                  onTap: () async {
                    _controller.selectedFilter.value = filter['value']!;
                    Navigator.pop(ctx);
                    await _controller.fetchSchedules();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            filter['label']!,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF004E7E)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Color(0xFF004E7E),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  void _showBulkActionConfirm(_BulkScheduleAction action) {
    if (_isRunningBulkAction) return;
    // Lock immediately so double-tapping the Confirm button never opens
    // a second dialog before the first one is dismissed.
    setState(() => _isRunningBulkAction = true);

    final selectedCount = _controller.selectedRecordIds.length;
    final title = switch (action) {
      _BulkScheduleAction.delete => 'Delete Schedules',
      _BulkScheduleAction.stop => 'Stop Schedules',
      _BulkScheduleAction.restart => 'Restart Schedules',
    };
    final buttonLabel = switch (action) {
      _BulkScheduleAction.delete => 'Delete',
      _BulkScheduleAction.stop => 'Stop',
      _BulkScheduleAction.restart => 'Restart',
    };
    final description = switch (action) {
      _BulkScheduleAction.delete =>
        'Are you sure you want to delete $selectedCount selected schedules?',
      _BulkScheduleAction.stop =>
        'Are you sure you want to stop $selectedCount selected schedules?',
      _BulkScheduleAction.restart =>
        'Are you sure you want to restart $selectedCount selected schedules?',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopupDialog(
        title: title,
        buttonlable: buttonLabel,
        description: description,
        iconAssetPath: 'assets/images/schedule.svg',
        isactive: action == _BulkScheduleAction.restart,
        onDelete: () async {
          // FFButtonWidget(showLoadingIndicator: true) already blocks re-taps
          // within the dialog. This just runs the action and closes.
          await _runBulkAction(action);
          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
        },
        onCancel: () => Navigator.pop(dialogCtx),
      ),
    ).whenComplete(() {
      // Unlock after dialog is fully dismissed (confirm or cancel).
      if (mounted) setState(() => _isRunningBulkAction = false);
    });
  }

  Future<bool> _runBulkAction(_BulkScheduleAction action) {
    return switch (action) {
      _BulkScheduleAction.delete =>
        _controller.deleteSelectedSchedules(_motorScheduleController),
      _BulkScheduleAction.stop => _controller.toggleSelectedSchedules(
          _motorScheduleController,
          enabled: false,
        ),
      _BulkScheduleAction.restart => _controller.toggleSelectedSchedules(
          _motorScheduleController,
          enabled: true,
        ),
    };
  }

  String _formatCardDate(DateTime value) =>
      DateFormat('dd MMM yyyy').format(value);
}
