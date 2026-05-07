part of '../testrun_verification_card.dart';

/// User-triggered and timer-driven actions for [_ConfirmTestRunScreenState].
extension _TestRunActions on _ConfirmTestRunScreenState {
  /// Guards [_startMeasuring]: blocks and warns when the motor is in Auto mode.
  void _onStartPressed() {
    if (_isAutoMode) {
      geterrorSnackBar('Motor is in Auto Mode. Switch to Manual Mode');
      return;
    }
    _startMeasuring();
  }

  // ── Phase transitions ──────────────────────────────────────────────────────

  void _completeTestRun() {
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    final sum = _flcData.isNotEmpty ? _flcData.reduce((a, b) => a + b) : 0.0;
    final average = _flcData.isNotEmpty ? sum / _flcData.length : 0.0;
    _overalCurrent.value = average;

    // Immediately send motor OFF (D:0) in the background so it is confirmed
    // by the time the user taps "Save Settings".
    _motorCmdSentAt = DateTime.now();
    _hasPendingSave = true;
    _savingIsSendingSettings = false;
    _d0Countdown = _kWaitingTimerSeconds;

    if (_mqttMotorId.isNotEmpty) {
      // Listen for D:0 ACK.
      widget.mqttService.dataUpdateNotifier.addListener(_checkMotorOffAck);
      // Listen for retry exhaustion.
      widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
      widget.mqttService.commandStatusNotifier.addListener(_onCommandStatus);
      // Start 15s countdown shown in the "Stopping Motor..." dialog.
      _d0CountdownTimer?.cancel();
      _d0CountdownTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (_d0Countdown > 0) {
          // ignore: invalid_use_of_protected_member
          setState(() => _d0Countdown--);
        } else {
          timer.cancel();
          _handleMotorOffFailure('No response from device');
        }
      });
      widget.mqttService
          .publishTestRunCommand(_mqttMotorId, 1, data: 0, type: 1);
    } else {
      // No motor ID — skip D:0, go straight to completed.
      _hasPendingSave = false;
      // ignore: invalid_use_of_protected_member
      if (mounted) setState(() { _remainingSeconds = 0; _phase = _TestRunPhase.completed; });
      return;
    }

    // Show "Stopping Motor..." loading dialog immediately.
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {
        _remainingSeconds = 0;
        _phase = _TestRunPhase.saving;
      });
    }
  }

  void _startMeasuring() {
    _preCheckTimeoutTimer?.cancel();
    _avgCurrent.value = 0;
    _overalCurrent.value = 0;
    _flcData.clear();
    _controller = Get.put(DashboardController());
    widget.mqttService.dataUpdateNotifier.addListener(_checkUpdates);

    final identifier = getMotorIdentifier(
        widget.motor.starter!.deviceAllocation.toString(),
        widget.motor.starter!.pcbNumber.toString(),
        widget.motor.starter!.macAddress.toString());
    final groupId = identifier.isNotEmpty ? _getMotorGroupId(identifier) : '';
    _mqttMotorId = identifier.isNotEmpty ? '$identifier-$groupId' : '';
    final mqttMotorId = _mqttMotorId;

    _motorOnCmdSentAt = DateTime.now();
    _motorOnFailed = false;
    _motorOnFailureMsg = '';
    _motorOnCountdown = _kWaitingTimerSeconds;

    // ignore: invalid_use_of_protected_member
    setState(() => _phase = _TestRunPhase.motorOnWaiting);

    // Register BEFORE publishing so T:31 ACK never updates motor state.
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService.addTestRunMotor(mqttMotorId);
    }

    // Listen for retry-exhaustion → shows error in the waiting dialog.
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    widget.mqttService.commandStatusNotifier.addListener(_onCommandStatus);

    // Listen for T:31 ACK → transition to measuring.
    widget.mqttService.dataUpdateNotifier.addListener(_checkMotorOnAck);

    // Publish D:2 (motor ON) with retry.
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService
          .publishTestRunCommand(mqttMotorId, 1, data: 2, type: 1);
    }

    // 15-second countdown shown in the waiting dialog. When it hits 0 without
    // a T:31 ACK, surface the failure so the spinner stops and the user
    // sees the error state instead of an indefinite loading icon.
    _motorOnCountdownTimer?.cancel();
    _motorOnCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_motorOnCountdown > 0) {
        // ignore: invalid_use_of_protected_member
        setState(() => _motorOnCountdown--);
      } else {
        timer.cancel();
        _handleMotorOnFailure('No response from device');
      }
    });
  }

  /// Starts the measuring timer after motor ON ACK is confirmed.
  void _startActualMeasuring() {
    _avgCurrent.value = 0.0;
    _flcData.clear();
    _overalCurrent.value = 0.0;
    _testStartTime = DateTime.now();
    final mqttMotorId = _mqttMotorId;

    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {
        _phase = _TestRunPhase.measuring;
        _remainingSeconds = _kTotalSeconds;
      });
    }

    // Wall-clock elapsed keeps countdown accurate even when OS throttles timers.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_testStartTime!).inSeconds;
      final remaining = (_kTotalSeconds - elapsed).clamp(0, _kTotalSeconds);

      if (mqttMotorId.isNotEmpty && elapsed > 0 && elapsed % 10 == 0) {
        widget.mqttService
            .publishTestRunCommand(mqttMotorId, 1, data: 1, type: 5);
      }

      if (remaining > 0) {
        // ignore: invalid_use_of_protected_member
        if (mounted) setState(() => _remainingSeconds = remaining);
      } else {
        timer.cancel();
        _completeTestRun();
      }
    });
  }

  void _checkUpdates() {
    if (!mounted) return;

    // Try direct lookup by _mqttMotorId first (fast path).
    // Fall back to MAC/PCB search because the device may publish T:41 live data
    // on a topic whose identifier (MAC or PCB) differs from the one used in
    // commands — e.g. commands use PCB but status topics use MAC. In that case
    // _handleLiveData creates an alias under a different key, so the direct
    // lookup returns null or stale data. Searching by MAC/PCB always finds the
    // correct entry regardless of which identifier the device uses on the wire.
    MotorData? motordata;
    if (_mqttMotorId.isNotEmpty) {
      final direct = widget.mqttService.motorDataMap[_mqttMotorId];
      if (direct != null && direct.hasReceivedLiveData) {
        motordata = direct;
      }
    }

    if (motordata == null) {
      final mac = widget.motor.starter?.macAddress;
      final pcb = widget.motor.starter?.pcbNumber;
      DateTime? bestTime;
      for (final entry in widget.mqttService.motorDataMap.entries) {
        final data = entry.value;
        if (!data.hasReceivedLiveData) continue;
        final matchesMac = mac != null &&
            mac.isNotEmpty &&
            (data.macAddress == mac || data.pcbNumber == mac);
        final matchesPcb = pcb != null &&
            pcb.isNotEmpty &&
            (data.macAddress == pcb || data.pcbNumber == pcb);
        if (matchesMac || matchesPcb) {
          final ackTime = widget.mqttService.getLastAckTime(entry.key);
          if (motordata == null ||
              (ackTime != null &&
                  (bestTime == null || ackTime.isAfter(bestTime)))) {
            motordata = data;
            bestTime = ackTime;
            // Fix _mqttMotorId so _completeTestRun's publishMotorOFF and
            // future direct lookups use the correct key.
            _mqttMotorId = entry.key;
          }
        }
      }
    }

    motordata ??= widget.motorData;

    final c1 = double.tryParse(motordata?.currentRed ?? '0.0') ?? 0.0;
    final c2 = double.tryParse(motordata?.currentBlue ?? '0.0') ?? 0.0;
    final c3 = double.tryParse(motordata?.currentYellow ?? '0.0') ?? 0.0;

    // Only accept if all phases have at least 0.5A
    if (c1 >= 0.5 && c2 >= 0.5 && c3 >= 0.5) {
      final res = _percentageOfAmps(c1, c2, c3);
      final avg = double.parse(res.toStringAsFixed(2));

      // Update ValueNotifier directly — ValueListenableBuilder in
      // _buildMeasuringPhase handles its own rebuild without setState.
      _avgCurrent.value = avg;

      if (!_flcData.contains(avg)) {
        _flcData.add(avg);
        final sum = _flcData.reduce((a, b) => a + b);
        _overalCurrent.value = sum / _flcData.length;
      }
    }
  }

  // ── Emergency stop / Cancel ────────────────────────────────────────────────

  void _emergencyStop() {
    _isSubDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomConfirmationDialog(
        title: "Emergency Stop",
        message:
            "Emergency stop will immediately abort the ongoing test process.\n\nAre you sure you want to continue?",
        confirmText: "Stop Test",
        confirmColor: const Color(0xFFDC2626),
        icon: Icons.warning_amber_rounded,
        onConfirm: _confirmEmergencyStop,
      ),
    ).then((_) => _isSubDialogOpen = false);
  }

  void _confirmEmergencyStop() {
    _timer?.cancel();
    _motorOnCountdownTimer?.cancel();
    _d0CountdownTimer?.cancel();
    _settingsCountdownTimer?.cancel();
    widget.mqttService.dataUpdateNotifier.removeListener(_checkUpdates);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOffAck);
    widget.mqttService.dataUpdateNotifier.removeListener(_checkMotorOnAck);
    widget.mqttService.commandStatusNotifier.removeListener(_onCommandStatus);
    if (_mqttMotorId.isNotEmpty) {
      widget.mqttService.removeTestRunMotor(_mqttMotorId);
    }

    final identifier = getMotorIdentifier(
        widget.motor.starter!.deviceAllocation.toString(),
        widget.motor.starter!.pcbNumber.toString(),
        widget.motor.starter!.macAddress.toString());
    final groupId = identifier.isNotEmpty ? _getMotorGroupId(identifier) : '';
    final mqttMotorId = identifier.isNotEmpty ? '$identifier-$groupId' : '';

    // Send stop command T=1, D=0
    if (mqttMotorId.isNotEmpty) {
      widget.mqttService
          .publishTestRunCommand(mqttMotorId, 1, data: 0, type: 1)
          .then((_) {
        if (widget.route == Routes.dashboard) {
          Get.offAllNamed(widget.route, arguments: {'refresh': true});
        } else {
          Navigator.of(context).pop();
        }
        debugPrint('Emergency stop command sent for $mqttMotorId');
      }).catchError((e) {
        if (widget.route == Routes.dashboard) {
          Get.offAllNamed(widget.route, arguments: {'refresh': true});
        } else {
          Navigator.of(context).pop();
        }
        debugPrint('Failed to send emergency stop command: $e');
      });
    }
  }

  // ── Save / Cancel ──────────────────────────────────────────────────────────

  /// Called when user taps "Save Settings".
  /// Motor OFF (D:0) is already confirmed by this point — transition to saving
  /// phase and send the calibration payload (T:4).
  Future<void> _onSave() async {
    _hasPendingSave = true;
    // ignore: invalid_use_of_protected_member
    setState(() {
      _phase = _TestRunPhase.saving;
      isWaitingForAck = true;
      _savingIsSendingSettings = true;
    });
    _sendSettings();
  }

  /// Sends the calibration settings payload (T:4) and awaits T:34 ACK.
  /// Called after D:0 T:31 ACK is confirmed by [_checkMotorOffAck].
  Future<void> _sendSettings() async {
    try {
      final identifier = getMotorIdentifier(
          widget.motor.starter!.deviceAllocation.toString(),
          widget.motor.starter!.pcbNumber.toString(),
          widget.motor.starter!.macAddress.toString());
      if (identifier.isNotEmpty && _controller != null) {
        await _controller!.fetchUserSettings2();
        final avgFlc = _overalCurrent.value;
        final OLR1 = _calculatedFlc(_controller!.olr.value, avgFlc);
        final LRF2 = _calculatedFlc(_controller!.lrf.value, avgFlc);
        final LRR3 = _calculatedFlc(_controller!.lrr.value, avgFlc);
        final DRF4 = _calculatedFlc(_controller!.drf.value.toDouble(), avgFlc);
        final OLF5 = _calculatedFlc(_controller!.olf.value.toDouble(), avgFlc);
        final trimFlc = avgFlc.toStringAsFixed(2);
        final flc = double.parse(trimFlc);
        final payload = {
          "dvc_c": {
            "olr": OLR1,
            "lrr": LRR3,
            "lrf": LRF2,
            "drf": DRF4,
            "olf": OLF5,
            'flc': flc
          },
        };
        _controller!.flc.value = flc;

        // Start 15-second countdown for T:34 ACK displayed in saving dialog.
        _settingsCountdownTimer?.cancel();
        _settingsCountdown.value = 15;
        _settingsCountdownTimer =
            Timer.periodic(const Duration(seconds: 1), (t) {
          if (_settingsCountdown.value > 0) {
            _settingsCountdown.value--;
          } else {
            t.cancel();
          }
        });

        // Set up timer and listener BEFORE publishing so the real device's
        // immediate T=34 ACK is not missed. settingstream is a broadcast
        // StreamController — events emitted before listen() is called are lost.
        settingsAckTimer = Timer(const Duration(seconds: 15), () {
          _settingsCountdownTimer?.cancel();
          mqttStreamSubscription?.cancel();
          if (mounted && !_ackInProgress) {
            _resetPreCheckState();
            // ignore: invalid_use_of_protected_member
            setState(() {
              isWaitingForAck = false;
              _hasPendingSave = false;
              _phase = _TestRunPhase.failure;
              failureMessage = 'No acknowledgment received from device';
            });
            if (widget.motor.testrunStatus?.toUpperCase() == "IN_TEST") {
              _controller?.startTestRun(widget.motor.id!);
            } else {
              _controller?.completeTestRun(widget.motor.id!);
            }
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) {
                if (widget.route == Routes.dashboard) {
                  Get.offAllNamed(widget.route, arguments: {'refresh': true});
                } else {
                  Get.offAllNamed(Routes.devices);
                }
              }
            });
          }
        });

        // Listen for ACK on settingstream
        mqttStreamSubscription =
            widget.mqttService.settingstream.listen((data) async {
          final type = data["D"];
          final topic = data["topic"];
          if (topic != _controller!.pcbNumber.value &&
              topic != _controller!.macAddress.value) return;
          if (type == 1 && !_ackInProgress && _hasPendingSave) {
            settingsAckTimer?.cancel();
            _settingsCountdownTimer?.cancel();
            _hasPendingSave = false;
            _ackInProgress = true;
            mqttStreamSubscription?.cancel();
            _finalFLC = _overalCurrent.value;
            _resetPreCheckState();
            if (mounted) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                isWaitingForAck = false;
                _phase = _TestRunPhase.success;
              });
            }
            try {
              _controller?.completeTestRun(widget.motor.id!);
              _controller?.fetchupdateSettingsAck();
            } finally {
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted) {
                  if (widget.route == Routes.dashboard) {
                    Get.offAllNamed(widget.route, arguments: {'refresh': true});
                  } else {
                    Get.offAllNamed(Routes.devices);
                  }
                }
              });
            }
          } else {
            mqttStreamSubscription?.cancel();
            _settingsCountdownTimer?.cancel();
            if (mounted && !_ackInProgress) {
              _resetPreCheckState();
              // ignore: invalid_use_of_protected_member
              setState(() {
                isWaitingForAck = false;
                _hasPendingSave = false;
                _phase = _TestRunPhase.failure;
                failureMessage = 'Smart Calibration Failed';
              });
              if (widget.motor.testrunStatus?.toUpperCase() == "IN_TEST") {
                _controller?.startTestRun(widget.motor.id!);
              } else {
                _controller?.completeTestRun(widget.motor.id!);
              }
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted) {
                  if (widget.route == Routes.dashboard) {
                    Get.offAllNamed(widget.route, arguments: {'refresh': true});
                  } else {
                    Get.offAllNamed(Routes.devices);
                  }
                }
              });
            }
          }
        });

        // Publish AFTER listener is ready so the device's immediate ACK is caught.
        await widget.mqttService
            .publishUpdateSettings(_controller!.pcbNumber.value, payload);
        _controller?.fetchupdateSettings();
      }
    } catch (e) {
      debugPrint("Error publishing settings command: $e");
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        setState(() {
          isWaitingForAck = false;
          _hasPendingSave = false;
          failureMessage = 'Failed to send settings command';
          _phase = _TestRunPhase.failure;
        });
      }
    }
  }

  void _onCancel() {
    _isSubDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomConfirmationDialog(
        title: "Cancel Settings ?",
        message:
            "Are you sure you want to cancel? The calibration data will not be saved.",
        confirmText: "Yes",
        cancelText: 'No',
        confirmColor: const Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
        onConfirm: () {
          _flcData.clear();
          _overalCurrent.value = 0.0;
          _avgCurrent.value = 0.0;
          if (_mqttMotorId.isNotEmpty) {
            widget.mqttService.removeTestRunMotor(_mqttMotorId);
          }
          if (widget.route == Routes.dashboard) {
            Get.offAllNamed(widget.route, arguments: {'refresh': true});
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    ).then((_) => _isSubDialogOpen = false);
  }
}
