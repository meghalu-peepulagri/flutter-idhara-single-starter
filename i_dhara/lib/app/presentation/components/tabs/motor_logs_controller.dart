import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/motors/faults_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_alerts_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_logs_model.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';

class MotorLogsController extends GetxController {
  final MotorsRepositoryImpl _motorRepo = MotorsRepositoryImpl();
  final controller1 = TextEditingController();
  final ScrollController scrollController = ScrollController();

  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var motorFaultsList = <MotorFaults>[].obs;
  var motorAlertsList = <MotorAlerts>[].obs;
  var motorLogsList = <MotorLogs>[].obs;
  var expandedLocationIds = <int>{}.obs;
  var locationscount = 0.obs;
  var isInitialLoading = true.obs;
  var isLoadingMore = false.obs;

  var page = 1.obs;
  var limit = 10.obs;
  var searchQuery = ''.obs;
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var hasMoreData = true.obs;
  var currentFilter = ''.obs;

  dynamic errorInstance = {};
  String? message = '';
  final connectivity = Connectivity();
  var hasInternet = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    fetchMotorFaults();
    _setupScrollListener();
    debounce<String>(
      searchQuery,
      (_) => fetchMotorFaults(),
      time: const Duration(milliseconds: 400),
    );

    controller1.addListener(() {
      final value = controller1.text.trim();
      if (value == searchQuery.value) return;
      searchQuery.value = value;
    });
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore.value && hasMoreData.value && !isLoading.value) {
          loadMoreData();
        }
      }
    });
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.isNotEmpty) {
      _updateConnectionStatus(connectivityResult.first);
    }
    connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    hasInternet.value = result != ConnectivityResult.none;
  }

  @override
  void onClose() {
    controller1.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void resetPagination() {
    page.value = 1;
    currentPage.value = 0;
    hasMoreData.value = true;
  }

  Future<void> loadMoreData() async {
    if (currentPage.value >= totalPages.value) {
      hasMoreData.value = false;
      return;
    }

    isLoadingMore.value = true;
    page.value = currentPage.value + 1;

    try {
      if (currentFilter.value == 'Faults') {
        await fetchMotorFaults(append: true);
      } else if (currentFilter.value == 'Alerts') {
        await fetchMotorAlerts(append: true);
      } else if (_isPumpFilter(currentFilter.value)) {
        await fetchMotorLogs(currentFilter.value, append: true);
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  bool _isPumpFilter(String filter) {
    return filter == 'ON' || filter == 'OFF' || filter == 'MODE';
  }

  Future<void> fetchMotorFaults({bool append = false}) async {
    try {
      if (!append) {
        if (!isRefreshing.value) isLoading.value = true;
        resetPagination();
      }

      final response = await _motorRepo.getMotorFaults(
        page.value,
        limit.value,
      );

      if (response != null &&
          response.success == true &&
          response.data != null) {
        if (append) {
          motorFaultsList.addAll(response.data!.records!);
        } else {
          motorFaultsList.value = response.data!.records!;
        }
      }

      currentPage.value = response!.data!.pagination!.currentPage!;
      totalPages.value = response.data!.pagination!.totalPages!;
      hasMoreData.value = currentPage.value < totalPages.value;
    } catch (e) {
      debugPrint('Error fetching motor faults: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<void> fetchMotorAlerts({bool append = false}) async {
    try {
      if (!append) {
        if (!isRefreshing.value) isLoading.value = true;
        resetPagination();
      }

      final response = await _motorRepo.getMotorAlerts(
        page.value,
        limit.value,
      );

      if (response != null &&
          response.success == true &&
          response.data != null) {
        if (append) {
          motorAlertsList.addAll(response.data!.records!);
        } else {
          motorAlertsList.value = response.data!.records!;
        }

        currentPage.value = response.data!.pagination!.currentPage!;
        totalPages.value = response.data!.pagination!.totalPages!;
        hasMoreData.value = currentPage.value < totalPages.value;
      }
    } catch (e) {
      debugPrint('Error fetching motor alerts: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> fetchMotorLogs(String action, {bool append = false}) async {
    try {
      if (!append) {
        if (!isRefreshing.value) isLoading.value = true;
        resetPagination();
      }

      final response = await _motorRepo.getMotorLogs(
        page.value,
        limit.value,
        action,
      );

      if (response != null &&
          response.success == true &&
          response.data != null) {
        if (append) {
          motorLogsList.addAll(response.data!.records!);
        } else {
          motorLogsList.value = response.data!.records!;
        }

        currentPage.value = response.data!.paginationInfo!.currentPage!;
        totalPages.value = response.data!.paginationInfo!.totalPages!;
        hasMoreData.value = currentPage.value < totalPages.value;
      }
    } catch (e) {
      debugPrint('Error fetching motor logs: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshLocations() async {
    isRefreshing.value = true;
    resetPagination();

    if (currentFilter.value == 'Faults') {
      await fetchMotorFaults();
    } else if (currentFilter.value == 'Alerts') {
      await fetchMotorAlerts();
    } else if (_isPumpFilter(currentFilter.value)) {
      await fetchMotorLogs(currentFilter.value);
    }
  }
}
