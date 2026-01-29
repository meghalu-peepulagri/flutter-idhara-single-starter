import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/utils/app_text/app_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie_animations/No internet connection.json',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          AppText(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              text: AppLocalizations.of(context)!.noInternet),
        ],
      ),
    );
  }
}
