import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/devices/devices_controller.dart';
import 'package:i_dhara/app/presentation/modules/devices/edit_device/edit_device_controller.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../core/flutter_flow/flutter_flow_widgets.dart';

class EditDevicePage extends StatefulWidget {
  const EditDevicePage(
      {super.key,
      required this.motorId,
      required this.motorName,
      required this.hp,
      required this.onLocationAdded});
  final Function(String) onLocationAdded;
  final int motorId;
  final String motorName;
  final double hp;

  @override
  State<EditDevicePage> createState() => _EditDevicePageState();
}

class _EditDevicePageState extends State<EditDevicePage> {
  late EditDeviceController _model;

  final DevicesController devicesController = Get.find<DevicesController>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditDeviceController());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textController!.text = widget.motorName;
    _getLocationName();
  }

  Future<void> _getLocationName() async {
    String? motorname = SharedPreference.getMotorName();
    if (motorname.isNotEmpty) {
      setState(() {
        _model.textController!.text = motorname;
      });
    }
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
                        'Rename Pump',
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
                            TextSpan(text: 'Pump Name'),
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
                        hintText: 'Enter Pump name',
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
                        //       'title': ['Motor name is required']
                        //     };
                        //   });
                        //   return;
                        // }

                        await devicesController.renamedevice(
                          motorId: widget.motorId,
                          name: newName,
                          hp: widget.hp,
                        );
                        setState(() {
                          _model.error = true;
                          _model.message = devicesController.message ?? '';
                          _model.errorInstance =
                              devicesController.errorInstance;
                        });

                        return;

                        // widget.onLocationAdded(newName);
                      },
                      text: 'Save',
                      options: FFButtonOptions(
                        height: 45.0,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        color: const Color(0xFF3686AF),
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
