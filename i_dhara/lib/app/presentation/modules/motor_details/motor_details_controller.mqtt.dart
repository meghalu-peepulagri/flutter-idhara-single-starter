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
      // Record any group whose modeIndex has moved off its publish-time
      // snapshot. Combined with current==expectedMode in the check below,
      // this lets us recognise the real ACK across echo sequences (e.g.
      // device sends D:current_mode echo then D:new_mode) and across mode
      // changes where the publish-time snapshot happened to already equal
      // the requested mode — neither of which the strict snapshot-vs-current
      // comparison alone catches.
      _trackPerGroupChanges();
      if (_anyGroupTransitionedTo(_pendingModeValue!)) {
        final ackedMode = _pendingModeValue!;
        _modeAckTimer?.cancel();
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        _modeAckSnapshot = {};
        _modeAckGroupChanged = {};
        _modeAckLastAckSnapshot = {};
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
        // Use the freshest group's modeIndex as the source of truth, not
        // motorData (which getMotorData returns by static iteration order).
        // Otherwise, when both MAC-G0X and PCB-G0X exist (built in init for
        // every group) and the device publishes T:41 on whichever of the
        // two is *not* first in iteration, the stale entry wins and
        // localModeIndex never updates from live data — only the API
        // refresh would correct it.
        final freshestMode = _freshestGroupModeIndex();
        if (freshestMode != null && localModeIndex.value != freshestMode) {
          localModeIndex.value = freshestMode;
          motorMode.value = freshestMode == 1 ? 'Auto' : 'Manual';
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

  // Picks the modeIndex of the group whose lastAckTime is the most recent
  // among groups with hasReceivedData=true. This is the only mode value
  // safe to follow for localModeIndex updates: it ignores stale per-key
  // entries (e.g. the MAC-G0X duplicate sitting on its API-derived init
  // value while the device is currently publishing on PCB topic, or vice
  // versa) that would otherwise hide the device's current mode behind
  // getMotorData's static iteration order.
  int? _freshestGroupModeIndex() {
    DateTime? freshestTime;
    int? freshestMode;
    for (final key in _allMotorKeys()) {
      final data = mqttService.motorDataMap[key];
      if (data?.hasReceivedData != true) continue;
      final lastAck = mqttService.getLastAckTime(key);
      if (lastAck == null) continue;
      if (freshestTime == null || lastAck.isAfter(freshestTime)) {
        freshestTime = lastAck;
        freshestMode = data?.modeIndex;
      }
    }
    return freshestMode;
  }

  // Sticky per-group flag: once a group's modeIndex is observed to differ
  // from its publish-time snapshot, the flag stays true for the remainder
  // of the pending window. Combined with current==expectedMode this lets us
  // detect the real ACK in patterns the snapshot-only check misses
  // (echo D:current → real D:new, or value oscillating back to the
  // snapshot during the wait).
  void _trackPerGroupChanges() {
    for (final key in _allMotorKeys()) {
      final current = mqttService.motorDataMap[key]?.modeIndex;
      if (current != _modeAckSnapshot[key]) {
        _modeAckGroupChanged[key] = true;
      }
    }
  }

  // Returns true if any group's modeIndex equals expectedMode and we have
  // evidence that group transitioned during this pending window. Evidence
  // is either:
  //   (a) the publish-time snapshot for the group differed from
  //       expectedMode — the original strict check,
  //   (b) the per-group change flag is set — covers echo + real ACK
  //       sequences (D:current echo → D:new real), or
  //   (c) the group's lastAckTime advanced past its publish-time snapshot —
  //       covers the case where the publish-time snapshot already equalled
  //       expectedMode AND the real ACK arrives without changing the
  //       modeIndex value, which (a) and (b) both miss.
  // The change flag and the per-key lastAckTime check both avoid the false
  // ACK risk of a session-wide "any change observed" condition.
  bool _anyGroupTransitionedTo(int expectedMode) {
    for (final key in _allMotorKeys()) {
      final current = mqttService.motorDataMap[key]?.modeIndex;
      if (current != expectedMode) continue;
      if (_modeAckGroupChanged[key] == true) return true;
      final snapshot = _modeAckSnapshot[key];
      if (snapshot != expectedMode) return true;
      final currentLastAck = mqttService.getLastAckTime(key);
      final snapshotLastAck = _modeAckLastAckSnapshot[key];
      if (currentLastAck != null &&
          (snapshotLastAck == null ||
              currentLastAck.isAfter(snapshotLastAck))) {
        return true;
      }
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
        _modeAckGroupChanged = {};
        _modeAckLastAckSnapshot = {};
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
    _modeAckGroupChanged = {for (final k in _allMotorKeys()) k: false};
    _modeAckLastAckSnapshot = {
      for (final k in _allMotorKeys()) k: mqttService.getLastAckTime(k)
    };

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
      _modeAckGroupChanged = {};
      _modeAckLastAckSnapshot = {};
      isWaitingForModeAck.value = false;
    }
  }
}
