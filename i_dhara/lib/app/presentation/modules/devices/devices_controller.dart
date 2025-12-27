import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';

class DevicesController extends GetxController {
  final controller1 = TextEditingController();
  final RxList<Devices> devicesList = <Devices>[].obs;

  final RxBool isLoading = false.obs;
  var isRefreshing = false.obs;
  var isInitialLoading = true.obs;
  var isHasMoreLoading = false.obs;
  var isLocationReplacing = false.obs;
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var page = 1.obs;
  var limit = 10.obs;

  final RxString errorMessage = ''.obs;

  var searchQuery = ''.obs;
  Map<String, dynamic> errorInstance = {};
  String message = '';
  final connectivity = Connectivity();
  var hasInternet = true.obs;

  final DevicesRepositoryImpl _repository = DevicesRepositoryImpl();

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    fetchDevices(isInitial: true);
    _addScrollListener();
    debounce<String>(
      searchQuery,
      (_) {
        page.value = 1;
        fetchDevices(isInitial: true);
      },
      time: const Duration(milliseconds: 400),
    );

    controller1.addListener(() {
      final value = controller1.text.trim();
      if (value == searchQuery.value) return;
      searchQuery.value = value;
    });
  }

  void _addScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isHasMoreLoading.value &&
          page.value < totalPages.value) {
        loadMoreDevices();
      }
    });
  }

  @override
  void dispose() {
    controller1.dispose();
    super.dispose();
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
    connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    hasInternet.value = result != ConnectivityResult.none;
  }

  @override
  void onClose() {
    controller1.dispose();
    super.onClose();
  }

  Future<void> loadMoreDevices() async {
    isHasMoreLoading.value = true;
    page.value += 1;
    await fetchDevices();
  }

  Future<void> fetchDevices({bool isInitial = false}) async {
    try {
      if (isInitial) {
        isInitialLoading.value = true;
        devicesList.clear();
        page.value = 1;
      }

      final response = await _repository.getDevices(
        page.value,
        searchQuery.value.isEmpty ? null : searchQuery.value,
        limit.value,
      );

      if (response != null && response.data != null) {
        final newList = response.data!.records ?? [];

        if (page.value == 1) {
          devicesList.assignAll(newList);
        } else {
          devicesList.addAll(newList);
        }

        currentPage.value =
            response.data!.paginationInfo!.currentPage ?? page.value;
        totalPages.value = response.data!.paginationInfo!.totalPages ?? 1;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching devices';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isInitialLoading.value = false;
      isHasMoreLoading.value = false;
    }
  }

  Future<void> refreshDevices() async {
    isRefreshing.value = true;
    page.value = 1;
    await fetchDevices();
  }

  Future<void> renamedevice(
      {required int motorId, required double hp, required String name}) async {
    final response = await _repository.renameDevice(motorId, name, hp);
    if (response != null && response.errors == null) {
      await fetchDevices();
      Get.back();
      getsuccessSnackBar(response.message ?? 'Device renamed successfully');
    } else if (response!.errors != null) {
      errorInstance = response.errors!.toJson();
    }
  }

  Future<void> deleteDevice(int starterId) async {
    final response = await _repository.deletestarter(starterId);
    if (response != null) {
      await fetchDevices();
      getsuccessSnackBar(response.message ?? 'Device deleted successfully');
      print("line 268 -----------> ${response.message}");
    }
  }

  Future<void> locationreplace({
    required int starterId,
    required int locationId,
    required int motorId,
  }) async {
    try {
      isLocationReplacing.value = true;
      final response =
          await _repository.locationreplace(starterId, locationId, motorId);
      if (response != null) {
        await fetchDevices();
        getsuccessSnackBar(
            response.message ?? 'Location replaced successfully');
      }
    } catch (e) {
      // Handle error if needed
      print("Error replacing location: $e");
    } finally {
      isLocationReplacing.value = false; // Stop loading
    }
  }

  List<Devices> searchDevices(String query) {
    if (query.isEmpty) return devicesList;

    return devicesList.where((device) {
      final nameMatch =
          device.name?.toLowerCase().contains(query.toLowerCase()) ?? false;
      final pcbMatch =
          device.pcbNumber?.toLowerCase().contains(query.toLowerCase()) ??
              false;
      final motorMatch = device.motors?.any((motor) =>
              motor.name?.toLowerCase().contains(query.toLowerCase()) ??
              false) ??
          false;

      return nameMatch || pcbMatch || motorMatch;
    }).toList();
  }
}
