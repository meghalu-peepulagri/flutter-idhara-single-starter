import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_model.dart';
import 'package:i_dhara/app/presentation/widgets/filter_bottomsheet/filter_bottomsheet.dart';

class FiltersBottomsheetModel
    extends FlutterFlowModel<FiltersBottomsheetWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();
  }
}
