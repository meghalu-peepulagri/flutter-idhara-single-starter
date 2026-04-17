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
    toDate = today.obs;
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

  Future<bool> deleteSelectedSchedules(
      MotorScheduleController motorScheduleController) async {
    final records = selectedRecords;
    if (records.isEmpty) return false;

    bool hasSuccess = false;
    for (final record in records) {
      final success = await motorScheduleController.deleteSchedule(record);
      hasSuccess = hasSuccess || success;
    }

    await fetchSchedules();
    clearSelection();
    return hasSuccess;
  }

  Future<bool> toggleSelectedSchedules(
    MotorScheduleController motorScheduleController, {
    required bool enabled,
  }) async {
    final records = selectedRecords;
    if (records.isEmpty) return false;

    bool hasSuccess = false;
    for (final record in records) {
      final success =
          await motorScheduleController.toggleSchedule(record, enabled);
      hasSuccess = hasSuccess || success;
    }

    await fetchSchedules();
    clearSelection();
    return hasSuccess;
  }

  void _syncSelection() {
    selectedRecordIds.removeWhere(
      (id) => !schedules.any((record) => record.id == id),
    );
  }
}
