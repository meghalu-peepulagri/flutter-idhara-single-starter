import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddHpFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final Map<String, dynamic> errors;
  final String errorKey;
  final String hintText;
  final void Function(String)? onChanged;

  const AddHpFieldWidget({
    super.key,
    required this.controller,
    required this.errors,
    required this.errorKey,
    this.hintText = 'Enter HP',
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
            hintText: hintText,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB4C1D6)),
              borderRadius: BorderRadius.circular(9),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF45A845)),
              borderRadius: BorderRadius.circular(9),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(9),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(9),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
