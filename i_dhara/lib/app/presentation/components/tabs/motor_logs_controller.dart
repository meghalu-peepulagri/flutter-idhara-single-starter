import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/motors/faults_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_alerts_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_logs_model.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';

import '../../../data/models/motors/all_logs_model.dart';

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
  var limit = 15.obs;
  var searchQuery = ''.obs;
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var hasMoreData = true.obs;
  var currentFilter = ''.obs;

  dynamic errorInstance = {};
  String? message = '';
  final connectivity = Connectivity();
  var hasInternet = true.obs;

  var logsData = <LogResponse>[].obs;

  // Multi-select filter state — stores display names e.g. {'Faults', 'PUMP ON'}
  var selectedFilters = <String>{}.obs;

  static const Map<String, String> _filterToLogType = {
    'Faults': 'fault',
    'Alerts': 'alert',
    'PUMP ON': 'on',
    'PUMP OFF': 'off',
    'PUMP MODE': 'mode',
  };

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    fetchAllLogs();
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
      // More aggressive threshold for better cross-device compatibility
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final delta = maxScroll - currentScroll;

      // Trigger when within 100 pixels of the bottom
      if (delta <= 100) {
        if (!isLoadingMore.value &&
            hasMoreData.value &&
            !isLoading.value &&
            !isRefreshing.value) {
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
    totalPages.value = 1;
  }

  Future<void> fetchLogsWithFilters(Set<String> filters,
      {bool append = false}) async {
    try {
      if (!append) {
        if (!isRefreshing.value) isLoading.value = true;
        resetPagination();
        motorLogsList.clear();
      }

      final logTypes =
          filters.map((f) => _filterToLogType[f] ?? f.toLowerCase()).join(',');

      final response =
          await _motorRepo.getMotorLogs(page.value, limit.value, logTypes);

      if (response != null &&
          response.success == true &&
          response.data?.records != null) {
        if (append) {
          motorLogsList.addAll(response.data!.records!);
        } else {
          motorLogsList.value = response.data!.records!;
        }

        if (response.data!.paginationInfo != null) {
          currentPage.value =
              response.data!.paginationInfo!.currentPage ?? page.value;
          totalPages.value = response.data!.paginationInfo!.totalPages ?? 1;
          hasMoreData.value = currentPage.value < totalPages.value;
        }
      }
    } catch (e) {
      debugPrint('Error fetching filtered logs: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<void> loadMoreData() async {
    if (isLoadingMore.value) return;

    if (currentPage.value >= totalPages.value) {
      hasMoreData.value = false;
      return;
    }

    isLoadingMore.value = true;
    page.value = currentPage.value + 1;

    try {
      if (selectedFilters.isEmpty) {
        await fetchAllLogs(append: true);
      } else {
        await fetchLogsWithFilters(selectedFilters.toSet(), append: true);
      }
    } catch (e) {
      debugPrint('Error loading more data: $e');
      page.value = currentPage.value;
    } finally {
      isLoadingMore.value = false;
    }
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
          response.data != null &&
          response.data!.records != null) {
        if (append) {
          motorFaultsList.addAll(response.data!.records!);
        } else {
          motorFaultsList.value = response.data!.records!;
        }

        if (response.data!.pagination != null) {
          currentPage.value =
              response.data!.pagination!.currentPage ?? page.value;
          totalPages.value = response.data!.pagination!.totalPages ?? 1;
          hasMoreData.value = currentPage.value < totalPages.value;
        }
      }
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
          response.data != null &&
          response.data!.records != null) {
        if (append) {
          motorAlertsList.addAll(response.data!.records!);
        } else {
          motorAlertsList.value = response.data!.records!;
        }

        if (response.data!.pagination != null) {
          currentPage.value =
              response.data!.pagination!.currentPage ?? page.value;
          totalPages.value = response.data!.pagination!.totalPages ?? 1;
          hasMoreData.value = currentPage.value < totalPages.value;
        }
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
          response.data != null &&
          response.data!.records != null) {
        if (append) {
          motorLogsList.addAll(response.data!.records!);
        } else {
          motorLogsList.value = response.data!.records!;
        }

        if (response.data!.paginationInfo != null) {
          currentPage.value =
              response.data!.paginationInfo!.currentPage ?? page.value;
          totalPages.value = response.data!.paginationInfo!.totalPages ?? 1;
          hasMoreData.value = currentPage.value < totalPages.value;
        }
      }
    } catch (e) {
      debugPrint('Error fetching motor logs: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> fetchAllLogs({bool append = false}) async {
    try {
      if (!append) {
        if (!isRefreshing.value) isLoading.value = true;
        resetPagination();
      }

      final response = await _motorRepo.getAllLogs(
        page.value,
        limit.value,
      );

      if (response?.status == 200 || response?.status == 201) {
        final data = response?.data?.records;
        if (append) {
          logsData.addAll(data!);
        } else {
          logsData.assignAll(data!);
        }

        if (response?.data?.pagination != null) {
          currentPage.value =
              response!.data!.pagination!.currentPage ?? page.value;
          totalPages.value = response.data!.pagination!.totalPages ?? 1;
          hasMoreData.value = currentPage.value < totalPages.value;
        }
      }
    } catch (e) {
      debugPrint('Error fetching all logs: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<void> refreshLocations() async {
    isRefreshing.value = true;
    resetPagination();
    if (selectedFilters.isEmpty) {
      await fetchAllLogs();
    } else {
      await fetchLogsWithFilters(selectedFilters.toSet());
    }
  }

  Future<void> refreshCurrentTab() async {
    isRefreshing.value = true;
    resetPagination();
    try {
      if (selectedFilters.isEmpty) {
        await fetchAllLogs();
      } else {
        await fetchLogsWithFilters(selectedFilters.toSet());
      }
    } finally {
      isRefreshing.value = false;
    }
  }
}
