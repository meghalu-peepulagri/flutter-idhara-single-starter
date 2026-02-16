import 'package:flutter/material.dart';

import 'testrun_verification_card2.dart';

class ConfirmTestRunScreen extends StatefulWidget {
  const ConfirmTestRunScreen({super.key});

  @override
  State<ConfirmTestRunScreen> createState() => _ConfirmTestRunScreenState();
}

class _ConfirmTestRunScreenState extends State<ConfirmTestRunScreen> {
  bool isMotorWiresChecked = false;
  bool isPumpValveChecked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close icon

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Test Run',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Smart Calibration v2.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  // Close icon
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Pre-Test Verifications Section
              const Text(
                'Pre - Test Verifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),

              // Cloud Connection - Verified
              _buildVerifiedItem('Cloud Connection'),
              const SizedBox(height: 16),

              // Input Power - Verified
              _buildVerifiedItem('Input Power ( 415V 3-Phase )'),
              const SizedBox(height: 24),

              // Motor wires checkbox
              _buildCheckboxItem(
                'Motor wires / terminals securely connected',
                isMotorWiresChecked,
                (value) {
                  setState(() {
                    isMotorWiresChecked = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Pump valve checkbox
              _buildCheckboxItem(
                'Pump / delivery valve fully open',
                isPumpValveChecked,
                (value) {
                  setState(() {
                    isPumpValveChecked = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle start test run
                    if (isMotorWiresChecked && isPumpValveChecked) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: MotorTestRunCard(),
                        ),
                      );
                      // Start the test
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(
                      //     content: Text('Starting 2-minute test run...'),
                      //   ),
                      // );
                    } else {
                      // Show warning
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please confirm all verifications'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6B8A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'START TEST RUN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedItem(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFECFDF5),
            border: Border.all(
              color: const Color(0xFF10B981),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF10B981),
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(
              color: Color(0xFFCBD5E1),
              width: 1.5,
            ),
            activeColor: const Color(0xFF0F6B8A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
