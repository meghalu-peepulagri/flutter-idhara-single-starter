import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../presentation/routes/app_routes.dart';

class BottomNavigation extends StatelessWidget {
  final int activeIndex;
  final bool isNavigateScreen;

  const BottomNavigation({
    super.key,
    required this.activeIndex,
    this.isNavigateScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () {
              if (!isNavigateScreen && activeIndex != 0) {
                Get.offNamed(Routes.dashboard);
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3686AF), // main blue
                    Color(0xFF004E7E), // lighter gradient blue
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B7DE9).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    color: Color(0XFFFFFFFF),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: Color(0XFFFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
