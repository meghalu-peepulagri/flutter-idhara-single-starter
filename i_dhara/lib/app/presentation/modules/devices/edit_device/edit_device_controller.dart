import 'package:flutter/material.dart';

import '../../../../core/flutter_flow/flutter_flow_model.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';

class EditDeviceController extends FlutterFlowModel {
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;

  // Additional fields to match LocationpopupModel
  Record? record;
  bool error = false;
  bool isValidation = false;
  Map<String, dynamic> errorInstance =
      {}; // Changed to dynamic to match LocationpopupModel
  String message = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
