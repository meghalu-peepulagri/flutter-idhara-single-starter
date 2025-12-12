import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => DashboardController(), fenix: true);
  }
}
