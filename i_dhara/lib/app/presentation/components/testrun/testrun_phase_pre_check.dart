part of '../testrun_verification_card.dart';

/// Pre-check / no-internet phase widgets for [_ConfirmTestRunScreenState].
extension _TestRunPhasePreCheck on _ConfirmTestRunScreenState {
  // ===================== No Internet Widget =====================

  Widget _buildNoInternetWidget() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 340,
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.red.shade400,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your internet connection.\nThe test run will resume automatically\nonce you are back online.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Waiting for connection...',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Phase 1: Pre-Check =====================

  Widget _buildPreCheckPhase() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        'Smart Calibration',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 28,
                        color: Color(0xFF6B7280),
                      )),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  // Network Connectivity — verified via motorData.testRunSignal.
                  // Listens to both liveDataNotifier (T:35/T:41) and
                  // heartbeatNotifier (T:40) so the icon updates from either.
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.mqttService.liveDataNotifier,
                      widget.mqttService.heartbeatNotifier,
                    ]),
                    builder: (context, _) {
                      // widget.motorData may be a stale reference if the map
                      // was rebuilt after the dialog opened. Fall back to a
                      // fresh lookup by MAC / PCB so heartbeat updates (which
                      // update the live map entry) are always reflected.
                      MotorData? motorData = widget.motorData;
                      if (motorData?.testRunSignal != true) {
                        final mac = widget.motor.starter?.macAddress;
                        final pcb = widget.motor.starter?.pcbNumber;
                        for (final data
                            in widget.mqttService.motorDataMap.values) {
                          if ((mac != null && data.macAddress == mac) ||
                              (pcb != null && data.pcbNumber == pcb)) {
                            motorData = data;
                            break;
                          }
                        }
                      }
                      final bool? signal;
                      if (motorData?.testRunSignal == true) {
                        signal = true;
                      } else if (_preCheckTimedOut) {
                        signal = false;
                      } else {
                        signal = null;
                      }
                      return _buildVerificationCloudConnection(
                        'Network Connectivity',
                        signal,
                        'assets/images/network_device.svg',
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Power Supply Status — verified via motorData.testrunPowerSupply.
                  ValueListenableBuilder<int>(
                    valueListenable: widget.mqttService.liveDataNotifier,
                    builder: (context, _, __) {
                      final int? powerVerified;
                      if (widget.motorData?.testrunPowerSupply == true) {
                        powerVerified = 1;
                      } else if (_preCheckTimedOut) {
                        powerVerified = 0;
                      } else {
                        powerVerified = null;
                      }
                      return _buildVerificationInputPower(
                          'Power Supply Status', powerVerified);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Voltage Range — verified via motorData.testrunVoltageRange
                  // and actual phase voltage values.
                  ValueListenableBuilder<int>(
                    valueListenable: widget.mqttService.liveDataNotifier,
                    builder: (context, _, __) {
                      return _buildVoltageVerification();
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildCheckboxItem(
                    'Motor wires / terminals securely connected',
                    isMotorWiresChecked,
                    (value) {
                      // ignore: invalid_use_of_protected_member
                      setState(() {
                        isMotorWiresChecked = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCheckboxItem(
                    'Pump / delivery valve fully open',
                    isPumpValveChecked,
                    (value) {
                      // ignore: invalid_use_of_protected_member
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
                      onPressed: isActive ? _onStartPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? const Color(0xFF0F6B8A)
                            : Colors.grey.shade400,
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
          ],
        ),
      ),
    );
  }
}
