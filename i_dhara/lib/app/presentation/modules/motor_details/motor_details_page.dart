import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/no_data_svg/no_internet.dart';
import 'package:i_dhara/app/presentation/widgets/graphs/motor_run_time_graph_card.dart';
import 'package:i_dhara/app/presentation/widgets/graphs/power_graph_card.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../core/flutter_flow/flutter_flow_util.dart';
import 'motor_details_controller.dart';

export 'motor_details_controller.dart';

class MotorControlWidget extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AnalyticsController controller1 = Get.put(AnalyticsController());

  MotorControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    print("motor name ${controller1.motorName.value}");
    return WillPopScope(
      onWillPop: () async {
        Get.back();
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
          body: SafeArea(
            child: Obx(() {
              if (controller1.isMotorDetailsLoading.value) {
                return const AppLottieLoading();
              } else if (!controller1.hasInternet.value) {
                return const Center(
                  child: NoInternetWidget(),
                );
              }
              return Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(1.0, 8.0, 0.0, 0.0),
                child: Column(mainAxisSize: MainAxisSize.max, children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        16.0, 0.0, 16.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: const BoxDecoration(),
                          child: InkWell(
                            onTap: () {
                              Get.back();
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
                        Text(
                          controller1.motorName.value.capitalizeFirst!,
                          // controller1.motorName.value.capitalizeFirst!,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
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
                        Opacity(
                          opacity: 0.0,
                          child: Icon(
                            Icons.arrow_back,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
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
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Obx(() {
                                              return Text(
                                                controller1.motorName.value
                                                    .capitalizeFirst!,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.dmSans(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: const Color(
                                                          0xFF0A0A0A),
                                                      fontSize: 20.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              );
                                            }),
                                            const SizedBox(width: 2),
                                            Obx(() {
                                              return Text(
                                                'HP : ${controller1.hp.value}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.dmSans(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: const Color(
                                                          0xFF6A7282),
                                                      fontSize: 14.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              );
                                            }),
                                            const SizedBox(width: 2),
                                            Obx(() {
                                              final deviceId =
                                                  controller1.deviceId.value;
                                              final displayId = deviceId
                                                          .length >
                                                      10
                                                  ? '${deviceId.substring(0, 10)}...'
                                                  : deviceId;
                                              return Text(
                                                'PCB: $displayId',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.dmSans(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: const Color(
                                                          0xFF6A7282),
                                                      fontSize: 14.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              );
                                            }),
                                            // const SizedBox(height: 8.0),
                                            // Toggle Switch - separate row
                                            // Obx(() {
                                            //   final mode = controller1
                                            //       .motorMode.value
                                            //       .toLowerCase();
                                            //   final isAuto = mode == 'auto';
                                            //   final int selectedIndex =
                                            //       isAuto ? 0 : 1;

                                            //   return ToggleSwitch(
                                            //     key: ValueKey(mode),
                                            //     changeOnTap: false,
                                            //     customWidths: const [90, 90],
                                            //     radiusStyle: true,
                                            //     minWidth: 80.0,
                                            //     minHeight: 30.0,
                                            //     initialLabelIndex:
                                            //         selectedIndex,
                                            //     cornerRadius: 8.0,
                                            //     activeBgColor: [
                                            //       isAuto
                                            //           ? const Color(0xFFFFA500)
                                            //               .withOpacity(0.5)
                                            //           : !isAuto
                                            //               ? const Color(
                                            //                       0xFF2F80ED)
                                            //                   .withOpacity(0.5)
                                            //               : const Color(
                                            //                   0xFF2F80ED)
                                            //     ],
                                            //     activeFgColor: Colors.white,
                                            //     inactiveBgColor: Colors.white,
                                            //     inactiveFgColor: Colors.black,
                                            //     fontSize: 12,
                                            //     totalSwitches: 2,
                                            //     labels: const [
                                            //       'Auto',
                                            //       'Manual'
                                            //     ],
                                            //     borderWidth: 1,
                                            //     borderColor: [
                                            //       Colors.grey.shade300
                                            //     ],
                                            //     onToggle: null,
                                            //   );
                                            // }),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          // Obx(() {
                                          //   return AdvancedSwitch(
                                          //     activeColor: Colors.green,
                                          //     inactiveColor:
                                          //         Colors.red.shade500,
                                          //     activeChild: const Text('ON'),
                                          //     inactiveChild: const Text('OFF'),
                                          //     initialValue: controller1
                                          //             .motorState.value ==
                                          //         1,
                                          //     borderRadius:
                                          //         const BorderRadius.all(
                                          //             Radius.circular(15)),
                                          //     width: 55,
                                          //     height: 25,
                                          //     enabled: false,
                                          //     disabledOpacity: 0.5,
                                          //     onChanged: null,
                                          //   );
                                          // }),
                                          const SizedBox(height: 30.0),
                                          Obx(() {
                                            final locationName =
                                                controller1.locationName.value;
                                            final displayName = locationName
                                                        .length >
                                                    15
                                                ? '${locationName.substring(0, 15)}...'
                                                : locationName;
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/images/location.svg',
                                                  fit: BoxFit.cover,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  displayName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.dmSans(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: const Color(
                                                            0xFF6A7282),
                                                        fontSize: 16.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Obx(() {
                                    final fault =
                                        controller1.faultMessage.value.trim();

                                    if (fault.isEmpty)
                                      return const SizedBox.shrink();

                                    return Container(
                                      margin: const EdgeInsets.only(top: 0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCF4D9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Lottie.asset(
                                            'assets/lottie_animations/warning 1.json',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            repeat: true,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              fault,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.dmSans(
                                                        fontWeight:
                                                            FontWeight.w300),
                                                    fontSize: 12,
                                                    color:
                                                        const Color(0xFFFF8A00),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ].divide(const SizedBox(height: 12.0)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Obx(() {
                              return RefreshIndicator(
                                onRefresh: controller1.onrefresh,
                                child: Skeletonizer(
                                  enabled: controller1.isRefreshing.value,
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      0,
                                      0,
                                      24.0,
                                    ),
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    children: [
                                      // Date Card - Always shows current date with month view
                                      _buildDateCard(context, controller1),
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          MotorRuntimeGraphWidget(
                                            selectedDateRange:
                                                controller1.daterange,
                                          ),
                                          PowerGraphWidget(
                                            selectedDateRange:
                                                controller1.daterange,
                                          ),
                                          // VoltageGraphWidget(
                                          //   selectedDateRange:
                                          //       controller1.daterange,
                                          //   motorName:
                                          //       controller1.selectedTitle.value,
                                          //   sharedPointNotifier:
                                          //       controller1.sharedPointNotifier,
                                          //   sharedTimeNotifier:
                                          //       controller1.sharedTimeNotifier,
                                          // ),
                                          // CurrentGraphWidget(
                                          //   sharedPointNotifier:
                                          //       controller1.valueNotifier,
                                          //   sharedTimeNotifier:
                                          //       controller1.sharedTimeNotifier,
                                          //   selectedDateRange:
                                          //       controller1.daterange,
                                          //   motorName:
                                          //       controller1.selectedTitle.value,
                                          // ),
                                        ].divide(const SizedBox(height: 16)),
                                      ),
                                    ].divide(const SizedBox(height: 12.0)),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ]
                            .divide(const SizedBox(height: 12.0))
                            .addToStart(const SizedBox(height: 10.0)),
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

  Widget _buildDateCard(BuildContext context, AnalyticsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Arrow Button
            GestureDetector(
              onTap: () => controller.leftClick(),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF004E7E),
                  size: 18.0,
                ),
              ),
            ),

            // Date Display
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  controller.isModalOpen.value = true;
                  var results = await showCalendarDatePicker2Dialog(
                    context: context,
                    config: CalendarDatePicker2WithActionButtonsConfig(
                      calendarType: CalendarDatePicker2Type.single,
                      lastDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      disableModePicker: true,
                      calendarViewScrollPhysics:
                          const NeverScrollableScrollPhysics(),
                    ),
                    dialogSize: const Size(325, 400),
                    value: [controller.daterange.first],
                    borderRadius: BorderRadius.circular(15),
                  );

                  try {
                    if (results != null &&
                        results.isNotEmpty &&
                        results.first != null) {
                      controller.selectSingleDate(results.first!);
                    }
                  } catch (e) {
                    print('Error selecting date: $e');
                  } finally {
                    controller.isModalOpen.value = false;
                  }
                },
                child: Obx(() {
                  final selectedDate =
                      controller.daterange.first ?? DateTime.now();
                  return Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(selectedDate),
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF6B7280),
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(selectedDate),
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF004E7E),
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // Right Arrow Button
            Obx(() {
              final selectedDate = controller.daterange.first ?? DateTime.now();
              final today = DateTime.now();
              final isToday = selectedDate.year == today.year &&
                  selectedDate.month == today.month &&
                  selectedDate.day == today.day;

              return GestureDetector(
                onTap: isToday ? null : () => controller.rightClick(),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: isToday
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF004E7E),
                    size: 18.0,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget _buildMonthView(BuildContext context, AnalyticsController controller,
  //     DateTime rangeStart, DateTime rangeEnd) {
  //   final today = DateTime.now();

  //   // Get first and last day of current month
  //   final firstDayOfMonth = DateTime(today.year, today.month, 1);
  //   final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
  //   final daysInMonth = lastDayOfMonth.day;

  //   // Check if it's a single date selection or range
  //   final isSingleDateSelection = rangeStart.year == rangeEnd.year &&
  //       rangeStart.month == rangeEnd.month &&
  //       rangeStart.day == rangeEnd.day;
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (controller.monthScrollController.hasClients) {
  //       final todayIndex = today.day - 1; // Index starts from 0
  //       const itemWidth = 45.0 + 8.0; // width + margin (4.0 * 2)
  //       final screenWidth = MediaQuery.of(context).size.width;
  //       final scrollPosition =
  //           (todayIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

  //       controller.monthScrollController.animateTo(
  //         scrollPosition.clamp(
  //             0.0, controller.monthScrollController.position.maxScrollExtent),
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeInOut,
  //       );
  //     }
  //   });

  //   return SizedBox(
  //     height: 70,
  //     child: ListView.builder(
  //       controller: controller.monthScrollController,
  //       scrollDirection: Axis.horizontal,
  //       padding: const EdgeInsets.symmetric(horizontal: 12.0),
  //       itemCount: daysInMonth,
  //       itemBuilder: (context, index) {
  //         final date = DateTime(today.year, today.month, index + 1);
  //         final isToday = date.day == today.day;

  //         // Check if this date is the selected single date
  //         final isSelectedDate = isSingleDateSelection &&
  //             date.day == rangeStart.day &&
  //             date.month == rangeStart.month &&
  //             date.year == rangeStart.year;

  //         // Check if date is in range (only for range selection)
  //         final isInRange = !isSingleDateSelection &&
  //             (date.isAtSameMomentAs(rangeStart) ||
  //                 date.isAtSameMomentAs(rangeEnd) ||
  //                 (date.isAfter(rangeStart) && date.isBefore(rangeEnd)));

  //         final isFuture = date.isAfter(today);

  //         return GestureDetector(
  //           onTap: isFuture
  //               ? null
  //               : () {
  //                   controller.selectSingleDate(date);
  //                 },
  //           child: Container(
  //             width: 45,
  //             margin: const EdgeInsets.symmetric(horizontal: 4.0),
  //             decoration: BoxDecoration(
  //               color: isSelectedDate || isInRange
  //                   ? const Color(0xFF004E7E)
  //                   : isToday
  //                       ? const Color(0xFFE0F2FE)
  //                       : Colors.transparent,
  //               borderRadius: BorderRadius.circular(8.0),
  //               border: Border.all(
  //                 color: isToday && !isSelectedDate && !isInRange
  //                     ? const Color(0xFF004E7E)
  //                     : Colors.transparent,
  //                 width: 1.5,
  //               ),
  //             ),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Text(
  //                   DateFormat('EEE').format(date).substring(0, 3),
  //                   style: GoogleFonts.dmSans(
  //                     fontSize: 11.0,
  //                     color: isFuture
  //                         ? const Color(0xFFD1D5DB)
  //                         : (isSelectedDate || isInRange)
  //                             ? Colors.white
  //                             : const Color(0xFF6B7280),
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 4),
  //                 Text(
  //                   '${date.day}',
  //                   style: GoogleFonts.dmSans(
  //                     fontSize: 16.0,
  //                     color: isFuture
  //                         ? const Color(0xFFD1D5DB)
  //                         : (isSelectedDate || isInRange)
  //                             ? Colors.white
  //                             : const Color(0xFF111827),
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}
