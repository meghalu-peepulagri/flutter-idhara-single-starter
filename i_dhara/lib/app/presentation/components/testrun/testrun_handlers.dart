part of '../testrun_verification_card.dart';

/// MQTT and notifier handlers for [_ConfirmTestRunScreenState].
extension _TestRunHandlers on _ConfirmTestRunScreenState {
  // ── Pre-check timeout ──────────────────────────────────────────────────────

  void _startPreCheckTimeout() {
    _preCheckTimeoutTimer?.cancel();
    _preCheckTimeoutTimer =
        Timer(const Duration(seconds: 15), _onPreCheckTimeout);
  }

  void _onPreCheckTimeout() {
    if (!mounted || _phase != _TestRunPhase.preCheck) return;

    // ignore: invalid_use_of_protected_member
    setState(() => _preCheckTimedOut = true);

    if (_connectionSnackBarShown) return;

    if (widget.motorData?.testRunSignal != true) {
      _connectionSnackBarShown = true;
      geterrorSnackBar('Device is not connected.');
      return;
    }

    if (widget.motorData?.testrunPowerSupply != true ||
        widget.motorData?.testrunVoltageRange != true ||
        !_isVoltageInRange) {
      _connectionSnackBarShown = true;
      geterrorSnackBar(
          'Device is not connected due to no power or voltage mismatch.');
    }
  }

  // ── First-data listeners ───────────────────────────────────────────────────

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
        // ignore: invalid_use_of_protected_member
        setState(() => _freshSignalReceived = true);
        _freshSignalNotifier.value = true;

        // Always listen for live data regardless of signal bars.
        // Errors are only reported after the 15-second timeout.
        widget.mqttService.liveDataNotifier
            .removeListener(_onFirstLiveData); // guard double-add
        widget.mqttService.liveDataNotifier.addListener(_onFirstLiveData);
      });
    }
  }

  /// Called on the first T:35/T:41 live-data update — unlocks power & voltage
  /// icons only. Network Connectivity (signal) is ONLY unlocked by T:40
  /// heartbeat via [_onFirstHeartbeat]. Live data and heartbeat are separate
  /// payloads and must be verified independently.
  void _onFirstLiveData() {
    if (!_freshLiveDataReceived && mounted) {
      widget.mqttService.liveDataNotifier.removeListener(_onFirstLiveData);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Step 1 — T:35/T:41 implies network connectivity.
        // Unlock signal icon first so the UI confirms network before checking
        // the remaining conditions.
        if (!_freshSignalReceived) {
          // ignore: invalid_use_of_protected_member
          setState(() => _freshSignalReceived = true);
          _freshSignalNotifier.value = true;
        }
        // Step 2 — After the signal rebuild, unlock live data and evaluate
        // power status and voltage range in the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // ignore: invalid_use_of_protected_member
          setState(() => _freshLiveDataReceived = true);
          _checkPowerVoltageNow();
        });
      });
    }
  }

  /// Immediately checks all verification states once live data arrives.
  /// If all three icons show close (network/power/voltage all failed),
  /// fires the error snackbar right away without waiting for the 15-second timeout.
  void _checkPowerVoltageNow() {
    // No early snackbar — errors are only shown after the 15-second timeout
    // in _onPreCheckTimeout. This method only triggers a rebuild so the UI
    // icons update immediately when live data arrives.
    // ignore: invalid_use_of_protected_member
    if (mounted) setState(() {});
  }

  // ── Command status (T:1 retries exhausted) ────────────────────────────────

  /// Fires when [commandStatusNotifier] changes (T:1 retries exhausted).
  ///
  /// • During [measuring]: D:2 never ACK'd → stop timer, snackbar, go to dashboard.
  /// • During [saving]: D:0 never ACK'd → snackbar, navigate away.
  void _onCommandStatus() {
    final message = widget.mqttService.commandStatusNotifier.value;
    if (message == null || !mounted) return;
    widget.mqttService.commandStatusNotifier.value = null;

    if (_phase == _TestRunPhase.motorOnWaiting) {
      // D:2 retries exhausted — motor never confirmed ON.
      _motorOnCountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) {
        widget.mqttService.removeTestRunMotor(_mqttMotorId);
      }
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        setState(() {
          _motorOnFailed = true;
          _motorOnFailureMsg = message;
        });
      }
    } else if (_phase == _TestRunPhase.measuring) {
      // D:2 retries exhausted — motor never confirmed ON, stop the run.
      _timer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) widget.mqttService.removeTestRunMotor(_mqttMotorId);
      geterrorSnackBar(message);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (widget.route == Routes.dashboard) {
          Get.offAllNamed(Routes.dashboard, arguments: {'refresh': true});
        } else {
          Navigator.of(context).pop();
        }
      });
    } else if (_phase == _TestRunPhase.saving) {
      _d0CountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) widget.mqttService.removeTestRunMotor(_mqttMotorId);
      if (!_savingIsSendingSettings) {
        // D:0 retries exhausted — motor didn't confirm OFF.
        _handleMotorOffFailure(message);
      } else {
        // Calibration retries exhausted.
        geterrorSnackBar(message);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            if (widget.route == Routes.dashboard) {
              Get.offAllNamed(widget.route, arguments: {'refresh': true});
            } else {
              Navigator.of(context).pop();
            }
          }
        });
      }
    }
  }

  // ── ACK checks ─────────────────────────────────────────────────────────────

  /// Listens to [dataUpdateNotifier] during [saving] (D:0 wait sub-state).
  /// When T:31 ACK for D:0 arrives, transitions to [completed] so the user
  /// can review the FLC and tap "Save Settings".
  void _checkMotorOffAck() {
    if (!mounted) return;
    if (_phase != _TestRunPhase.saving) return;
    if (_savingIsSendingSettings) return; // Already in calibration sub-state
    if (!_hasPendingSave) return;
    final ackTime = _resolveAckTime();
    if (ackTime != null &&
        _motorCmdSentAt != null &&
        ackTime.isAfter(_motorCmdSentAt!)) {
      _d0CountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      if (_mqttMotorId.isNotEmpty) {
        widget.mqttService.removeTestRunMotor(_mqttMotorId);
      }
      _hasPendingSave = false;
      // Motor confirmed OFF — show FLC result and "Save Settings" button.
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() => _phase = _TestRunPhase.completed);
    }
  }

  /// Listens on [dataUpdateNotifier] during [motorOnWaiting].
  /// When T:31 ACK for D:2 arrives, cancels the countdown and starts measuring.
  void _checkMotorOnAck() {
    if (!mounted || _phase != _TestRunPhase.motorOnWaiting) return;
    final ackTime = _resolveAckTime();
    if (ackTime != null &&
        _motorOnCmdSentAt != null &&
        ackTime.isAfter(_motorOnCmdSentAt!)) {
      _motorOnCountdownTimer?.cancel();
      widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      _startActualMeasuring();
    }
  }

  void _handleMotorOnFailure(String message) {
    _motorOnCountdownTimer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    if (_mqttMotorId.isNotEmpty) {
      widget.mqttService.removeTestRunMotor(_mqttMotorId);
    }
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {
        _motorOnFailed = true;
        _motorOnFailureMsg = message;
      });
    }
  }

  void _handleMotorOffFailure(String message) {
    _d0CountdownTimer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    if (_mqttMotorId.isNotEmpty) widget.mqttService.removeTestRunMotor(_mqttMotorId);
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {
        _hasPendingSave = false;
        _motorOffFailed = true;
        _motorOffFailureMsg = message;
      });
    }
  }
}
