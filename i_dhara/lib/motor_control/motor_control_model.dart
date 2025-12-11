import '/components/motor_control_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'motor_control_widget.dart' show MotorControlWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MotorControlModel extends FlutterFlowModel<MotorControlWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Switch widget.
  bool? switchValue;
  // Model for Motor_Control_Card component.
  late MotorControlCardModel motorControlCardModel1;
  // Model for Motor_Control_Card component.
  late MotorControlCardModel motorControlCardModel2;
  // Model for Motor_Control_Card component.
  late MotorControlCardModel motorControlCardModel3;

  @override
  void initState(BuildContext context) {
    motorControlCardModel1 =
        createModel(context, () => MotorControlCardModel());
    motorControlCardModel2 =
        createModel(context, () => MotorControlCardModel());
    motorControlCardModel3 =
        createModel(context, () => MotorControlCardModel());
  }

  @override
  void dispose() {
    motorControlCardModel1.dispose();
    motorControlCardModel2.dispose();
    motorControlCardModel3.dispose();
  }
}
