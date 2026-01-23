import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/text_fields/description_text_field.dart';
import 'package:i_dhara/app/core/utils/text_fields/text_form_field.dart';
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
  RegisterModel _model = RegisterModel();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterModel());
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
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
        body: LayoutBuilder(builder: (context, constraints) {
          return SafeArea(
            top: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Verify OTP.png'),
                    fit: BoxFit.cover,
                  ),
                ),
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
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Manrope',
                                                    color:
                                                        const Color(0xFF000000),
                                                  ),
                                              children: const [
                                                TextSpan(
                                                  text: '*',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          TextFieldComponent(
                                            readOnly: false,
                                            controller: nameController,
                                            errors: _model.errorInstance,
                                            hintText: 'Enter Full Name',
                                            errorKey: 'full_name',
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
                                              text: 'Mobile Number',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Manrope',
                                                    color:
                                                        const Color(0xFF000000),
                                                  ),
                                              children: const [
                                                TextSpan(
                                                  text: '*',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          TextFieldComponent(
                                            readOnly: false,
                                            controller: phoneController,
                                            errors: _model.errorInstance,
                                            hintText: 'Enter Mobile Number',
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
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                  10),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text.rich(
                                            TextSpan(
                                              text: 'Email',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    fontFamily: 'Manrope',
                                                    color:
                                                        const Color(0xFF000000),
                                                  ),
                                              children: const [
                                                TextSpan(
                                                  text: '',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          TextFieldComponent(
                                            readOnly: false,
                                            controller: emailController,
                                            errors: _model.errorInstance,
                                            hintText: 'Enter Email',
                                            errorKey: 'email',
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
                                                  color:
                                                      const Color(0xFF000000),
                                                ),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          DescriptionTextField(
                                            readOnly: false,
                                            controller: addressController,
                                            errors: _model.errorInstance,
                                            hintText: 'Enter Address',
                                            errorKey: 'location',
                                            keyboardType: TextInputType.text,
                                            ontap: () {},
                                          ),
                                          const SizedBox(height: 30),
                                          Container(
                                            width: double.infinity,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF004E7E),
                                                  Color(0xFF3686AF),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: FFButtonWidget(
                                              onPressed: () async {
                                                String id = await SmsAutoFill()
                                                    .getAppSignature;

                                                await _model.fetchregister(
                                                    fullName: nameController
                                                        .text
                                                        .trim(),
                                                    email: emailController.text
                                                            .trim()
                                                            .isEmpty
                                                        ? null
                                                        : emailController.text
                                                            .trim(),
                                                    phone: phoneController.text
                                                        .trim(),
                                                    address: addressController
                                                        .text
                                                        .trim(),
                                                    sid: id);

                                                if (!mounted) return;
                                                setState(() {});
                                              },
                                              text: 'Register',
                                              options: FFButtonOptions(
                                                width: double.infinity,
                                                height: 40,
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(16, 0, 16, 0),
                                                iconPadding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(0, 0, 0, 0),
                                                color: Colors.transparent,
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
                                                        color: const Color(
                                                            0xFF6A7185),
                                                        fontWeight:
                                                            FontWeight.w300,
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
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Lexend',
                                                          color: const Color(
                                                              0xFF6A7185),
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w300,
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
                                                            fontFamily:
                                                                'Lexend',
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
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
