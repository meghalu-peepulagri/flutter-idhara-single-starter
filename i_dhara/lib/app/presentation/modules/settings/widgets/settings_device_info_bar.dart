import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

class SettingsDeviceInfoBar extends StatelessWidget {
  final String pumpName;
  final String pumpHP;
  final VoidCallback onDefaultPressed;
  final bool showDefaultButton;

  const SettingsDeviceInfoBar({
    super.key,
    required this.pumpName,
    required this.pumpHP,
    required this.onDefaultPressed,
    this.showDefaultButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final truncatedName = pumpName.replaceAll(RegExp(r'\s+'), ' ');
    final displayName = truncatedName.length > 16
        ? '${truncatedName.substring(0, 16)}...'
        : truncatedName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 10,
            children: [
              Text(
                displayName,
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF000000),
                      fontSize: 16.0,
                    ),
              ),
              Text(
                '$pumpHP HP',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF000000),
                      fontSize: 12.0,
                    ),
              ),
            ],
          ),
          Visibility(
            visible: showDefaultButton,
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            child: Container(
              height: 32,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF2994A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FFButtonWidget(
                onPressed: onDefaultPressed,
                text: 'Default',
                options: FFButtonOptions(
                  color: Colors.transparent,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Manrope',
                        color: const Color(0XFFFFFFFF),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
