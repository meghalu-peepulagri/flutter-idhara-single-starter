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

  /// Convert the backend's YYMMDD integer (e.g. 260526) to a DateTime in
  /// the local 21st-century calendar (2026-05-26). Returns null for any
  /// value that can't be parsed.
  static DateTime? parseScheduleDate(int? yymmdd) {
    if (yymmdd == null) return null;
    final s = yymmdd.toString().padLeft(6, '0');
    if (s.length != 6) return null;
    final yy = int.tryParse(s.substring(0, 2));
    final mm = int.tryParse(s.substring(2, 4));
    final dd = int.tryParse(s.substring(4, 6));
    if (yy == null || mm == null || dd == null) return null;
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;
    return DateTime(2000 + yy, mm, dd);
  }

  /// Keep only records whose schedule_start_date falls inside the selected
  /// [fromDate]..[toDate] range. Defends against the backend currently
  /// returning records outside the requested window.
  List<Record> _filterToDateRange(Iterable<Record> input) {
    final from = _normalize(fromDate.value);
    final to = _normalize(toDate.value);
    return input.where((r) {
      final scheduleDate = parseScheduleDate(r.scheduleStartDate);
      if (scheduleDate == null) return false;
      return !scheduleDate.isBefore(from) && !scheduleDate.isAfter(to);
    }).toList();
  }

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
      final raw = response?.data?.records ?? [];
      records.value = _filterToDateRange(raw);
      final pagination = response?.data?.pagination;
      currentPage.value = pagination?.currentPage ?? 1;
      totalPages.value = pagination?.totalPages ?? 1;
      totalRecords.value = records.length;
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
      final raw = response?.data?.records ?? [];
      records.addAll(_filterToDateRange(raw));
      final pagination = response?.data?.pagination;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? totalPages.value;
      totalRecords.value = records.length;
    } catch (_) {
      // keep current state
    } finally {
      isLoadingMore.value = false;
    }
  }
}
