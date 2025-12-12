import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/modules/auth/otp/otp_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';

class OtpWidget extends StatelessWidget {
  OtpWidget({super.key});
  final OtpController controller = Get.find<OtpController>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          body: SafeArea(
            top: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              'assets/images/Peepul_Agri_logo.svg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            'OTP Verification',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Lexend',
                                  color: const Color(0xFF35353D),
                                  fontSize: 18,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          Obx(
                            () => RichText(
                              textScaler: MediaQuery.of(context).textScaler,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '       Enter the OTP sent to your mobile number \n ',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Lexend',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                  TextSpan(
                                    text: 'ends with ',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Lexend',
                                          color: Color(0xFF6A7185),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' ${controller.maskedPhoneNumber.value}',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Lexend',
                                          color: Color(0xFF35353D),
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                  WidgetSpan(child: SizedBox(width: 8)),
                                  TextSpan(
                                    text: 'Change',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Lexend',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF2F80ED),
                                          letterSpacing: 0.0,
                                          decoration: TextDecoration.underline,
                                        ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        await SmsAutoFill()
                                            .unregisterListener();
                                        controller.codeValue.value = '';
                                        controller.pinCodeController.text = '';
                                        Get.offNamed(Routes.loginwithmobile);
                                      },
                                  ),
                                ],
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Lexend',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ].divide(const SizedBox(height: 8)),
                      ),
                      const SizedBox(height: 24.0),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 30, right: 30, bottom: 10),
                        child: PinFieldAutoFill(
                          enableInteractiveSelection: false,
                          controller: controller.pinCodeController,
                          onCodeChanged: (val) async {
                            controller.codeValue.value = val ?? '';
                            controller.pinCodeController.text = val ?? '';
                            if (val != null && val.length == 4) {
                              controller.codeValue.value = val;
                              controller.pinCodeController.text = val;
                              await controller.verifying(context);
                            }
                          },
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
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
                            hintTextStyle: const TextStyle(color: Colors.black),
                            hintText: '****',
                            strokeColorBuilder: PinListenColorBuilder(
                              Color(0xFF45A845),
                              Color(0xFFB4C1D6),
                            ),
                            gapSpace: 30,
                            radius: Radius.circular(4),
                          ),
                        ),
                      ),
                      Obx(
                        () => controller.error.value &&
                                controller.errorInstance.value.isNotEmpty
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Text(
                                    controller.errorInstance.value,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16.0),
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
                                          text: controller.remainingTime.value
                                              .toString()
                                              .padLeft(2, '0'),
                                          style: const TextStyle(
                                            color: Color(0XFFFFA500),
                                            fontSize: 16,
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' seconds',
                                          style: const TextStyle(
                                            color: Color(0XFF555555),
                                            fontSize: 16,
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : InkWell(
                                    // onTap: controller.resendOtp,
                                    child: Text(
                                      'Resend OTP ',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Lato',
                                            color: const Color(0xFF05A155),
                                            fontSize: 16,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                          ].divide(const SizedBox(height: 8)),
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: const Color(0xFF45A845),
                            surfaceTintColor: const Color(0xFF45A845),
                            backgroundColor: const Color(0xFF45A845),
                            foregroundColor: Color(0xFF45A845),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            elevation: 0,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.all(
                              const Color(0xFF45A845),
                            ),
                          ),
                          onPressed: () => controller.verifying(context),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 4,
                                  ),
                                )
                              : Text(
                                  'Verify',
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Lexend',
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SvgPicture.asset(
                        'assets/images/Login_vector.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
