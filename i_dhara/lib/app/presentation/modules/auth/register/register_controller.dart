import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository_impl.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../core/flutter_flow/form_field_controller.dart';

class RegisterModel extends FlutterFlowModel {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}
  bool error = false;
  bool isValidation = false;
  dynamic errorInstance;
  dynamic errorInstance1;
  dynamic errorInstance2;
  String message = '';

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  Future<void> fetchregister({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final response =
        await AuthRepositoryImpl().register(fullName, email, phone);

    if (response != null && response.errors == null) {
      Get.offNamed(Routes.otp);
      print("line 268 -----------> ${Get.offNamed(Routes.otp)}");
      SharedPreference.setPhone(phone);
    } else if (response?.errors != null) {
      errorInstance = response?.errors!.toJson();
    }
  }
}
