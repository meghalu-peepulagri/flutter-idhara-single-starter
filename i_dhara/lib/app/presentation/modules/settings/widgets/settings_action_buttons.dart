import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

class SettingsActionButtons extends StatelessWidget {
  final bool isActive;
  final bool isFlcOutOfRange;
  final bool hasStarter;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const SettingsActionButtons({
    super.key,
    required this.isActive,
    required this.isFlcOutOfRange,
    required this.hasStarter,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isSaveDisabled = !isActive || isFlcOutOfRange;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FFButtonWidget(
              onPressed: onCancel,
              text: 'Cancel',
              options: FFButtonOptions(
                height: 45.0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0),
                color: hasStarter
                    ? FlutterFlowTheme.of(context).secondaryBackground
                    : Colors.white38,
                textStyle:
                    FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Manrope',
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                elevation: 0.0,
                borderSide: const BorderSide(color: Color(0x38000000)),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          const SizedBox(width: 24.0),
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                gradient: isSaveDisabled
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: isSaveDisabled ? const Color(0xFFB0B0B0) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FFButtonWidget(
                onPressed: isSaveDisabled ? null : onSave,
                text: 'Save',
                options: FFButtonOptions(
                  height: 45.0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24.0),
                  color: Colors.transparent,
                  textStyle:
                      FlutterFlowTheme.of(context).titleSmall.override(
                            fontFamily: 'Manrope',
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                  elevation: 0.0,
                  borderRadius: BorderRadius.circular(12.0),
                  disabledColor: const Color(0xFFB0B0B0),
                  disabledTextColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
