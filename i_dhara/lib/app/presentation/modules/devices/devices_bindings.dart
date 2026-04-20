import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/modules/devices/devices_controller.dart';

class DevicesBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => DevicesController(), fenix: true);
  }
}
