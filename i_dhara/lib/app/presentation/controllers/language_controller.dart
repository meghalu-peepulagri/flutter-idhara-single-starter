import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class LanguageController extends GetxController {
  static LanguageController get to => Get.find();

  var currentLocale = const Locale('en', '').obs;

  @override
  void onInit() {
    super.onInit();
    loadLanguage();
  }

  void loadLanguage() {
    String langCode = SharedPreference.getLanguage();
    if (langCode.isNotEmpty) {
      currentLocale.value = Locale(langCode, '');
      // Get.updateLocale(
      //     currentLocale.value); // Removed to prevent setState during build
    }
  }

  void changeLanguage(String langCode) {
    Locale locale = Locale(langCode, '');
    currentLocale.value = locale;
    Get.updateLocale(locale);
    SharedPreference.setLanguage(langCode);
  }
}
