import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// Error snackbars stay on screen long enough for the user to read the
// message without lingering — 5s is the sweet spot for short device-
// response text.
const Duration _kErrorSnackBarDuration = Duration(seconds: 4);

void errorSnackBar(BuildContext context, String message) {
  return showTopSnackBar(
    Overlay.of(context),
    SizedBox(
      height: 50,
      child: CustomSnackBar.success(
        icon: const Icon(
          Icons.more_horiz,
          color: Color(0XFFDB3B2A),
        ),
        message: message,
        backgroundColor: const Color(0XFFDB3B2A),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    ),
    displayDuration: _kErrorSnackBarDuration,
  );
}

void geterrorSnackBar(String message) {
  Get.snackbar(
    '', // no title
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0XFFDB3B2A),
    colorText: Colors.white,
    margin: const EdgeInsets.all(10),
    borderRadius: 8,
    icon: null,
    duration: _kErrorSnackBarDuration,
    titleText: const SizedBox.shrink(), // removes default title spacing
    messageText: Text(
      textAlign: TextAlign.center,
      message,
      style: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: Colors.white,
      ),
    ),
  );
}
