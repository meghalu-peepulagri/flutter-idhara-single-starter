import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/locations/add_new_location/add_new_location_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_widgets.dart';

class AddNewLocation extends StatefulWidget {
  const AddNewLocation({super.key, required this.onLocationAdded});
  final Function(String) onLocationAdded;

  @override
  State<AddNewLocation> createState() => _AddNewLocationState();
}

class _AddNewLocationState extends State<AddNewLocation> {
  late AddNewLocationController _model;

  @override
  void initState() {
    super.initState();
    _model = AddNewLocationController();
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
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.newLocation,
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
                  const SizedBox(height: 20.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: AppLocalizations.of(context)!.locationName,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
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
                          errorKey: 'name',
                          hintText:
                              AppLocalizations.of(context)!.enterLocationName,
                          onChanged: (value) {
                            if (_model.errorInstance.containsKey('name')) {
                              setState(() {
                                _model.errorInstance.remove('name');
                              });
                            }
                          },
                          readOnly: false),
                    ],
                  ),
                  const SizedBox(height: 20.0),
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
                      text: AppLocalizations.of(context)!.cancel,
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
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF004E7E),
                            Color(0xFF3686AF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FFButtonWidget(
                        onPressed: () async {
                          // if (_model.textController!.text.trim().isEmpty) {
                          //   // Show error
                          //   return;
                          // }
                          setState(() {
                            _model.errorInstance = {};
                            _model.error = false;
                            _model.isValidation = false;
                            _model.message = '';
                          });

                          final isSuccess = await _model.fetchnewlocation(
                            name: _model.textController!.text.trim(),
                          );
                          setState(() {});
                          if (!isSuccess) {
                            return;
                          }
                          print("line 36 loc id-----------> ${_model.error}");
                          print(
                              "line 37 loc id-----------> ${_model.errorInstance}");

                          SharedPreference.setLocationId(
                              _model.locationId.toString());
                          final locationName =
                              _model.textController!.text.trim();

                          Get.back();
                          getsuccessSnackBar("Location added successfully");
                          widget.onLocationAdded(locationName);
                        },
                        text: AppLocalizations.of(context)!.save,
                        options: FFButtonOptions(
                          height: 45.0,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          color: Colors.transparent,
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
