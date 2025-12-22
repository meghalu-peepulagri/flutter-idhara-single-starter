import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';

class LocationsController extends GetxController {
  final LocationRepoImpl _locationRepo = LocationRepoImpl();
  final controller1 = TextEditingController();

  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var locationsList = <Location>[].obs;
  var expandedLocationIds = <int>{}.obs;

  var page = 1.obs;
  var limit = 10.obs;
  var searchQuery = ''.obs;

  Map<String, dynamic> errorInstance =
      {}; // Changed to dynamic to match LocationpopupModel
  String message = '';

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
    debounce<String>(
      searchQuery,
      (_) => fetchLocations(),
      time: const Duration(milliseconds: 400),
    );

    controller1.addListener(() {
      final value = controller1.text.trim();
      if (value == searchQuery.value) return;
      searchQuery.value = value;
    });
  }

  @override
  void onClose() {
    controller1.dispose();
    super.onClose();
  }

  Future<void> fetchLocations({String? search}) async {
    try {
      if (!isRefreshing.value) isLoading.value = true;
      final response = await _locationRepo.getAllLocations(
        page.value,
        limit.value,
        searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      if (response != null &&
          response.success == true &&
          response.data != null) {
        locationsList.value = response.data!;
      }
    } catch (e) {
      print('Error fetching locations: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> renamelocation(
      {required int locationId, required String name}) async {
    final response = await LocationRepoImpl().renameLocation(locationId, name);
    if (response != null && response.errors == null) {
      await fetchLocations();
      Get.back();
    } else if (response!.errors != null) {
      errorInstance = response.errors!.toJson();
    }
  }

  Future<void> deleteLocation(int locationId) async {
    final response = await _locationRepo.deleteLocation(locationId);
    if (response != null) {
      await fetchLocations();
    }
  }

  Future<void> refreshLocations() async {
    isRefreshing.value = true;
    await fetchLocations();
  }

  void toggleLocationExpansion(int locationId) {
    if (expandedLocationIds.contains(locationId)) {
      expandedLocationIds.remove(locationId);
    } else {
      expandedLocationIds.add(locationId);
    }
  }

  bool isLocationExpanded(int locationId) {
    return expandedLocationIds.contains(locationId);
  }
}
