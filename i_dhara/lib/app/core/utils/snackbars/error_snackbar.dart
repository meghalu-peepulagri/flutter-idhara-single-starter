import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void errorSnackBar(BuildContext context, String message) {
  return showTopSnackBar(
    Overlay.of(context),
    Container(
      height: 50,
      child: CustomSnackBar.success(
        icon: Icon(
          Icons.more_horiz,
          color: Color(0XFFDB3B2A),
        ),
        message: message,
        backgroundColor: Color(0XFFDB3B2A),
        textStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    ),
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
    duration: const Duration(seconds: 2),
    icon: null,
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
