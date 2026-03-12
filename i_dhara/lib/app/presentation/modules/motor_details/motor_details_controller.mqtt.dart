part of 'motor_details_controller.dart';

extension AnalyticsControllerMqtt on AnalyticsController {
  Future<void> _initializeMqtt() async {
    if (motorDetails.value?.starter == null) {
      if (kDebugMode) print('Motor details not loaded, cannot initialize MQTT');
      return;
    }

    final starter = motorDetails.value!.starter!;
    final mac = starter.macAddress;
    final pcb = starter.pcbNumber;

    if (kDebugMode) {
      print('=== Analytics MQTT Initialization ===');
      print('MAC Address: ${mac ?? "NULL"}');
      print('PCB Number: ${pcb ?? "NULL"}');
    }

    if ((mac == null || mac.isEmpty) && (pcb == null || pcb.isEmpty)) {
      if (kDebugMode) print('No MAC or PCB available');
      return;
    }

    // Get the singleton instance
    // No need to create motorMap or update motors since we're using wildcard subscriptions
    mqttService = MqttService();

    // Check if already connected, if not initialize
    if (!mqttService.isConnected) {
      if (kDebugMode)
        print(
            'MQTT not connected - it should have been initialized from dashboard');
      if (kDebugMode) print('   Initializing MQTT from motor details...');

      // Build minimal motor map for this motor
      final motor = _convertMotorDetailsToMotor(motorDetails.value!);
      final motorMap = <String, Motor>{};

      // Build motor map for all 4 groups
      for (int i = 1; i <= 4; i++) {
        final groupId = 'G0$i';
        if (mac != null && mac.isNotEmpty) {
          final key = '$mac-$groupId';
          motorMap[key] = motor;
          if (kDebugMode) print('✓ Analytics: Added motor map entry: $key');
        }
        if (pcb != null && pcb.isNotEmpty) {
          final key = '$pcb-$groupId';
          motorMap[key] = motor;
          if (kDebugMode) print('✓ Analytics: Added motor map entry: $key');
        }
      }

      mqttService = MqttService(initialMotors: motorMap);
      await mqttService.initializeMqttClient();
    } else {
      if (kDebugMode)
        print('✓ MQTT already connected with wildcard subscriptions');
      if (kDebugMode) print('   No need to update motors or resubscribe');
    }

    mqttInitialized = true;

    mqttService.dataUpdateNotifier.addListener(_onMqttDataUpdate);

    // Check if we have data
    if (kDebugMode) {
      print('Checking motor data availability...');
      final motorData = getMotorData();
      if (motorData != null && motorData.hasReceivedData) {
        print('✓ Motor data found!');
        print('   State: ${motorData.state}');
        print('   Mode: ${motorData.modeIndex}');
        print('   Group: ${motorData.groupId}');
      } else {
        print('No motor data yet, waiting for MQTT messages...');
        print('   Motor data map size: ${mqttService.motorDataMap.length}');

        // Print all keys in the map
        if (mqttService.motorDataMap.isNotEmpty) {
          print('   Available keys:');
          for (var key in mqttService.motorDataMap.keys) {
            final data = mqttService.motorDataMap[key];
            print('     $key: hasData=${data?.hasReceivedData}');
          }
        }
      }
    }

    // Initial update
    _updateFromMqttData();
    _updateCanChangeMode();

    if (kDebugMode) {
      print('✓ Analytics MQTT initialization complete');
      print('   Listener added for MQTT updates');
    }
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
    if (kDebugMode) {
      print('MQTT data update notification received');
    }
    _updateFromMqttData();
  }

  void _updateFromMqttData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) {
      if (kDebugMode) print('MQTT not ready or no motor details');
      return;
    }

    final motorData = getMotorData();

    if (motorData != null && motorData.hasReceivedData) {
      // Handle mode ACK
      if (_hasPendingModeCommand) {
        final mqttMode = motorData.modeIndex;

        if (mqttMode == _pendingModeValue) {
          if (kDebugMode) {
            print('Mode ACK MATCHED! (via ${motorData.modeIndex != null ? "live-data" : "type-32"})');
          }

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
          motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';
        } else {
          if (kDebugMode) {
            print('ACK mismatch - still waiting');
          }
        }
      } else {
        final mqttMode = motorData.modeIndex;
        if (mqttMode != null && localModeIndex.value != mqttMode) {
          if (kDebugMode) {}
          localModeIndex.value = mqttMode;
          motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';
        }
      }

      // Update motor state
      if (motorState.value != motorData.state) {
        if (kDebugMode) {
          print('State updated to ${motorData.state}');
        }
        motorState.value = motorData.state;
      }

      // Update network signal quality
      if (!motorData.isSignalStale()) {
        signalQuality.value = motorData.signalStrength;
        if (kDebugMode) {
          print(
              'Signal Quality updated to ${motorData.signalStrength} (bars=${motorData.signalBars})');
        }
      } else {
        // Signal is stale — fall back to API value, matching dashboard behavior
        signalQuality.value =
            motorDetails.value?.starter?.signalQuality ?? 0;
      }
    } else {
      if (kDebugMode) {
        print('No valid motor data available');
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
          if (kDebugMode) print('Found data for MAC key=$key');
          return data;
        }
      }

      if (pcb != null && pcb.isNotEmpty) {
        final key = '$pcb-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          if (kDebugMode) print('Found data for PCB key=$key');
          return data;
        }
      }
    }

    if (kDebugMode) print('No motor data found with received data');
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
        if (kDebugMode) print('Using active MAC motor ID: $motorId');
        return motorId;
      }
    }

    if (publishedNumber.isNotEmpty) {
      final motorId = '$publishedNumber-G01';
      if (kDebugMode) print('fallback MAC motor ID: $motorId');
      return motorId;
    }

    if (kDebugMode) print(' No valid motor ID found');
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
        if (kDebugMode) {
          print(
              '⚠ Analytics: Mode ACK timeout - reverting to previous mode: $previousValue');
        }
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
        isWaitingForModeAck.value = false;
      }
    });
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
    motorMode.value = newModeIndex == 1 ? 'Auto' : 'Manual';
    _hasPendingModeCommand = true;
    _pendingModeValue = newModeIndex;

    _startModeAckTimer(previousValue);

    try {
      await mqttService.publishModeCommand(mId, newModeIndex);
      if (kDebugMode) print('Mode command published successfully');
    } catch (e) {
      if (kDebugMode) print('Error publishing mode command: $e');
      _modeAckTimer?.cancel();
      mqttService.clearPendingModeCommand(mId);
      localModeIndex.value = previousValue;
      motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      isWaitingForModeAck.value = false;
    }
  }
}
