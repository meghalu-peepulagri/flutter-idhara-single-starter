import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/presentation/controllers/language_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final LanguageController languageController = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: InkWell(
          onTap: () => Get.back(),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.selectLanguage,
          style: GoogleFonts.dmSans(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final currentLang = languageController.currentLocale.value.languageCode;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildLanguageItem(
                context,
                title: AppLocalizations.of(context)!.english,
                isSelected: currentLang == 'en',
                onTap: () => languageController.changeLanguage('en'),
              ),
              const SizedBox(height: 16),
              _buildLanguageItem(
                context,
                title: AppLocalizations.of(context)!.telugu,
                isSelected: currentLang == 'te',
                onTap: () => languageController.changeLanguage('te'),
              ),
              const SizedBox(height: 16),
              _buildLanguageItem(
                context,
                title: AppLocalizations.of(context)!.hindi,
                isSelected: currentLang == 'hi',
                onTap: () => languageController.changeLanguage('hi'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLanguageItem(BuildContext context,
      {required String title,
      required bool isSelected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEBF3FE)
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF004E7E) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: isSelected ? const Color(0xFF004E7E) : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF004E7E),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
