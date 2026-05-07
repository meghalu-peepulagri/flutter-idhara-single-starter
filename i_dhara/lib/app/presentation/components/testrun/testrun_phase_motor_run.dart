part of '../testrun_verification_card.dart';

/// Motor-running phase widgets (motor-on waiting + measuring) for
/// [_ConfirmTestRunScreenState].
extension _TestRunPhaseMotorRun on _ConfirmTestRunScreenState {
  // ===================== Phase 1b: Motor ON Waiting =====================

  Widget _buildMotorOnWaitingPhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _testrunColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Motor Test Run',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Smart Calibration',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(32),
                child: _motorOnFailed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Motor Failed to Respond',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _motorOnFailureMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.route == Routes.dashboard) {
                                  Get.offAllNamed(Routes.dashboard,
                                      arguments: {'refresh': true});
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F6B8A),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Dismiss',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF0F6B8A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Starting Motor...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF004E7E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_motorOnCountdown s',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F6B8A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Waiting for device acknowledgment',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== Phase 2: Measuring =====================

  double get _progress => _remainingSeconds / _kTotalSeconds;

  Widget _buildMeasuringPhase() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Top Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _testrunColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      "Motor Test Run",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Smart Calibration",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                  ],
                ),
              ),

              /// Body Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Measuring Full Load Current ( FLC )..",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Current Value
                    ValueListenableBuilder(
                        valueListenable: _avgCurrent,
                        builder: (context, val, _) {
                          return RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _avgCurrent.value.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                                const TextSpan(
                                  text: "  A",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                    const SizedBox(height: 18),

                    /// Progress Line
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFD1D5DB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF004E7E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Time remaining: $_remainingSeconds Seconds",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF004E7E),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Emergency Stop Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _emergencyStop,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "EMERGENCY STOP",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.white,
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
      ),
    );
  }
}
