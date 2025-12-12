import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';

class AppMenuButtton extends StatelessWidget {
  final Function() onTap;
  const AppMenuButtton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.menu,
              color: FlutterFlowTheme.of(context).primaryText, size: 30),
        ),
      ),
    );
  }
}
