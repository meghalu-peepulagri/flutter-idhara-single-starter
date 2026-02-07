import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository_impl.dart';
import 'package:i_dhara/app/data/services/storages/hive_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../routes/app_routes.dart';

// Controller for OTP screen
class OtpController extends GetxController with CodeAutoFill {
  final pinCodeController = TextEditingController();
  final timer = Rxn<Timer>();
  final remainingTime = 59.obs;
  final isTimerRunning = true.obs;
  final isLoading = false.obs;
  final maskedPhoneNumber = ''.obs;
  final error = false.obs;
  final errorInstance = ''.obs;
  final codeValue = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
    String phone = HiveHandler.getValue(Hivekeys.userPhone, '');

    if (phone.length >= 4) {
      maskedPhoneNumber.value =
          '*' * (phone.length - 4) + phone.substring(phone.length - 4);
    } else {
      maskedPhoneNumber.value = phone;
    }
    SmsAutoFill().unregisterListener();
    _listenSmsCode();
  }

  void _startTimer() {
    remainingTime.value = 59;
    isTimerRunning.value = true;
    timer.value = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.value > 0) {
        remainingTime.value--;
      } else {
        isTimerRunning.value = false;
        timer.cancel();
      }
    });
  }

  Future<void> verifying(BuildContext context) async {
    try {
      isLoading.value = true;
      error.value = false;
      errorInstance.value = '';

      FocusScope.of(context).unfocus();
      await fetchOtp(
          phone: HiveHandler.getValue(Hivekeys.userPhone, ''),
          otp: pinCodeController.text.trim());
    } catch (e) {
      debugPrint('Error during verification: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOtp({String phone = '', required String otp}) async {
    final response = await AuthRepositoryImpl().verifyOtp(phone, otp);

    if (response?.data != null && response?.errors == null) {
      error.value = false;
      Get.offNamed(Routes.dashboard);
      final userId = response!.data!.userDetails!.id;

      await HiveHandler.setValue(
          Hivekeys.accessToken, response.data?.accessToken.toString());
      HiveHandler.setValue(Hivekeys.userId, userId);
      await SmsAutoFill().unregisterListener();
      pinCodeController.text = '';
    } else {
      error.value = true;
      errorInstance.value = response?.errors?.otp.toString() ?? "";
    }
  }

  Future<void> fetchResendOtp({required String phone, String sid = ''}) async {
    errorInstance.value = '';
    final response = await AuthRepositoryImpl().resendOtp(phone, sid);

    if (response != null && response.errors == null) {
      // Success case for resend OTP
    } else if (response?.errors != null) {
      errorInstance.value = response!.errors!.toJson().toString();
    }
  }

  void resendOtp() async {
    isTimerRunning.value = true;
    _startTimer();
    String id = await SmsAutoFill().getAppSignature;
    await fetchResendOtp(
        phone: HiveHandler.getValue(Hivekeys.userPhone, ''), sid: id);
  }

  Future<void> _listenSmsCode() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() async {
    codeValue.value = code!;
  }

  @override
  void onClose() {
    pinCodeController.dispose();
    SmsAutoFill().unregisterListener();
    timer.value?.cancel();
    super.onClose();
  }
}
