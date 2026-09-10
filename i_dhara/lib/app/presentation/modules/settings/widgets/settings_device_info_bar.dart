import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

class SettingsDeviceInfoBar extends StatelessWidget {
  final String pumpName;
  final String pumpHP;
  final VoidCallback onDefaultPressed;
  final bool showDefaultButton;
  final bool showHp;
  final bool showFaultButton;
  final VoidCallback? onFaultPressed;

  const SettingsDeviceInfoBar({
    super.key,
    required this.pumpName,
    required this.pumpHP,
    required this.onDefaultPressed,
    this.showDefaultButton = true,
    this.showHp = true,
    this.showFaultButton = false,
    this.onFaultPressed,
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
              if (showHp)
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
          _buildTrailingAction(context),
        ],
      ),
    );
  }

  Widget _buildTrailingAction(BuildContext context) {
    if (showDefaultButton) {
      return Container(
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
      );
    }

    if (showFaultButton) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECDCA)),
        ),
        child: FFButtonWidget(
          onPressed: onFaultPressed,
          // clearFault() stays open (confirm dialog + MQTT ack wait) far
          // longer than this tap — its own "Clear Fault" button already
          // shows a spinner for that. Don't also swap this header button
          // out for a spinner underneath the dialog for the same duration.
          showLoadingIndicator: false,
          text: 'Fault',
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFDB3B2A),
          ),
          options: FFButtonOptions(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  fontFamily: 'Manrope',
                  color: const Color(0xFFDB3B2A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
            elevation: 0.0,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
