import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/data/repository/auth/auth_repository_impl.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
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
  final isValidation = false.obs;
  final message = ''.obs;
  final user = ''.obs;
  final errorInstance = ''.obs;
  final clientId = Rxn<String>();
  final codeValue = ''.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
    });
    _startTimer();
    String phone = SharedPreference.getPhone();
    if (phone.length >= 4) {
      maskedPhoneNumber.value =
          '*' * (phone.length - 4) + phone.substring(phone.length - 4);
    } else {
      maskedPhoneNumber.value = phone;
    }
    SmsAutoFill().unregisterListener();
    _listenSmsCode();
    // pinCodeController.addListener(verifying2);
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

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Future<void> verifying2(BuildContext context) async {
    if (pinCodeController.text.trim().length == 4) {
      isLoading.value = true;
      await verifying(context);
      isLoading.value = false;
      if (message.value.isNotEmpty && error.value) {
        errorSnackBar(Get.context!, message.value);
      }
    }
  }

  // Future<void> verifying(BuildContext context) async {
  //   try {
  //     isLoading.value = true;
  //     errorInstance.value = '';
  //     FocusScope.of(context).unfocus();
  //     await fetchOtp(
  //         phone: SharedPreference.getPhone(),
  //         otp: pinCodeController.text.trim());
  //     isLoading.value = false;
  //     if (!error.value && message.value.isNotEmpty) {
  //       Get.toNamed(Routes.dashboard);
  //       // ToastService.showsuccessToast(message.value);
  //       await SmsAutoFill().unregisterListener();
  //       pinCodeController.text = '';
  //     } else if (error.value &&
  //         message.value.isNotEmpty &&
  //         errorInstance.value.isEmpty) {
  //       geterrorSnackBar(message.value);
  //     }
  //   } catch (e) {}
  // }
  Future<void> verifying(BuildContext context) async {
    try {
      isLoading.value = true;
      error.value = false;
      errorInstance.value = '';
      FocusScope.of(context).unfocus();
      await fetchOtp(
          phone: SharedPreference.getPhone(),
          otp: pinCodeController.text.trim());
      isLoading.value = false;
    } catch (e) {}
  }

  Future<void> fetchOtp({String phone = '', required String otp}) async {
    final response = await AuthRepositoryImpl().verifyOtp(phone, otp);

    if (response?.data != null && response?.errors == null) {
      error.value = false;
      Get.offNamed(Routes.dashboard);
      SharedPreference.setAccessToken(
          response?.data?.accessToken.toString() ?? "");
      final userId = response!.data!.userDetails!.id;
      SharedPreference.setUserId(userId!);
      await SmsAutoFill().unregisterListener();
      // ToastService.showsuccessToast(response?.message?.toString() ?? "");
      pinCodeController.text = '';
    } else {
      error.value = true;
      errorInstance.value = response?.errors?.otp.toString() ?? "";
    }
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
    // pinCodeController.removeListener(verifying2);
    pinCodeController.dispose();
    SmsAutoFill().unregisterListener();
    timer.value?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
