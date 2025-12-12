// import 'dashboard_page.dart' show DashboardWidget;
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';
import 'package:i_dhara/app/data/repository/locations/location_dropdown_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';

class DashboardController extends GetxController {
  final motors = <Motor>[].obs;
  final allMotors = <Motor>[].obs;
  final locations = <LocationDropDown>[].obs;

  // Loading state
  final isLoading = true.obs;
  var isRefreshing = false.obs;
  final isFiltering = false.obs;

  final selectedLocationId = Rxn<int>();
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchMotors();
    fetchLocationDropDown();
  }

  Future<void> refreshMotors() async {
    isRefreshing.value = true;
    selectedLocationId.value = null;
    await fetchMotors();
  }

  Future<void> fetchMotors() async {
    try {
      if (!isRefreshing.value) isLoading.value = true;

      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        allMotors.value = response.data!.records ?? [];
        motors.value = allMotors;
        // motors.value = response.data!.records ?? [];
      } else {
        errorMessage.value = 'Failed to load motors';
      }
    } catch (e) {
      isLoading.value = false;
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> fetchLocationDropDown() async {
    final response = await LocationDropdownRepoImpl().getLocations();
    if (response != null) {
      locations.value = response.data ?? [];
      locations.insert(0, LocationDropDown(id: null, name: 'All'));
    }
  }

  void filterMotorsByLocation(int? locationId) {
    selectedLocationId.value = locationId;

    if (locationId == null) {
      motors.value = allMotors;
      return;
    }

    motors.value =
        allMotors.where((m) => m.location?.id == locationId).toList();
  }
}
