import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/presentation/modules/locations/locations_controller.dart';
import 'package:i_dhara/app/presentation/modules/locations/rename_delete_bottomsheet/rename_locaiton_controller.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../core/flutter_flow/flutter_flow_widgets.dart';
// import 'locationpopup_model.dart';

class EditLocationWidget extends StatefulWidget {
  const EditLocationWidget(
      {super.key,
      required this.locationId,
      required this.locationName,
      required this.onLocationAdded});
  final Function(String) onLocationAdded;
  final int locationId;
  final String locationName;

  @override
  State<EditLocationWidget> createState() => _LocationpopupWidgetState();
}

class _LocationpopupWidgetState extends State<EditLocationWidget> {
  late EditLocationModel _model;
  final LocationsController locationsController =
      Get.find<LocationsController>();
  //  String? errorMessage; // Error message state

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditLocationModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textController!.text = widget.locationName;
    _getLocationName();
  }

  Future<void> _getLocationName() async {
    // String? locationName = await SharedPreference.getLocationName();
    // if (locationName.isNotEmpty) {
    //   setState(() {
    //     _model.textController!.text = locationName;
    //   });
    // }
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rename Location',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Manrope',
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      InkWell(
                        onTap: () {
                          // FocusScope.of(context).unfocus();
                          Get.back();
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9E9E9),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              color: Colors.black), // Default text style
                          children: [
                            TextSpan(text: 'Location Name '),
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextFieldComponent(
                        controller: _model.textController!,
                        errors: _model.errorInstance,
                        errorKey: 'name',
                        hintText: 'Enter location name',
                        readOnly: false,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _model.errorInstance =
                                  Map.from(_model.errorInstance)
                                    ..remove('name');
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Get.back();
                      },
                      text: 'Cancel',
                      options: FFButtonOptions(
                        height: 45.0,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Manrope',
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                        elevation: 0.0,
                        borderSide: const BorderSide(color: Color(0x38000000)),
                        borderRadius: BorderRadius.circular(60.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();

                        final newName = _model.textController!.text.trim();

                        // if (newName.isEmpty) {
                        //   setState(() {
                        //     _model.errorInstance = {
                        //       'title': ['Location name is required']
                        //     };
                        //   });
                        //   return;
                        // }

                        await locationsController.renamelocation(
                          locationId: widget.locationId,
                          name: newName,
                        );
                        setState(() {
                          _model.error = true;
                          _model.message = locationsController.message ?? '';
                          _model.errorInstance =
                              locationsController.errorInstance;
                        });

                        return;

                        // widget.onLocationAdded(newName);

                        // Get.back();
                      },
                      text: 'Save',
                      options: FFButtonOptions(
                        height: 45.0,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        color: const Color(0xFF45A845),
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  fontFamily: 'Manrope',
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  fontWeight: FontWeight.w500,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(60.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
