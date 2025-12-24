import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:i_dhara/app/core/utils/app_text/app_text.dart';

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/No internet.svg',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          AppText(
              fontSize: 16, fontWeight: FontWeight.w500, text: "No Internet"),
        ],
      ),
    );
  }
}
