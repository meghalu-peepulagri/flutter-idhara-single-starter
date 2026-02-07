import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/bottomsheets/location_bottomsheet.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_card_widget.dart';
import 'package:i_dhara/app/presentation/components/weather_card.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/widgets/no_data_view.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../core/flutter_flow/flutter_flow_util.dart';
import 'dashboard_controller.dart';

export 'dashboard_controller.dart';

class DashboardWidget extends StatelessWidget {
  DashboardWidget({super.key});

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final controller = Get.put(DashboardController(), permanent: true);
  final ScrollController _scrollController = ScrollController();

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !controller.isLoadingMore.value &&
          !controller.isLoading.value &&
          !controller.isRefreshing.value) {
        controller.loadMoreMotors();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await SystemNavigator.pop();
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          endDrawer: Drawer(width: 250, elevation: 16, child: SidebarWidget()),
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: Image.asset(
                    'assets/images/idhara_background.png',
                  ).image,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0, 0.0, 16.0, 0.0),
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 50),
                            child: Center(
                              child: AppLottieLoading(),
                            ),
                          );
                        } else if (!controller.hasInternet.value) {
                          return const Center(
                            child: NoInternetWidget(),
                          );
                        }
                        return Column(
                          children: [
                            const WeatherCard(),
                            Expanded(child: _buildMotorList()),
                          ]
                              .divide(const SizedBox(height: 10.0))
                              .addToStart(const SizedBox(height: 10.0)),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0.0),
            child: SvgPicture.asset(
              'assets/images/idhara_logo.svg',
              fit: BoxFit.cover,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildLocationSelector(context),
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
            ].divide(const SizedBox(width: 8.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => const LocationBottomSheet(),
        );
      },
      child: Obx(() {
        final selectedId = controller.selectedLocationId.value;
        String locationName;

        if (selectedId == null) {
          locationName = "All";
        } else {
          locationName = controller.locations
                  .firstWhereOrNull((e) => e.id == selectedId)
                  ?.name ??
              "Location";
        }

        final displayName = locationName.length > 10
            ? '${locationName.substring(0, 10)}…'
            : locationName;

        return Row(
          children: [
            SvgPicture.asset(
              'assets/images/location_pin.svg',
              width: 20,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 4),
            Text(
              displayName,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 30,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMotorList() {
    return Obx(() {
      if (controller.isFiltering.value) {
        return const Padding(
          padding: EdgeInsets.only(right: 50),
          child: Center(child: AppLottieLoading()),
        );
      } else if (controller.motors.isEmpty && !controller.isLoading.value) {
        return const NoMotorFound();
      }

      return Skeletonizer(
        enabled: controller.isRefreshing.value,
        child: RefreshIndicator(
          onRefresh: controller.refreshMotors,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24.0),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.motors.length +
                (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.motors.length) {
                return Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                });
              }

              final motor = controller.motors[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MotorCardWidget(
                  motor: motor,
                  mqttService: controller.mqttService,
                  onToggleMotor: controller.toggleMotor,
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
