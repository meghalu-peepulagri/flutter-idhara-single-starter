import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/dto/device_assign_dto.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

import '../../../../core/flutter_flow/flutter_flow_util.dart';
import 'add_devices_page.dart' show AddDevicesWidget;

class AddDevicesModel extends FlutterFlowModel<AddDevicesWidget> {
  // dynamic errorInstance;
  dynamic errorInstance1;
  String message = '';
  Map<String, dynamic> errorInstance = {};
  List<Location>? locations;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();
  }

  Future<void> fetchLocationDropDown() async {
    final response = await LocationRepoImpl().getLocations();
    if (response != null) {
      response.data ?? [];
    }
  }

  Future<void> assignDevice({
    required String pcbNumber,
    required String pumpName,
    required double hp,
    required int locationId,
  }) async {
    final dto = StarterCreateDto(
      pcbNumber: pcbNumber,
      motorName: pumpName,
      hp: hp,
      locationId: locationId,
    );

    print("line 28 -----------> $locationId");
    final response = await DevicesRepositoryImpl().deviceassign(dto);

    // if (response != null && response.errors == null) {
    //   await Future.delayed(const Duration(milliseconds: 300));

    //   if (Get.isRegistered<DashboardController>()) {
    //     final dashboardController = Get.find<DashboardController>();
    //     dashboardController.isLoading.value = true;
    //     await dashboardController.fetchMotors();
    //   }
    //   Get.offAllNamed(Routes.dashboard);
    // }
    if (response != null && response.errors == null) {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshMotors();
      }

      Get.offAllNamed(Routes.dashboard);
    } else if (response?.errors != null) {
      errorInstance.clear();
      errorInstance.addAll(response!.errors!.toJson());
    }
  }
}
