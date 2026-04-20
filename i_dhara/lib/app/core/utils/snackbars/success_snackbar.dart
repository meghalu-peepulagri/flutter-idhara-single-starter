import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void successSnackBar(BuildContext context, String message) {
  return showTopSnackBar(
    Overlay.of(context),
    SizedBox(
      height: 50,
      child: CustomSnackBar.success(
        icon: const Icon(
          Icons.more_horiz,
          color: Color(0xFF1AAA55),
        ),
        message: message,
        backgroundColor: const Color(0xFF1AAA55),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    ),
  );
}

void getsuccessSnackBar(String message) {
  Get.snackbar(
    message,
    "",
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.symmetric(
        vertical: 0, horizontal: 12), // smaller padding
    backgroundColor: const Color(0xFF1AAA55),
    colorText: Colors.white,
    borderRadius: 8,
    titleText: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    ),
    duration: const Duration(seconds: 3),
  );
}
