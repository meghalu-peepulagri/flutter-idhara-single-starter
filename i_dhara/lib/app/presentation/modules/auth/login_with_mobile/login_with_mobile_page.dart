import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/text_fields/app_textfield.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/auth/login_with_mobile/login_with_mobile_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginwithmobileWidget extends StatefulWidget {
  const LoginwithmobileWidget({super.key});

  static String routeName = 'Login_Page';
  static String routePath = '/loginPage';

  @override
  State<LoginwithmobileWidget> createState() => _LoginwithmobileWidgetState();
}

class _LoginwithmobileWidgetState extends State<LoginwithmobileWidget> {
  late LoginwithmobileModel _model;
  bool showVerifyButton = false;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController controller1 = TextEditingController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginwithmobileModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _loadSavedPhoneNumber();

    controller1.addListener(() {
      if (_model.errorInstance != null && controller1.text.isNotEmpty) {
        setState(() {
          _model.errorInstance = null; // Clear error when user starts typing
        });
      }
    });

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      if (!isConnected) {
        errorSnackBar(context, 'No Internet Please Check Your Connectivity');
      } else {}
    });
  }

  Future<void> _loadSavedPhoneNumber() async {
    String? phoneNumber = SharedPreference.getPhone();
    if (phoneNumber.isNotEmpty) {
      setState(() {
        controller1.text = phoneNumber;
      });
    }
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    } on TimeoutException catch (e) {
      return false;
    }
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
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.asset(
                'assets/images/login_bg.png',
              ).image,
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0.0),
                        child: SvgPicture.asset(
                          'assets/images/login_image.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        'Verify Your Phone Number',
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
                                              color: const Color(0xFF35353D),
                                              fontSize: 18.0,
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
                                      Text(
                                        'Enter Phone Number to Access Your Account',
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
                                              color: const Color(0xFF6A7185),
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
                                    ].divide(const SizedBox(height: 12.0)),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.25,
                                        child: TextFieldComponent(
                                          readOnly: false,
                                          controller: controller1,
                                          errors: _model.errorInstance,
                                          hintText: 'Enter Your Phone Number',
                                          errorKey: 'phone',
                                          // maxlength: 10,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                                10),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ].divide(const SizedBox(width: 8.0)),
                                ),
                              ].divide(const SizedBox(height: 24.0)),
                            ),
                          ),
                          FFButtonWidget(
                            onPressed: () async {
                              String id = '';
                              if (!kIsWeb) {
                                await SmsAutoFill().unregisterListener();
                                id = await SmsAutoFill().getAppSignature;
                                bool isConnected = await _checkConnectivity();
                                if (!isConnected) {
                                  errorSnackBar(context,
                                      'No internet connection. Please check your network.');
                                  return;
                                }
                              }

                              // bool isConnected = await _checkConnectivity();
                              // if (!isConnected) {
                              //   errorSnackBar(context, 'No internet connection. Please check your network.');
                              //   return;
                              // }
                              await _model.fetchMobiel(
                                  phone: controller1.text.trim());
                              setState(() {
                                showVerifyButton =
                                    _model.message == "User not verified";
                              });
                              if (_model.error &&
                                  _model.message.isNotEmpty &&
                                  !_model.isValidation) {
                                errorSnackBar(context, _model.message);
                              } else if (!_model.error &&
                                  _model.message.isNotEmpty) {
                                Get.offNamed(Routes.otp);

                                // successSnackBar(context, _model.message);
                                SharedPreference.setPhone(controller1.text);
                              }
                            },
                            text: 'Generate OTP',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 40.0,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: const Color(0xFF3686AF),
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ].divide(const SizedBox(height: 44.0)),
                      ),
                    ),
                  ].divide(const SizedBox(height: 24.0)),
                ),
              ]
                  .divide(const SizedBox(height: 24.0))
                  .addToStart(const SizedBox(height: 56.0)),
            ),
          ),
        ),
      ),
    );
  }
}
