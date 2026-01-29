import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/controllers/language_controller.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';

class LanguageBindings extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => LanguageController(), fenix: true);
  }
}
