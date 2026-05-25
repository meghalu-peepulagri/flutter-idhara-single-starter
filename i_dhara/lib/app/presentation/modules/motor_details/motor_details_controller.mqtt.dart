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

    // ACK detection first — scan ALL groups across both mac and pcb keys for
    // any entry whose modeIndex now equals the pending value. getMotorData()
    // returns the first entry with hasReceivedData=true, which may not be
    // the same entry MqttService updated when the T:32 ACK arrived, so a
    // single-entry comparison was missing real ACKs.
    if (_hasPendingModeCommand && _pendingModeValue != null) {
      if (_anyGroupTransitionedTo(_pendingModeValue!)) {
        final ackedMode = _pendingModeValue!;
        _modeAckTimer?.cancel();
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        _modeAckSnapshot = {};
        isWaitingForModeAck.value = false;

        final mId = _getMotorId();
        if (mId.isNotEmpty) {
          mqttService.clearPendingModeCommand(mId);
        }

        localModeIndex.value = ackedMode;
        motorMode.value = ackedMode == 1 ? 'Auto' : 'Manual';
        _updateCanChangeMode();
        return;
      }
    }

    final motorData = getMotorData();

    if (motorData != null && motorData.hasReceivedData) {
      if (!_hasPendingModeCommand) {
        final mqttMode = motorData.modeIndex;
        if (mqttMode != null && localModeIndex.value != mqttMode) {
          // Only accept MQTT's mode if our current local mode is no longer
          // represented in any group's data. Right after an ACK, the
          // confirmed group has modeIndex=new but a periodic live-data
          // publish may still be carrying mode=old on another group; without
          // this guard, getMotorData() can pick the stale group and revert
          // localModeIndex back to the pre-ACK value.
          if (!_anyGroupHasMode(localModeIndex.value)) {
            localModeIndex.value = mqttMode;
            motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';
          }
        }
      }

      // Update motor state
      if (motorState.value != motorData.state) {
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

  List<String> _allMotorKeys() {
    final keys = <String>[];
    final starter = motorDetails.value?.starter;
    if (starter == null) return keys;
    final mac = starter.macAddress;
    final pcb = starter.pcbNumber;
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      if (mac != null && mac.isNotEmpty) keys.add('$mac-$groupId');
      if (pcb != null && pcb.isNotEmpty) keys.add('$pcb-$groupId');
    }
    return keys;
  }

  Map<String, int?> _snapshotGroupModes() {
    final snapshot = <String, int?>{};
    for (final key in _allMotorKeys()) {
      snapshot[key] = mqttService.motorDataMap[key]?.modeIndex;
    }
    return snapshot;
  }

  bool _anyGroupHasMode(int expectedMode) {
    for (final key in _allMotorKeys()) {
      if (mqttService.motorDataMap[key]?.modeIndex == expectedMode) return true;
    }
    return false;
  }

  // ACK-detection variant of _anyGroupHasMode. Only returns true when a
  // group's modeIndex moved to expectedMode AFTER the publish — i.e. its
  // snapshot value at publish time was different. This prevents false ACKs
  // from stale entries that were already at expectedMode (typical on the
  // 2nd+ mode change of a session: groups that never received a real ACK
  // still carry the initial API-derived modeIndex).
  bool _anyGroupTransitionedTo(int expectedMode) {
    for (final key in _allMotorKeys()) {
      final current = mqttService.motorDataMap[key]?.modeIndex;
      if (current != expectedMode) continue;
      final snapshot = _modeAckSnapshot[key];
      if (snapshot != expectedMode) return true;
    }
    return false;
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
        // Cancel MQTT retries immediately so they don't re-publish the old
        // command after we've given up, and to avoid the race where the
        // MqttService timer fires just after the controller clears its state
        // and removes a freshly-registered new-command entry.
        final mId = _getMotorId();
        if (mId.isNotEmpty) {
          mqttService.clearPendingModeCommand(mId);
        }
        localModeIndex.value = previousValue;
        motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        _modeAckSnapshot = {};
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

  Future<void> handleModeChange(int newModeIndex) async {
    if (!mqttInitialized || isWaitingForModeAck.value) return;

    final mId = _getMotorId();
    if (mId.isEmpty) return;

    final previousValue = localModeIndex.value;

    // Cancel any stale mode-command retries in the MQTT service before issuing
    // a new command. Without this, a retry from the previous round can fire
    // after this publish and overwrite the new mode on the device.
    mqttService.clearPendingModeCommand(mId);

    // Snapshot every relevant group's modeIndex BEFORE the publish so the
    // ACK detector can distinguish a real transition from a pre-existing
    // stale value that already matches the new mode.
    _modeAckSnapshot = _snapshotGroupModes();

    // Optimistically update UI
    isWaitingForModeAck.value = true;
    localModeIndex.value = newModeIndex;
    motorMode.value = newModeIndex == 1 ? 'Auto' : 'Manual';
    _hasPendingModeCommand = true;
    _pendingModeValue = newModeIndex;

    _startModeAckTimer(previousValue);

    try {
      await mqttService.publishModeCommand(mId, newModeIndex);
    } catch (e) {
      _modeAckTimer?.cancel();
      mqttService.clearPendingModeCommand(mId);
      localModeIndex.value = previousValue;
      motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      _modeAckSnapshot = {};
      isWaitingForModeAck.value = false;
    }
  }
}
