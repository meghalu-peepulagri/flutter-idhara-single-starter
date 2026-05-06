import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/repository/user_profile/user_profile_repo_impl.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';

export 'sidebar_controller.dart';

// Sidebar Controller
class SidebarController extends GetxController {
  var selectedRoute = '/dashboard'.obs;
  final userName = ''.obs;
  final appVersion = ''.obs;

  void setSelectedRoute(String route) {
    selectedRoute.value = route;
  }

  @override
  void onInit() {
    super.onInit();
    setSelectedRoute(Get.currentRoute);
    _fetchUserName();
    _fetchAppVersion();
  }

  Future<void> _fetchUserName() async {
    try {
      final response = await UserProfileRepoImpl().getUserProfile();
      if (response?.data?.fullName != null) {
        userName.value = response!.data!.fullName!;
      }
    } catch (_) {}
  }

  Future<void> _fetchAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = info.version;
    } catch (_) {}
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
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF004E7E), // main blue
                        Color(0xFF3686AF), // lighter gradient blue
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
              dense: true,
              horizontalTitleGap: 15,
              minLeadingWidth: 10,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            )),
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
                              Get.offAllNamed(Routes.dashboard,
                                  arguments: {"refresh": true});
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
                    _buildMenuItem(
                        route: Routes.devices,
                        label: 'Devices',
                        icon: SvgPicture.asset(
                          'assets/images/Device Icon.svg',
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
                    _buildMenuItem(
                        route: Routes.settingsDevices,
                        label: 'Settings',
                        icon: Icon(
                          Icons.settings_outlined,
                          color: _controller.selectedRoute.value ==
                                  Routes.settingsDevices
                              ? Colors.white
                              : Colors.black.withOpacity(0.7),
                          size: 22,
                        ),
                        onTap: () {
                          Get.offNamed(Routes.settingsDevices);
                        },
                        context: context),
                    _buildMenuItem(
                        route: Routes.userprofile,
                        label: 'Profile',
                        icon: Icon(
                          Icons.person,
                          color: _controller.selectedRoute.value ==
                                  Routes.userprofile
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).primaryText,
                          size: 24,
                        ),
                        onTap: () {
                          Get.offNamed(Routes.userprofile);
                        },
                        count: null,
                        context: context),
                  ].divide(const SizedBox(height: 2)),
                ),
              ),
            ),
            const Divider(color: Color(0xFFCCDEF5), thickness: 1, height: 1),
            Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                          ),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _controller.userName.value.isNotEmpty
                                  ? _controller.userName.value
                                  : '—',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F0F0F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_controller.appVersion.value.isNotEmpty)
                              Text(
                                'v${_controller.appVersion.value}',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
