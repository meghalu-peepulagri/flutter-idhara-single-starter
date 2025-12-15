import 'package:flutter/material.dart';

import '../../../core/flutter_flow/flutter_flow_util.dart';
import '../../widgets/motor_control_card_widget.dart';
import 'motor_details_page.dart' show MotorControlWidget;

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
