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
    _modeAckErrorSubscription =
        mqttService.modeAckErrorStream.listen((event) {
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

    if (motorData != null && motorData.hasReceivedData) {
      // Handle mode ACK
      if (_hasPendingModeCommand) {
        final mqttMode = motorData.modeIndex;

        if (mqttMode == _pendingModeValue) {
          if (kDebugMode) {}

          _modeAckTimer?.cancel();
          _hasPendingModeCommand = false;
          _pendingModeValue = null;
          isWaitingForModeAck.value = false;

          // ACK may have arrived via live data (T:35/41) rather than the
          // explicit T:32 ACK, so the MqttService retry timer may still be
          // running. Cancel it now to prevent it from re-publishing the old
          // command after we already consider it resolved.
          final mId = _getMotorId();
          if (mId.isNotEmpty) {
            mqttService.clearPendingModeCommand(mId);
          }

          // Force UI update
          localModeIndex.value = mqttMode!;
          motorMode.value = _labelForMode(mqttMode);
        } else {
          if (kDebugMode) {}
        }
      } else {
        final mqttMode = motorData.modeIndex;
        if (mqttMode != null && localModeIndex.value != mqttMode) {
          if (kDebugMode) {}
          localModeIndex.value = mqttMode;
          motorMode.value = _labelForMode(mqttMode);
        }
      }

      // Update motor state
      if (motorState.value != motorData.state) {
        if (kDebugMode) {}
        motorState.value = motorData.state;
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
    if (signal == null || signal < 2 || signal > 31) return 0;
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
