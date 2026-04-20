import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';

class SearchFieldComponent extends StatelessWidget {
  final TextEditingController controller;
  final String? errorKey;
  final int? maxlength;
  final String hintText;
  final Icon? icon;
  final Function(String)? onchange;
  const SearchFieldComponent(
      {super.key,
      required this.controller,
      this.errorKey,
      required this.hintText,
      this.maxlength,
      this.icon,
      this.onchange});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: false,
      obscureText: false,
      maxLength: maxlength,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'Inter',
              letterSpacing: 0.0,
            ),
        hintText: hintText,
        hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
              fontFamily: 'DM Sans',
              color: const Color(0xFF848484),
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
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
        prefixIcon: Icon(Icons.search_sharp,
            color: FlutterFlowTheme.of(context).primaryText, size: 20),
        suffixIcon: icon,
        filled: true,
        errorStyle: const TextStyle(color: Colors.red),
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        hoverColor: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      style: FlutterFlowTheme.of(context).bodyMedium.override(
          fontFamily: 'Lexend', color: Colors.black, letterSpacing: 0),
      cursorColor: FlutterFlowTheme.of(context).primaryText,
      onChanged: (value) {
        onchange!(value);
      },
      inputFormatters: [
        FilteringTextInputFormatter.deny(
          RegExp(r'^[^a-zA-Z0-9]+'),
        ),
        FilteringTextInputFormatter.allow(
          RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9\s\-\_/]*$'),
        ),
      ],
    );
  }
}
