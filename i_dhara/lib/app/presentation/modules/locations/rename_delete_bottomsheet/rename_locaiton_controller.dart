import 'package:flutter/material.dart';

import '../../../../core/flutter_flow/flutter_flow_model.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';

class EditLocationModel extends FlutterFlowModel {
  /// State fields for stateful widgets in this component.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  // Additional fields to match LocationpopupModel
  Record? record;
  bool error = false;
  bool isValidation = false;
  dynamic errorInstance; // Changed to dynamic to match LocationpopupModel
  String message = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  Future<void> fetcheditapi({required String title}) async {
    // final response = await LocationRepositoryImpl().updateLocation(title);
    // if(response != null && response.errors == null){
    //   Get.offAllNamed(Routes.locations);
    // }else if (response!.errors !=null) {
    //   errorInstance = response!.errors!.toJson();
    // }
  }
}
