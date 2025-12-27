import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/text_fields/description_text_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/auth/register/register_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../core/flutter_flow/flutter_flow_widgets.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  @override
  State<RegisterWidget> createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  // late RegisterModel _model;
  RegisterModel _model = RegisterModel();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();
  TextEditingController controller3 = TextEditingController();
  TextEditingController controller4 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterModel());
  }

  // bool validateForm() {
  //   bool isValid = true;
  //   Map<String, String> errors = {};

  //   if (controller1.text.isEmpty) {
  //     errors['full_name'] = 'Full name is required';
  //     isValid = false;
  //   } else {
  //     errors['full_name'] = '';
  //   }

  //   if (controller2.text.isEmpty) {
  //     errors['email'] = 'Email is required';
  //     isValid = false;
  //   } else {
  //     errors['email'] = '';
  //   }

  //   if (controller3.text.isEmpty) {
  //     errors['phone'] = 'Phone is required';
  //     isValid = false;
  //   } else {
  //     errors['phone'] = '';
  //   }
  //   setState(() {
  //     _model.errorInstance = errors;
  //     _model.errorInstance1 = errors;
  //     _model.errorInstance2 = errors;
  //   });

  //   return isValid;
  // }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    controller3.dispose();
    controller4.dispose();
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
        // resizeToAvoidBottomInset: true,
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SvgPicture.asset(
                              'assets/images/idhara_logo.svg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Text(
                                'Create Your Account',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Lexend',
                                      color: const Color(0xFF35353D),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0,
                                    ),
                              ),
                              Text(
                                'Enter your details to get started.',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Lexend',
                                      color: const Color(0xFF6A7185),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 8)),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16, 0, 16, 0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          text: 'Full Name',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: 'Manrope',
                                                color: const Color(0xFF000000),
                                              ),
                                          children: const [
                                            TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      TextFieldComponent(
                                        readOnly: false,
                                        controller: controller1,
                                        errors: _model.errorInstance,
                                        hintText: 'Enter Full Name',
                                        errorKey: 'full_name',
                                        // maxlength: 10,
                                        keyboardType: TextInputType.name,
                                        onChanged: (value) {
                                          if (_model.errorInstance
                                              .containsKey('full_name')) {
                                            setState(() {
                                              _model.errorInstance
                                                  .remove('full_name');
                                            });
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[a-zA-Z\s]')),
                                          FilteringTextInputFormatter.deny(
                                              RegExp(r'^\s')),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: 'Phone Number',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: 'Manrope',
                                                color: const Color(0xFF000000),
                                              ),
                                          children: const [
                                            TextSpan(
                                              text: '*',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      TextFieldComponent(
                                        readOnly: false,
                                        controller: controller3,
                                        errors: _model.errorInstance,
                                        hintText: 'Enter Phone Number',
                                        errorKey: 'phone',
                                        onChanged: (value) {
                                          if (_model.errorInstance
                                              .containsKey('phone')) {
                                            setState(() {
                                              _model.errorInstance
                                                  .remove('phone');
                                            });
                                          }
                                        },
                                        // maxlength: 10,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          text: 'Email',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                fontFamily: 'Manrope',
                                                color: const Color(0xFF000000),
                                              ),
                                          children: const [
                                            TextSpan(
                                              text: '',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      TextFieldComponent(
                                        readOnly: false,
                                        controller: controller2,
                                        // errors: _model.errorInstance,
                                        hintText: 'Enter Email',
                                        // errorKey: 'email',
                                        // maxlength: 10,
                                        onChanged: (value) {
                                          if (_model.errorInstance
                                              .containsKey('email')) {
                                            setState(() {
                                              _model.errorInstance
                                                  .remove('email');
                                            });
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(
                                                  r'[a-zA-Z0-9$#%^&*!@()/|.]')),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        'Address',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'Manrope',
                                              color: const Color(0xFF000000),
                                            ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      DescriptionTextField(
                                        readOnly: false,
                                        controller: controller4,
                                        // errors: _model.errorInstance,
                                        hintText: 'Enter Address',
                                        errorKey: 'location',
                                        keyboardType: TextInputType.text,
                                      ),
                                      // ),
                                      const SizedBox(height: 30),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          String id = await SmsAutoFill()
                                              .getAppSignature;
                                          await _model.fetchregister(
                                            fullName: controller1.text.trim(),
                                            email: controller2.text.trim(),
                                            phone: controller3.text.trim(),
                                          );
                                          setState(() {});
                                          if (_model.error &&
                                              _model.message.isNotEmpty) {
                                            errorSnackBar(
                                                context, _model.message);
                                          } else if (!_model.error &&
                                              _model.message.isNotEmpty) {
                                            Get.toNamed(Routes.otp);
                                            print(
                                                "line 26 -----------> ${Get.toNamed(Routes.otp)}");
                                            // await _otpModel.fetchOtp(
                                            //     phone: controller3.text.trim(),
                                            //     otp: '');
                                            // successSnackBar(
                                            //     context, _model.message);
                                            SharedPreference.setPhone(
                                                controller3.text);
                                          }
                                        },
                                        text: 'Register',
                                        options: FFButtonOptions(
                                          width: double.infinity,
                                          height: 40,
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(16, 0, 16, 0),
                                          iconPadding:
                                              const EdgeInsetsDirectional
                                                  .fromSTEB(0, 0, 0, 0),
                                          color: const Color(0xFF3686AF),
                                          textStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .override(
                                                    fontFamily: 'Lexend',
                                                    color: Colors.white,
                                                    letterSpacing: 0,
                                                  ),
                                          elevation: 0,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                      ),
                                      const SizedBox(height: 13),
                                      Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'or',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Lexend',
                                                    color:
                                                        const Color(0xFF6A7185),
                                                    fontWeight: FontWeight.w300,
                                                    fontSize: 16,
                                                    letterSpacing: 0,
                                                  ),
                                            ),
                                          ]),
                                      const SizedBox(height: 13),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Already have an account?',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Lexend',
                                                  color:
                                                      const Color(0xFF6A7185),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300,
                                                  letterSpacing: 0,
                                                ),
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Get.toNamed(
                                                  Routes.loginwithmobile);
                                            },
                                            child: Text('Login',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                        fontFamily: 'Lexend',
                                                        color: const Color(
                                                            0xFF121212),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        letterSpacing: 0,
                                                        decoration:
                                                            TextDecoration
                                                                .underline)),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ].divide(const SizedBox(height: 20)),
                      ),
                    ].divide(const SizedBox(height: 20)),
                  ),
                  // Align(
                  //   alignment: Alignment.bottomCenter,
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(8),
                  //     child: SvgPicture.asset(
                  //       'assets/images/Login_vector.svg',
                  //       fit: BoxFit.cover,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
