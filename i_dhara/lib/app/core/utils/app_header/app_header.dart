import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/utils/app_header/app_back_button.dart';

class AppHeader extends StatelessWidget {
  final Function()? backbuttoncallback;
  final String title;
  final Widget? leadingchild;
  final Function()? leadingcallback;
  final Color? titleColor;
  final Color? iconColor;

  const AppHeader(
      {super.key,
      this.backbuttoncallback,
      required this.title,
      this.leadingchild,
      this.leadingcallback,
      this.titleColor,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppBackButtonIcon(
          onTap: backbuttoncallback,
          color: iconColor ?? const Color(0xFF383838),
        ),
        Text(
          '$title ',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Manrope',
              color: titleColor ?? const Color(0xFF383838),
              // color: const Color(0xFF383838),
              fontSize: 16,
              fontWeight: FontWeight.w500),
        ),
        // GestureDetector(
        //     onTap: leadingcallback,
        //     child: leadingchild == null ? AppBellIcon() : leadingchild)
      ],
    );
  }
}
