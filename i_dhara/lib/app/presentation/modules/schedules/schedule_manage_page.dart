import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/dialogs/popup_dialog.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_manage_controller.dart';
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
            Expanded(
              child: Obx(() {
                final isLoading = _controller.isLoading.value;
                final isRefreshing = _controller.isRefreshing.value;
                final schedules = _controller.schedules;
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      children: [
                        _buildDateSelector(),
                        const SizedBox(height: 16),
                        // _buildFilterRow(),
                        // const SizedBox(height: 12),
                        _buildActionSelector(),
                        const SizedBox(height: 14),
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
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD7E3F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Date Range',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF005A96),
                  ),
                ),
              ),
              Obx(() {
                final fromDate = _controller.fromDate.value;
                return InkWell(
                  onTap: () => _openDateDialog(
                    initialDate: fromDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 2),
                    onPicked: (date) => _controller.updateDateRange(from: date),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    height: 36,
                    width: 36,
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF004E7E),
                      size: 20,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final fromDate = _controller.fromDate.value;
            final toDate = _controller.toDate.value;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDateCard(
                    label: 'Start Date',
                    value: _formatCardDate(fromDate),
                    isActive: true,
                    onTap: () => _openDateDialog(
                      initialDate: fromDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 2),
                      onPicked: (date) =>
                          _controller.updateDateRange(from: date),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 72,
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF004E7E),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildDateCard(
                    label: 'End Date',
                    value: _formatCardDate(toDate),
                    isActive: false,
                    onTap: () => _openDateDialog(
                      initialDate: toDate,
                      firstDate: fromDate,
                      lastDate: DateTime(DateTime.now().year + 2),
                      onPicked: (date) => _controller.updateDateRange(to: date),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEBF3FE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF004E7E) : const Color(0xFF94A9C2),
            width: isActive ? 1.8 : 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF004E7E)
                          : const Color(0xFF93A3B8),
                    ),
                  ),
                ),
                // Icon(
                //   Icons.edit_calendar_outlined,
                //   size: 13,
                //   color: isActive
                //       ? const Color(0xFF004E7E)
                //       : const Color(0xFF93A3B8),
                // ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionRadioTile(
                  label: 'Delete',
                  value: _BulkScheduleAction.delete,
                ),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 10),
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
            padding: const EdgeInsets.only(bottom: 12),
            child: ScheduleCard(
              key: ValueKey(record.scheduleId ?? record.id),
              record: record,
              showEditAction: false,
              showDeleteAction: false,
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEBF3FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 34,
                color: const Color(0xFF004E7E).withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No schedules in this range',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF14181B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the dates or create a new schedule from the motor schedule tab.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF667788),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDateDialog({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        firstDate: firstDate.isBefore(todayNorm) ? todayNorm : firstDate,
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
          final success = await _runBulkAction(action);
          if (dialogCtx.mounted) {
            Navigator.pop(dialogCtx);
          }
          if (success && mounted) {
            setState(() {});
          }
        },
        onCancel: () => Navigator.pop(dialogCtx),
      ),
    );
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
