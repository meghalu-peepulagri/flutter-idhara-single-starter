import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';

class AddNewLocatonController extends GetxController {
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}
  Record? record;
  bool error = false;
  bool isValidation = false;
  dynamic errorInstance;
  String message = '';

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  Future<void> fetchnewlocation({required String name}) async {
    final response = await LocationRepoImpl().addLocation(name);
    if (response != null && response.errors == null) {
      // Get.offAllNamed(Routes.locations);
    } else if (response!.errors != null) {
      errorInstance = response.errors!.toJson();
    }
  }
}
