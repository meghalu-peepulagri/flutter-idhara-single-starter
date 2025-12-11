import '/components/motor_control_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'motor_control_model.dart';
export 'motor_control_model.dart';

class MotorControlWidget extends StatefulWidget {
  const MotorControlWidget({super.key});

  static String routeName = 'Motor_Control';
  static String routePath = '/motorControl';

  @override
  State<MotorControlWidget> createState() => _MotorControlWidgetState();
}

class _MotorControlWidgetState extends State<MotorControlWidget> {
  late MotorControlModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MotorControlModel());

    _model.switchValue = true;
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFEBF3FE),
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(1.0, 0.0, 0.0, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(),
                      child: Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xFF004E7E),
                          size: 20.0,
                        ),
                      ),
                    ),
                    Text(
                      'Motor ',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: Color(0xFF004E7E),
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    Opacity(
                      opacity: 0.0,
                      child: Icon(
                        Icons.arrow_back,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24.0,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Motor Control',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF0A0A0A),
                                              fontSize: 20.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                      Text(
                                        'Device ID: MTR-NK-001',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.dmSans(
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF6A7282),
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ].divide(SizedBox(height: 8.0)),
                                  ),
                                  Switch.adaptive(
                                    value: _model.switchValue!,
                                    onChanged: (newValue) async {
                                      safeSetState(
                                          () => _model.switchValue = newValue!);
                                    },
                                    activeColor: Color(0xFF34C759),
                                    activeTrackColor: Color(0xFF34C759),
                                    inactiveTrackColor:
                                        FlutterFlowTheme.of(context).alternate,
                                    inactiveThumbColor:
                                        FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                  ),
                                ],
                              ),
                            ].divide(SizedBox(height: 12.0)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            0,
                            0,
                            24.0,
                          ),
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 8.0, 12.0, 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      color: Color(0xFF4D4D4D),
                                      size: 20.0,
                                    ),
                                    Text(
                                      'Select Date',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.dmSans(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xB2000000),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.motorControlCardModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: MotorControlCardWidget(),
                            ),
                            wrapWithModel(
                              model: _model.motorControlCardModel2,
                              updateCallback: () => safeSetState(() {}),
                              child: MotorControlCardWidget(),
                            ),
                            wrapWithModel(
                              model: _model.motorControlCardModel3,
                              updateCallback: () => safeSetState(() {}),
                              child: MotorControlCardWidget(),
                            ),
                          ].divide(SizedBox(height: 12.0)),
                        ),
                      ),
                    ]
                        .divide(SizedBox(height: 24.0))
                        .addToStart(SizedBox(height: 24.0)),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6.0,
                      color: Color(0x1F000000),
                      offset: Offset(
                        0.0,
                        -1.0,
                      ),
                    )
                  ],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0.0),
                    bottomRight: Radius.circular(0.0),
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [],
                  ),
                ),
              ),
            ].addToStart(SizedBox(height: 56.0)),
          ),
        ),
      ),
    );
  }
}
