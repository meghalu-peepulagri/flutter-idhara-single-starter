import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

export 'sidebar_controller.dart';

// Sidebar Controller
class SidebarController extends GetxController {
  var selectedRoute = '/dashboard'.obs;

  void setSelectedRoute(String route) {
    selectedRoute.value = route;
  }

  @override
  onInit() {
    super.onInit();
    setSelectedRoute(Get.currentRoute);
  }
}

class SidebarWidget extends StatelessWidget {
  SidebarWidget({super.key});

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  // Initialize the controller
  final SidebarController _controller = Get.put(SidebarController());

  // Helper method to build menu item
  Widget _buildMenuItem(
      {required String route,
      required String label,
      required Widget icon,
      required VoidCallback onTap,
      String? count,
      required BuildContext context}) {
    return Obx(() {
      bool isSelected = _controller.selectedRoute.value == route;
      return GestureDetector(
        onTap: () {
          _controller.setSelectedRoute(route); // Update selected route
          onTap();
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            // decoration: BoxDecoration(
            //   color: isSelected
            //       ? FlutterFlowTheme.of(context).primary.withOpacity(0.1)
            //       : Colors.transparent,
            //   borderRadius: BorderRadius.circular(8),
            // ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3686AF), // main blue
                        Color(0xFF004E7E), // lighter gradient blue
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              trailing: count == null ? null : Text(count ?? ""),
              leading: icon,
              title: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 15, // slightly smaller font
                  textStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF0F0F0F),
                    letterSpacing: .4,
                  ),
                ),
              ),
              dense: true, // makes tile vertically smaller
              horizontalTitleGap: 15, // reduce space between icon and text
              minLeadingWidth: 10, // tighten icon width
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            )

            //  Row(
            //   mainAxisSize: MainAxisSize.max,
            //   children: [
            //     icon,
            //     const SizedBox(width: 16),
            //     Text(
            //       label,
            //       style: GoogleFonts.lato(
            //         fontSize: 17,
            //         textStyle: TextStyle(
            //             fontWeight:
            //                 isSelected ? FontWeight.w600 : FontWeight.w500,
            //             color: isSelected
            //                 ? FlutterFlowTheme.of(context).primary
            //                 : const Color(0xFF0F0F0F),
            //             letterSpacing: .5),
            //       ),
            //     )
            //   ],
            // ),
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FE),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x0F000000),
            offset: Offset(0, 0),
          ),
        ],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => Get.back(),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 30, right: 20),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
                        child: _buildMenuItem(
                            route: Routes.dashboard,
                            label: 'Home',
                            icon: SvgPicture.asset(
                              'assets/images/Home.svg',
                              height: 22,
                              width: 22,
                              fit: BoxFit.cover,
                              color: _controller.selectedRoute.value ==
                                      Routes.dashboard
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onTap: () {
                              // SharedPreference.setRouting('/gateway');
                              // SharedPreference.setlocationdropdownid(0);
                              Get.offNamed(Routes.dashboard);
                            },
                            // count: SharedPreference.getPondstats(),
                            context: context)),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                      child: _buildMenuItem(
                          route: Routes.locations,
                          label: 'Locations',
                          icon: SvgPicture.asset(
                            'assets/images/location.svg',
                            height: 22,
                            width: 22,
                            fit: BoxFit.cover,
                            color: _controller.selectedRoute.value ==
                                    Routes.locations
                                ? Colors.white
                                : FlutterFlowTheme.of(context).primaryText,
                          ),
                          onTap: () {
                            // Get.delete<SidebarLocationController>();
                            // SharedPreference.setRouting('/locations');
                            // SharedPreference.setlocationdropdownid(0);
                            Get.offNamed(Routes.locations);
                          },
                          // count: SharedPreference.getlocationstats(),
                          context: context),
                    ),
                    // _buildMenuItem(
                    //     route: Routes.gateway,
                    //     label: 'Gateways',
                    //     icon: SvgPicture.asset(
                    //       'assets/images/wifi.svg',
                    //       height: 24,
                    //       width: 24,
                    //       fit: BoxFit.cover,
                    //       color:
                    //           _controller.selectedRoute.value == Routes.gateway
                    //               ? FlutterFlowTheme.of(context).primary
                    //               : null,
                    //     ),
                    //     onTap: () {
                    //       // SharedPreference.setRouting('/gateway');
                    //       // SharedPreference.setlocationdropdownid(0);
                    //       // Get.offNamed(Routes.gateway);
                    //     },
                    //     count: null,
                    //     context: context),
                    _buildMenuItem(
                        route: Routes.devices,
                        label: 'Devices',
                        icon: SvgPicture.asset(
                          'assets/images/devices.svg',
                          height: 22,
                          width: 22,
                          fit: BoxFit.cover,
                          color:
                              _controller.selectedRoute.value == Routes.devices
                                  ? Colors.white
                                  : null,
                        ),
                        onTap: () {
                          // SharedPreference.setRouting('/starters');
                          // SharedPreference.setlocationdropdownid(0);
                          Get.offNamed(Routes.devices);
                        },
                        // count: SharedPreference.getstarterStats(),
                        context: context),
                    // _buildMenuItem(
                    //     route: Routes.userprofile,
                    //     label: 'Profile',
                    //     icon: Icon(
                    //       Icons.person,
                    //       color: _controller.selectedRoute.value ==
                    //               Routes.userprofile
                    //           ? FlutterFlowTheme.of(context).primary
                    //           : FlutterFlowTheme.of(context).primaryText,
                    //       size: 24,
                    //     ),
                    //     onTap: () {
                    //       SharedPreference.setlocationdropdownid(0);
                    //       Get.offNamed(Routes.userprofile);
                    //     },
                    //     count: null,
                    //     context: context),
                  ].divide(const SizedBox(height: 2)),
                ),
              ),
            ),
            // Logout Section at the Bottom
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 4, 16),
              child: ValueListenableBuilder(
                valueListenable: _isLoading,
                builder: (context, isLoading, child) {
                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            // _isLoading.value = true;
                            // await _model.fetchfcmtoken();
                            // if (!_model.isError && !_model.isMessage.isEmpty) {
                            Get.offAllNamed(Routes.loginwithmobile);
                            SharedPreference.clear();
                            //   FirebaseMessaging.instance
                            //       .getToken()
                            //       .then((value) {
                            //     SharedPreference.setFcmToken(value!);
                            //   });
                            // } else {
                            //   errorSnackBar(context, _model.isMessage);
                            // }
                            // _isLoading.value = false;
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEB5757),
                          size: 20.0,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            'LOG OUT',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              color: Color(0xFFEB5757),
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                        const Spacer(),
                        isLoading
                            ? const SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFEB5757),
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFEB5757),
                                size: 25.0,
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
