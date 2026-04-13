import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/services/connectivity_service.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/text_fields/app_search_field.dart';
import 'package:i_dhara/app/presentation/components/settings_device_card.dart';
import 'package:i_dhara/app/presentation/modules/devices/devices_controller.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/no_data_view.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsDevicesPage extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  SettingsDevicesPage({super.key});

  final DevicesController controller = Get.put(DevicesController());

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed(Routes.dashboard, arguments: {"refresh": true});
        return false;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFFEBF3FE),
          endDrawer: Drawer(width: 250, elevation: 16, child: SidebarWidget()),
          body: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 8.0, 16.0, 0.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Device Settings',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: const Color(0xFF004E7E),
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.offAllNamed(
                                    Routes.dashboard,
                                    arguments: {'refresh': true},
                                  );
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF004E7E),
                                  size: 20.0,
                                ),
                              ),
                              GestureDetector(
                                onTap: onTapMenu,
                                child: Container(
                                  decoration: const BoxDecoration(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(
                                      Icons.menu_sharp,
                                      color: Color(0xFF121212),
                                      size: 30.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        16.0, 0.0, 16.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: SearchFieldComponent(
                                  controller: controller.controller1,
                                  hintText: 'Search devices',
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(width: 10)),
                        ),
                        Expanded(
                          child: Obx(() {
                            if (controller.isInitialLoading.value) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 50, right: 50),
                                child: Center(child: AppLottieLoading()),
                              );
                            } else if (!ConnectivityService.to.isConnected) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 70),
                                child: Center(child: NoInternetWidget()),
                              );
                            }
                            if (controller.devicesList.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 100),
                                child: Center(child: NoStartersFound()),
                              );
                            }
                            return Column(
                              children: [
                                Expanded(
                                  child: Skeletonizer(
                                    enabled: controller.isRefreshing.value,
                                    child: RefreshIndicator(
                                      onRefresh: controller.refreshDevices,
                                      child: ListView.separated(
                                        controller: controller.scrollController,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemCount:
                                            controller.devicesList.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 12.0),
                                        itemBuilder: (context, index) {
                                          final device =
                                              controller.devicesList[index];
                                          return SettingsDeviceCard(
                                              device: device);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                if (controller.isHasMoreLoading.value)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ]
                          .divide(const SizedBox(height: 16.0))
                          .addToStart(const SizedBox(height: 8.0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
