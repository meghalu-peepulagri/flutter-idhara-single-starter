import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditDeleteLocationController extends GetxController {
  set textController(TextEditingController textController) {}
  // State field(s) for TextField widget.

  @override
  void initState(BuildContext context) {}
  Record? record;

  bool error = false;
  bool isValidation = false;
  dynamic errorInstance;
  dynamic errorInstance1;
  String message = '';

  @override
  void dispose() {}

  Future<void> fetchremoveapi() async {
    // final response = await LocationRepositoryImpl().deleteLocation();
    // if(response != null){
    //   await controller.fetchlocation();
    // }
  }

  // Future<void> fetcheditapi() async {
  //   CustomResponse<Editapiresponse> response = await EditApi().call(title: '');
  //   if (response.statusCode == 200) {
  //     // editRespons=response.data!.record;
  //     editResponse = response.data!;
  //   }
  // }
}
