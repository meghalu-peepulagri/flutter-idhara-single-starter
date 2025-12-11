import '/components/location_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'locations_widget.dart' show LocationsWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LocationsModel extends FlutterFlowModel<LocationsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Location_Card component.
  late LocationCardModel locationCardModel1;
  // Model for Location_Card component.
  late LocationCardModel locationCardModel2;
  // Model for Location_Card component.
  late LocationCardModel locationCardModel3;
  // Model for Location_Card component.
  late LocationCardModel locationCardModel4;
  // Model for Location_Card component.
  late LocationCardModel locationCardModel5;

  @override
  void initState(BuildContext context) {
    locationCardModel1 = createModel(context, () => LocationCardModel());
    locationCardModel2 = createModel(context, () => LocationCardModel());
    locationCardModel3 = createModel(context, () => LocationCardModel());
    locationCardModel4 = createModel(context, () => LocationCardModel());
    locationCardModel5 = createModel(context, () => LocationCardModel());
  }

  @override
  void dispose() {
    locationCardModel1.dispose();
    locationCardModel2.dispose();
    locationCardModel3.dispose();
    locationCardModel4.dispose();
    locationCardModel5.dispose();
  }
}
