import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';

class ScheduleManageController extends GetxController {
  ScheduleManageController({ScheduleRepositoryImpl? scheduleRepo})
      : _scheduleRepo = scheduleRepo ?? ScheduleRepositoryImpl();

  final ScheduleRepositoryImpl _scheduleRepo;

  final schedules = <Record>[].obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final page = 1.obs;
  final limit = 10.obs;
  final currentPage = 0.obs;
  final totalPages = 1.obs;
  final totalRecords = 0.obs;
  final selectedFilter = ''.obs;
  final selectedRecordIds = <int>{}.obs;

  late final Rx<DateTime> fromDate;
  late final Rx<DateTime> toDate;

  final scrollController = ScrollController();

  static int dateToYYMMDD(DateTime d) =>
      (d.year % 100) * 10000 + d.month * 100 + d.day;

  @override
  void onInit() {
    super.onInit();
    final today = _normalize(DateTime.now());
    fromDate = today.obs;
    toDate = today.add(const Duration(days: 14)).obs;
    scrollController.addListener(_onScroll);
    fetchSchedules();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 160) {
      loadMoreSchedules();
    }
  }

  Future<void> updateDateRange({
    DateTime? from,
    DateTime? to,
    bool fetch = true,
  }) async {
    final nextFrom = _normalize(from ?? fromDate.value);
    final nextTo = _normalize(to ?? toDate.value);

    fromDate.value = nextFrom.isAfter(nextTo) ? nextTo : nextFrom;
    toDate.value = nextTo.isBefore(nextFrom) ? nextFrom : nextTo;

    if (fetch) {
      await fetchSchedules();
    }
  }

  void toggleSelection(Record record) {
    final recordId = record.id;
    if (recordId == null) return;

    final nextSelection = Set<int>.from(selectedRecordIds);
    if (nextSelection.contains(recordId)) {
      nextSelection.remove(recordId);
    } else {
      nextSelection.add(recordId);
    }
    selectedRecordIds.assignAll(nextSelection);
  }

  bool isSelected(Record record) {
    final recordId = record.id;
    if (recordId == null) return false;
    return selectedRecordIds.contains(recordId);
  }

  void clearSelection() {
    selectedRecordIds.clear();
  }

  /// Replaces the current selection with every record id in [records] that
  /// has a non-null id. Page passes the action-filtered list so "Select All"
  /// under e.g. the Stop action only picks stoppable schedules.
  void selectAll(List<Record> records) {
    selectedRecordIds.assignAll(
      records
          .map((r) => r.id)
          .whereType<int>()
          .toSet(),
    );
  }

  List<Record> get selectedRecords => schedules
      .where((record) =>
          record.id != null && selectedRecordIds.contains(record.id))
      .toList();

  Future<void> fetchSchedules({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }

    page.value = 1;

    try {
      final response = await _scheduleRepo.getScheduleList(
        page.value,
        limit.value,
        scheduleStatus:
            selectedFilter.value.isNotEmpty ? selectedFilter.value : null,
        scheduleStartDate: dateToYYMMDD(fromDate.value),
        scheduleEndDate: dateToYYMMDD(toDate.value),
      );

      schedules.value = response?.data?.records ?? [];
      _syncSelection();

      final pagination = response?.data?.paginationInfo;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? 1;
      totalRecords.value = pagination?.totalRecords ?? schedules.length;
    } catch (_) {
      schedules.clear();
      selectedRecordIds.clear();
      totalRecords.value = 0;
      currentPage.value = 1;
      totalPages.value = 1;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreSchedules() async {
    if (isLoadingMore.value) return;
    if (currentPage.value >= totalPages.value) return;

    isLoadingMore.value = true;
    page.value = currentPage.value + 1;

    try {
      final response = await _scheduleRepo.getScheduleList(
        page.value,
        limit.value,
        scheduleStatus:
            selectedFilter.value.isNotEmpty ? selectedFilter.value : null,
        scheduleStartDate: dateToYYMMDD(fromDate.value),
        scheduleEndDate: dateToYYMMDD(toDate.value),
      );

      schedules.addAll(response?.data?.records ?? []);
      _syncSelection();

      final pagination = response?.data?.paginationInfo;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? totalPages.value;
      totalRecords.value = pagination?.totalRecords ?? totalRecords.value;
    } catch (_) {
      // Keep current state when pagination fails.
    } finally {
      isLoadingMore.value = false;
    }
  }

  // The bulk methods below intentionally do NOT clear selection. The caller
  // (schedule_manage_page) clears it in its `.then()` after the dialog
  // closes — that's where the page also resets its _selectedAction chip, so
  // both pieces of UI state flip in the same frame. Partial bulk ACKs
  // return success=false here but the manage page's fetchSchedules() below
  // still refreshes the list, so device-acked schedules pick up their new
  // status from the backend.

  Future<bool> deleteSelectedSchedules(
      MotorScheduleController motorScheduleController) async {
    final records = selectedRecords;
    if (records.isEmpty) return false;

    // Single-record selection goes through the well-trodden single-action
    // path (T:24 → _listenScheduleActionAck) which calls the per-record
    // delete API directly. The bulk path's "all covered" tracking has an
    // edge case for length=1 where the final-result stream can fail to
    // fire, leaving the API uncalled and the status stale.
    final bool success;
    if (records.length == 1) {
      success = await motorScheduleController.deleteSchedule(records.first);
    } else {
      success = await motorScheduleController.deleteBulkSchedules(records);
    }
    isLoading.value = true;
    await fetchSchedules();
    return success;
  }

  Future<bool> toggleSelectedSchedules(
    MotorScheduleController motorScheduleController, {
    required bool enabled,
  }) async {
    final records = selectedRecords;
    if (records.isEmpty) return false;

    // Same length=1 fork as deleteSelectedSchedules — single record uses
    // the single-action ACK path so the stop/restart API is reliably
    // invoked even when the bulk final-result stream doesn't fire.
    final bool success;
    if (records.length == 1) {
      success =
          await motorScheduleController.toggleSchedule(records.first, enabled);
    } else {
      success =
          await motorScheduleController.toggleBulkSchedules(records, enabled);
    }
    isLoading.value = true;
    await fetchSchedules();
    return success;
  }

  Future<bool> republishSelectedSchedules(
      MotorScheduleController motorScheduleController) async {
    final records = selectedRecords;
    if (records.isEmpty) return false;

    // idx=1 means "first publish — device has nothing yet", idx=2 means
    // "device already holds at least one accepted schedule, append to it".
    //
    // Only statuses the device has actually accepted occupy a slot:
    // SCHEDULED / RUNNING / STOPPED / COMPLETED / PARTIAL / MISSED.
    // PENDING never reached the device, FAILED was rejected — neither
    // takes a slot. So if every loaded schedule is PENDING or FAILED,
    // the device is empty and we must send idx=1 (fresh-create);
    // otherwise idx=2 (append).
    const nonDeviceStatuses = {'PENDING', 'FAILED'};
    final hasDeviceActiveSchedule = schedules.any((r) {
      final s = (r.scheduleStatus ?? '').toUpperCase();
      return s.isNotEmpty && !nonDeviceStatuses.contains(s);
    });
    final idx = hasDeviceActiveSchedule ? 2 : 1;

    // Blocks until device ACK received (or timeout) — dialog stays open with loading
    final success =
        await motorScheduleController.republishSchedules(records, idx: idx);
    isLoading.value = true;
    await fetchSchedules();
    return success;
  }

  void _syncSelection() {
    selectedRecordIds.removeWhere(
      (id) => !schedules.any((record) => record.id == id),
    );
  }
}
