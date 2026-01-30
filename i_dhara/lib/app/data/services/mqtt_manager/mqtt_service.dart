import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

class MotorData {
  ValueNotifier<bool> controller = ValueNotifier<bool>(false);
  ValueNotifier<int?> modeswitchcontroller = ValueNotifier<int?>(null);

  String voltageRed = '0';
  String voltageYellow = '0';
  String voltageBlue = '0';
  String currentRed = '0';
  String currentYellow = '0';
  String currentBlue = '0';
  int state = 0;
  String motorMode = '_';
  int? modeIndex;
  int power = 0;
  int fault = 0;
  int alert = 0;
  String runTime = '-';
  bool hasReceivedData = false;

  String? macAddress;
  String? pcbNumber;
  String? groupId;
  String? title;

  int signalStrength = 0;
  int signalBars = 0;
  DateTime? lastSignalUpdate;

  MotorData({
    this.macAddress,
    this.pcbNumber,
    this.groupId,
    this.title,
  });

  void dispose() {
    controller.dispose();
    modeswitchcontroller.dispose();
  }

  void updateSignalStrength(int strength) {
    signalStrength = strength;
    lastSignalUpdate = DateTime.now();

    if (strength < 2 || strength > 31) {
      signalBars = 0;
    } else if (strength <= 9) {
      signalBars = 1;
    } else if (strength <= 14) {
      signalBars = 2;
    } else if (strength <= 19) {
      signalBars = 3;
    } else if (strength <= 30) {
      signalBars = 4;
    } else {
      signalBars = 0;
    }
  }

  bool isSignalStale() {
    if (lastSignalUpdate == null) return true;
    return DateTime.now().difference(lastSignalUpdate!).inSeconds > 60;
  }
}

/// Tracks pending commands for retry mechanism
class PendingCommand {
  final String motorId;
  final int commandType; // 1 = motor control, 2 = mode change
  final dynamic commandData;
  final int sequenceNumber;
  int retryCount;
  Timer? retryTimer;
  final Function(String) onMaxRetriesReached;

  PendingCommand({
    required this.motorId,
    required this.commandType,
    required this.commandData,
    required this.sequenceNumber,
    this.retryCount = 0,
    required this.onMaxRetriesReached,
  });

  void cancelTimer() {
    retryTimer?.cancel();
    retryTimer = null;
  }
}

/// MQTT Service - Singleton that handles all MQTT communication
class MqttService {
  static final MqttService _instance = MqttService._internal();
  final StreamController<Map<String, dynamic>> defaultSettingsController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get settingstream =>
      defaultSettingsController.stream;

  factory MqttService({Map<String, Motor>? initialMotors}) {
    if (initialMotors != null) {
      _instance._motors = initialMotors;
      _instance._buildMotorDataMap();
    }
    return _instance;
  }

  MqttService._internal() {
    _motorDataMap = {};
  }

  // MQTT Client
  MqttServerClient? _mqttClient;
  bool isConnected = false;
  String statusMessage = 'Connecting to MQTT broker...';
  DateTime? lastMessageTime;

  // Motor data
  Map<String, Motor> _motors = {};
  late Map<String, MotorData> _motorDataMap;

  // Notifiers
  final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);
  final ValueNotifier<String?> commandStatusNotifier =
      ValueNotifier<String?>(null);

  // Command tracking
  final Map<String, PendingCommand> _pendingCommands = {};
  final Map<String, DateTime> _lastCommandTimes = {};
  final Map<String, DateTime> _lastAckTimes = {};

  // Retry settings
  static const int _maxRetries = 2;
  static const Duration _firstRetryDelay = Duration(seconds: 5);
  static const Duration _secondRetryDelay = Duration(seconds: 3);

  final Random _random = Random();

  ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;
  Map<String, MotorData> get motorDataMap => _motorDataMap;
  Map<String, Motor> get motors => _motors;

  /// Update motors and rebuild the motor data map
  void updateMotors(Map<String, Motor> newMotors) {
    _motors = newMotors;
    _buildMotorDataMap();
    _dataUpdateNotifier.value++;
  }

  /// Get last ack time for a motor
  DateTime? getLastAckTime(String motorId) => _lastAckTimes[motorId];

  /// Initialize MQTT connection
  Future<void> initializeMqttClient() async {
    if (_mqttClient != null && isConnected) {
      _mqttClient!.disconnect();
    }

    const broker = 'e0be1176.ala.asia-southeast1.emqxsl.com';
    const port = 8883;
    const username = 'ss_user';
    const password = '123456';
    final clientId = 'idhara_${const Uuid().v4()}';

    _mqttClient = MqttServerClient(broker, clientId)
      ..logging(on: false)
      ..keepAlivePeriod = 60
      ..connectTimeoutPeriod = 10000
      ..autoReconnect = true
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed
      ..onSubscribeFail = _onSubscribeFail
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected
      ..secure = true
      ..port = port
      ..connectionMessage =
          MqttConnectMessage().authenticateAs(username, password).startClean();

    try {
      await _mqttClient?.connect();
      debugPrint('✓ MQTT connection initiated');
      debugPrint(
          '   Connection state: ${_mqttClient?.connectionStatus?.state}');
    } catch (e) {
      debugPrint('✗ MQTT Connection Error: $e');
      return;
    }

    if (_mqttClient!.updates == null) {
      debugPrint('⚠️ MQTT updates stream is null!');
      return;
    }

    _mqttClient!.updates!.listen(
      _onMessageReceived,
      onError: (e) {
        debugPrint('✗ MQTT Stream error: $e');
        statusMessage = 'Stream error: $e';
        _dataUpdateNotifier.value++;
      },
      onDone: () {
        debugPrint('MQTT Stream closed');
      },
    );
    debugPrint('✓ MQTT message listener set up');
  }

  /// Resubscribe to all topics (called after reconnect or motor list update)
  Future<void> resubscribeToTopics() async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('Cannot resubscribe: MQTT not connected');
      return;
    }
    debugPrint('🔄 Resubscribing to all topics...');
    _subscribeToAllTopics();
  }

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
      _registerPendingCommand('', 4, payload, seq);
    } catch (e) {
      statusMessage = 'Failed to publish Device Settings command: $e';
      // _lastCommandTimes.remove();
      _dataUpdateNotifier.value++;
      rethrow;
    }
  }

  Future<void> _publishDefaultSettingCommandInternal(
      dynamic commandData, String pcbnumber,
      {int? sequenceNumber, bool isRetry = false}) async {
    if (_mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }
    final topic = 'peepul/$pcbnumber/cmd';

    final seq = sequenceNumber ?? _random.nextInt(251);
    ();

    final payload = {"T": 1, "S": seq, "D": commandData};

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    if (!isRetry) {
      debugPrint(' Payload: $message');
    } else {}
  }

  /// Publish mode change command (0=Manual, 1=Auto)
  Future<void> publishModeCommand(String motorId, int mode) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('✗ Cannot publish: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      return;
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

  /// Get motor data filtered by location
  Map<String, MotorData> getMotorDataForLocation(int? locationId) {
    if (locationId == null) return _motorDataMap;

    return Map.fromEntries(
      _motorDataMap.entries.where((entry) {
        final motor = _motors[entry.key];
        return motor?.location?.id == locationId;
      }),
    );
  }

  void dispose() {
    _mqttClient?.disconnect();
    for (var data in _motorDataMap.values) {
      data.dispose();
    }
  }

  /// Build motor data map from motors
  void _buildMotorDataMap() {
    _motorDataMap.clear();
    debugPrint('=== Building motorDataMap from ${_motors.length} entries ===');

    for (var entry in _motors.entries) {
      final motor = entry.value;
      final key = entry.key;

      final lastDashIndex = key.lastIndexOf('-');
      String identifier;
      String groupId;

      if (lastDashIndex > 0) {
        identifier = key.substring(0, lastDashIndex);
        groupId = key.substring(lastDashIndex + 1);
      } else {
        identifier = key;
        groupId = 'G01';
      }

      _motorDataMap[key] = MotorData(
        macAddress: motor.starter?.macAddress,
        pcbNumber: motor.starter?.pcbNumber,
        groupId: groupId,
        title: motor.name,
      )
        ..state = motor.state ?? 0
        ..motorMode = motor.mode ?? '--'
        ..modeIndex = _getModeIndex(motor.mode ?? '--')
        ..controller.value = motor.state == 1
        ..modeswitchcontroller.value = _getModeIndex(motor.mode ?? '--')
        ..hasReceivedData = false;

      // Copy starter parameters if available
      if (motor.starter?.starterParameters?.isNotEmpty ?? false) {
        final params = motor.starter!.starterParameters!.first;
        _motorDataMap[key]!
          ..voltageRed = params.lineVoltageR?.toString() ?? '0'
          ..voltageYellow = params.lineVoltageY?.toString() ?? '0'
          ..voltageBlue = params.lineVoltageB?.toString() ?? '0'
          ..currentRed = params.currentR?.toString() ?? '0'
          ..currentYellow = params.currentY?.toString() ?? '0'
          ..currentBlue = params.currentB?.toString() ?? '0'
          ..fault = params.fault ?? 0;
      }

      if (motor.starter?.power != null) {
        _motorDataMap[key]!.power = motor.starter!.power!;
      }

      debugPrint(
          '   Added: $key (identifier=$identifier, groupId=$groupId, mac=${motor.starter?.macAddress}, pcb=${motor.starter?.pcbNumber})');
    }

    debugPrint('=== motorDataMap built: ${_motorDataMap.length} entries ===');
    _dataUpdateNotifier.value++;
  }

  int? _getModeIndex(String mode) {
    if (mode.toUpperCase().contains('AUTO')) return 1;
    if (mode.toUpperCase().contains('MANUAL')) return 0;
    return null;
  }

  void _onConnected() {
    isConnected = true;
    statusMessage = 'Connected';
    debugPrint('✓ MQTT Connected');
    debugPrint('   Motors count: ${_motors.length}');
    debugPrint('   MotorDataMap count: ${_motorDataMap.length}');
    // Use Future.microtask to allow the connection to stabilize before subscribing
    Future.microtask(() => _subscribeToAllTopics());
    _dataUpdateNotifier.value++;
  }

  void _onDisconnected() {
    isConnected = false;
    statusMessage = 'Disconnected';
    debugPrint('✗ MQTT Disconnected');

    // Cancel all pending retries
    for (var cmd in _pendingCommands.values) {
      cmd.cancelTimer();
    }
    _pendingCommands.clear();
    _dataUpdateNotifier.value++;
  }

  void _onSubscribed(String topic) {
    debugPrint('✓ Subscription confirmed: $topic');
    _dataUpdateNotifier.value++;
  }

  void _onSubscribeFail(String topic) {
    debugPrint('✗ Subscription FAILED: $topic');
    _dataUpdateNotifier.value++;
  }

  void _onAutoReconnect() {
    debugPrint('⟳ MQTT Auto reconnecting...');
  }

  void _onAutoReconnected() {
    isConnected = true;
    statusMessage = 'Reconnected';
    debugPrint('✓ MQTT Auto-reconnected');
    // Use Future.microtask to allow the connection to stabilize before subscribing
    Future.microtask(() => _subscribeToAllTopics());
    _dataUpdateNotifier.value++;
  }

  /// Subscribe to all motor topics using wildcard subscription
  /// This avoids broker subscription limits by using just 2 wildcard topics
  void _subscribeToAllTopics() {
    if (_mqttClient == null) {
      debugPrint('⚠️ Cannot subscribe: MQTT client is null');
      return;
    }

    debugPrint('=== Starting topic subscription ===');
    debugPrint('   MQTT Client state: ${_mqttClient!.connectionStatus?.state}');
    debugPrint('   Motors count: ${_motors.length}');

    // Use wildcard subscriptions to avoid broker subscription limits
    // peepul/+/cmd - subscribes to all command topics
    // peepul/+/status - subscribes to all status topics
    final wildcardTopics = [
      'peepul/+/cmd',
      'peepul/+/status',
    ];

    for (final topic in wildcardTopics) {
      _mqttClient!.subscribe(topic, MqttQos.atMostOnce);
      debugPrint('   ✓ Subscribing to wildcard: $topic');
    }

    debugPrint('=== Wildcard subscription requests sent ===');

    // Log which identifiers we're expecting to receive messages for
    final uniqueMotors = <int, Motor>{};
    for (var motor in _motors.values) {
      if (motor.id != null && motor.starter != null) {
        uniqueMotors[motor.id!] = motor;
      }
    }

    debugPrint('   Expecting messages for ${uniqueMotors.length} motors:');
    for (var motor in uniqueMotors.values) {
      final mac = motor.starter!.macAddress;
      final pcb = motor.starter!.pcbNumber;
      debugPrint(
          '      - Motor ${motor.id} (${motor.name}): mac=$mac, pcb=$pcb');
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    lastMessageTime = DateTime.now();

    for (var message in messages) {
      final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message);
      final topic = message.topic;

      debugPrint('📨 RAW MQTT: topic=$topic, payload=$payload');

      try {
        final data = jsonDecode(payload);
        final type = data['T'] as int?;
        final payloadData = data['D'];

        debugPrint(
            '   Parsed: T=$type, D=$payloadData (${payloadData.runtimeType})');

        if (type == null) {
          debugPrint('   ⚠️ Skipping: type is null');
          continue;
        }

        final topicParts = topic.split('/');
        if (topicParts.length < 2) {
          debugPrint('   ⚠️ Skipping: invalid topic format');
          continue;
        }

        final identifier = topicParts[1];

        debugPrint(
            '📩 MQTT Message: topic=$topic, type=$type, identifier=$identifier');

        switch (type) {
          case 31:
            _handleMotorControlAck(identifier, payloadData);
            break;
          case 32:
            _handleModeChangeAck(identifier, payloadData);
            break;
          case 34:
            handleDefaultSettings(identifier, payloadData);
            break;
          case 35:
          case 41:
            _handleLiveData(identifier, payloadData);
            break;
          case 40:
            _handleHeartbeat(identifier, payloadData);
            break;
          default:
            debugPrint('   Unknown message type: $type');
        }
      } catch (e, stackTrace) {
        debugPrint('✗ Error processing MQTT message: $e');
        debugPrint('   Stack: $stackTrace');
      }
    }

    _dataUpdateNotifier.value++;
  }

  /// Handle motor ON/OFF acknowledgment (type 31)
  void _handleMotorControlAck(String identifier, dynamic payloadData) {
    debugPrint(
        '🔧 _handleMotorControlAck called: identifier=$identifier, payloadData=$payloadData (${payloadData.runtimeType})');

    // Parse state from various formats
    int? newState;
    if (payloadData is int) {
      newState = payloadData;
    } else if (payloadData is String) {
      newState = int.tryParse(payloadData);
    } else if (payloadData is double) {
      newState = payloadData.toInt();
    }

    if (newState == null) {
      debugPrint(
          '    Motor ACK: Could not parse state from payloadData=$payloadData');
      return;
    }

    debugPrint('📥 Motor Control ACK: identifier=$identifier, state=$newState');
    debugPrint('   Pending commands: ${_pendingCommands.keys.toList()}');
    debugPrint('   MotorDataMap keys: ${_motorDataMap.keys.toList()}');

    // Find motor with this identifier that has a pending command
    final motorId = _findMotorWithPendingCommand(identifier, 1);

    if (motorId != null) {
      final motorData = _motorDataMap[motorId];
      if (motorData != null) {
        motorData.state = newState;
        motorData.controller.value = (newState == 1);
        motorData.hasReceivedData = true;
        _lastAckTimes[motorId] = DateTime.now();
        _clearPendingCommand(motorId, 1);
        debugPrint(
            '   ✓ Motor ACK processed (pending): $motorId -> state=$newState');
      }
    } else {
      // No pending command - update any matching motor
      final fallbackId = _findAnyMotorWithIdentifier(identifier);
      if (fallbackId != null) {
        final motorData = _motorDataMap[fallbackId];
        if (motorData != null) {
          motorData.state = newState;
          motorData.controller.value = (newState == 1);
          motorData.hasReceivedData = true;
          _lastAckTimes[fallbackId] = DateTime.now();
          debugPrint(
              '   ✓ Motor ACK processed (fallback): $fallbackId -> state=$newState');
        }
      } else {
        debugPrint('   ⚠️ Could not find motor for identifier=$identifier');
      }
    }

    _dataUpdateNotifier.value++;
  }

  /// Handle mode change acknowledgment (type 32)
  void _handleModeChangeAck(String identifier, dynamic payloadData) {
    debugPrint(
        '🔧 _handleModeChangeAck called: identifier=$identifier, payloadData=$payloadData (${payloadData.runtimeType})');

    // Parse mode from various formats
    int? newMode;
    if (payloadData is int) {
      newMode = payloadData;
    } else if (payloadData is String) {
      newMode = int.tryParse(payloadData);
    } else if (payloadData is double) {
      newMode = payloadData.toInt();
    }

    if (newMode == null || (newMode != 0 && newMode != 1)) {
      debugPrint(
          '   ⚠️ Mode ACK: Invalid mode value: $payloadData (parsed as $newMode)');
      return;
    }

    debugPrint(
        '📥 Mode Change ACK: identifier=$identifier, mode=$newMode (${newMode == 1 ? "AUTO" : "MANUAL"})');
    debugPrint('   Pending commands: ${_pendingCommands.keys.toList()}');
    debugPrint('   MotorDataMap keys: ${_motorDataMap.keys.toList()}');

    // Find motor with this identifier that has a pending command
    final motorId = _findMotorWithPendingCommand(identifier, 2);

    if (motorId != null) {
      final motorData = _motorDataMap[motorId];
      if (motorData != null) {
        motorData.modeIndex = newMode;
        motorData.modeswitchcontroller.value = newMode;
        motorData.motorMode = newMode == 1 ? 'AUTO' : 'MANUAL';
        motorData.hasReceivedData = true;
        _lastAckTimes[motorId] = DateTime.now();
        _clearPendingCommand(motorId, 2);
        debugPrint(
            '   ✓ Mode ACK processed (pending): $motorId -> mode=$newMode');
      }
    } else {
      // No pending command - update any matching motor
      final fallbackId = _findAnyMotorWithIdentifier(identifier);
      if (fallbackId != null) {
        final motorData = _motorDataMap[fallbackId];
        if (motorData != null) {
          motorData.modeIndex = newMode;
          motorData.modeswitchcontroller.value = newMode;
          motorData.motorMode = newMode == 1 ? 'AUTO' : 'MANUAL';
          motorData.hasReceivedData = true;
          _lastAckTimes[fallbackId] = DateTime.now();
          debugPrint(
              '   ✓ Mode ACK processed (fallback): $fallbackId -> mode=$newMode');
        }
      } else {
        debugPrint('   ⚠️ Could not find motor for identifier=$identifier');
      }
    }

    _dataUpdateNotifier.value++;
  }

  /// Handle live data (type 35, 41)
  void _handleLiveData(String identifier, dynamic payloadData) {
    if (payloadData is! Map<String, dynamic>) {
      debugPrint('   ⚠️ Live data payload is not a Map: $payloadData');
      return;
    }

    debugPrint(
        '📊 Live data received for identifier=$identifier, groups=${payloadData.keys.toList()}');

    for (var entry in payloadData.entries) {
      final groupId = entry.key;
      if (groupId == 'ct') continue;

      final groupData = entry.value as Map<String, dynamic>?;
      if (groupData == null) continue;

      final fullMotorId = '$identifier-$groupId';

      // Get or create motor data
      var motorData = _motorDataMap[fullMotorId];
      if (motorData == null) {
        debugPrint('   Creating new MotorData for $fullMotorId');
        motorData = MotorData(
          macAddress: identifier,
          groupId: groupId,
          title: groupId,
        );
        _motorDataMap[fullMotorId] = motorData;
      }

      // Update motor data from payload
      _updateMotorDataFromPayload(motorData, groupData, groupId == 'G04');

      motorData.hasReceivedData = true;
      _lastAckTimes[fullMotorId] = DateTime.now();
      debugPrint(
          '   ✓ Updated $fullMotorId: state=${motorData.state}, mode=${motorData.motorMode}');
    }

    _dataUpdateNotifier.value++;
  }

  void handleDefaultSettings(String identifier, dynamic payloadData) {
    final type = payloadData as int;
    final map = {"D": type, "topic": identifier};
    for (var entry in motorDataMap.entries) {
      final motorData = entry.value;
      print("line 47 $type");
      defaultSettingsController.add(map);
    }
  }

  /// Handle heartbeat (type 40)
  void _handleHeartbeat(String identifier, dynamic payloadData) {
    if (payloadData is! Map<String, dynamic>) {
      debugPrint('   ⚠️ Heartbeat payload is not a Map');
      return;
    }

    final signalQuality = payloadData['s_q'] as int?;
    if (signalQuality == null) {
      debugPrint('   ⚠️ Heartbeat missing signal quality');
      return;
    }

    debugPrint('💓 Heartbeat: identifier=$identifier, signal=$signalQuality');

    // Find any motor with this identifier
    final motorId = _findAnyMotorWithIdentifier(identifier);
    if (motorId != null) {
      final motorData = _motorDataMap[motorId];
      motorData?.updateSignalStrength(signalQuality);
      motorData?.hasReceivedData = true;
      debugPrint(
          '   ✓ Updated signal for $motorId: bars=${motorData?.signalBars}');
    }

    _dataUpdateNotifier.value++;
  }

  /// Update motor data from live data payload
  void _updateMotorDataFromPayload(
      MotorData motorData, Map<String, dynamic> data, bool isG04) {
    // State
    if (data.containsKey('m_s') || data.containsKey('mtr_sts')) {
      final newState = (data['m_s'] ?? data['mtr_sts']) ?? 0;
      motorData.state = newState;
      motorData.controller.value = (newState == 1);
    }

    // Power
    if (data.containsKey('pwr')) {
      motorData.power = data['pwr'] ?? 0;
    }

    // Mode
    if (data.containsKey('mode')) {
      final modeValue = data['mode'] as int?;
      if (modeValue != null) {
        motorData.modeIndex = modeValue;
        motorData.modeswitchcontroller.value = modeValue;
        motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
      }
    }

    // Voltage
    if (data.containsKey('llv') || data.containsKey('ll_v')) {
      final llv = (data['llv'] ?? data['ll_v']) as List<dynamic>? ?? [0, 0, 0];
      motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
      motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
      motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
    }

    // Current (preserve G04 values if not present)
    if (data.containsKey('amp')) {
      final amp = data['amp'] as List<dynamic>? ?? [0, 0, 0];
      motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
      motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
      motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
    } else if (!isG04) {
      motorData.currentRed = '0';
      motorData.currentYellow = '0';
      motorData.currentBlue = '0';
    }

    // Fault
    if (data.containsKey('flt')) {
      motorData.fault = data['flt'] ?? 0;
    } else if (!isG04) {
      motorData.fault = 0;
    }

    // Alert
    if (data.containsKey('alt')) {
      motorData.alert = data['alt'] ?? 0;
    } else if (!isG04) {
      motorData.alert = 0;
    }
  }

  /// Find motor with pending command of given type for the identifier
  String? _findMotorWithPendingCommand(String identifier, int commandType) {
    for (var entry in _motorDataMap.entries) {
      final motorData = entry.value;
      final matchesMac = motorData.macAddress == identifier;
      final matchesPcb = motorData.pcbNumber == identifier;

      if (matchesMac || matchesPcb) {
        final pendingKey = '${entry.key}_$commandType';
        if (_pendingCommands.containsKey(pendingKey)) {
          debugPrint(
              '   Found pending command match: ${entry.key} (mac=${motorData.macAddress}, pcb=${motorData.pcbNumber})');
          return entry.key;
        }
      }
    }
    debugPrint(
        '   No pending command found for identifier=$identifier, type=$commandType');
    return null;
  }

  /// Find any motor with the given identifier
  String? _findAnyMotorWithIdentifier(String identifier) {
    for (var entry in _motorDataMap.entries) {
      final motorData = entry.value;
      if (motorData.macAddress == identifier ||
          motorData.pcbNumber == identifier) {
        debugPrint(
            '   Found motor match: ${entry.key} (mac=${motorData.macAddress}, pcb=${motorData.pcbNumber})');
        return entry.key;
      }
    }
    debugPrint('   ⚠️ No motor found for identifier=$identifier');
    debugPrint('   Available identifiers in motorDataMap:');
    for (var entry in _motorDataMap.entries) {
      debugPrint(
          '      - ${entry.key}: mac=${entry.value.macAddress}, pcb=${entry.value.pcbNumber}');
    }
    return null;
  }

  /// Publish a command to MQTT
  Future<void> _publishCommand(
      String motorId, int type, int data, int seq) async {
    final lastDashIndex = motorId.lastIndexOf('-');
    if (lastDashIndex <= 0) {
      throw Exception('Invalid motorId format: $motorId');
    }

    final identifier = motorId.substring(0, lastDashIndex);
    final topic = 'peepul/$identifier/cmd';

    final payload = jsonEncode({"T": type, "S": seq, "D": data});
    final builder = MqttClientPayloadBuilder()..addString(payload);

    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    debugPrint(' Published: $motorId (T=$type, D=$data) -> $topic');
  }

  void _registerPendingCommand(
      String motorId, int type, dynamic data, int seq) {
    final key = '${motorId}_$type';

    final command = PendingCommand(
      motorId: motorId,
      commandType: type,
      commandData: data,
      sequenceNumber: seq,
      onMaxRetriesReached: (message) {
        commandStatusNotifier.value = message;
        _dataUpdateNotifier.value++;
      },
    );

    _scheduleRetry(command);
    _pendingCommands[key] = command;

    debugPrint('   Registered pending: $key');
  }

  void _scheduleRetry(PendingCommand command) {
    final delay =
        command.retryCount == 0 ? _firstRetryDelay : _secondRetryDelay;

    command.retryTimer = Timer(delay, () async {
      final key = '${command.motorId}_${command.commandType}';

      // Check if command was already acked
      if (!_pendingCommands.containsKey(key)) return;

      if (command.retryCount < _maxRetries) {
        command.retryCount++;

        try {
          await _publishCommand(
            command.motorId,
            command.commandType,
            command.commandData as int,
            command.sequenceNumber,
          );
          debugPrint('🔄 Retry ${command.retryCount}: ${command.motorId}');
          _scheduleRetry(command);
        } catch (e) {
          _pendingCommands.remove(key);
        }
      } else {
        // Max retries reached
        _pendingCommands.remove(key);

        final motorName = _motors.entries
                .firstWhere((e) => e.key == command.motorId,
                    orElse: () => MapEntry('', Motor()))
                .value
                .aliasName ??
            'Motor';

        command.onMaxRetriesReached('$motorName: No response from device');
      }
    });
  }

  void _clearPendingCommand(String motorId, int type) {
    final key = '${motorId}_$type';
    final command = _pendingCommands[key];
    if (command != null) {
      command.cancelTimer();
      _pendingCommands.remove(key);
      debugPrint('   Cleared pending: $key');
    }
  }
}
