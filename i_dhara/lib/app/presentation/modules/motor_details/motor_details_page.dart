// import 'package:calendar_date_picker2/calendar_date_picker2.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/presentation/routes/app_routes.dart';
// import 'package:i_dhara/app/presentation/widgets/graphs/current_graph_card.dart';
// import 'package:i_dhara/app/presentation/widgets/graphs/motor_run_time_graph_card.dart';
// import 'package:i_dhara/app/presentation/widgets/graphs/voltage_graph_card.dart';
// import 'package:toggle_switch/toggle_switch.dart';

// import '../../../core/flutter_flow/flutter_flow_theme.dart';
// import '../../../core/flutter_flow/flutter_flow_util.dart';
// import 'motor_details_controller.dart';

// export 'motor_details_controller.dart';

// class MotorControlWidget extends StatelessWidget {
//   final scaffoldKey = GlobalKey<ScaffoldState>();

//   final AnalyticsController controller1 = Get.put(AnalyticsController());

//   MotorControlWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         FocusScope.of(context).unfocus();
//         FocusManager.instance.primaryFocus?.unfocus();
//       },
//       child: Scaffold(
//         key: scaffoldKey,
//         backgroundColor: const Color(0xFFEBF3FE),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsetsDirectional.fromSTEB(1.0, 16.0, 0.0, 0.0),
//             child: Column(mainAxisSize: MainAxisSize.max, children: [
//               Padding(
//                 padding:
//                     const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.max,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       decoration: const BoxDecoration(),
//                       child: GestureDetector(
//                         onTap: () {
//                           Get.offAllNamed(Routes.dashboard);
//                         },
//                         child: const Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Icon(
//                             Icons.arrow_back,
//                             color: Color(0xFF004E7E),
//                             size: 20.0,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       'Motor ',
//                       style: FlutterFlowTheme.of(context).bodyMedium.override(
//                             font: GoogleFonts.dmSans(
//                               fontWeight: FontWeight.w500,
//                               fontStyle: FlutterFlowTheme.of(context)
//                                   .bodyMedium
//                                   .fontStyle,
//                             ),
//                             color: const Color(0xFF004E7E),
//                             fontSize: 16.0,
//                             letterSpacing: 0.0,
//                             fontWeight: FontWeight.w500,
//                             fontStyle: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .fontStyle,
//                           ),
//                     ),
//                     Opacity(
//                       opacity: 0.0,
//                       child: Icon(
//                         Icons.arrow_back,
//                         color: FlutterFlowTheme.of(context).primaryText,
//                         size: 24.0,
//                       ),
//                     ),
//                   ],
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
//                         decoration: BoxDecoration(
//                           color:
//                               FlutterFlowTheme.of(context).secondaryBackground,
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.max,
//                             children: [
//                               Row(
//                                 mainAxisSize: MainAxisSize.max,
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Column(
//                                     mainAxisSize: MainAxisSize.max,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         controller1.motorName.value,
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
//                                               fontSize: 20.0,
//                                               letterSpacing: 0.0,
//                                               fontWeight: FontWeight.w500,
//                                               fontStyle:
//                                                   FlutterFlowTheme.of(context)
//                                                       .bodyMedium
//                                                       .fontStyle,
//                                             ),
//                                       ),
//                                       Text(
//                                         'Device ID: ${controller1.deviceId.value}',
//                                         style: FlutterFlowTheme.of(context)
//                                             .bodyMedium
//                                             .override(
//                                               font: GoogleFonts.dmSans(
//                                                 fontWeight: FontWeight.normal,
//                                                 fontStyle:
//                                                     FlutterFlowTheme.of(context)
//                                                         .bodyMedium
//                                                         .fontStyle,
//                                               ),
//                                               color: const Color(0xFF6A7282),
//                                               fontSize: 14.0,
//                                               letterSpacing: 0.0,
//                                               fontWeight: FontWeight.normal,
//                                               fontStyle:
//                                                   FlutterFlowTheme.of(context)
//                                                       .bodyMedium
//                                                       .fontStyle,
//                                             ),
//                                       ),
//                                       ToggleSwitch(
//                                         changeOnTap: true,
//                                         customWidths: const [90, 90],
//                                         radiusStyle: true,
//                                         minWidth: 80.0,
//                                         minHeight: 30.0,
//                                         // initialLabelIndex: currentModeIndex ?? 0,
//                                         cornerRadius: 8.0,
//                                         // activeBgColors: const Color(0xFFFFA500),
//                                         // ? [
//                                         //     [const Color(0xFFFFA500)],
//                                         //     [const Color(0xFF2F80ED)]
//                                         //   ]
//                                         // : [
//                                         //     [
//                                         //       const Color(0xFFFFA500)
//                                         //           .withOpacity(0.3)
//                                         //     ],
//                                         //     [
//                                         //       const Color(0xFF2F80ED)
//                                         //           .withOpacity(0.3)
//                                         //     ],
//                                         //   ],
//                                         // activeFgColor:
//                                         //     isAvailable ? Colors.white : Colors.black,
//                                         inactiveBgColor: Colors.white,
//                                         inactiveFgColor: Colors.black,
//                                         fontSize: 12,
//                                         totalSwitches: 2,
//                                         labels: const ['Auto', 'Manual'],
//                                         borderWidth: 1,
//                                         borderColor: [Colors.grey.shade300],
//                                         // onToggle:
//                                         //     isAvailable ? _handleModeToggle : null,
//                                       ),
//                                     ].divide(const SizedBox(height: 8.0)),
//                                   ),
//                                   AdvancedSwitch(
//                                     // key: ValueKey('switch_${widget.motor.id}_$isOn'),
//                                     // controller: ,
//                                     // initialValue: isOn,
//                                     activeColor: Colors.green,
//                                     inactiveColor: Colors.red.shade500,
//                                     activeChild: const Text('ON'),
//                                     inactiveChild: const Text('OFF'),
//                                     borderRadius: const BorderRadius.all(
//                                         Radius.circular(15)),
//                                     width: 55,
//                                     height: 25,
//                                     enabled: true,
//                                     disabledOpacity: 0.5,
//                                     onChanged: (value) {},
//                                   ),
//                                 ],
//                               ),
//                             ].divide(const SizedBox(height: 12.0)),
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: ListView(
//                           padding: const EdgeInsets.fromLTRB(
//                             0,
//                             0,
//                             0,
//                             24.0,
//                           ),
//                           shrinkWrap: true,
//                           scrollDirection: Axis.vertical,
//                           children: [
//                             GestureDetector(
//                               onTap: () async {
//                                 controller1.isModalOpen.value = true;
//                                 var results =
//                                     await showCalendarDatePicker2Dialog(
//                                   context: context,
//                                   config:
//                                       CalendarDatePicker2WithActionButtonsConfig(
//                                     calendarType: CalendarDatePicker2Type.range,
//                                     lastDate: DateTime.now(),
//                                     firstDate: DateTime(2000),
//                                     disableModePicker: true,
//                                     calendarViewScrollPhysics:
//                                         const NeverScrollableScrollPhysics(),
//                                   ),
//                                   dialogSize: const Size(325, 400),
//                                   value: controller1.daterange,
//                                   borderRadius: BorderRadius.circular(15),
//                                 );
//                                 try {
//                                   if (results != null) {
//                                     if (!listEquals(
//                                         results, controller1.daterange)) {
//                                       controller1.daterange.assignAll(results);
//                                       controller1.onDateRangeSelected();
//                                       // controller1.fetchdate();
//                                     }
//                                   }
//                                 } catch (e) {
//                                   // Handle error
//                                 } finally {
//                                   controller1.isModalOpen.value = false;
//                                 }
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(6.0),
//                                   border: Border.all(
//                                     color: const Color(0xFFE5E7EB),
//                                   ),
//                                 ),
//                                 child: Padding(
//                                   padding: const EdgeInsetsDirectional.fromSTEB(
//                                       12.0, 8.0, 12.0, 8.0),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.max,
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           const Icon(
//                                             Icons.calendar_month_outlined,
//                                             color: Color(0xFF4D4D4D),
//                                             size: 20.0,
//                                           ),
//                                           const SizedBox(width: 8.0),
//                                           Obx(() {
//                                             final firstDate =
//                                                 controller1.daterange.first ??
//                                                     DateTime.now();
//                                             final lastDate =
//                                                 controller1.daterange.last ??
//                                                     DateTime.now();
//                                             final isSameDate =
//                                                 firstDate == lastDate;

//                                             return Text(
//                                               isSameDate
//                                                   ? DateFormat('dd-MM-yyyy')
//                                                       .format(firstDate)
//                                                   : '${DateFormat('dd-MM-yyyy').format(firstDate)} ~ ${DateFormat('dd-MM-yyyy').format(lastDate)}',
//                                               style: FlutterFlowTheme.of(
//                                                       context)
//                                                   .bodyMedium
//                                                   .override(
//                                                     font: GoogleFonts.dmSans(
//                                                       fontWeight:
//                                                           FlutterFlowTheme.of(
//                                                                   context)
//                                                               .bodyMedium
//                                                               .fontWeight,
//                                                       fontStyle:
//                                                           FlutterFlowTheme.of(
//                                                                   context)
//                                                               .bodyMedium
//                                                               .fontStyle,
//                                                     ),
//                                                     color:
//                                                         const Color(0xB2000000),
//                                                     letterSpacing: 0.0,
//                                                     fontWeight:
//                                                         FlutterFlowTheme.of(
//                                                                 context)
//                                                             .bodyMedium
//                                                             .fontWeight,
//                                                     fontStyle:
//                                                         FlutterFlowTheme.of(
//                                                                 context)
//                                                             .bodyMedium
//                                                             .fontStyle,
//                                                   ),
//                                             );
//                                           }),
//                                         ],
//                                       ),
//                                       const Icon(
//                                         Icons.keyboard_arrow_down,
//                                         color: Color(0xFF4D4D4D),
//                                         size: 20.0,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Column(
//                               mainAxisSize: MainAxisSize.max,
//                               children: [
//                                 MotorRuntimeGraphWidget(
//                                   selectedDateRange: controller1.daterange,
//                                 ),
//                                 VoltageGraphWidget(
//                                   selectedDateRange: controller1.daterange,
//                                   motorName: controller1.selectedTitle.value,
//                                   sharedPointNotifier:
//                                       controller1.sharedPointNotifier,
//                                   sharedTimeNotifier:
//                                       controller1.sharedTimeNotifier,
//                                 ),
//                                 CurrentGraphWidget(
//                                   sharedPointNotifier:
//                                       controller1.valueNotifier,
//                                   sharedTimeNotifier:
//                                       controller1.sharedTimeNotifier,
//                                   selectedDateRange: controller1.daterange,
//                                   motorName: controller1.selectedTitle.value,
//                                 ),
//                               ].divide(const SizedBox(height: 16)),
//                             ),
//                           ].divide(const SizedBox(height: 12.0)),
//                         ),
//                       ),
//                     ]
//                         .divide(const SizedBox(height: 24.0))
//                         .addToStart(const SizedBox(height: 24.0)),
//                   ),
//                 ),
//               ),
//               Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: FlutterFlowTheme.of(context).secondaryBackground,
//                   boxShadow: const [
//                     BoxShadow(
//                       blurRadius: 6.0,
//                       color: Color(0x1F000000),
//                       offset: Offset(
//                         0.0,
//                         -1.0,
//                       ),
//                     )
//                   ],
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(0.0),
//                     bottomRight: Radius.circular(0.0),
//                     topLeft: Radius.circular(8.0),
//                     topRight: Radius.circular(8.0),
//                   ),
//                 ),
//                 child: const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.max,
//                     children: [],
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

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/graphs/current_graph_card.dart';
import 'package:i_dhara/app/presentation/widgets/graphs/motor_run_time_graph_card.dart';
import 'package:i_dhara/app/presentation/widgets/graphs/voltage_graph_card.dart';
import 'package:toggle_switch/toggle_switch.dart';

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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFEBF3FE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(1.0, 16.0, 0.0, 0.0),
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: const BoxDecoration(),
                      child: GestureDetector(
                        onTap: () {
                          Get.offAllNamed(Routes.dashboard);
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
                      'Motor ',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller1.motorName.value,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: const Color(0xFF0A0A0A),
                                              fontSize: 20.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                      Text(
                                        'Device ID: ${controller1.deviceId.value}',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: const Color(0xFF6A7282),
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                      ToggleSwitch(
                                        changeOnTap: false,
                                        customWidths: const [90, 90],
                                        radiusStyle: true,
                                        minWidth: 80.0,
                                        minHeight: 30.0,
                                        // initialLabelIndex: widget.device.mode == null
                                        //     ? null
                                        //     : modeController.switchIndexes[newId] == null
                                        //         ? modeConversion(widget.device.mode)
                                        //         : modeController.switchIndexes[newId],
                                        cornerRadius: 8.0,
                                        // activeBgColor:
                                        //     ? [Color(0xFF2F80ED)]
                                        //     : [Color(0xFF2F80ED).withOpacity(0.3)],
                                        // activeFgColor: Colors.white,
                                        inactiveBgColor: Colors.white,
                                        inactiveFgColor: Colors.black,
                                        fontSize: 12,
                                        totalSwitches: 2,
                                        labels: const ['Auto', 'Manual'],
                                        borderWidth: 0,
                                        borderColor: [Colors.grey.shade300],
                                        // onToggle: (!isswitchon(mode) ||
                                        //         widget.device.starterBox == null)
                                        //     ? (index) {}
                                        //     : widget.onToggle,
                                      ),
                                    ].divide(const SizedBox(height: 8.0)),
                                  ),
                                  AdvancedSwitch(
                                    activeColor: Colors.green,
                                    inactiveColor: Colors.red.shade500,
                                    activeChild: const Text('ON'),
                                    inactiveChild: const Text('OFF'),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(15)),
                                    width: 55,
                                    height: 25,
                                    enabled: true,
                                    disabledOpacity: 0.5,
                                    onChanged: (value) {},
                                  ),
                                ],
                              ),
                            ].divide(const SizedBox(height: 12.0)),
                          ),
                        ),
                      ),
                      Expanded(
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
                                  selectedDateRange: controller1.daterange,
                                ),
                                VoltageGraphWidget(
                                  selectedDateRange: controller1.daterange,
                                  motorName: controller1.selectedTitle.value,
                                  sharedPointNotifier:
                                      controller1.sharedPointNotifier,
                                  sharedTimeNotifier:
                                      controller1.sharedTimeNotifier,
                                ),
                                CurrentGraphWidget(
                                  sharedPointNotifier:
                                      controller1.valueNotifier,
                                  sharedTimeNotifier:
                                      controller1.sharedTimeNotifier,
                                  selectedDateRange: controller1.daterange,
                                  motorName: controller1.selectedTitle.value,
                                ),
                              ].divide(const SizedBox(height: 16)),
                            ),
                          ].divide(const SizedBox(height: 12.0)),
                        ),
                      ),
                    ]
                        .divide(const SizedBox(height: 24.0))
                        .addToStart(const SizedBox(height: 24.0)),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 6.0,
                      color: Color(0x1F000000),
                      offset: Offset(
                        0.0,
                        -1.0,
                      ),
                    )
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0.0),
                    bottomRight: Radius.circular(0.0),
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [],
                  ),
                ),
              ),
            ]),
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
      child: Column(
        children: [
          // Date Header with Calendar Icon
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Obx(() {
                    final today = DateTime.now();
                    final firstDate = controller.daterange.first ?? today;
                    final lastDate = controller.daterange.last ?? today;
                    final isRange = firstDate != lastDate;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Always show today's date
                        Text(
                          DateFormat('dd MMM yyyy').format(firstDate),
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF004E7E),
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Show range info if range is selected
                        if (isRange) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Range: ${DateFormat('dd MMM').format(firstDate)} - ${DateFormat('dd MMM yyyy').format(lastDate)}',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF6B7280),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
                GestureDetector(
                  onTap: () async {
                    controller.isModalOpen.value = true;
                    var results = await showCalendarDatePicker2Dialog(
                      context: context,
                      config: CalendarDatePicker2WithActionButtonsConfig(
                        calendarType: CalendarDatePicker2Type.range,
                        lastDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        disableModePicker: true,
                        calendarViewScrollPhysics:
                            const NeverScrollableScrollPhysics(),
                      ),
                      dialogSize: const Size(325, 400),
                      value: controller.daterange,
                      borderRadius: BorderRadius.circular(15),
                    );

                    try {
                      if (results != null && results.isNotEmpty) {
                        if (!listEquals(results, controller.daterange)) {
                          controller.daterange.assignAll(results);
                          controller.onDateRangeSelected();
                        }
                      }
                    } catch (e) {
                      // Handle error
                    } finally {
                      controller.isModalOpen.value = false;
                    }
                  },
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF004E7E),
                    size: 18.0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Horizontal month view
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Obx(() {
              final today = DateTime.now();
              final firstDate = controller.daterange.first ?? today;
              final lastDate = controller.daterange.last ?? today;
              return _buildMonthView(context, controller, firstDate, lastDate);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(BuildContext context, AnalyticsController controller,
      DateTime rangeStart, DateTime rangeEnd) {
    final today = DateTime.now();

    // Get first and last day of current month
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Check if it's a single date selection or range
    final isSingleDateSelection = rangeStart.year == rangeEnd.year &&
        rangeStart.month == rangeEnd.month &&
        rangeStart.day == rangeEnd.day;

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          final date = DateTime(today.year, today.month, index + 1);
          final isToday = date.day == today.day;

          // Check if this date is the selected single date
          final isSelectedDate = isSingleDateSelection &&
              date.day == rangeStart.day &&
              date.month == rangeStart.month &&
              date.year == rangeStart.year;

          // Check if date is in range (only for range selection)
          final isInRange = !isSingleDateSelection &&
              (date.isAtSameMomentAs(rangeStart) ||
                  date.isAtSameMomentAs(rangeEnd) ||
                  (date.isAfter(rangeStart) && date.isBefore(rangeEnd)));

          final isFuture = date.isAfter(today);

          return GestureDetector(
            onTap: isFuture
                ? null
                : () {
                    controller.selectSingleDate(date);
                  },
            child: Container(
              width: 45,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: isSelectedDate || isInRange
                    ? const Color(0xFF004E7E)
                    : isToday
                        ? const Color(0xFFE0F2FE)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isToday && !isSelectedDate && !isInRange
                      ? const Color(0xFF004E7E)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).substring(0, 3),
                    style: GoogleFonts.dmSans(
                      fontSize: 11.0,
                      color: isFuture
                          ? const Color(0xFFD1D5DB)
                          : (isSelectedDate || isInRange)
                              ? Colors.white
                              : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.dmSans(
                      fontSize: 16.0,
                      color: isFuture
                          ? const Color(0xFFD1D5DB)
                          : (isSelectedDate || isInRange)
                              ? Colors.white
                              : const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
