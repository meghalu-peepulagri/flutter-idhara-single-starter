import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_history_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:intl/intl.dart';

class ScheduleHistoryController extends GetxController {
  ScheduleHistoryController({ScheduleRepositoryImpl? scheduleRepo})
      : _scheduleRepo = scheduleRepo ?? ScheduleRepositoryImpl();

  final ScheduleRepositoryImpl _scheduleRepo;

  final records = <Record>[].obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;

  final page = 1.obs;
  final limit = 10.obs;
  final currentPage = 0.obs;
  final totalPages = 1.obs;
  final totalRecords = 0.obs;

  late final Rx<DateTime> fromDate;
  late final Rx<DateTime> toDate;

  final scrollController = ScrollController();

  static final _fmt = DateFormat('yyyy-MM-dd');
  String _fmtDate(DateTime d) => _fmt.format(d);

  @override
  void onInit() {
    super.onInit();
    final today = _normalize(DateTime.now());
    fromDate = today.obs;
    toDate = today.obs;
    scrollController.addListener(_onScroll);
    fetchHistory();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 160) {
      loadMore();
    }
  }

  Future<void> updateDateRange({DateTime? from, DateTime? to}) async {
    final nextFrom = _normalize(from ?? fromDate.value);
    final nextTo = _normalize(to ?? toDate.value);
    fromDate.value = nextFrom.isAfter(nextTo) ? nextTo : nextFrom;
    toDate.value = nextTo.isBefore(nextFrom) ? nextFrom : nextTo;
    await fetchHistory();
  }

  Future<void> fetchHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    page.value = 1;

    try {
      final response = await _scheduleRepo.getScheduleHistory(
        fromDate: _fmtDate(fromDate.value),
        toDate: _fmtDate(toDate.value),
        page: page.value,
        limit: limit.value,
      );
      records.value = response?.data?.records ?? [];
      final pagination = response?.data?.pagination;
      currentPage.value = pagination?.currentPage ?? 1;
      totalPages.value = pagination?.totalPages ?? 1;
      totalRecords.value = pagination?.totalRecords ?? records.length;
    } catch (_) {
      records.clear();
      totalRecords.value = 0;
      currentPage.value = 1;
      totalPages.value = 1;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value) return;
    if (currentPage.value >= totalPages.value) return;
    isLoadingMore.value = true;
    page.value = currentPage.value + 1;

    try {
      final response = await _scheduleRepo.getScheduleHistory(
        fromDate: _fmtDate(fromDate.value),
        toDate: _fmtDate(toDate.value),
        page: page.value,
        limit: limit.value,
      );
      records.addAll(response?.data?.records ?? []);
      final pagination = response?.data?.pagination;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? totalPages.value;
      totalRecords.value = pagination?.totalRecords ?? totalRecords.value;
    } catch (_) {
      // keep current state
    } finally {
      isLoadingMore.value = false;
    }
  }
}
