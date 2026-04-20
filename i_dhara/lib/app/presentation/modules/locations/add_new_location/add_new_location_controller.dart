import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class AddNewLocationController extends GetxController {
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}
  Record? record;
  bool error = false;
  bool isValidation = false;
  // dynamic errorInstance;
  String message = '';
  Map<String, dynamic> errorInstance = {};
  String locationName = '';
  String locationId = '';

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  Future<void> fetchLocationDropDown2(String name) async {
    final response = await LocationRepoImpl().getLocations();
    if (response != null) {
      final data = response.data;

      if (data != null) {
        for (var element in data) {
          if (element.name == name) {
            final id = element.id;
            locationId = id.toString();
            await SharedPreference.setLocationId(locationId);
            await SharedPreference.setLocationName(name);
          }
        }
      }
    }
  }
  Future<bool> fetchnewlocation({required String name}) async {
    final response = await LocationRepoImpl().addLocation(name);
    if (response != null && response.errors == null) {
      error = false;
      isValidation = false;
      errorInstance = {};
      message = '';
      await fetchLocationDropDown2(name);
      return true; // Success
    } else if (response?.errors != null) {
      error = true;
      isValidation = true;
      errorInstance = response!.errors!.toJson();
      message = 'Please fix the validation errors';
      return false;
    } else {
      error = true;
      isValidation = false;
      message = 'Something went wrong. Please try again.';
      return false; // Other error
    }
  }
}
