// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/utils/no_data_svg/no_data_svg.dart';
// import 'package:i_dhara/app/core/utils/text_fields/app_search_field.dart';
// import 'package:i_dhara/app/presentation/modules/locations/locations_controller.dart';
// import 'package:i_dhara/app/presentation/modules/locations/new_location/add_new_location.dart';
// import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
// import 'package:i_dhara/app/presentation/routes/app_routes.dart';
// import 'package:i_dhara/app/presentation/widgets/location_card.dart';
// import 'package:skeletonizer/skeletonizer.dart';

// import '../../../core/flutter_flow/flutter_flow_theme.dart';
// import '../../../core/flutter_flow/flutter_flow_util.dart';

// export 'locations_controller.dart';

// class LocationsWidget extends StatelessWidget {
//   final scaffoldKey = GlobalKey<ScaffoldState>();
//   final LocationsController controller = Get.put(LocationsController());

//   LocationsWidget({super.key});

//   void onTapMenu() {
//     scaffoldKey.currentState!.openEndDrawer();
//   }

//   ontaplocation(BuildContext context) {
//     showModalBottomSheet(
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
//       ),
//       context: context,
//       builder: (BuildContext context) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: NewLocation(
//             onLocationAdded: (String newLocation) {},
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () {
//         return Future.value(false);
//       },
//       child: GestureDetector(
//         onTap: () {
//           FocusScope.of(context).unfocus();
//           FocusManager.instance.primaryFocus?.unfocus();
//         },
//         child: Scaffold(
//           key: scaffoldKey,
//           backgroundColor: const Color(0xFFEBF3FE),
//           endDrawer: Drawer(width: 250, elevation: 16, child: SidebarWidget()),
//           body: SafeArea(
//             top: true,
//             child: Column(mainAxisSize: MainAxisSize.max, children: [
//               Padding(
//                 padding:
//                     const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.max,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         Get.offAllNamed(Routes.dashboard);
//                       },
//                       child: const Icon(
//                         Icons.arrow_back,
//                         color: Color(0xFF004E7E),
//                         size: 20.0,
//                       ),
//                     ),
//                     Expanded(
//                       child: Row(
//                           mainAxisSize: MainAxisSize.max,
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Locations ',
//                               style: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w500,
//                                       fontStyle: FlutterFlowTheme.of(context)
//                                           .bodyMedium
//                                           .fontStyle,
//                                     ),
//                                     color: const Color(0xFF004E7E),
//                                     fontSize: 16.0,
//                                     letterSpacing: 0.0,
//                                     fontWeight: FontWeight.w500,
//                                     fontStyle: FlutterFlowTheme.of(context)
//                                         .bodyMedium
//                                         .fontStyle,
//                                   ),
//                             ),
//                             GestureDetector(
//                               onTap: () {
//                                 onTapMenu();
//                               },
//                               child: Container(
//                                 decoration: const BoxDecoration(),
//                                 child: const Padding(
//                                   padding: EdgeInsets.all(6.0),
//                                   child: Icon(
//                                     Icons.menu_sharp,
//                                     color: Color(0xFF121212),
//                                     size: 30.0,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ]),
//                     ),
//                   ].divide(const SizedBox(width: 100.0)),
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsetsDirectional.fromSTEB(
//                       16.0, 0.0, 16.0, 0.0),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.max,
//                     children: [
//                       Container(
//                         child: Row(
//                             mainAxisSize: MainAxisSize.max,
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Expanded(
//                                 child: SizedBox(
//                                   height: 40,
//                                   child: SearchFieldComponent(
//                                     controller: controller.controller1,
//                                     hintText: 'Search Locations',
//                                   ),
//                                 ),
//                               ),
//                             ]),
//                       ),
//                       Expanded(
//                         child: Obx(() {
//                           if (controller.isLoading.value) {
//                             return const Center(
//                               child: CircularProgressIndicator(),
//                             );
//                           }

//                           if (controller.locationsList.isEmpty) {
//                             return const NoLocationsFound();
//                           }

//                           return Skeletonizer(
//                             enabled: controller.isRefreshing.value,
//                             child: RefreshIndicator(
//                               onRefresh: () => controller.refreshLocations(),
//                               child: ListView(
//                                 padding: EdgeInsets.zero,
//                                 shrinkWrap: true,
//                                 scrollDirection: Axis.vertical,
//                                 children: [
//                                   Row(
//                                     mainAxisSize: MainAxisSize.max,
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(
//                                         'Locations',
//                                         style: FlutterFlowTheme.of(context)
//                                             .bodyMedium
//                                             .override(
//                                               font: GoogleFonts.dmSans(
//                                                 fontWeight: FontWeight.w500,
//                                                 fontStyle:
//                                                     FlutterFlowTheme.of(context)
//                                                         .bodyMedium
//                                                         .fontStyle,
//                                               ),
//                                               color: const Color(0xFF0A0A0A),
//                                               fontSize: 18.0,
//                                               letterSpacing: 0.0,
//                                               fontWeight: FontWeight.w500,
//                                               fontStyle:
//                                                   FlutterFlowTheme.of(context)
//                                                       .bodyMedium
//                                                       .fontStyle,
//                                             ),
//                                       ),
//                                       Row(
//                                         children: [
//                                           InkWell(
//                                             onTap: () {
//                                               ontaplocation(context);
//                                             },
//                                             child: Container(
//                                               decoration: BoxDecoration(
//                                                 gradient: const LinearGradient(
//                                                   begin: Alignment.topLeft,
//                                                   end: Alignment.bottomRight,
//                                                   colors: [
//                                                     Color(0xFF3686AF),
//                                                     Color(0xFF004E7E),
//                                                   ],
//                                                 ),
//                                                 borderRadius:
//                                                     BorderRadius.circular(6),
//                                               ),
//                                               padding:
//                                                   const EdgeInsetsDirectional
//                                                       .fromSTEB(
//                                                       10.0, 6.0, 10.0, 6.0),
//                                               child: Row(
//                                                 children: [
//                                                   const Icon(
//                                                     Icons.add,
//                                                     size: 16,
//                                                     color: Colors.white,
//                                                   ),
//                                                   const SizedBox(width: 4),
//                                                   Text(
//                                                     'Add',
//                                                     style: FlutterFlowTheme.of(
//                                                             context)
//                                                         .bodySmall
//                                                         .override(
//                                                           fontSize: 14,
//                                                           font: GoogleFonts
//                                                               .dmSans(
//                                                             fontWeight:
//                                                                 FontWeight.w500,
//                                                           ),
//                                                           color: Colors.white,
//                                                         ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(width: 8),
//                                           Container(
//                                             decoration: BoxDecoration(
//                                               color:
//                                                   FlutterFlowTheme.of(context)
//                                                       .secondaryBackground,
//                                               border: Border.all(
//                                                 color: const Color(0xFFEFEFEF),
//                                               ),
//                                             ),
//                                             child: Padding(
//                                               padding:
//                                                   const EdgeInsetsDirectional
//                                                       .fromSTEB(
//                                                       8.0, 6.0, 8.0, 6.0),
//                                               child: Text(
//                                                 '${controller.locationsList.length}',
//                                                 style: FlutterFlowTheme.of(
//                                                         context)
//                                                     .bodyMedium
//                                                     .override(
//                                                       fontSize: 14,
//                                                       font: GoogleFonts.dmSans(
//                                                         fontWeight:
//                                                             FlutterFlowTheme.of(
//                                                                     context)
//                                                                 .bodyMedium
//                                                                 .fontWeight,
//                                                         fontStyle:
//                                                             FlutterFlowTheme.of(
//                                                                     context)
//                                                                 .bodyMedium
//                                                                 .fontStyle,
//                                                       ),
//                                                       color: const Color(
//                                                           0xFF087D40),
//                                                       letterSpacing: 0.0,
//                                                     ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 8.0),
//                                   ...controller.locationsList.map((location) {
//                                     return Container(
//                                       margin:
//                                           const EdgeInsets.only(bottom: 12.0),
//                                       decoration: BoxDecoration(
//                                         color: FlutterFlowTheme.of(context)
//                                             .secondaryBackground,
//                                         borderRadius:
//                                             BorderRadius.circular(8.0),
//                                         border: Border.all(
//                                           color: const Color(0xFFEFEFEF),
//                                         ),
//                                       ),
//                                       child: LocationCard(
//                                         location: location,
//                                         isExpanded:
//                                             controller.isLocationExpanded(
//                                                 location.id ?? 0),
//                                         onToggle: () =>
//                                             controller.toggleLocationExpansion(
//                                                 location.id ?? 0),
//                                       ),
//                                     );
//                                   }),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }),
//                       ),
//                     ]
//                         .divide(const SizedBox(height: 16.0))
//                         .addToStart(const SizedBox(height: 24.0)),
//                   ),
//                 ),
//               ),
//             ]),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/no_data_svg/no_data_svg.dart';
import 'package:i_dhara/app/core/utils/text_fields/app_search_field.dart';
import 'package:i_dhara/app/presentation/modules/locations/locations_controller.dart';
import 'package:i_dhara/app/presentation/modules/locations/new_location/add_new_location.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/location_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../core/flutter_flow/flutter_flow_util.dart';

export 'locations_controller.dart';

class LocationsWidget extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final LocationsController controller = Get.put(LocationsController());

  LocationsWidget({super.key});

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  ontaplocation(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NewLocation(
            onLocationAdded: (String newLocation) {},
          ),
        );
      },
    );
  }

  // Extract the header row as a separate method
  Widget _buildHeaderRow(BuildContext context, int count) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Locations',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                color: const Color(0xFF0A0A0A),
                fontSize: 18.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () {
                ontaplocation(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3686AF),
                      Color(0xFF004E7E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding:
                    const EdgeInsetsDirectional.fromSTEB(10.0, 6.0, 10.0, 6.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontSize: 14,
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w500,
                            ),
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                border: Border.all(
                  color: const Color(0xFFEFEFEF),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(8.0, 6.0, 8.0, 6.0),
                child: Text(
                  '$count',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontSize: 14,
                        font: GoogleFonts.dmSans(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: const Color(0xFF087D40),
                        letterSpacing: 0.0,
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
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
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.offAllNamed(Routes.dashboard);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF004E7E),
                        size: 20.0,
                      ),
                    ),
                    Expanded(
                      child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Locations ',
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
                          ]),
                    ),
                  ].divide(const SizedBox(width: 100.0)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 0.0, 16.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: SearchFieldComponent(
                                    controller: controller.controller1,
                                    hintText: 'Search Locations',
                                  ),
                                ),
                              ),
                            ]),
                      ),
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value) {
                            return const AppLottieLoading();
                          }

                          return Column(
                            children: [
                              _buildHeaderRow(
                                  context, controller.locationsList.length),
                              const SizedBox(height: 8.0),
                              Expanded(
                                child: controller.locationsList.isEmpty
                                    ? const NoLocationsFound()
                                    : Skeletonizer(
                                        enabled: controller.isRefreshing.value,
                                        child: RefreshIndicator(
                                          onRefresh: () =>
                                              controller.refreshLocations(),
                                          child: ListView(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            children: [
                                              ...controller.locationsList
                                                  .map((location) {
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 12.0),
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFFEFEFEF),
                                                    ),
                                                  ),
                                                  child: LocationCard(
                                                    location: location,
                                                    isExpanded: controller
                                                        .isLocationExpanded(
                                                            location.id ?? 0),
                                                    onToggle: () => controller
                                                        .toggleLocationExpansion(
                                                            location.id ?? 0),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ]
                        .divide(const SizedBox(height: 16.0))
                        .addToStart(const SizedBox(height: 24.0)),
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
