import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/bottomsheets/location_bottomsheet.dart';
import 'package:i_dhara/app/core/utils/text_fields/hp_text_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/upper_case_text_formator.dart';
import 'package:i_dhara/app/presentation/modules/devices/add_new_location/add_new_location_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../core/flutter_flow/flutter_flow_widgets.dart';
import 'add_devices_controller.dart';

export 'add_devices_controller.dart';

class AddDevicesWidget extends StatefulWidget {
  const AddDevicesWidget({super.key});

  static String routeName = 'Add_Devices';
  static String routePath = '/addDevices';

  @override
  State<AddDevicesWidget> createState() => _AddDevicesWidgetState();
}

class _AddDevicesWidgetState extends State<AddDevicesWidget> {
  late AddDevicesModel _model;
  String? selectedLocationId;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddDevicesModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    final args = Get.arguments;
    if (args != null && args['pcbNumber'] != null) {
      _model.textController1!.text = args['pcbNumber'];
    }
    _model.fetchLocationDropDown();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void showLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.50,
          child: LocationSelectionBottomSheet(
            onLocationSelected: (String name, String id) {
              setState(() {
                _model.textController4!.text = name;
                selectedLocationId = id;
              });
              Navigator.pop(context);
            },
            selectedLocationId: selectedLocationId,
          ),
        );
      },
    );
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
          child: AddNewLocation(
            onLocationAdded: (String newLocation) {
              setState(() {
                _model.textController4!.text = newLocation;
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
          body: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(1.0, 0.0, 0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 0.0, 16.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: const BoxDecoration(),
                        child: GestureDetector(
                          onTap: () {
                            Get.offAllNamed(Routes.devices);
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
                        'Add Devices',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Information',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Pcb / Serial Number',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Colors.black,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '*',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextFieldComponent(
                                        controller: _model.textController1!,
                                        errors: _model.errorInstance,
                                        errorKey: 'pcb_number',
                                        hintText: 'Enter Pcb/Serial number',
                                        readOnly: false,
                                        onChanged: (value) {
                                          if (_model.errorInstance
                                              .containsKey('pcb_number')) {
                                            setState(() {
                                              _model.errorInstance
                                                  .remove('pcb_number');
                                            });
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(
                                                r'[A-Za-z0-9]'), // allow letters & numbers
                                          ),
                                          UpperCaseTextFormatter(), // 👈 auto convert to CAPITAL
                                        ],
                                      ),
                                    ),
                                  ),
                                ].divide(const SizedBox(height: 8.0)),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Pump Name',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.urbanist(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                              ),
                                              color: Colors.black,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '*',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width * 0.2,
                                  child: const Row(
                                    children: [
                                      Text(
                                        'HP',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '*',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ].divide(const SizedBox(width: 8)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFieldComponent(
                                    controller: _model.textController2!,
                                    errors: _model.errorInstance,
                                    errorKey: 'motor_name',
                                    hintText: 'Enter Pump Name',
                                    readOnly: false,
                                    onChanged: (value) {
                                      if (_model.errorInstance
                                          .containsKey('motor_name')) {
                                        setState(() {
                                          _model.errorInstance
                                              .remove('motor_name');
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width * 0.2,
                                  child: AddHpFieldWidget(
                                    controller: _model.textController3!,
                                    errors: _model.errorInstance,
                                    errorKey: 'hp',
                                    onChanged: (value) {
                                      if (_model.errorInstance
                                          .containsKey('hp')) {
                                        setState(() {
                                          _model.errorInstance.remove('hp');
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ].divide(const SizedBox(width: 8)),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Location',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.dmSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Colors.black,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '*',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // GestureDetector(
                                //   onTap: () {
                                //     ontaplocation(context);
                                //   },
                                //   child: Row(
                                //     mainAxisSize: MainAxisSize.max,
                                //     children: [
                                //       const Icon(
                                //         Icons.add,
                                //         color: Color(0xFF087D40),
                                //         size: 18.0,
                                //       ),
                                //       Text(
                                //         'Location',
                                //         style: FlutterFlowTheme.of(context)
                                //             .bodyMedium
                                //             .override(
                                //               font: GoogleFonts.dmSans(
                                //                 fontWeight:
                                //                     FlutterFlowTheme.of(context)
                                //                         .bodyMedium
                                //                         .fontWeight,
                                //                 fontStyle:
                                //                     FlutterFlowTheme.of(context)
                                //                         .bodyMedium
                                //                         .fontStyle,
                                //               ),
                                //               color: const Color(0xFF087D40),
                                //               letterSpacing: 0.0,
                                //               fontWeight:
                                //                   FlutterFlowTheme.of(context)
                                //                       .bodyMedium
                                //                       .fontWeight,
                                //               fontStyle:
                                //                   FlutterFlowTheme.of(context)
                                //                       .bodyMedium
                                //                       .fontStyle,
                                //             ),
                                //       ),
                                //     ].divide(const SizedBox(width: 4.0)),
                                //   ),
                                // ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                showLocationBottomSheet(context);
                              },
                              child: AbsorbPointer(
                                child: TextFieldComponent(
                                  controller: _model.textController4!,
                                  errors: _model.errorInstance,
                                  errorKey: 'location_id',
                                  hintText: 'Select Location',
                                  readOnly: false,
                                  onChanged: (value) {},
                                  suffixIcon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF757575),
                                    size: 24.0,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z\s]')),
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'^\s')),
                                  ],
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(height: 8.0)),
                        ),
                        FFButtonWidget(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            if (_model.textController1!.text.trim().isEmpty) {
                              _model.errorInstance['pcb_number'] =
                                  'PCB number is required';
                            }

                            if (_model.textController2!.text.trim().isEmpty) {
                              _model.errorInstance['motor_name'] =
                                  'Pump name is required';
                            }

                            if (_model.textController3!.text.trim().isEmpty) {
                              _model.errorInstance['hp'] = 'HP required';
                            } else if (double.tryParse(
                                    _model.textController3!.text.trim()) ==
                                null) {
                              _model.errorInstance['hp'] =
                                  'Enter a valid number';
                            }

                            if (selectedLocationId == null) {
                              _model.errorInstance['location_id'] =
                                  'Location is required';
                            }
                            if (_model.errorInstance.isNotEmpty) {
                              setState(() {});
                              return;
                            }
                            await _model.assignDevice(
                              pcbNumber: _model.textController1!.text.trim(),
                              pumpName: _model.textController2!.text.trim(),
                              hp: double.parse(
                                  _model.textController3!.text.trim()),
                              locationId: int.parse(selectedLocationId!.trim()),
                            );
                            print("line 260 -----------> $selectedLocationId");
                          },
                          text: 'Add Device',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 40.0,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 0.0, 16.0, 0.0),
                            iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: const Color(0xFF3686AF),
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ]
                          .divide(const SizedBox(height: 16.0))
                          .addToStart(const SizedBox(height: 24.0)),
                    ),
                  ),
                ),
              ].addToStart(const SizedBox(height: 56.0)),
            ),
          ),
        ),
      ),
    );
  }
}
