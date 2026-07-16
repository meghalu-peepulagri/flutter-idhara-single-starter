import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/bottomsheets/location_bottomsheet.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/core/utils/text_fields/horse_power_text_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/upper_case_text_formator.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/locations/add_new_location/add_new_location_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';

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

class _AddDevicesWidgetState extends State<AddDevicesWidget>
    with WidgetsBindingObserver {
  late AddDevicesModel _model;
  String? selectedLocationId;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLocationFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => AddDevicesModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();

    _model.textController5 ??= TextEditingController();
    _model.textFieldFocusNode5 ??= FocusNode();

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

    // Auto-fetch location
    _fetchCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Retry fetching location when app is resumed (e.g. from settings)
      // Only retry if location is not already set
      if (_model.textController4!.text.isEmpty) {
        _fetchCurrentLocation();
      }
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      isLocationFetching = true;
    });

    final loc = await _model.getCurrentLocation();

    if (mounted) {
      setState(() {
        isLocationFetching = false;
      });

      if (loc != null) {
        if (loc.containsKey('error')) {
          geterrorSnackBar("Enable the Mobile location");
        } else {
          setState(() {
            _model.textController4!.text = loc['name'];
            selectedLocationId = loc['id'];
            if (_model.errorInstance.containsKey('location_id')) {
              _model.errorInstance.remove('location_id');
            }
          });
        }
      }
    }
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
              suffixIcon: isLocationFetching
                  ? Transform.scale(
                      scale: 0.5,
                      child: const CircularProgressIndicator(
                        // strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF004E7E)),
                      ),
                    )
                  : const Icon(
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          resizeToAvoidBottomInset: true,
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
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          16.0, 0.0, 16.0, 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'Device Information'),
                          _buildPcbNumberField(context),
                          if (_model.pcbConfirmed &&
                              _model.confirmedMotors.isNotEmpty)
                            _buildMotorInputs(context),
                          _buildLocationField(context),
                          _buildImageUploadField(context),
                          _buildDeviceLocationField(context),
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

  Widget _buildDeviceLocationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'Land Mark', isMandatory: false),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextFieldComponent(
            maxLines: 1,
            controller: _model.textController5!,
            errors: _model.errorInstance,
            errorKey: 'device_location',
            hintText: 'Enter Device Location',
            readOnly: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPcbNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'Serial Number', isMandatory: true),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldComponent(
                controller: _model.textController1!,
                errors: _model.errorInstance,
                errorKey: 'pcb_number',
                hintText: 'Enter Serial Number',
                readOnly: false,
                onChanged: (value) {
                  setState(() {
                    if (_model.errorInstance.containsKey('pcb_number')) {
                      _model.errorInstance.remove('pcb_number');
                    }
                    if (_model.pcbConfirmed ||
                        _model.confirmedMotors.isNotEmpty) {
                      _model.resetPcbConfirmation();
                    }
                  });
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9]'),
                  ),
                  UpperCaseTextFormatter(), // auto convert to CAPITAL
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildConfirmButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    if (_model.isConfirmingPcb) {
      return Container(
        height: 40,
        width: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9.12),
          border: Border.all(color: const Color(0xFFB4C1D6)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004E7E)),
          ),
        ),
      );
    }

    if (_model.pcbConfirmed) {
      return Container(
        height: 40,
        width: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F6EE),
          borderRadius: BorderRadius.circular(9.12),
          border: Border.all(color: const Color(0xFF1AAA55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF1AAA55), size: 18),
            const SizedBox(width: 4),
            Text(
              'Confirmed',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                    color: const Color(0xFF1AAA55),
                    fontSize: 13,
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onConfirmPcb(context),
      child: Container(
        height: 40,
        width: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(9.12),
        ),
        child: Text(
          'Confirm',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.0,
              ),
        ),
      ),
    );
  }

  Future<void> _onConfirmPcb(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final pcb = _model.textController1!.text.trim();
    if (pcb.isEmpty) {
      setState(() {
        _model.errorInstance['pcb_number'] = 'Please enter the Serial Number';
      });
      return;
    }

    setState(() {
      _model.isConfirmingPcb = true;
      _model.errorInstance.remove('pcb_number');
    });

    final success = await _model.confirmPcbMotors(pcb);

    if (!mounted) return;
    setState(() {
      _model.isConfirmingPcb = false;
    });

    if (success) {
      successSnackBar(context, 'Serial Number confirmed');
    } else {
      geterrorSnackBar(_model.message);
    }
  }

  Widget _buildMotorInputs(BuildContext context) {
    final motors = _model.confirmedMotors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          context,
          motors.length > 1 ? 'Connected Motors' : 'Connected Motor',
        ),
        const SizedBox(height: 8),
        ...List.generate(
          motors.length,
          (index) => Padding(
            padding:
                EdgeInsets.only(bottom: index == motors.length - 1 ? 0 : 12),
            child: _buildMotorInputCard(context, index),
          ),
        ),
      ],
    );
  }

  Widget _buildMotorInputCard(BuildContext context, int index) {
    final bool multiple = _model.confirmedMotors.length > 1;
    final String nameKey = index == 0 ? 'motor_name' : 'motor_name_$index';
    final String hpKey = index == 0 ? 'hp' : 'hp_$index';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB4C1D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (multiple) ...[
            Text(
              'Motor ${index + 1}',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                    color: const Color(0xFF004E7E),
                    fontSize: 14,
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context, 'Pump Name', isMandatory: true),
                    const SizedBox(height: 6),
                    TextFieldComponent(
                      maxlength: 20,
                      controller: _model.motorNameControllers[index],
                      errors: _model.errorInstance,
                      errorKey: nameKey,
                      hintText: 'Enter Pump Name',
                      readOnly: false,
                      onChanged: (value) {
                        if (_model.errorInstance.containsKey(nameKey)) {
                          setState(() => _model.errorInstance.remove(nameKey));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context, 'HP', isMandatory: true),
                    const SizedBox(height: 6),
                    AddHorsePowerFieldWidget(
                      controller: _model.motorHpControllers[index],
                      errors: _model.errorInstance,
                      hintText: 'Enter HP',
                      errorKey: hpKey,
                      onChanged: (value) {
                        if (_model.errorInstance.containsKey(hpKey)) {
                          setState(() => _model.errorInstance.remove(hpKey));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _model.pickImage(source);
    if (file != null && mounted) {
      setState(() {
        _model.imageFile = file;
      });
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF004E7E)),
                title: Text('Camera',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(),
                          color: Colors.black,
                        )),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF004E7E)),
                title: Text('Gallery',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(),
                          color: Colors.black,
                        )),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadField(BuildContext context) {
    final image = _model.selectedImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'Device Image'),
        const SizedBox(height: 8),
        if (image == null)
          GestureDetector(
            onTap: () => _showImageSourceSheet(context),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFBDBDBD),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0xFF9E9E9E), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload image',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(),
                          color: const Color(0xFF9E9E9E),
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(image.path),
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showImageSourceSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF004E7E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _model.removeImage();
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAddDeviceButton(BuildContext context) {
    final bool enabled = _model.pcbConfirmed;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
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
          onPressed: !enabled
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  await _model.assignDevice(
                    deviceLoc: _model.textController5.text.trim(),
                    pcbNumber: _model.textController1!.text.trim(),
                    locationId: int.tryParse(selectedLocationId ?? '') ?? 0,
                  );
                  setState(() {});
                },
          text: 'Add Device',
          options: FFButtonOptions(
            width: double.infinity,
            height: 40.0,
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
            iconPadding:
                const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
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
      ),
    );
  }
}
