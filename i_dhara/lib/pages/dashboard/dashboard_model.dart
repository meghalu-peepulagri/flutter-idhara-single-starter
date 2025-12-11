import '/components/motor_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'dashboard_widget.dart' show DashboardWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashboardModel extends FlutterFlowModel<DashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Motor_Card component.
  late MotorCardModel motorCardModel1;
  // Model for Motor_Card component.
  late MotorCardModel motorCardModel2;
  // Model for Motor_Card component.
  late MotorCardModel motorCardModel3;
  // Model for Motor_Card component.
  late MotorCardModel motorCardModel4;

  @override
  void initState(BuildContext context) {
    motorCardModel1 = createModel(context, () => MotorCardModel());
    motorCardModel2 = createModel(context, () => MotorCardModel());
    motorCardModel3 = createModel(context, () => MotorCardModel());
    motorCardModel4 = createModel(context, () => MotorCardModel());
  }

  @override
  void dispose() {
    motorCardModel1.dispose();
    motorCardModel2.dispose();
    motorCardModel3.dispose();
    motorCardModel4.dispose();
  }
}
