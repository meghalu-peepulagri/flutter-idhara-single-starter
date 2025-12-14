import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/utils/text_fields/form_error_helper.dart';

class TextFieldComponent extends StatelessWidget {
  final TextEditingController controller;
  final String? errorKey;
  final dynamic errors;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxlength;
  final String hintText;
  final bool readOnly;
  final Function()? ontap;
  final Icon? icon;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  const TextFieldComponent({
    super.key,
    required this.controller,
    this.errorKey,
    this.keyboardType,
    this.errors,
    this.inputFormatters,
    required this.hintText,
    required this.readOnly,
    this.maxlength = 30,
    this.ontap,
    this.icon,
    this.onChanged,
  });

  String? message() {
    return FormErrorHelper(errors: errors).message(errorKey!);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: false,
      obscureText: false,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      maxLength: maxlength,
      maxLengthEnforcement: MaxLengthEnforcement
          .enforced, // Ensure maxLength is strictly enforced
      keyboardType: keyboardType,
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
          borderSide:
              BorderSide(color: FlutterFlowTheme.of(context).error, width: 1),
          borderRadius: BorderRadius.circular(9.12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: FlutterFlowTheme.of(context).error, width: 1),
          borderRadius: BorderRadius.circular(9.12),
        ),
        suffixIcon: icon,
        filled: true,
        errorText: message(),
        errorStyle: const TextStyle(color: Colors.red),
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        hoverColor: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Lexend',
            color: Colors.black,
            letterSpacing: 0,
          ),
      cursorColor: FlutterFlowTheme.of(context).primaryText,
      onTap: ontap,
      onChanged: onChanged,
      buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) =>
          null, // Disable character counter
    );
  }
}
