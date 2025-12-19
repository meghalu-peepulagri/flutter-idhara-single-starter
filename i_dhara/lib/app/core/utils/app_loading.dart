import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottieLoading extends StatelessWidget {
  const AppLottieLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lottie_animations/loading.json',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }
}
