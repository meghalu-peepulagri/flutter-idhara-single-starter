import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_list_card.dart';
import 'package:i_dhara/app/presentation/components/schedules/schedule_logs_sheet.dart';
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
  // Flipped on when the user long-presses any card. Acts like a second
  // gate (alongside `hasFilter`) that surfaces the checkbox column and
  // the Select All / bulk-action chip row, so power users can multi-
  // select without first opening the filter sheet.
  bool _longPressSelectionMode = false;

  static const _filters = [
    {'label': 'All', 'value': ''},
    {'label': 'Pending', 'value': 'PENDING'},
    {'label': 'Scheduled', 'value': 'SCHEDULED'},
    {'label': 'Running', 'value': 'RUNNING'},
    {'label': 'Stopped', 'value': 'STOPPED'},
    {'label': 'Partial', 'value': 'PARTIAL'},
    {'label': 'Completed', 'value': 'COMPLETED'},
    {'label': 'Missed', 'value': 'MISSED'},
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
        // Delete is allowed for every status the card itself lets the
        // user delete — including PENDING, since unsynced rows still
        // exist on the backend and need to be cleared. The FAILED /
        // PARTIAL / MISSED handling is covered by the guards above.
        return true;
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
                        if (_longPressSelectionMode) {
                          setState(() => _longPressSelectionMode = false);
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
      // Bulk-selection mode is normally gated behind a chosen status
      // filter, BUT a card long-press also flips it on (see
      // `_longPressSelectionMode`). Either path reveals checkboxes,
      // Select All, and the bulk-action chip row.
      final hasFilter = _controller.selectedFilter.value.isNotEmpty;
      final selectionEnabled = hasFilter || _longPressSelectionMode;

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
                if (selectionEnabled)
                  GestureDetector(
                    onTap: visibleEmpty
                        ? null
                        : () {
                            if (allSelected) {
                              _controller.clearSelection();
                              if (_selectedAction != null) {
                                setState(() => _selectedAction = null);
                              }
                              // Leaving an empty selection in long-press
                              // mode also exits long-press mode so the
                              // user returns to the regular "tap to
                              // open logs" interaction.
                              if (_longPressSelectionMode) {
                                setState(() => _longPressSelectionMode = false);
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
                            const SizedBox(width: 6),
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
                  )
                else
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Apply a status filter to select multiple schedules',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              height: 1.3,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectionEnabled && count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count selected',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (selectionEnabled) const Spacer(),
                Obx(() {
                  final currentFilter = _controller.selectedFilter.value;
                  final isFiltered = currentFilter.isNotEmpty;
                  // Resolve the human label from the static `_filters`
                  // list so the chip mirrors what the user picked in the
                  // bottom sheet. Empty value maps to the "All" entry,
                  // so the chip always reads as a current state rather
                  // than a bare icon.
                  final filterLabel = _filters.firstWhere(
                        (f) => f['value'] == currentFilter,
                        orElse: () => const {'label': 'All'},
                      )['label'] ??
                      'All';
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showFilterSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        // Apply the brand gradient when a filter is
                        // active so the chip pops the same way the
                        // selected-count badge does.
                        gradient: isFiltered
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF004E7E),
                                  Color(0xFF3686AF),
                                ],
                              )
                            : null,
                        color: isFiltered ? null : const Color(0xFFEBF3FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            filterLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isFiltered
                                  ? Colors.white
                                  : const Color(0xFF004E7E),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: isFiltered
                                ? Colors.white
                                : const Color(0xFF004E7E),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            if (selectionEnabled && count > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTextChip(
                    label: 'Stop',
                    icon: Icons.stop_circle_outlined,
                    action: _BulkScheduleAction.stop,
                    color: const Color(0xFFF59E0B),
                    enabled: hasStoppable,
                  ),
                  const SizedBox(width: 8),
                  _buildTextChip(
                    label: 'Restart',
                    icon: Icons.play_circle_outline_rounded,
                    action: _BulkScheduleAction.restart,
                    color: const Color(0xFF10B981),
                    enabled: hasResumable,
                  ),
                  const SizedBox(width: 8),
                  _buildTextChip(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    action: _BulkScheduleAction.delete,
                    color: const Color(0xFFEF4444),
                    enabled: hasDeletable,
                  ),
                  const SizedBox(width: 8),
                  _buildTextChip(
                    label: 'Resync',
                    icon: Icons.refresh_rounded,
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
    required IconData icon,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? color : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : const Color(0xFF64748B),
                  ),
                ),
              ],
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
          final hasFilter = _controller.selectedFilter.value.isNotEmpty;
          // Selection UI also surfaces when the user has long-pressed
          // to start a bulk pick, not only via the status filter path.
          final selectionEnabled = hasFilter || _longPressSelectionMode;
          // While at least one row is checked the user is in bulk-select
          // mode — the per-card Edit/Delete/Resync pills stay visible
          // but are rendered inactive so the user can't accidentally
          // fire a single-record action alongside the pending bulk one.
          final inSelectionMode = _controller.selectedRecordIds.isNotEmpty;
          final dateLabel = _formatScheduleDate(
            record.scheduleStartDate,
            record.scheduleEndDate,
          );
          // STOPPED rows can only restart while the window is still in
          // the future — past-stopped rows stay read-only for the
          // toggle. The card hides the restart action for those.
          final startDate = _yymmddToDate(record.scheduleStartDate);
          final isFutureSchedule = startDate == null
              ? true
              : !startDate.isBefore(
                  DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day),
                );
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              // Long-pressing a card flips the page into selection mode
              // and toggles the pressed record. The card's inner
              // InkWell (added when `onTap` is set) only claims taps —
              // it leaves long-presses to fall through to this outer
              // detector, so the gesture arena routes correctly.
              onLongPress: () {
                final oid = record.id;
                if (oid == null || oid <= 0) return;
                if (!_longPressSelectionMode) {
                  setState(() => _longPressSelectionMode = true);
                }
                _controller.toggleSelection(record);
              },
              child: ScheduleCard(
                key: ValueKey(record.scheduleId ?? record.id),
              record: record,
              dateLabel: dateLabel.isEmpty ? null : dateLabel,
              isFutureSchedule: isFutureSchedule,
              disableEditAction: inSelectionMode,
              disableDeleteAction: inSelectionMode,
              disableSyncAction: inSelectionMode,
              // Tapping anywhere on the card surface opens the
              // per-schedule logs bottom sheet, except while a bulk
              // selection is in progress — taps then should only
              // toggle the checkbox / action pills, not pop a sheet
              // over the bulk-select UI. Taps that land on the
              // action-pill row are absorbed inside `ScheduleCard`
              // itself, so they don't bubble up to this handler.
              onTap: inSelectionMode || (record.id ?? 0) <= 0
                  ? null
                  : (r) => showSingleScheduleLogsSheet(
                        context,
                        objectId: r.id!,
                      ),
              leading: selectionEnabled
                  ? Checkbox(
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
                    )
                  : null,
              onDelete: (item) async {
                final s = (item.scheduleStatus ?? '').toUpperCase();
                // PENDING / FAILED rows never reached the device, so
                // there's nothing to clear over MQTT — call the backend
                // DELETE directly. Everything else stays on the
                // MQTT-then-API path that waits for the device ACK.
                final isApiOnly = s == 'PENDING' || s == 'FAILED';
                final success = isApiOnly
                    ? await _motorScheduleController.deleteScheduleApiOnly(item)
                    : await _motorScheduleController.deleteSchedule(item);
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
              onSync: (item) => _controller.republishSingleSchedule(
                item,
                _motorScheduleController,
              ),
              onCancelAction: (item) => _motorScheduleController
                  .cancelPendingScheduleAction(item.scheduleId ?? 0),
              // Resync's Cancel tap has to stop the T:23 republish
              // retry loop, not the T:24 action loop that
              // cancelPendingScheduleAction targets.
              onCancelSync: (_) =>
                  _motorScheduleController.cancelInFlightScheduleOperation(),
              ),
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

  /// Renders the record's `schedule_start_date` (YYMMDD int from the
  /// backend) as a compact label shown next to the time on the card.
  /// Only the start date is surfaced — per-date records have one date
  /// anyway, and ranges are already disambiguated by the date filter
  /// chips above the list. The year is intentionally omitted —
  /// schedules always live in the near future, so the year adds noise
  /// without disambiguating.
  String _formatScheduleDate(int? startCode, int? endCode) {
    final start = _yymmddToDate(startCode);
    if (start == null) return '';
    return DateFormat('dd MMM').format(start);
  }

  DateTime? _yymmddToDate(int? code) {
    if (code == null || code <= 0) return null;
    final yy = code ~/ 10000;
    final mm = (code % 10000) ~/ 100;
    final dd = code % 100;
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    return DateTime(2000 + yy, mm, dd);
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
                    setState(() {
                      _selectedAction = null;
                      _longPressSelectionMode = false;
                    });
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
                          // Switching filter invalidates any in-flight bulk
                          // pick — selections made under the old filter may
                          // not be eligible under the new one (or, when the
                          // user goes back to "All", the checkbox column
                          // disappears entirely).
                          _controller.clearSelection();
                          if (_selectedAction != null) {
                            setState(() => _selectedAction = null);
                          }
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

    // Resync only: cap the selection to a FIXED window of the next
    // _kResyncMaxDates calendar days starting from today (inclusive)
    // so the device receives one small MQTT payload per round and
    // only the schedules that are actually about to run get
    // resent. Anything outside that window — past-dated rows or
    // dates further out — is excluded from this payload and stays
    // PENDING for a follow-up resync closer to its date. Done at
    // the page layer so the confirm dialog's count and the
    // failureMessageBuilder both see the already-capped selection.
    if (action == _BulkScheduleAction.republish) {
      final allSelected = _controller.selectedRecords;
      final capped = _takeNextNDaysFromToday(allSelected, _kResyncMaxDates);

      if (capped.isEmpty && allSelected.isNotEmpty) {
        // Every selected schedule is past-dated or beyond the
        // resync window. Nothing to publish, so abort before the
        // dialog opens.
        setState(() => _isRunningBulkAction = false);
        geterrorSnackBar(
          'Nothing to resync. Selected schedules are past or '
          'beyond the next $_kResyncMaxDates days.',
        );
        return;
      }

      if (capped.length < allSelected.length) {
        // Narrow the selection to the publishable subset; the
        // confirm dialog (and the controller below) only sees the
        // capped ids. No top snackbar is fired here — the dialog
        // itself communicates how many schedules will be resynced
        // via its count, so the green "Resyncing X / N excluded"
        // toast would just be visual noise.
        _controller.selectedRecordIds.assignAll(
          capped.map((r) => r.id).whereType<int>().toSet(),
        );
      }
    }

    final selectedCount = _controller.selectedRecordIds.length;
    final title = switch (action) {
      _BulkScheduleAction.delete => 'Delete Schedules',
      _BulkScheduleAction.stop => 'Stop Schedules',
      _BulkScheduleAction.restart => 'Restart Schedules',
      _BulkScheduleAction.republish => 'Resync Schedules',
    };
    final buttonLabel = switch (action) {
      _BulkScheduleAction.delete => 'Delete',
      _BulkScheduleAction.stop => 'Stop',
      _BulkScheduleAction.restart => 'Restart',
      _BulkScheduleAction.republish => 'Resync',
    };
    final description = switch (action) {
      _BulkScheduleAction.delete =>
        'Are you sure you want to delete $selectedCount selected schedules?',
      _BulkScheduleAction.stop =>
        'Are you sure you want to stop $selectedCount selected schedules?',
      _BulkScheduleAction.restart =>
        'Are you sure you want to restart $selectedCount selected schedules?',
      _BulkScheduleAction.republish =>
        'Resync $selectedCount pending schedule${selectedCount > 1 ? 's' : ''} to the device?',
    };

    // For a bulk delete where every picked row is PENDING / FAILED, the
    // controller skips MQTT entirely — so the dialog should also skip
    // its 23s "Waiting for device" timer view. Any other action (or a
    // mixed delete that still has device-resident rows) keeps the
    // existing timer behavior.
    final selectedRecords = _controller.schedules
        .where(
            (r) => r.id != null && _controller.selectedRecordIds.contains(r.id))
        .toList();
    final isApiOnlyDelete = action == _BulkScheduleAction.delete &&
        selectedRecords.isNotEmpty &&
        selectedRecords.every((r) {
          final s = (r.scheduleStatus ?? '').toUpperCase();
          return s == 'PENDING' || s == 'FAILED';
        });

    // Snapshot the originally-selected object ids before the dialog
    // opens. After the bulk run resolves, the failureMessageBuilder
    // compares the refreshed list against this snapshot to compute
    // how many rows didn't transition into the expected post-action
    // state — that count drives the "X of Y didn't respond" copy
    // shown inside the dialog instead of the generic fallback.
    //
    // Per-action "not ACKed" definition:
    //   • delete   → row is still present in the list
    //   • stop     → row is still RUNNING or SCHEDULED
    //   • restart  → row is still STOPPED
    //   • resync   → row is still PENDING or FAILED
    final Set<int> originalSelectedIds =
        Set<int>.from(_controller.selectedRecordIds);
    final int originalSelectedCount = originalSelectedIds.length;

    bool isStillNotAcked(Record r, _BulkScheduleAction action) {
      final status = (r.scheduleStatus ?? '').toUpperCase();
      switch (action) {
        case _BulkScheduleAction.delete:
          return true; // present in list => not deleted
        case _BulkScheduleAction.stop:
          return status == 'RUNNING' || status == 'SCHEDULED';
        case _BulkScheduleAction.restart:
          return status == 'STOPPED';
        case _BulkScheduleAction.republish:
          return status == 'PENDING' || status == 'FAILED';
      }
    }

    Future<String?> Function()? failureMessageBuilder;
    if (originalSelectedCount > 0) {
      failureMessageBuilder = () async {
        final notAckedCount = _controller.schedules.where((r) {
          if (r.id == null) return false;
          if (!originalSelectedIds.contains(r.id)) return false;
          return isStillNotAcked(r, action);
        }).length;
        if (notAckedCount == 0) return null;
        if (notAckedCount == originalSelectedCount) {
          return 'No response from device. Please try again.';
        }
        return '$notAckedCount of $originalSelectedCount schedules didn\'t respond. Please try again.';
      };
    }

    showScheduleActionConfirmDialog(
      context: context,
      title: title,
      buttonLabel: buttonLabel,
      description: description,
      iconAssetPath: 'assets/images/schedule.svg',
      isActive: action == _BulkScheduleAction.restart ||
          action == _BulkScheduleAction.republish,
      skipDeviceAck: isApiOnlyDelete,
      failureMessageBuilder: failureMessageBuilder,
      onConfirm: () => _runBulkAction(action),
      // Aborts MQTT retries + resolves the bulk/republish completer with
      // false so the controller's 23s `.timeout()` doesn't fire a stale
      // "No response from device" snackbar after the user dismisses.
      onCancelWhileWaiting:
          _motorScheduleController.cancelInFlightScheduleOperation,
    ).then((success) {
      // Resync only: fire the success snackbar deterministically from
      // the manage page rather than relying on the motor controller's
      // `_listenScheduleAck` listener. In release builds the listener
      // does two awaited fetch calls before its `getsuccessSnackBar`,
      // by which time the dialog route has been disposed and the
      // GetX snackbar can't render. Firing here, in the dialog's own
      // `.then`, happens before any route teardown so the snackbar
      // always appears. Stop / Restart / Delete keep their motor-
      // controller-owned per-record snackbars and aren't touched.
      if (success == true &&
          action == _BulkScheduleAction.republish &&
          mounted) {
        getsuccessSnackBar('Schedules resynced successfully');
      }
      _controller.clearSelection();
      if (mounted && _selectedAction != null) {
        setState(() => _selectedAction = null);
      }
      if (mounted && _longPressSelectionMode) {
        setState(() => _longPressSelectionMode = false);
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

  /// Size of the fixed, today-anchored window the Resync action
  /// publishes in a single MQTT round. The window is
  /// `[today, today+1, today+2]` when this is 3 — schedules outside
  /// that range are excluded so the device receives one small
  /// payload covering only its immediate upcoming work.
  static const int _kResyncMaxDates = 3;

  /// Returns the subset of [records] whose `schedule_start_date`
  /// falls within the [days]-day window starting at today
  /// (inclusive). The window is FIXED — anchored to today's date,
  /// not derived from the input.
  ///
  /// Every PENDING row inside the window is published, INCLUDING
  /// rows that share a date with an existing SCHEDULED / RUNNING
  /// entry on the device — the device side accepts up to
  /// `kMaxSchedulesPerDate` schedules per calendar date, and
  /// `republishSelectedSchedules` sends `idx = 2` (append) when
  /// any non-PENDING/FAILED record is present, so the new entries
  /// land in free slots beside the existing ones instead of
  /// overwriting them.
  ///
  /// Records dated before today or after today + (days - 1) are
  /// excluded. Records with no schedule_start_date are also
  /// excluded.
  ///
  /// Example with [days] = 3 and today = 27 May:
  ///   selection [27, 28, 29] → returns [27, 28, 29]
  ///                            (even if 27 already has a
  ///                            SCHEDULED row — the new PENDING
  ///                            row for 27 still gets published)
  ///   selection [25, 26, 27] → returns [27]  (25, 26 are past)
  ///   selection [30, 31]     → returns []   (beyond window)
  List<Record> _takeNextNDaysFromToday(List<Record> records, int days) {
    if (records.isEmpty || days <= 0) return records;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: days - 1));

    return records.where((r) {
      final sd = r.scheduleStartDate ?? 0;
      if (sd <= 0) return false;
      final yy = sd ~/ 10000;
      final mm = (sd % 10000) ~/ 100;
      final dd = sd % 100;
      if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return false;
      final date = DateTime(2000 + yy, mm, dd);
      if (date.isBefore(start) || date.isAfter(end)) return false;
      return true;
    }).toList();
  }
}
