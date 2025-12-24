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

  final RxString errorMessage = ''.obs;
  var page = 1.obs;
  var limit = 10.obs;
  var searchQuery = ''.obs;
  Map<String, dynamic> errorInstance =
      {}; // Changed to dynamic to match LocationpopupModel
  String message = '';
  final connectivity = Connectivity();
  var hasInternet = true.obs;

  final DevicesRepositoryImpl _repository = DevicesRepositoryImpl();

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    fetchDevices();
    debounce<String>(
      searchQuery,
      (_) => fetchDevices(),
      time: const Duration(milliseconds: 400),
    );

    controller1.addListener(() {
      final value = controller1.text.trim();
      if (value == searchQuery.value) return;
      searchQuery.value = value;
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

  /// Fetch devices from API
  Future<void> fetchDevices({String? search}) async {
    try {
      if (!isRefreshing.value) isLoading.value = true;

      final response = await _repository.getDevices(
        page.value,
        searchQuery.value.isEmpty ? null : searchQuery.value,
        limit.value,
      );

      if (response != null && response.data != null) {
        devicesList.value = response.data!.records ?? [];
      } else {
        errorMessage.value = 'No data found';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching devices: $e';
      print('Error in fetchDevices: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshDevices() async {
    isRefreshing.value = true;
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

  Future<void> locationreplace(
      {required int starterId,
      required int locationId,
      required int motorId}) async {
    final response =
        await _repository.locationreplace(starterId, locationId, motorId);
    if (response != null) {
      await fetchDevices();
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
