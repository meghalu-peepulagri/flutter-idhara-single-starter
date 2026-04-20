import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottieLoading extends StatelessWidget {
  const AppLottieLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lottie_animations/i Dhara loading.json',
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }
}

class GraphLottieLoading extends StatelessWidget {
  const GraphLottieLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lottie_animations/Graph.json',
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }
}
