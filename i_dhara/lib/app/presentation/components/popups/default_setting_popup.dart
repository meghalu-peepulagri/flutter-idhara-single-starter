import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';

Future<bool?> showDeviceSettingConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String yesText = "Yes",
  String noText = "No",
  required Function()? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ❗ Icon
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 30,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                spacing: 10,
                children: [
                  // YES Button
                  Expanded(
                      child: FFButtonWidget(
                          showLoadingIndicator: true,
                          text: yesText,
                          onPressed: onConfirm,
                          options: FFButtonOptions(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ))),
                  Expanded(
                      child: FFButtonWidget(
                          showLoadingIndicator: true,
                          text: noText,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          options: FFButtonOptions(
                            textStyle: const TextStyle(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: Colors.red.withOpacity(0.15),
                            elevation: 0,
                            borderRadius: BorderRadius.circular(8),
                          ))),
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}
