import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';

class LocationsController extends GetxController {
  final LocationRepoImpl _locationRepo = LocationRepoImpl();

  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var locationsList = <Location>[].obs;
  var expandedLocationIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      if (!isRefreshing.value) isLoading.value = true;
      final response = await _locationRepo.getAllLocations();

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
