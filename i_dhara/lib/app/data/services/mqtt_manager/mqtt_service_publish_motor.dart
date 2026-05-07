part of 'mqtt_service.dart';

/// Motor / mode / fault / settings publish methods for [MqttService].
extension MqttPublishMotor on MqttService {
  /// Publish motor ON/OFF command
  Future<void> publishMotorCommand(String motorId, int state) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('✗ Cannot publish: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      return;
    }

    // Throttle commands (2 second cooldown)
    final lastTime = _lastCommandTimes[motorId];
    if (lastTime != null && DateTime.now().difference(lastTime).inSeconds < 2) {
      debugPrint('⏳ Command throttled for $motorId');
      return;
    }

    _lastAckTimes.remove(motorId);
    _lastCommandTimes[motorId] = DateTime.now();

    final seq = _random.nextInt(251);

    try {
      await _publishCommand(motorId, 1, state, seq);
      statusMessage = 'Motor command sent successfully';
      _registerPendingCommand(motorId, 1, state, seq);
    } catch (e) {
      debugPrint('✗ Failed to publish motor command: $e');
      statusMessage = 'Failed to publish: $e';
      _lastCommandTimes.remove(motorId);
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> publishTestRunCommand(
    String motorId,
    int state, {
    int data = 2,
    int type = 1,
  }) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('Cannot publish test run: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    _lastAckTimes.remove(motorId);

    final seq = _random.nextInt(251);

    try {
      await _publishCommand(motorId, type, data, seq);
      statusMessage = 'Test run command sent';
      _registerPendingCommand(motorId, type, data, seq);

      debugPrint(
          'Test run command published for $motorId (state=$state) - No retries');
    } catch (e) {
      debugPrint('Failed to publish test run command: $e');
      statusMessage = 'Failed to publish test run: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> publishMotorOFF(
    String motorId,
    int state, {
    int data = 2,
    int type = 1,
  }) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('Cannot publish test run: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    _lastAckTimes.remove(motorId);

    final seq = _random.nextInt(251);

    try {
      await _publishCommand(motorId, type, data, seq);
      statusMessage = 'Test run command sent';
      debugPrint(
          'Test run command published for $motorId (state=$state) - No retries');
    } catch (e) {
      debugPrint('Failed to publish test run command: $e');
      statusMessage = 'Failed to publish test run: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> publishUpdateSettings(
      String pcb, Map<String, dynamic> payload) async {
    if (_mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      return;
    }
    final seq = _random.nextInt(251);

    try {
      await _publishDefaultSettingCommandInternal(
        payload,
        pcb,
        sequenceNumber: seq,
      );
      statusMessage = 'Device Settings command sent successfully';
      _registerPendingCommand('', 4, payload, seq, pcbnumber: pcb);
    } catch (e) {
      statusMessage = 'Failed to publish Device Settings command: $e';
      // _lastCommandTimes.remove();
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> _publishDefaultSettingCommandInternal(
      dynamic commandData, String pcbnumber,
      {int? sequenceNumber, bool isRetry = false}) async {
    if (_mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }
    final topic = 'peepul/$pcbnumber/cmd';

    final seq = sequenceNumber ?? _random.nextInt(251);

    final payload = {"T": 4, "S": seq, "D": commandData};

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    if (!isRetry) {
      debugPrint('✓ Published Settings Command: $message');
    }
  }

  /// Cancel any pending mode command retries for the given motor.
  /// Call this before sending a new mode command or when reverting on timeout.
  void clearPendingModeCommand(String motorId) {
    final key = '${motorId}_2';
    final command = _pendingCommands[key];
    if (command != null) {
      command.cancelTimer();
      _pendingCommands.remove(key);
      debugPrint('✓ Cleared pending mode command: $key');
    }
  }

  /// Cancel any pending settings command retries.
  void cancelPendingSettingsCommand() {
    const key = '_4';
    final command = _pendingCommands[key];
    if (command != null) {
      command.cancelTimer();
      _pendingCommands.remove(key);
      debugPrint('✓ Cancelled pending settings command');
    }
  }

  /// Publish mode change command (0=Manual, 1=Auto)
  Future<void> publishModeCommand(String motorId, int mode) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('✗ Cannot publish: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    _lastAckTimes.remove(motorId);

    final seq = _random.nextInt(251);

    try {
      await _publishCommand(motorId, 2, mode, seq);
      statusMessage = 'Mode command sent successfully';
      _registerPendingCommand(motorId, 2, mode, seq);
    } catch (e) {
      debugPrint('✗ Failed to publish mode command: $e');
      statusMessage = 'Failed to publish: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  /// Publish fault clear command (T:21, S:seq, D:1)
  Future<void> publishFaultClearCommand(String motorId) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('✗ Cannot publish fault clear: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    _lastAckTimes.remove(motorId);
    final seq = _random.nextInt(251);

    try {
      await _publishCommand(motorId, 21, 1, seq);
      statusMessage = 'Fault clear command sent';
      _registerPendingCommand(motorId, 21, 1, seq);
    } catch (e) {
      debugPrint('✗ Failed to publish fault clear command: $e');
      statusMessage = 'Failed to publish fault clear: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }
}
