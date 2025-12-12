import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBackButtonIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double size;
  final EdgeInsets padding;
  final Color color;

  const AppBackButtonIcon({
    super.key,
    this.onTap,
    this.iconColor,
    this.size = 24,
    this.padding = const EdgeInsets.all(6),
    this.color = const Color(0xFF383838),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap ?? () => Get.back(),
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: padding,
          child: Icon(
            Icons.arrow_back,
            color: color,
            size: size,
          ),
        ),
      ),
    );
  }
}
