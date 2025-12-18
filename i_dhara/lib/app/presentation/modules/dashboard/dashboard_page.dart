import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/bottomsheets/location_bottomsheet.dart';
import 'package:i_dhara/app/core/utils/no_data_svg/no_data_svg.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/weather_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../core/flutter_flow/flutter_flow_util.dart';
import '../../widgets/motor_card/motor_card_widget.dart';
import 'dashboard_controller.dart';

export 'dashboard_controller.dart';

class DashboardWidget extends StatelessWidget {
  DashboardWidget({super.key});

  final unfocusNode = FocusNode();

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final controller = Get.put(DashboardController());

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        // bottomNavigationBar: const BottomNavigation(activeIndex: 0),
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
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
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
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => LocationBottomSheet(),
                                );
                              },
                              child: Obx(() {
                                final selectedId =
                                    controller.selectedLocationId.value;

                                //                             final locationName = controller.locations
                                // .firstWhere((e) => e.id == selectedId)
                                // .name;

                                String locationName;

                                if (selectedId == null) {
                                  locationName = "All";
                                } else {
                                  locationName = controller.locations
                                          .firstWhere((e) => e.id == selectedId)
                                          .name ??
                                      "Location";
                                }

                                return Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/location_pin.svg',
                                      width: 20,
                                      fit: BoxFit.cover,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      locationName,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
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
                            ),
                            // ClipRRect(
                            //   borderRadius: BorderRadius.circular(0.0),
                            //   child: SvgPicture.asset(
                            //     'assets/images/bell-simple_1.svg',
                            //     fit: BoxFit.cover,
                            //   ),
                            // ),
                          ].divide(const SizedBox(width: 10.0)),
                        ),
                        GestureDetector(
                          onTap: () {
                            onTapMenu();
                          },
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 0.0, 16.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const WeatherCard(),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     color: Colors.white,
                      //     borderRadius: BorderRadius.circular(6.0),
                      //     border: Border.all(
                      //       color: const Color(0xFFE5E7EB),
                      //     ),
                      //   ),
                      //   child: Padding(
                      //     padding: const EdgeInsetsDirectional.fromSTEB(
                      //         12.0, 8.0, 12.0, 8.0),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.max,
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         Row(
                      //           mainAxisSize: MainAxisSize.max,
                      //           children: [
                      //             const Icon(
                      //               Icons.search,
                      //               color: Color(0xFF828282),
                      //               size: 20.0,
                      //             ),
                      //             Text(
                      //               'Search Pumps ',
                      //               style: FlutterFlowTheme.of(context)
                      //                   .bodyMedium
                      //                   .override(
                      //                     font: GoogleFonts.dmSans(
                      //                       fontWeight: FontWeight.w500,
                      //                       fontStyle:
                      //                           FlutterFlowTheme.of(context)
                      //                               .bodyMedium
                      //                               .fontStyle,
                      //                     ),
                      //                     color: const Color(0xFF828282),
                      //                     fontSize: 16.0,
                      //                     letterSpacing: 0.0,
                      //                     fontWeight: FontWeight.w500,
                      //                     fontStyle:
                      //                         FlutterFlowTheme.of(context)
                      //                             .bodyMedium
                      //                             .fontStyle,
                      //                   ),
                      //             ),
                      //           ].divide(const SizedBox(width: 8.0)),
                      //         ),
                      //         Padding(
                      //           padding: const EdgeInsetsDirectional.fromSTEB(
                      //               0.0, 0.0, 6.0, 0.0),
                      //           child: Row(
                      //             mainAxisSize: MainAxisSize.max,
                      //             children: [
                      //               SizedBox(
                      //                 height: 30.0,
                      //                 child: VerticalDivider(
                      //                   thickness: 1.0,
                      //                   color: FlutterFlowTheme.of(context)
                      //                       .alternate,
                      //                 ),
                      //               ),
                      //               Container(
                      //                 decoration: const BoxDecoration(),
                      //                 child: Padding(
                      //                   padding: const EdgeInsets.all(6.0),
                      //                   child: GestureDetector(
                      //                     onTap: () async {
                      //                       await showModalBottomSheet(
                      //                         isScrollControlled: true,
                      //                         backgroundColor:
                      //                             Colors.transparent,
                      //                         context: context,
                      //                         builder: (context) {
                      //                           return Padding(
                      //                             padding:
                      //                                 MediaQuery.of(context)
                      //                                     .viewInsets,
                      //                             child: const SizedBox(
                      //                                 height: 400,
                      //                                 child:
                      //                                     FiltersBottomsheetWidget()),
                      //                           );
                      //                         },
                      //                       );
                      //                     },
                      //                     child: Icon(
                      //                       Icons.filter_list_outlined,
                      //                       color: FlutterFlowTheme.of(context)
                      //                           .primaryText,
                      //                       size: 20.0,
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ),
                      //             ].divide(const SizedBox(width: 10.0)),
                      //           ),
                      //         ),
                      //       ].divide(const SizedBox(width: 8.0)),
                      //     ),
                      //   ),
                      // ),
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value ||
                              controller.isFiltering.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (controller.motors.isEmpty) {
                            return const NoMotorFound();
                          }
                          return Skeletonizer(
                            enabled: controller.isRefreshing.value,
                            child: RefreshIndicator(
                              onRefresh: controller.refreshMotors,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 0, 0, 24.0),
                                itemCount: controller.motors.length,
                                itemBuilder: (context, index) {
                                  final motor = controller.motors[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GestureDetector(
                                      onTap: () {
                                        SharedPreference.setMotorId(
                                            motor.id ?? 0);
                                        SharedPreference.setStarterId(
                                            motor.starter?.id ?? 0);
                                        Get.toNamed(
                                          Routes.motorDetails,
                                          arguments: {
                                            'motor': motor,
                                            'motorId': motor.id,
                                            'motorName': motor.name ?? 'Motor',
                                            'deviceId':
                                                motor.starter?.macAddress ??
                                                    'N/A',
                                          },
                                        );
                                      },
                                      child: MotorCardWidget(
                                        motor: motor,
                                        mqttService: controller.mqttService,
                                        onToggleMotor: controller.toggleMotor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ]
                        .divide(const SizedBox(height: 10.0))
                        .addToStart(const SizedBox(height: 20.0)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
