import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/presentation/modules/devices/add_new_location/add_new_locaton_controller.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_widgets.dart';

class AddNewLocation extends StatefulWidget {
  const AddNewLocation({super.key, required this.onLocationAdded});
  final Function(String) onLocationAdded;

  @override
  State<AddNewLocation> createState() => _AddNewLocationState();
}

class _AddNewLocationState extends State<AddNewLocation> {
  late AddNewLocatonController _model;

  @override
  void initState() {
    super.initState();
    _model = AddNewLocatonController();
    _model.textController = TextEditingController();
    _model.textFieldFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                /// Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Location',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Manrope',
                          color: Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700),
                    ),
                    InkWell(
                      onTap: () => Get.back(),
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
                    Text.rich(
                      TextSpan(
                        text: 'Location Name',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Manrope',
                              letterSpacing: 0,
                              color: const Color(0xFF000000),
                            ),
                        children: const [
                          TextSpan(
                            text: '\u00A0*',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFieldComponent(
                        controller: _model.textController!,
                        errors: _model.errorInstance,
                        errorKey: 'title',
                        hintText: 'Enter location name',
                        readOnly: false),
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
                    onPressed: () => Get.back(),
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
                      // Validate that location name is not empty
                      if (_model.textController!.text.trim().isEmpty) {
                        // Show error
                        return;
                      }

                      await _model.fetchnewlocation(
                        name: _model.textController!.text.trim(),
                      );
                      final locationName = _model.textController!.text.trim();

                      Get.back();
                      widget.onLocationAdded(locationName);
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
    );
  }
}
