import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';
import 'package:i_dhara/app/presentation/modules/auth/otp/otp_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpWidget extends StatelessWidget {
  OtpWidget({super.key});
  final OtpController controller = Get.find<OtpController>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          body: SafeArea(
            top: true,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: Image.asset(
                    'assets/images/login_bg.png',
                  ).image,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Column(mainAxisSize: MainAxisSize.max, children: [
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
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
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
                                          'OTP Verification',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.dmSans(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
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
                                        Obx(
                                          () => RichText(
                                            textScaler: MediaQuery.of(context)
                                                .textScaler,
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '       Enter the OTP sent to your mobile number \n ',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Lexend',
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                                TextSpan(
                                                  text: 'ends with ',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Lexend',
                                                        color: const Color(
                                                            0xFF6A7185),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' ${controller.maskedPhoneNumber.value}',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Lexend',
                                                        color: const Color(
                                                            0xFF35353D),
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                                const WidgetSpan(
                                                    child: SizedBox(width: 8)),
                                                TextSpan(
                                                  text: 'Change',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Lexend',
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: const Color(
                                                            0xFF2F80ED),
                                                        letterSpacing: 0.0,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () async {
                                                          await SmsAutoFill()
                                                              .unregisterListener();
                                                          controller.codeValue
                                                              .value = '';
                                                          controller
                                                              .pinCodeController
                                                              .text = '';
                                                          Get.offNamed(Routes
                                                              .loginwithmobile);
                                                        },
                                                ),
                                              ],
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Lexend',
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ].divide(const SizedBox(height: 12.0)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 30, right: 30, bottom: 10),
                                    child: PinFieldAutoFill(
                                      enableInteractiveSelection: false,
                                      controller: controller.pinCodeController,
                                      onCodeChanged: (val) async {
                                        controller.codeValue.value = val ?? '';
                                        controller.pinCodeController.text =
                                            val ?? '';
                                        if (val != null && val.length == 4) {
                                          controller.codeValue.value = val;
                                          controller.pinCodeController.text =
                                              val;
                                          await controller.verifying(context);
                                        }
                                      },
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]')),
                                      ],
                                      cursor: Cursor(
                                        color: Colors.black,
                                        enabled: true,
                                        width: 2,
                                        height: 25,
                                      ),
                                      currentCode: controller.codeValue.value,
                                      codeLength: 4,
                                      autoFocus: true,
                                      decoration: BoxLooseDecoration(
                                        hintTextStyle: const TextStyle(
                                            color: Colors.black),
                                        hintText: '****',
                                        strokeColorBuilder:
                                            PinListenColorBuilder(
                                          const Color(0xFF45A845),
                                          const Color(0xFFB4C1D6),
                                        ),
                                        gapSpace: 30,
                                        radius: const Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Obx(
                                    () => controller.error.value &&
                                            controller
                                                .errorInstance.value.isNotEmpty
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Text(
                                                controller.errorInstance.value,
                                                style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  Obx(
                                    () => Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Text(
                                          'Didn’t you receive OTP? ',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Lexend',
                                                color: const Color(0xFF6A7185),
                                                fontSize: 16,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w300,
                                              ),
                                        ),
                                        controller.isTimerRunning.value
                                            ? Text.rich(
                                                TextSpan(
                                                  text: 'Resend OTP in  ',
                                                  style: const TextStyle(
                                                    color: Color(0XFF555555),
                                                    fontSize: 16,
                                                    fontFamily: 'Lato',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: controller
                                                          .remainingTime.value
                                                          .toString()
                                                          .padLeft(2, '0'),
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0XFFFFA500),
                                                        fontSize: 16,
                                                        fontFamily: 'Lato',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: ' seconds',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0XFF555555),
                                                        fontSize: 16,
                                                        fontFamily: 'Lato',
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : InkWell(
                                                onTap: controller.resendOtp,
                                                child: Text(
                                                  'Resend OTP ',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Lato',
                                                        color: const Color(
                                                            0xFF3686AF),
                                                        fontSize: 16,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                      ].divide(const SizedBox(height: 8)),
                                    ),
                                  ),
                                ].divide(const SizedBox(height: 20.0)),
                              ),
                            ),
                            // FFButtonWidget(
                            //   onPressed: () {
                            //     controller.verifying(context);
                            //   },
                            //   text: 'Verify',
                            //   options: FFButtonOptions(
                            //     width: double.infinity,
                            //     height: 40.0,
                            //     padding: const EdgeInsetsDirectional.fromSTEB(
                            //         16.0, 0.0, 16.0, 0.0),
                            //     iconPadding: const EdgeInsetsDirectional.fromSTEB(
                            //         0.0, 0.0, 0.0, 0.0),
                            //     color: const Color(0xFF3686AF),
                            //     textStyle: FlutterFlowTheme.of(context)
                            //         .titleSmall
                            //         .override(
                            //           font: GoogleFonts.dmSans(
                            //             fontWeight: FontWeight.normal,
                            //             fontStyle: FlutterFlowTheme.of(context)
                            //                 .titleSmall
                            //                 .fontStyle,
                            //           ),
                            //           color: Colors.white,
                            //           letterSpacing: 0.0,
                            //           fontWeight: FontWeight.normal,
                            //           fontStyle: FlutterFlowTheme.of(context)
                            //               .titleSmall
                            //               .fontStyle,
                            //         ),
                            //     elevation: 0.0,
                            //     borderRadius: BorderRadius.circular(8.0),
                            //   ),
                            // ),
                            Obx(
                              () => FFButtonWidget(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                        if (controller.pinCodeController.text
                                                .length ==
                                            4) {
                                          controller.verifying(context);
                                        } else {
                                          controller.error.value = true;
                                          controller.errorInstance.value =
                                              'Please enter valid OTP';
                                        }
                                      },
                                text: controller.isLoading.value
                                    ? 'Verifying...'
                                    : 'Verify',
                                options: FFButtonOptions(
                                  width: double.infinity,
                                  height: 40,
                                  color: controller.isLoading.value
                                      ? Colors.grey
                                      : const Color(0xFF3686AF),
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ].divide(const SizedBox(height: 14.0)),
                        ),
                      ),
                    ].divide(const SizedBox(height: 24.0)),
                  ),
                ]
                    // .divide(const SizedBox(height: 8.0))
                    // .addToStart(const SizedBox(height: 56.0)),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
