import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<DashboardController>()) {
      Get.delete<DashboardController>(force: true);
    }
    Get.lazyPut(() => DashboardController());
  }
}
