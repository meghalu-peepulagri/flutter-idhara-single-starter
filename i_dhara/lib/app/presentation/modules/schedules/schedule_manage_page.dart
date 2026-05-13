import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_dialogs.dart';
import 'package:i_dhara/app/presentation/modules/schedules/schedule_manage_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ScheduleManagePage extends StatefulWidget {
  const ScheduleManagePage({super.key});

  @override
  State<ScheduleManagePage> createState() => _ScheduleManagePageState();
}

enum _BulkScheduleAction { delete, stop, restart, republish }

class _ScheduleManagePageState extends State<ScheduleManagePage> {
  late final String _controllerTag;
  late final ScheduleManageController _controller;
  late final MotorScheduleController _motorScheduleController;
  // Picked from the inline chip row; null means no action chosen yet,
  // so the bottom Confirm button stays hidden.
  _BulkScheduleAction? _selectedAction;
  bool _isRunningBulkAction = false;

  static const _filters = [
    {'label': 'All', 'value': ''},
    {'label': 'Pending', 'value': 'PENDING'},
    {'label': 'Running', 'value': 'RUNNING'},
    {'label': 'Stopped', 'value': 'STOPPED'},
    {'label': 'Scheduled', 'value': 'SCHEDULED'},
    {'label': 'Completed', 'value': 'COMPLETED'},
    {'label': 'Missed', 'value': 'MISSED'},
    {'label': 'Partial', 'value': 'PARTIAL'},
    {'label': 'Failed', 'value': 'FAILED'},
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
    _motorScheduleController.onScheduleAckRefreshed = () {
      _controller.fetchSchedules();
    };
  }

  @override
  void dispose() {
    _motorScheduleController.onScheduleAckRefreshed = null;
    if (Get.isRegistered<ScheduleManageController>(tag: _controllerTag)) {
      Get.delete<ScheduleManageController>(tag: _controllerTag);
    }
    super.dispose();
  }

  bool _isEligibleForAction(Record record, _BulkScheduleAction? action) {
    if (action == null) return true;
    final s = (record.scheduleStatus ?? '').toUpperCase();
    // Failed schedules are read-only from the manage page — no bulk action
    // (including republish) should target them.
    if (s == 'FAILED') return false;
    // Partial / missed are terminal — the window already ended on the
    // device, so Stop / Restart / Republish make no sense. Only Delete
    // is allowed so the user can clear them out.
    if (s == 'PARTIAL' || s == 'MISSED') {
      return action == _BulkScheduleAction.delete;
    }
    switch (action) {
      case _BulkScheduleAction.stop:
        return s == 'RUNNING' || s == 'SCHEDULED';
      case _BulkScheduleAction.restart:
        return s == 'STOPPED';
      case _BulkScheduleAction.republish:
        return s == 'PENDING';
      case _BulkScheduleAction.delete:
        return s != 'PENDING';
    }
  }

  List<Record> _filterByAction(List<Record> schedules) =>
      schedules.where((r) => _isEligibleForAction(r, _selectedAction)).toList();

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
              child: _buildDateSelector(),
            ),
            _buildSelectionBar(),
            // Only the schedule list scrolls
            Expanded(
              child: ClipRect(
                child: Obx(() {
                  final isLoading = _controller.isLoading.value;
                  final isRefreshing = _controller.isRefreshing.value;
                  final schedules =
                      _filterByAction(_controller.schedules.toList());
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
                      onRefresh: () async {
                        if (_selectedAction != null) {
                          setState(() => _selectedAction = null);
                        }
                        _controller.clearSelection();
                        _controller.selectedFilter.value = '';
                        await _controller.fetchSchedules(isRefresh: true);
                      },
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
                // const Spacer(),
                // const Icon(
                //   Icons.calendar_month_outlined,
                //   size: 18,
                //   color: Color(0xFF004E7E),
                // ),
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

  Widget _buildSelectionBar() {
    return Obx(() {
      final count = _controller.selectedRecordIds.length;
      final allSchedules = _controller.schedules.toList();

      final visible = _filterByAction(allSchedules);
      final selectableIds = visible.map((r) => r.id).whereType<int>().toSet();
      final visibleEmpty = selectableIds.isEmpty;

      final allSelected = !visibleEmpty &&
          selectableIds.every(_controller.selectedRecordIds.contains);

      final selectedRecords = allSchedules
          .where((r) =>
              r.id != null && _controller.selectedRecordIds.contains(r.id))
          .toList();
      final hasStoppable = selectedRecords.any((r) => _isEligibleForAction(
            r,
            _BulkScheduleAction.stop,
          ));
      final hasResumable = selectedRecords.any((r) => _isEligibleForAction(
            r,
            _BulkScheduleAction.restart,
          ));
      final hasPending = selectedRecords.any((r) => _isEligibleForAction(
            r,
            _BulkScheduleAction.republish,
          ));

      final hasDeletable = selectedRecords.any((r) => _isEligibleForAction(
            r,
            _BulkScheduleAction.delete,
          ));

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  visibleEmpty
                      ? (_selectedAction != null
                          ? 'No schedules for this action'
                          : 'No schedules')
                      : (count > 0
                          ? '$count of ${selectableIds.length} selected'
                          : '${selectableIds.length} schedule${selectableIds.length > 1 ? 's' : ''}'),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: count > 0
                        ? const Color(0xFF004E7E)
                        : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: visibleEmpty
                      ? null
                      : () {
                          if (allSelected) {
                            _controller.clearSelection();
                            if (_selectedAction != null) {
                              setState(() => _selectedAction = null);
                            }
                          } else {
                            _controller.selectAll(visible);
                          }
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: visibleEmpty ? 0.4 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            allSelected
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: const Color(0xFF004E7E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            allSelected ? 'Deselect All' : 'Select All',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF004E7E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Obx(() {
                  final isFiltered =
                      _controller.selectedFilter.value.isNotEmpty;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showFilterSheet(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFiltered
                                ? const Color(0xFF004E7E)
                                : const Color(0xFFEBF3FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: isFiltered
                                ? Colors.white
                                : const Color(0xFF004E7E),
                          ),
                        ),
                        if (isFiltered)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 14,
                              height: 14,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '1',
                                style: GoogleFonts.dmSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            if (count > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTextChip(
                    label: 'Stop',
                    action: _BulkScheduleAction.stop,
                    color: const Color(0xFFF59E0B),
                    enabled: hasStoppable,
                  ),
                  const SizedBox(width: 8),
                  _buildTextChip(
                    label: 'Restart',
                    action: _BulkScheduleAction.restart,
                    color: const Color(0xFF10B981),
                    enabled: hasResumable,
                  ),
                  const SizedBox(width: 8),
                  _buildTextChip(
                    label: 'Delete',
                    action: _BulkScheduleAction.delete,
                    color: const Color(0xFFEF4444),
                    enabled: hasDeletable,
                  ),
                  const SizedBox(width: 8),
                  _buildTextChip(
                    label: 'Republish',
                    action: _BulkScheduleAction.republish,
                    color: const Color(0xFF6366F1),
                    enabled: hasPending,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTextChip({
    required String label,
    required _BulkScheduleAction action,
    required Color color,
    bool enabled = true,
  }) {
    final isSelected = _selectedAction == action;
    return Expanded(
      child: GestureDetector(
        onTap: !enabled
            ? null
            : () {
                setState(() {
                  _selectedAction = isSelected ? null : action;
                });

                if (!isSelected) {
                  final eligibleIds = _controller.schedules
                      .where((r) =>
                          r.id != null &&
                          _controller.selectedRecordIds.contains(r.id) &&
                          _isEligibleForAction(r, action))
                      .map((r) => r.id!)
                      .toSet();
                  if (eligibleIds.length !=
                      _controller.selectedRecordIds.length) {
                    _controller.selectedRecordIds.assignAll(eligibleIds);
                  }
                }
              },
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
            ),
          ),
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

      if (selectedCount == 0 || _selectedAction == null) {
        return const SizedBox.shrink();
      }
      final visibleForAction = _filterByAction(_controller.schedules.toList());
      if (visibleForAction.isEmpty) {
        return const SizedBox.shrink();
      }
      final action = _selectedAction!;

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
                  onPressed: () {
                    setState(() => _selectedAction = null);
                    _controller.clearSelection();
                  },
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
                  onPressed: () => _showBulkActionConfirm(action),
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
              // Title + close button row. Close icon mirrors the
              // motor_mode_info_sheet header so the dismiss control feels
              // consistent across the app's bottom sheets.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter by Status',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Flexible + scroll so the now-9 filter rows scroll inside the
              // sheet's existing height instead of overflowing it.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _filters.map((filter) {
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
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showBulkActionConfirm(_BulkScheduleAction action) {
    if (_isRunningBulkAction) return;

    setState(() => _isRunningBulkAction = true);

    final selectedCount = _controller.selectedRecordIds.length;
    final title = switch (action) {
      _BulkScheduleAction.delete => 'Delete Schedules',
      _BulkScheduleAction.stop => 'Stop Schedules',
      _BulkScheduleAction.restart => 'Restart Schedules',
      _BulkScheduleAction.republish => 'Republish Schedules',
    };
    final buttonLabel = switch (action) {
      _BulkScheduleAction.delete => 'Delete',
      _BulkScheduleAction.stop => 'Stop',
      _BulkScheduleAction.restart => 'Restart',
      _BulkScheduleAction.republish => 'Republish',
    };
    final description = switch (action) {
      _BulkScheduleAction.delete =>
        'Are you sure you want to delete $selectedCount selected schedules?',
      _BulkScheduleAction.stop =>
        'Are you sure you want to stop $selectedCount selected schedules?',
      _BulkScheduleAction.restart =>
        'Are you sure you want to restart $selectedCount selected schedules?',
      _BulkScheduleAction.republish =>
        'Republish $selectedCount pending schedule${selectedCount > 1 ? 's' : ''} to the device?',
    };

    showScheduleActionConfirmDialog(
      context: context,
      title: title,
      buttonLabel: buttonLabel,
      description: description,
      iconAssetPath: 'assets/images/schedule.svg',
      isActive: action == _BulkScheduleAction.restart ||
          action == _BulkScheduleAction.republish,
      onConfirm: () => _runBulkAction(action),
      // Aborts MQTT retries + resolves the bulk/republish completer with
      // false so the controller's 23s `.timeout()` doesn't fire a stale
      // "No response from device" snackbar after the user dismisses.
      onCancelWhileWaiting:
          _motorScheduleController.cancelInFlightScheduleOperation,
    ).then((success) {
      // No success snackbar fired from here — MotorScheduleController owns
      // every one of these messages:
      //   • single-record stop/restart → _listenScheduleActionAck →
      //     "Schedule stopped" / "Schedule restarted" after the post API.
      //   • single-record delete → _deleteScheduleAfterAck →
      //     "Schedule deleted successfully" after the delete API.
      //   • single-record republish → _listenScheduleAck →
      //     "Schedules acknowledged by device" once T:33 lands.
      //   • multi-record (>1) → showScheduleResultSnackBar with the
      //     "X succeeded, Y failed" partial / full toast.
      // Firing anything extra from the page double-toasts the user.
      _controller.clearSelection();
      if (mounted && _selectedAction != null) {
        setState(() => _selectedAction = null);
      }
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
      _BulkScheduleAction.republish =>
        _controller.republishSelectedSchedules(_motorScheduleController),
    };
  }

  String _formatCardDate(DateTime value) =>
      DateFormat('dd MMM yyyy').format(value);
}
