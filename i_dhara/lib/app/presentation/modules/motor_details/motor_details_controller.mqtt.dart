part of 'motor_details_controller.dart';

extension AnalyticsControllerMqtt on AnalyticsController {
  Future<void> _initializeMqtt() async {
    if (motorDetails.value?.starter == null) {
      return;
    }

    final starter = motorDetails.value!.starter!;
    final mac = starter.macAddress;
    final pcb = starter.pcbNumber;

    if (kDebugMode) {}

    if ((mac == null || mac.isEmpty) && (pcb == null || pcb.isEmpty)) {
      return;
    }

    // Get the singleton instance
    // No need to create motorMap or update motors since we're using wildcard subscriptions
    mqttService = MqttService();

    // Check if already connected, if not initialize
    if (!mqttService.isConnected) {
      // Build minimal motor map for this motor
      final motor = _convertMotorDetailsToMotor(motorDetails.value!);
      final motorMap = <String, Motor>{};

      // Build motor map for all 4 groups
      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        if (mac != null && mac.isNotEmpty) {
          final key = '$mac-$groupId';
          motorMap[key] = motor;
        }
        if (pcb != null && pcb.isNotEmpty) {
          final key = '$pcb-$groupId';
          motorMap[key] = motor;
        }
      }

      mqttService = MqttService(initialMotors: motorMap);
      await mqttService.initializeMqttClient();
    }

    mqttInitialized = true;

    mqttService.dataUpdateNotifier.addListener(_onMqttDataUpdate);

    _modeAckErrorSubscription?.cancel();
    _modeAckErrorSubscription = mqttService.modeAckErrorStream.listen((event) {
      if (!_hasPendingModeCommand) return;
      final code = event['code'];
      if (code is int) handleModeAckError(code);
    });

    // Check if we have data
    if (kDebugMode) {
      final motorData = getMotorData();
      if (motorData != null && motorData.hasReceivedData) {
      } else {
        // Print all keys in the map
        if (mqttService.motorDataMap.isNotEmpty) {
          for (var key in mqttService.motorDataMap.keys) {
            final data = mqttService.motorDataMap[key];
          }
        }
      }
    }

    // Initial update
    _updateFromMqttData();
    _updateCanChangeMode();

    if (kDebugMode) {}
  }

  Motor _convertMotorDetailsToMotor(MotorDetails details) {
    return Motor(
      id: details.id,
      name: details.name,
      aliasName: details.aliasName,
      hp: details.hp,
      state: details.state,
      mode: details.mode,
    );
  }

  void _onMqttDataUpdate() {
    _updateFromMqttData();
  }

  void _updateFromMqttData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) {
      return;
    }

    final motorData = getMotorData();
    final mac = motorDetails.value?.starter?.macAddress;
    final pcb = motorDetails.value?.starter?.pcbNumber;

    // True iff [entry] belongs to this motor — matches if either the
    // entry's macAddress or pcbNumber equals one of the motor's
    // identifiers. Used by both the ACK scan below and the propagate
    // step so they agree on what "this motor's rows" means.
    bool entryBelongsToThisMotor(MotorData entry) {
      final macMatch = mac != null &&
          mac.isNotEmpty &&
          (entry.macAddress == mac || entry.pcbNumber == mac);
      final pcbMatch = pcb != null &&
          pcb.isNotEmpty &&
          (entry.macAddress == pcb || entry.pcbNumber == pcb);
      return macMatch || pcbMatch;
    }

    // Set true the moment we land an ACK in this call. Two reasons
    // to track it: (1) skip the passive sync below in the same call
    // — getMotorData() can return a sibling row whose modeIndex
    // hasn't been refreshed yet, and reading it would immediately
    // revert localModeIndex back to the old mode. (2) Mirrors the
    // "we just answered the user, don't undo it" intent for the
    // rest of the function.
    bool ackProcessedThisCall = false;

    // Mode ACK detection — must scan EVERY motorDataMap entry that
    // belongs to this motor, not just the one getMotorData() picks
    // first. _handleModeChangeAck in MqttService writes the new mode
    // onto the entry resolved by _findMotorWithPendingCommand (which
    // matches by mac OR pcb on whichever group key holds the pending
    // command). getMotorData() walks `mac-G01 → pcb-G01 → mac-G02 …`
    // and returns the first hasReceivedData==true entry; if the ACK
    // landed on a different key, scanning the full map is what makes
    // the detection group-/identifier-agnostic.
    if (_hasPendingModeCommand) {
      int? ackedMode;
      for (final entry in mqttService.motorDataMap.values) {
        if (!entry.hasReceivedData) continue;
        if (!entryBelongsToThisMotor(entry)) continue;
        if (entry.modeIndex == _pendingModeValue) {
          ackedMode = entry.modeIndex;
          break;
        }
      }

      if (ackedMode != null) {
        // Propagate the ACKed mode onto every sibling row for this
        // motor. _handleModeChangeAck only writes onto one row (the
        // one with the pending command); without this fan-out, the
        // passive sync below — or the next T:35 live-data update
        // reading from a different row — would still see the old
        // mode on those siblings and try to revert localModeIndex.
        for (final entry in mqttService.motorDataMap.values) {
          if (!entryBelongsToThisMotor(entry)) continue;
          entry.modeIndex = ackedMode;
        }

        _modeAckTimer?.cancel();
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        isWaitingForModeAck.value = false;

        // ACK may have arrived via live data (T:35/41) rather than
        // the explicit T:32 ACK, so the MqttService retry timer may
        // still be running. Cancel it now to prevent it from
        // re-publishing the old command after we already consider it
        // resolved.
        final mId = _getMotorId();
        if (mId.isNotEmpty) {
          mqttService.clearPendingModeCommand(mId);
        }

        // Force UI update — this is the line that pops the dialog
        // (via isWaitingForModeAck above) and lands the toggle on
        // the new mode.
        localModeIndex.value = ackedMode;
        motorMode.value = _labelForMode(ackedMode);
        ackProcessedThisCall = true;
      }
    }

    if (motorData != null && motorData.hasReceivedData) {
      // Passive mode sync — mirror whatever the device's currently
      // active mode is. Skipped while a mode command is pending so
      // we don't fight the in-flight optimistic update, AND skipped
      // in the same call that just processed an ACK so a stale
      // sibling row read through getMotorData() doesn't immediately
      // overwrite the ACKed value we just wrote.
      //
      // Reading from the freshest matching row (rather than the
      // single one getMotorData() picks first) is what lets the mode
      // tab follow the device when it switches which group it
      // publishes on — e.g. live data starts arriving on G02 while
      // G01's modeIndex still holds an older value. getMotorData()
      // walks groups in fixed order, so without the most-recent-
      // ack-time tiebreak the tab would keep showing G01's stale
      // mode. Mirrors motor_card_widget._getMotorData on the
      // dashboard, which already uses the same lastAckTime
      // tiebreak.
      if (!_hasPendingModeCommand && !ackProcessedThisCall) {
        int? freshestMode;
        DateTime? freshestTime;
        for (final entry in mqttService.motorDataMap.entries) {
          final data = entry.value;
          if (!data.hasReceivedData) continue;
          if (!entryBelongsToThisMotor(data)) continue;
          final ackTime = mqttService.getLastAckTime(entry.key);
          if (ackTime != null) {
            if (freshestTime == null || ackTime.isAfter(freshestTime)) {
              freshestTime = ackTime;
              freshestMode = data.modeIndex;
            }
          } else
            freshestMode ??= data.modeIndex;
        }

        if (freshestMode != null && localModeIndex.value != freshestMode) {
          localModeIndex.value = freshestMode;
          motorMode.value = _labelForMode(freshestMode);
        }
      }

      // Update motor state. Only adopt the device's live state from a row
      // that has actually received live data (T:35/41). A heartbeat (T:40)
      // flips hasReceivedData=true but carries ONLY signal quality, leaving
      // `state` at its stale/init value — trusting it there shows "ON" while
      // the device (and API) report OFF. Pick the freshest live-data row,
      // mirroring the mode sync above; fall back to the API state when no
      // live data has arrived yet.
      int? liveState;
      DateTime? liveStateTime;
      for (final entry in mqttService.motorDataMap.entries) {
        final data = entry.value;
        if (!data.hasReceivedLiveData) continue;
        if (!entryBelongsToThisMotor(data)) continue;
        final ackTime = mqttService.getLastAckTime(entry.key);
        if (ackTime != null) {
          if (liveStateTime == null || ackTime.isAfter(liveStateTime)) {
            liveStateTime = ackTime;
            liveState = data.state;
          }
        } else
          liveState ??= data.state;
      }
      final resolvedState =
          liveState ?? motorDetails.value?.state ?? motorState.value;
      if (motorState.value != resolvedState) {
        motorState.value = resolvedState;
      }

      // Update network signal quality
      if (!motorData.isSignalStale()) {
        signalQuality.value = motorData.signalStrength;
      } else {
        // Signal is stale — fall back to API value, matching dashboard behavior
        signalQuality.value = motorDetails.value?.starter?.signalQuality ?? 0;
      }
    }

    _updateCanChangeMode();
  }

  MotorData? getMotorData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) return null;

    final mac = motorDetails.value!.starter!.macAddress;
    final pcb = motorDetails.value!.starter!.pcbNumber;

    // Check all possible groups to find active data
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';

      if (mac != null && mac.isNotEmpty) {
        final key = '$mac-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          return data;
        }
      }

      if (pcb != null && pcb.isNotEmpty) {
        final key = '$pcb-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          return data;
        }
      }
    }

    return null;
  }

  String _getMotorId() {
    if (motorDetails.value?.starter == null) return '';

    final motorData = getMotorData();
    final mac = motorDetails.value!.starter!.macAddress;
    final pcb = motorDetails.value!.starter!.pcbNumber;
    final publishedNumber = getMotorIdentifier(
        motorDetails.value!.starter!.deviceAllocation.toString(),
        pcb.toString(),
        mac.toString());

    if (motorData != null && motorData.groupId != null) {
      if (motorData.macAddress != null && publishedNumber.isNotEmpty) {
        final motorId = '$publishedNumber-${motorData.groupId}';
        return motorId;
      }
    }

    if (publishedNumber.isNotEmpty) {
      final motorId = '$publishedNumber-G01';
      return motorId;
    }

    return '';
  }

  void _updateCanChangeMode() {
    if (motorDetails.value?.starter == null) {
      canChangeMode.value = false;
      return;
    }

    final isAvailable =
        (motorDetails.value!.starter!.macAddress?.isNotEmpty == true) ||
            (motorDetails.value!.starter!.pcbNumber?.isNotEmpty == true);

    if (!isAvailable) {
      canChangeMode.value = false;
      return;
    }

    final motorData = getMotorData();
    final signalBars = _getSignalBars(motorData);
    canChangeMode.value = ConnectivityService.to.isConnected && signalBars > 0;
  }

  int _getSignalBars(MotorData? motorData) {
    if (motorData?.hasReceivedData == true && !motorData!.isSignalStale()) {
      return motorData.signalBars;
    }
    final signal = motorDetails.value?.starter?.signalQuality;
    if (signal == null || signal < 2 || signal > 40) return 0;
    if (signal < 10) return 1;
    if (signal < 15) return 2;
    if (signal < 20) return 3;
    return 4;
  }

  void _startModeAckTimer(int previousValue) {
    _modeAckTimer?.cancel();
    _modeAckTimer = Timer(AnalyticsController._ackTimeout, () {
      if (_hasPendingModeCommand) {
        if (kDebugMode) {}
        // Cancel MQTT retries immediately so they don't re-publish the old
        // command after we've given up, and to avoid the race where the
        // MqttService timer fires just after the controller clears its state
        // and removes a freshly-registered new-command entry.
        final mId = _getMotorId();
        if (mId.isNotEmpty) {
          mqttService.clearPendingModeCommand(mId);
        }
        localModeIndex.value = previousValue;
        motorMode.value = _labelForMode(previousValue);
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        isWaitingForModeAck.value = false;
      }
    });
  }

  /// Checks whether this motor has any schedule by calling the schedule-list
  /// API with no status filter, so schedules in every status (PARTIAL,
  /// SCHEDULED, COMPLETED, etc.) count. The result drives the Mode tab's
  /// Schedule segment — enabled when at least one schedule exists, disabled
  /// otherwise. On error we leave the segment enabled so a failed request
  /// never wrongly blocks the user.
  Future<void> checkScheduleAvailability() async {
    try {
      final response = await ScheduleRepositoryImpl().getScheduleList(1, 1);
      final records = response?.data?.records ?? [];
      final total =
          response?.data?.paginationInfo?.totalRecords ?? records.length;
      hasSchedule.value = total > 0 || records.isNotEmpty;
    } catch (_) {
      hasSchedule.value = true;
    }
  }

  Future<void> handleLiveData() async {
    if (!mqttInitialized || isWaitingForModeAck.value) return;

    final mId = _getMotorId();
    if (mId.isEmpty) return;
    try {
      await mqttService.publishTestRunCommand(mId, 5, data: 1, type: 5);
    } catch (e) {
      // ignore
    }
  }

  /// Cancel an in-flight mode change while the user is still on the
  /// confirmation dialog. Mirrors what `_startModeAckTimer`'s
  /// timeout callback does — stops MQTT retries, clears the
  /// controller's pending flags, and lands `localModeIndex` on
  /// whatever the device currently reports — but fires immediately
  /// instead of waiting the full 23s window. The dialog's Cancel
  /// button calls this so tapping Cancel stops the retry loop
  /// AND closes the dialog (via the rx flip the dialog watches).
  void cancelModeChange() {
    if (!_hasPendingModeCommand) return;

    final mId = _getMotorId();
    if (mId.isNotEmpty) {
      mqttService.clearPendingModeCommand(mId);
    }
    _modeAckTimer?.cancel();

    // Revert the optimistic localModeIndex to whatever the device
    // last reported. Use the same "freshest row" scan as passive
    // sync so the toggle lands on the actual device state, not the
    // pending value we optimistically wrote in handleModeChange.
    final mac = motorDetails.value?.starter?.macAddress;
    final pcb = motorDetails.value?.starter?.pcbNumber;
    int? revertMode;
    DateTime? freshestTime;
    for (final entry in mqttService.motorDataMap.entries) {
      final data = entry.value;
      if (!data.hasReceivedData) continue;
      final macMatch = mac != null &&
          mac.isNotEmpty &&
          (data.macAddress == mac || data.pcbNumber == mac);
      final pcbMatch = pcb != null &&
          pcb.isNotEmpty &&
          (data.macAddress == pcb || data.pcbNumber == pcb);
      if (!macMatch && !pcbMatch) continue;
      final ackTime = mqttService.getLastAckTime(entry.key);
      if (ackTime != null) {
        if (freshestTime == null || ackTime.isAfter(freshestTime)) {
          freshestTime = ackTime;
          revertMode = data.modeIndex;
        }
      } else
        revertMode ??= data.modeIndex;
    }
    if (revertMode != null) {
      localModeIndex.value = revertMode;
      motorMode.value = _labelForMode(revertMode);
    }

    _hasPendingModeCommand = false;
    _pendingModeValue = null;
    isWaitingForModeAck.value = false;
  }

  // UI uses index 2 for Schedule, but the device protocol expects D:6 on
  // T:2 / T:32. Translate at the publish boundary; ACK side is mirrored in
  // MqttService._handleModeChangeAck.
  int _deviceCodeForUiMode(int uiIndex) =>
      uiIndex == MqttService.scheduleModeUiIndex
          ? MqttService.scheduleModeDeviceCode
          : uiIndex;

  String _labelForMode(int index) {
    if (index == 1) return 'Auto';
    if (index == MqttService.scheduleModeUiIndex) return 'Schedule';
    return 'Manual';
  }

  Future<void> handleModeChange(int newModeIndex) async {
    if (!mqttInitialized || isWaitingForModeAck.value) return;

    final mId = _getMotorId();
    if (mId.isEmpty) return;

    final previousValue = localModeIndex.value;

    // Cancel any stale mode-command retries in the MQTT service before issuing
    // a new command. Without this, a retry from the previous round can fire
    // after this publish and overwrite the new mode on the device.
    mqttService.clearPendingModeCommand(mId);

    // Optimistically update UI
    isWaitingForModeAck.value = true;
    localModeIndex.value = newModeIndex;
    motorMode.value = _labelForMode(newModeIndex);
    _hasPendingModeCommand = true;
    _pendingModeValue = newModeIndex;

    _startModeAckTimer(previousValue);

    try {
      await mqttService.publishModeCommand(
          mId, _deviceCodeForUiMode(newModeIndex));
    } catch (e) {
      _modeAckTimer?.cancel();
      mqttService.clearPendingModeCommand(mId);
      localModeIndex.value = previousValue;
      motorMode.value = _labelForMode(previousValue);
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      isWaitingForModeAck.value = false;
    }
  }

  void handleModeAckError(int code) {
    final mId = _getMotorId();
    if (mId.isNotEmpty) {
      mqttService.clearPendingModeCommand(mId);
    }
    _modeAckTimer?.cancel();

    // Revert the optimistic toggle. _pendingModeValue is the index we
    // optimistically switched to; we don't track the previous value here,
    // so fall back to whatever modeIndex the device last reported.
    final motorData = getMotorData();
    final deviceMode = motorData?.modeIndex;
    if (deviceMode != null && deviceMode != localModeIndex.value) {
      localModeIndex.value = deviceMode;
      motorMode.value = _labelForMode(deviceMode);
    }

    _hasPendingModeCommand = false;
    _pendingModeValue = null;
    isWaitingForModeAck.value = false;

    final msg = MqttService.modeAckErrorMessage(code) ?? 'Mode change failed';
    geterrorSnackBar(msg);
  }
}
