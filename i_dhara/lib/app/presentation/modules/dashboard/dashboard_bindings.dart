import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Force-delete any stale instance before creating a fresh one.
    //
    // Without this, navigating to /dashboard while a DashboardController is
    // already registered (e.g. sidebar "Home" tap from the dashboard itself,
    // or Get.offAllNamed from motor-details) causes Get.find in the widget to
    // return the *existing* controller that GetX is about to dispose.  The new
    // widget then holds a reference to a closed controller whose observables
    // no longer emit, so isLoading never triggers and onInit is never called.
    //
    // Get.put (not lazyPut) creates the instance eagerly here so onInit runs
    // and data loading begins before the widget tree is even built.
    if (Get.isRegistered<DashboardController>()) {
      Get.delete<DashboardController>(force: true);
    }
    Get.put<DashboardController>(DashboardController());
  }
}
