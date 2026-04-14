import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

/// Pre-test verification dialog (Phase 1 of the test-run flow).
///
/// Manages its own MQTT listeners, timeout timers, and verification state.
/// Calls [onStartPressed] when the user taps START TEST RUN (after all checks
/// pass and the auto-mode guard is satisfied).
/// Calls [onClose] when the user taps the ✕ button.
class PreCheckPhase extends StatefulWidget {
  final Motor motor;
  final MotorData? motorData;
  final MqttService mqttService;
  final VoidCallback onStartPressed;
  final VoidCallback onClose;

  const PreCheckPhase({
    super.key,
    required this.motor,
    required this.motorData,
    required this.mqttService,
    required this.onStartPressed,
    required this.onClose,
  });

  @override
  State<PreCheckPhase> createState() => _PreCheckPhaseState();
}

class _PreCheckPhaseState extends State<PreCheckPhase> {
  // --- Checkbox state ---
  bool isMotorWiresChecked = false;
  bool isPumpValveChecked = false;

  // --- Pre-check timeout state ---
  // Set to true 15 s after the dialog opens; forces every still-loading
  // icon to ❌.
  bool _preCheckTimedOut = false;
  Timer? _preCheckTimeoutTimer;
  // Guards against showing duplicate connection snackbars.
  bool _connectionSnackBarShown = false;

  // --- Fresh-signal / live-data flags ---
  bool _freshSignalReceived = false;
  bool _freshLiveDataReceived = false;
  // Dedicated notifier so the Network Connectivity builder rebuilds
  // immediately whenever signal is confirmed (T:40 heartbeat OR T:41/T:35
  // live data), without depending on heartbeatNotifier alone.
  final ValueNotifier<bool> _freshSignalNotifier = ValueNotifier(false);

  // --- Voltage constants ---
  static const double _minVoltage = 370.0;
  static const double _maxVoltage = 450.0;

  // ─────────────────────────────── lifecycle ───────────────────────────────

  @override
  void initState() {
    super.initState();

    widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
    // Delay listener registration so loading icons are always shown for at
    // least 1 second each time the dialog opens, even when MQTT is already
    // streaming.
    // Future.delayed(const Duration(seconds: 1), () {
    //   if (mounted) {
    //     widget.mqttService.heartbeatNotifier
    //         .removeListener(_onFirstHeartbeat); // guard double-add
    //     widget.mqttService.heartbeatNotifier.addListener(_onFirstHeartbeat);
    //     // Also listen directly to liveDataNotifier — if T:41 arrives before
    //     // T:40 heartbeat, receiving live data implies network connectivity and
    //     // unlocks the signal icon before checking power & voltage.
    //     widget.mqttService.liveDataNotifier
    //         .removeListener(_onFirstLiveData); // guard double-add
    //     widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
    //   }
    // });
    // _startPreCheckTimeout();
  }

  @override
  void dispose() {
    widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
    widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
    _preCheckTimeoutTimer?.cancel();
    _freshSignalNotifier.dispose();
    super.dispose();
  }

  // ─────────────────────────────── helpers ─────────────────────────────────

  bool _isVoltageValid(double? voltage) {
    if (voltage == null) return false;
    return voltage >= _minVoltage && voltage <= _maxVoltage;
  }

  /// Returns null when all voltages are in range, or a descriptive error string.
  String? get _voltageError {
    if (widget.motorData == null || !widget.motorData!.hasReceivedLiveData) {
      return null; // No data yet — don't block
    }
    final v1 = double.tryParse(widget.motorData?.voltageBlue ?? '0') ?? 0;
    final v2 = double.tryParse(widget.motorData?.voltageRed ?? '0') ?? 0;
    final v3 = double.tryParse(widget.motorData?.voltageYellow ?? '0') ?? 0;

    final outOfRange = <String>[];
    if (!_isVoltageValid(v1))
      outOfRange.add('B-phase = ${v1.toStringAsFixed(0)} V');
    if (!_isVoltageValid(v2))
      outOfRange.add('R-phase = ${v2.toStringAsFixed(0)} V');
    if (!_isVoltageValid(v3))
      outOfRange.add('Y-phase = ${v3.toStringAsFixed(0)} V');

    if (outOfRange.isEmpty) return null;
    return 'Voltage out of range: ${outOfRange.join(', ')}. Test cannot proceed.';
  }

  bool get _isVoltageInRange {
    if (widget.motorData == null || !widget.motorData!.hasReceivedLiveData) {
      return false; // No data yet — not verified
    }
    return _voltageError == null;
  }

  int _getSignalBars(MotorData? motorData) {
    if (motorData?.hasReceivedData == true && !motorData!.isSignalStale()) {
      return motorData.signalBars;
    }
    final signal = widget.motor.starter?.signalQuality;
    if (signal == null || signal < 2 || signal > 31) return 0;
    if (signal < 10) return 1;
    if (signal < 15) return 2;
    if (signal < 20) return 3;
    return 4;
  }

  bool get _isPowerOn {
    if (widget.motorData != null && widget.motorData!.hasReceivedLiveData) {
      return widget.motorData!.power == 1;
    }
    return (widget.motor.starter?.power ?? 0) == 1;
  }

  /// True when network connectivity is definitively known to be absent —
  /// either the pre-check timed out without a heartbeat, or a fresh heartbeat
  /// arrived but reported 0 signal bars.
  bool get _isNetworkFalse {
    if (_preCheckTimedOut && !_freshSignalReceived) return true;
    if (_freshSignalReceived && _getSignalBars(widget.motorData) == 0)
      return true;
    return false;
  }

  /// True when the network check has completed AND passed (signal ≥ 1).
  bool get _networkVerified =>
      _freshSignalReceived && _getSignalBars(widget.motorData) >= 1;

  /// True when the power check has completed AND passed.
  /// Only evaluated after [_networkVerified] is true.
  bool get _powerVerified {
    if (!_networkVerified) return false;
    final liveReady = _freshLiveDataReceived &&
        (widget.motorData?.hasReceivedLiveData ?? false);
    return liveReady && _isPowerOn;
  }

  /// True when the motor is in Auto mode (live MQTT value takes priority
  /// over the API value stored in [widget.motor.mode]).
  bool get _isAutoMode {
    final liveIndex = widget.motorData?.modeIndex;
    if (liveIndex != null) return liveIndex == 1;
    return widget.motor.mode?.toUpperCase().contains('AUTO') ?? false;
  }

  bool get isActive {
    if (!_freshSignalReceived || !_freshLiveDataReceived) return false;
    final signal = _getSignalBars(widget.motorData);
    return isMotorWiresChecked &&
        isPumpValveChecked &&
        signal >= 1 &&
        signal <= 4 &&
        _isPowerOn &&
        _isVoltageInRange;
  }

  // ─────────────────────────────── timeout ─────────────────────────────────

  void _startPreCheckTimeout() {
    _preCheckTimeoutTimer?.cancel();
    _preCheckTimeoutTimer =
        Timer(const Duration(seconds: 15), _onPreCheckTimeout);
  }

  void _onPreCheckTimeout() {
    if (!mounted) return;
    setState(() => _preCheckTimedOut = true);

    // Immediate checks already fired a snackbar — don't duplicate.
    if (_connectionSnackBarShown) return;

    // Priority 1: network never responded, or responded with 0 bars.
    if (!_freshSignalReceived || _isNetworkFalse) {
      _connectionSnackBarShown = true;
      geterrorSnackBar('Device is not connected.');
      return;
    }

    // Priority 2: network OK but live data never arrived, or power/voltage bad.
    if (!_freshLiveDataReceived || !_isPowerOn || !_isVoltageInRange) {
      _connectionSnackBarShown = true;
      geterrorSnackBar('Device is not connected');
    }
  }

  // ───────────────────────────── MQTT listeners ─────────────────────────────

  /// Called on the first T:40 heartbeat — unlocks signal icon.
  ///
  /// Network-first priority:
  /// • signal >= 1 → network OK → register liveDataNotifier and proceed to
  ///   power / voltage checks.
  /// • signal == 0 → network false → show snackbar immediately; power and
  ///   voltage are never fetched or processed.
  void _onFirstHeartbeat() {
    if (!_freshSignalReceived && mounted) {
      widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _freshSignalReceived = true);
        _freshSignalNotifier.value = true;

        if (_getSignalBars(widget.motorData) >= 1) {
          // Network confirmed OK — now safe to listen for live data.
          widget.mqttService.liveDataNotifier
              .removeListener(_onFirstLiveData); // guard double-add
          widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
        } else {
          // Network false — show error immediately; skip live data entirely.
          if (!_connectionSnackBarShown) {
            _connectionSnackBarShown = true;
            geterrorSnackBar('Device is not connected.');
          }
        }
      });
    }
  }

  MotorData? _getMotorData() {
    if (widget.motor.starter == null) return null;
    final mac = widget.motor.starter!.macAddress;
    final pcb = widget.motor.starter!.pcbNumber;
    MotorData? bestData;
    DateTime? bestTime;
    for (var entry in widget.mqttService.motorDataMap.entries) {
      final data = entry.value;
      if (data.hasReceivedData != true) continue;
      final key = entry.key;
      final matchesByKey =
          (mac != null && mac.isNotEmpty && key.startsWith('$mac-')) ||
              (pcb != null && pcb.isNotEmpty && key.startsWith('$pcb-'));
      final matchesByData = (mac != null &&
              mac.isNotEmpty &&
              (data.macAddress == mac || data.pcbNumber == mac)) ||
          (pcb != null &&
              pcb.isNotEmpty &&
              (data.macAddress == pcb || data.pcbNumber == pcb));
      if (matchesByKey || matchesByData) {
        final ackTime = widget.mqttService.getLastAckTime(key);
        if (bestData == null ||
            (ackTime != null &&
                (bestTime == null || ackTime.isAfter(bestTime)))) {
          bestData = data;
          bestTime = ackTime;
        }
      }
    }
    return bestData;
  }

  /// Called on the first T:35/T:41 live-data update — unlocks power & voltage
  /// icons and checks them. If T:41 arrives before T:40, receiving live data
  /// implies network connectivity, so the signal icon is unlocked first in a
  /// separate frame before power / voltage are evaluated.
  void _onFirstLiveData() {
    widget.mqttService.liveDataNotifier.value;
    final motordata = _getMotorData();

    if (motordata?.hasReceivedData == true) {
      if (!_freshSignalReceived) {
        setState(() => _freshSignalReceived = true);
        _freshSignalNotifier.value = true;
      }
      // Step 2 — After the signal rebuild, unlock live data and evaluate
      // power status and voltage range in the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _freshLiveDataReceived = true;
        });
        _checkPowerVoltageNow();
      });
    }

    // if (!_freshLiveDataReceived && mounted) {
    //   widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (!mounted) return;
    //     // Step 1 — T:35/T:41 implies network connectivity.
    //     // Unlock signal icon first so the UI confirms network before checking
    //     // the remaining conditions.
    //     if (!_freshSignalReceived) {
    //       setState(() => _freshSignalReceived = true);
    //       _freshSignalNotifier.value = true;
    //     }
    //     // Step 2 — After the signal rebuild, unlock live data and evaluate
    //     // power status and voltage range in the next frame.
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       if (!mounted) return;
    //       setState(() => _freshLiveDataReceived = true);
    //       _checkPowerVoltageNow();
    //     });
    //   });
    // }
  }

  /// Immediately checks all verification states once live data arrives.
  /// If all three icons show close (network/power/voltage all failed),
  /// fires the error snackbar right away without waiting for the 15-second timeout.
  void _checkPowerVoltageNow() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _connectionSnackBarShown) return;
      if (!(widget.motorData?.hasReceivedLiveData ?? false)) return;
      if (_isNetworkFalse) {
        _connectionSnackBarShown = true;
        geterrorSnackBar('Device is not connected.');
        return;
      }
      if (!_isPowerOn || !_isVoltageInRange) {
        _connectionSnackBarShown = true;
        geterrorSnackBar(
            'Device is not connected due to no power or voltage mismatch.');
      }
    });
  }

  // ───────────────────────────── start action ──────────────────────────────

  /// Guards [widget.onStartPressed]: blocks and warns when the motor is in
  /// Auto mode.
  void _onStartPressed() {
    if (_isAutoMode) {
      geterrorSnackBar('Motor is in Auto Mode. Switch to Manual Mode');
      return;
    }
    widget.onStartPressed();
  }

  // ────────────────────────────── UI helpers ───────────────────────────────

  Widget get _checkIcon => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFECFDF5),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        ),
        child:
            const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
      );

  Widget get _closeIcon => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade100,
          border: Border.all(color: Colors.red, width: 1.5),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
      );

  Widget get _loadingIcon => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF0F6B8A),
        ),
      );

  Widget _buildVerificationCloudConnection(String text, int? signal) {
    return Row(
      spacing: 10,
      children: [
        SvgPicture.asset('assets/images/network_device.svg'),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
        ),
        signal != null
            ? signal >= 1 && signal <= 4
                ? _checkIcon
                : _closeIcon
            : _loadingIcon,
      ],
    );
  }

  Widget _buildVerificationInputPower(String text, int? verified) {
    return Row(
      spacing: 10,
      children: [
        SvgPicture.asset('assets/images/bulb_power.svg'),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
        ),
        verified != null
            ? verified == 1
                ? _checkIcon
                : _closeIcon
            : _loadingIcon,
      ],
    );
  }

  Widget _buildVoltageVerification() {
    final hasData = _freshLiveDataReceived &&
        widget.motorData != null &&
        widget.motorData!.hasReceivedLiveData;
    final networkDone = _freshSignalReceived || _preCheckTimedOut;

    // Sequential gates — voltage is only evaluated after network AND power pass.
    final bool showLoading;
    final bool forceFail;

    if (!networkDone) {
      // Gate 1: still waiting for network result → loading.
      showLoading = true;
      forceFail = false;
    } else if (!_networkVerified) {
      // Gate 2: network failed → voltage is blocked.
      showLoading = false;
      forceFail = true;
    } else if (!hasData && !_preCheckTimedOut) {
      // Gate 3: network OK, waiting for live data (power step) → loading.
      showLoading = true;
      forceFail = false;
    } else if (!_powerVerified) {
      // Gate 4: power failed or timed out → voltage is blocked.
      showLoading = false;
      forceFail = true;
    } else {
      // All previous checks passed → evaluate actual voltage.
      showLoading = false;
      forceFail = false;
    }

    final voltageOk =
        !showLoading && !forceFail && hasData && _isVoltageInRange;
    final error =
        (!showLoading && !forceFail && hasData) ? _voltageError : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            const Icon(Icons.electric_bolt, size: 20, color: Color(0xFF64748B)),
            const Expanded(
              child: Text(
                'Voltage Range (370V - 450V)',
                style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
              ),
            ),
            if (showLoading)
              _loadingIcon
            else if (voltageOk)
              _checkIcon
            else
              _closeIcon,
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
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
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              activeColor: const Color(0xFF0F6B8A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────── build ───────────────────────────────

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
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
                    onTap: widget.onClose,
                    child: const Icon(
                      Icons.close,
                      size: 28,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pre - Test Verifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Network Connectivity — rebuilds whenever signal is
                  // confirmed via T:40 heartbeat OR T:41/T:35 live data.
                  ValueListenableBuilder<bool>(
                    valueListenable: _freshSignalNotifier,
                    builder: (context, freshSignal, __) {
                      final int? signal = freshSignal
                          ? _getSignalBars(widget.motorData)
                          : (_preCheckTimedOut ? 0 : null);
                      return _buildVerificationCloudConnection(
                        'Network Connectivity',
                        signal,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Power Supply Status — sequential step 2.
                  // Stays loading until network (step 1) is confirmed first.
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.mqttService.liveDataNotifier,
                      _freshSignalNotifier,
                    ]),
                    builder: (context, _) {
                      final int? powerVerified;
                      final bool liveReady = _freshLiveDataReceived &&
                          (widget.motorData?.hasReceivedLiveData ?? false);
                      if (!_freshSignalReceived && !_preCheckTimedOut) {
                        powerVerified = null;
                      } else if (_isNetworkFalse || !_networkVerified) {
                        powerVerified = 0;
                      } else if (liveReady) {
                        powerVerified = _isPowerOn ? 1 : 0;
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

                  // Voltage Range — sequential step 3.
                  // Stays loading until both network (step 1) and power
                  // (step 2) are confirmed first.
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.mqttService.liveDataNotifier,
                      _freshSignalNotifier,
                    ]),
                    builder: (context, _) => _buildVoltageVerification(),
                  ),
                  const SizedBox(height: 24),

                  _buildCheckboxItem(
                    'Motor wires / terminals securely connected',
                    isMotorWiresChecked,
                    (value) =>
                        setState(() => isMotorWiresChecked = value ?? false),
                  ),
                  const SizedBox(height: 16),
                  _buildCheckboxItem(
                    'Pump / delivery valve fully open',
                    isPumpValveChecked,
                    (value) =>
                        setState(() => isPumpValveChecked = value ?? false),
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
