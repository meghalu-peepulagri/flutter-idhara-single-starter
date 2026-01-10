import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';

class AddHorsePowerFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final Map<String, dynamic> errors;
  final String errorKey;
  final String hintText;
  final void Function(String)? onChanged;

  const AddHorsePowerFieldWidget({
    super.key,
    required this.controller,
    required this.errors,
    required this.errorKey,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String? errorText =
        errors.containsKey(errorKey) ? errors[errorKey] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            LengthLimitingTextInputFormatter(7),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              final text = newValue.text;

              // Only one decimal
              if ('.'.allMatches(text).length > 1) return oldValue;

              // Max 2 decimal places
              if (text.contains('.')) {
                final parts = text.split('.');
                if (parts.length > 1 && parts[1].length > 2) {
                  return oldValue;
                }
              }
              return newValue;
            }),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                  fontFamily: 'Inter',
                  letterSpacing: 0.0,
                ),
            hintText: hintText,
            hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  letterSpacing: 0,
                  color: const Color(0xFFC5C5C5),
                ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB4C1D6), width: 1),
              borderRadius: BorderRadius.circular(9.12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF45A845), width: 1),
              borderRadius: BorderRadius.circular(9.12),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).error, width: 1),
              borderRadius: BorderRadius.circular(9.12),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).error, width: 1),
              borderRadius: BorderRadius.circular(9.12),
            ),
            // suffixIcon: suffixIcon,
            filled: true,
            // errorText: message(),
            errorStyle: const TextStyle(color: Colors.red),
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
            hoverColor: FlutterFlowTheme.of(context).secondaryBackground,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
