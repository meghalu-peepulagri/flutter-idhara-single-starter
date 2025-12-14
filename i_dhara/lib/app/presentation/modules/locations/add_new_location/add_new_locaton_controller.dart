import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

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
  //  Future<void> fetchaddapi({required String title})async{
  //   CustomResponse<Addapiresponse>response = await AddApi().call(title: title);
  //   error = false;
  //   isValidation = false;
  //   message = '';
  //   appResponse = AppResponse(response: response);
  //   switch (response.statusCode) {
  //     case 200:
  //     case 201:
  //       message = response.data!.message.toString();
  //       break;
  //     case 422:
  //       message = response.data!.message.toString();
  //       isValidation = true;
  //       error = true;
  //       errorInstance = response.data!.errors != null
  //           ? {'title': response.data!.errors!.title}
  //           : null;
  //       break;

  //     case 401:
  //       message = response.data!.message.toString();
  //       isValidation = false;
  //       error = true;
  //       break;
  //     default:
  //       message = response.data!.message.toString();
  //       error = true;
  //   }
  // }
}
