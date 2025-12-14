import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddHpFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;

  const AddHpFieldWidget({
    super.key,
    required this.controller,
    this.hintText = 'Enter HP',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlignVertical: TextAlignVertical.center,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(7),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final newText = newValue.text;

          // Allow only one dot
          if (newText.contains('.') &&
              newText.indexOf('.') != newText.lastIndexOf('.')) {
            return oldValue;
          }

          // Prevent starting with dot
          if (newText.startsWith('.') && newText.length == 1) {
            return oldValue;
          }

          // Prevent dot at 7th position
          if (newText.length >= 7 &&
              newText.endsWith('.') &&
              newText.indexOf('.') == newText.length - 1) {
            return oldValue;
          }

          // Allow only 2 digits after decimal
          if (newText.contains('.')) {
            final parts = newText.split('.');
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
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFFC5C5C5),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFB4C1D6)),
          borderRadius: BorderRadius.circular(9.12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF45A845)),
          borderRadius: BorderRadius.circular(9.12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(9.12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(9.12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(
        fontFamily: 'Lexend',
        color: Colors.black,
      ),
    );
  }
}
