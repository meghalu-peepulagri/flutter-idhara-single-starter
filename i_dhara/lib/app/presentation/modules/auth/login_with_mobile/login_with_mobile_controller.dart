import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository_impl.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../data/services/storages/hive_handler.dart';

class LoginwithmobileModel extends FlutterFlowModel {
  ///  State fields for stateful widgets in this page.

  @override
  void initState(BuildContext context) {}

  // Use Rx for reactive state if converting to full GetX later,
  // currently keeping as simple fields to match existing pattern but cleaned up.
  bool error = false;
  bool isValidation = false;
  dynamic errorInstance;
  String message = '';

  @override
  void dispose() {}

  Future<void> fetchMobile({required String phone, required String sid}) async {
    final response = await AuthRepositoryImpl().login(phone, sid);

    if (response != null && response.errors == null) {
      // Navigate and save phone
      Get.offNamed(Routes.otp);
      HiveHandler.setValue(Hivekeys.userPhone, phone);
    } else if (response?.errors != null) {
      errorInstance = response?.errors!.toJson();
      error = true;
    }
  }
}
