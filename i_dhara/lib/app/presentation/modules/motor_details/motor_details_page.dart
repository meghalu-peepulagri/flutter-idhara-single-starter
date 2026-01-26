import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/components/motor_details_card.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/motor_details_tab_bar.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_logs_tab.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_mode_tab.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_runtime_tab.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'motor_details_controller.dart';

export 'motor_details_controller.dart';

class MotorControlWidget extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AnalyticsController controller = Get.put(AnalyticsController());

  MotorControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Get.offAllNamed(Routes.dashboard);
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFFEBF3FE),
          body: SafeArea(
            child: Obx(() {
              if (controller.isMotorDetailsLoading.value) {
                return const Padding(
                  padding: EdgeInsets.only(right: 50),
                  child: Center(child: AppLottieLoading()),
                );
              } else if (!controller.hasInternet.value) {
                return const Center(
                  child: NoInternetWidget(),
                );
              }
              return Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(1.0, 8.0, 0.0, 0.0),
                child: Column(mainAxisSize: MainAxisSize.max, children: [
                  _buildHeader(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.onrefresh,
                      child: Skeletonizer(
                        enabled: controller.isRefreshing.value,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              MotorDetailsCard(controller: controller),
                              const SizedBox(height: 12),
                              MotorDetailsTabBar(controller: controller),
                              Expanded(
                                child: Obx(() => _buildTabContent(context)),
                              ),
                            ].addToStart(const SizedBox(height: 10.0)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Obx(() => Text(
                  controller.motorName.value,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: const Color(0xFF004E7E),
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: const BoxDecoration(),
              child: InkWell(
                onTap: () {
                  Get.offAllNamed(Routes.dashboard,
                      arguments: {"refresh": true});
                },
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF004E7E),
                    size: 20.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return switch (controller.selectedTabIndex.value) {
      0 => MotorModeTab(controller: controller),
      1 => MotorRuntimeTab(controller: controller),
      2 => const MotorLogsTab(),
      _ => MotorRuntimeTab(controller: controller),
    };
  }
}
