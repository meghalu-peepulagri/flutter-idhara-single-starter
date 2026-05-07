part of '../testrun_verification_card.dart';

/// Lifecycle, connectivity, ack-time resolution, and pure helpers for
/// [_ConfirmTestRunScreenState]. Behaviour is unchanged from the original
/// monolithic file.
extension _TestRunLifecycle on _ConfirmTestRunScreenState {
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void initStateImpl() {
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
    // Delay listener registration so loading icons are always shown for at
    // least 1 second each time the dialog opens, even when MQTT is already
    // streaming. Each icon type listens to its own topic-specific notifier.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.mqttService.heartbeatNotifier
            .removeListener(_onFirstHeartbeat); // guard double-add
        widget.mqttService.heartbeatNotifier.addListener(_onFirstHeartbeat);
        // Also listen directly to liveDataNotifier — if T:41 arrives before
        // T:40 heartbeat, receiving live data implies network connectivity and
        // unlocks the signal icon before checking power & voltage.
        widget.mqttService.liveDataNotifier
            .removeListener(_onFirstLiveData); // guard double-add
        widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
      }
    });
    _startPreCheckTimeout();
  }

  void didChangeAppLifecycleStateImpl(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _phase == _TestRunPhase.measuring &&
        _testStartTime != null) {
      final elapsed = DateTime.now().difference(_testStartTime!).inSeconds;
      if (elapsed >= _kTotalSeconds) {
        _timer?.cancel();
        _completeTestRun();
      } else {
        // ignore: invalid_use_of_protected_member
        setState(() => _remainingSeconds = _kTotalSeconds - elapsed);
      }
    }
  }

  void disposeImpl() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
    widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    if (_mqttMotorId.isNotEmpty &&
        (_phase == _TestRunPhase.motorOnWaiting ||
            _phase == _TestRunPhase.measuring ||
            _phase == _TestRunPhase.saving)) {
      widget.mqttService.removeTestRunMotor(_mqttMotorId);
    }
    _timer?.cancel();
    _preCheckTimeoutTimer?.cancel();
    _motorOnCountdownTimer?.cancel();
    _d0CountdownTimer?.cancel();
    _settingsCountdownTimer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    _avgCurrent.dispose();
    _overalCurrent.dispose();
    _freshSignalNotifier.dispose();
    _settingsCountdown.dispose();
  }

  // ── Connectivity ───────────────────────────────────────────────────────────

  void _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted && result.first == ConnectivityResult.none) {
      _goOffline();
      return;
    }
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      if (results.first == ConnectivityResult.none) {
        _goOffline();
      } else if (_isOffline) {
        _goOnline();
      }
    });
  }

  void _goOffline() {
    if (_isOffline) return;
    _timer?.cancel();
    _motorOnCountdownTimer?.cancel();
    _d0CountdownTimer?.cancel();
    _settingsCountdownTimer?.cancel();
    settingsAckTimer?.cancel();
    mqttStreamSubscription?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    if (_phase == _TestRunPhase.measuring ||
        _phase == _TestRunPhase.motorOnWaiting) {
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    }
    if (mounted) {
      // Close any open sub-dialogs (emergency stop, cancel confirmation, etc.)
      if (_isSubDialogOpen) {
        Navigator.of(context).pop();
        _isSubDialogOpen = false;
      }
      // ignore: invalid_use_of_protected_member
      setState(() {
        _isOffline = true;
      });
    }
  }

  void _goOnline() {
    if (!_isOffline || !mounted) return;
    // Reset both fresh flags and re-register type-specific listeners after
    // a 1-second delay so loading icons are shown when coming back online.
    _freshSignalReceived = false;
    _freshSignalNotifier.value = false;
    _freshLiveDataReceived = false;
    _preCheckTimedOut = false;
    _connectionSnackBarShown = false;
    _startPreCheckTimeout();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.mqttService.heartbeatNotifier.removeListener(_onFirstHeartbeat);
        widget.mqttService.heartbeatNotifier.addListener(_onFirstHeartbeat);
        // Also listen directly to liveDataNotifier — if T:41 arrives before
        // T:40, receiving live data implies network connectivity.
        widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
        widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
      }
    });
    // ignore: invalid_use_of_protected_member
    setState(() {
      _isOffline = false;
      // Reset to preCheck so user can re-verify and start fresh
      _phase = _TestRunPhase.preCheck;
      isMotorWiresChecked = false;
      isPumpValveChecked = false;
      _flcData.clear();
      _remainingSeconds = _kTotalSeconds;
      _avgCurrent.value = 0;
      _overalCurrent.value = 0;
      _motorOffFailed = false;
      _motorOffFailureMsg = '';
    });
  }

  void _resetPreCheckState() {
    // ignore: invalid_use_of_protected_member
    setState(() {
      _avgCurrent.value = 0;
      _overalCurrent.value = 0;
      _flcData.clear();
      isMotorWiresChecked = false;
      isPumpValveChecked = false;
      widget.cloudConnectionVerified.value = false;
      widget.inputPowerVerified.value = false;
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // ignore: unused_element
  int getSignalBars(MotorData? motorData) {
    if (motorData != null &&
        motorData.hasReceivedData &&
        !motorData.isSignalStale() &&
        motorData.groupId != null) {
      return motorData.signalBars;
    }
    final signalStrength = widget.motor.starter?.signalQuality;
    if (signalStrength != null && signalStrength >= 2 && signalStrength <= 31) {
      if (signalStrength >= 2 && signalStrength <= 9) return 1;
      if (signalStrength >= 10 && signalStrength <= 14) return 2;
      if (signalStrength >= 15 && signalStrength <= 19) return 3;
      if (signalStrength >= 20 && signalStrength <= 30) return 4;
    }
    return 0;
  }

  double _percentageOfAmps(double c1, double c2, double c3) {
    return (c1 + c2 + c3) / 3;
  }

  String _getMotorGroupId(String identifier) {
    const allowedGroups = ['G01', 'G02'];
    for (final groupId in allowedGroups) {
      final motorData = widget.mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) return groupId;
    }
    return 'G01';
  }

  double _calculatedFlc(double val, double flcVal) {
    final percentLow = val.toInt() / 100;
    final res = percentLow * flcVal;
    return double.parse(res.toStringAsFixed(2));
  }

  /// Resolves the latest ACK time for this motor across both PCB and MAC
  /// keyed entries. Commands may be sent under either identifier, but the
  /// device's T:31 ACK can land on a topic keyed by the other one — so a
  /// direct lookup by [_mqttMotorId] alone misses it. PCB is preferred per
  /// device convention; MAC is the fallback. When a candidate matches, the
  /// resolved key is written back to [_mqttMotorId] so future lookups and
  /// cleanup (removeTestRunMotor) use the right entry.
  DateTime? _resolveAckTime() {
    DateTime? ackTime = _mqttMotorId.isNotEmpty
        ? widget.mqttService.getLastAckTime(_mqttMotorId)
        : null;
    if (ackTime != null) return ackTime;

    final pcb = widget.motor.starter?.pcbNumber;
    final mac = widget.motor.starter?.macAddress;
    const groupIds = ['G01', 'G02'];

    // PCB-keyed candidates take priority.
    if (pcb != null && pcb.isNotEmpty) {
      for (final g in groupIds) {
        final key = '$pcb-$g';
        final t = widget.mqttService.getLastAckTime(key);
        if (t != null) {
          _mqttMotorId = key;
          return t;
        }
      }
    }
    // MAC-keyed candidates fall back next.
    if (mac != null && mac.isNotEmpty) {
      for (final g in groupIds) {
        final key = '$mac-$g';
        final t = widget.mqttService.getLastAckTime(key);
        if (t != null) {
          _mqttMotorId = key;
          return t;
        }
      }
    }

    // Last resort: scan motorDataMap by data fields in case the device
    // publishes on a key that doesn't combine identifier+group as expected.
    DateTime? best;
    String? bestKey;
    for (final entry in widget.mqttService.motorDataMap.entries) {
      final data = entry.value;
      final matchesPcb = pcb != null &&
          pcb.isNotEmpty &&
          (data.pcbNumber == pcb || data.macAddress == pcb);
      final matchesMac = mac != null &&
          mac.isNotEmpty &&
          (data.macAddress == mac || data.pcbNumber == mac);
      if (matchesPcb || matchesMac) {
        final t = widget.mqttService.getLastAckTime(entry.key);
        if (t != null && (best == null || t.isAfter(best))) {
          best = t;
          bestKey = entry.key;
        }
      }
    }
    if (bestKey != null) _mqttMotorId = bestKey;
    return best;
  }
}
