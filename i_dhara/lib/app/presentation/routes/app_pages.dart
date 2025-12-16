import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/modules/auth/login_with_mobile/login_with_mobile_page.dart';
import 'package:i_dhara/app/presentation/modules/auth/otp/otp_bindings.dart';
import 'package:i_dhara/app/presentation/modules/auth/otp/otp_page.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_bindings.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_page.dart';
import 'package:i_dhara/app/presentation/modules/devices/add_devices/add_devices_page.dart';
import 'package:i_dhara/app/presentation/modules/devices/devices_bindings.dart';
import 'package:i_dhara/app/presentation/modules/devices/devices_page.dart';
import 'package:i_dhara/app/presentation/modules/locations/locations_page.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_page.dart';
import 'package:i_dhara/app/presentation/modules/qr_code/q_r_code_page.dart';
import 'package:i_dhara/app/presentation/modules/splash_screen/splash_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class AppPages {
  static final getPages = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashCopyWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.loginwithmobile,
      page: () => const LoginwithmobileWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
        name: Routes.otp,
        page: () => OtpWidget(),
        transition: Transition.fade,
        transitionDuration: const Duration(milliseconds: 300),
        binding: OtpBinding()),
    GetPage(
      name: Routes.dashboard,
      page: () => DashboardWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.locations,
      page: () => LocationsWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
        name: Routes.devices,
        page: () => DevicesPage(),
        transition: Transition.fade,
        transitionDuration: const Duration(milliseconds: 300),
        binding: DevicesBinding()),
    GetPage(
      name: Routes.qrCode,
      page: () => const QRCodeWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.addDevices,
      page: () => const AddDevicesWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.motorDetails,
      page: () => const MotorControlWidget(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
