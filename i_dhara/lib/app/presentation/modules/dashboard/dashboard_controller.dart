// import 'dashboard_page.dart' show DashboardWidget;
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';

class DashboardController extends GetxController {
  final motors = <Motor>[].obs;

  // Loading state
  final isLoading = true.obs;
  var isRefreshing = false.obs;

  // Error message
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchMotors();
  }

  Future<void> refreshMotors() async {
    isRefreshing.value = true;
    await fetchMotors();
  }

  Future<void> fetchMotors() async {
    try {
      if (!isRefreshing.value) {
        isLoading.value = true; // Only for first load
      }

      final response = await MotorsRepositoryImpl().getMotors();

      if (response != null && response.data != null) {
        motors.value = response.data!.records ?? [];
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
}
