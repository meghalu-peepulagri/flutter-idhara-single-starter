import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/bottomsheets/location_bottomsheet.dart';
import 'package:i_dhara/app/core/utils/text_fields/horse_power_text_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/upper_case_text_formator.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
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

    _model.textController4!.addListener(() {
      if (_model.textController4!.text.isNotEmpty &&
          _model.errorInstance.containsKey('location_id')) {
        setState(() {
          _model.errorInstance.remove('location_id');
        });
      }
    });

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

  void _onTapLocation(BuildContext context) {
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
            onLocationAdded: (String newLocation) async {
              final locName = SharedPreference.getLocationName();
              final locId = SharedPreference.getLocationId();

              setState(() {
                _model.textController4!.text = locName;
                selectedLocationId = locId;

                _model.errorInstance.remove('location_id');
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Get.offAllNamed(Routes.devices);
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
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(1.0, 16.0, 0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0, 0.0, 16.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'Device Information'),
                          _buildPcbNumberField(context),
                          _buildPumpNameAndHpFields(context),
                          _buildLocationField(context),
                          _buildAddDeviceButton(context),
                        ]
                            .divide(const SizedBox(height: 16.0))
                            .addToStart(const SizedBox(height: 24.0)),
                      ),
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
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'Add Device',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500,
                    ),
                    color: const Color(0xFF004E7E),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                Get.offAllNamed(Routes.devices);
              },
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004E7E),
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.dmSans(
              fontWeight: FontWeight.w500,
            ),
            color: Colors.black,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildLabel(BuildContext context, String label,
      {bool isMandatory = false}) {
    return Row(
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.dmSans(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                ),
                color: Colors.black,
              ),
        ),
        if (isMandatory) ...[
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
      ],
    );
  }

  Widget _buildPcbNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'PCB / Starter Number', isMandatory: true),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextFieldComponent(
            controller: _model.textController1!,
            errors: _model.errorInstance,
            errorKey: 'pcb_number',
            hintText: 'Enter PCB/Starter Number',
            readOnly: false,
            onChanged: (value) {
              if (_model.errorInstance.containsKey('pcb_number')) {
                setState(() {
                  _model.errorInstance.remove('pcb_number');
                });
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9]'),
              ),
              UpperCaseTextFormatter(), // auto convert to CAPITAL
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPumpNameAndHpFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLabel(context, 'Pump Name', isMandatory: true),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldComponent(
                controller: _model.textController2!,
                errors: _model.errorInstance,
                errorKey: 'motor_name',
                hintText: 'Enter Pump Name',
                readOnly: false,
                onChanged: (value) {
                  if (_model.errorInstance.containsKey('motor_name')) {
                    setState(() {
                      _model.errorInstance.remove('motor_name');
                    });
                  }
                },
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.2,
              child: AddHorsePowerFieldWidget(
                controller: _model.textController3!,
                errors: _model.errorInstance,
                hintText: 'Enter HP',
                errorKey: 'hp',
                onChanged: (value) {
                  if (_model.errorInstance.containsKey('hp')) {
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
    );
  }

  Widget _buildLocationField(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(context, 'Location', isMandatory: true),
            GestureDetector(
              onTap: () {
                _onTapLocation(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18.0,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      'Add Location',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                            ),
                            color: Colors.white,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ].divide(const SizedBox(width: 4.0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              onChanged: (value) {
                if (_model.errorInstance.containsKey('location_id')) {
                  setState(() {
                    _model.errorInstance.remove('location_id');
                  });
                }
              },
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF757575),
                size: 24.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                FilteringTextInputFormatter.deny(RegExp(r'^\s')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddDeviceButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FFButtonWidget(
        onPressed: () async {
          FocusScope.of(context).unfocus();

          await _model.assignDevice(
            pcbNumber: _model.textController1!.text.trim(),
            pumpName: _model.textController2!.text.trim(),
            hp: double.tryParse(_model.textController3!.text.trim()) ?? 0,
            locationId: int.tryParse(selectedLocationId ?? '') ?? 0,
          );
          setState(() {});
        },
        text: 'Add Device',
        options: FFButtonOptions(
          width: double.infinity,
          height: 40.0,
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
          color: Colors.transparent,
          textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                font: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w500,
                ),
                color: Colors.white,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
          elevation: 0.0,
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
