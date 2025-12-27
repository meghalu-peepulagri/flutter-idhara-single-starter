import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

class MotorData {
  ValueNotifier<bool> controller = ValueNotifier<bool>(false);
  ValueNotifier<int?> modeswitchcontroller = ValueNotifier<int?>(null);
  bool? pendingCommand;

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
  String? groupId;
  String? title;

  int signalStrength = 0;
  int signalBars = 0;
  DateTime? lastSignalUpdate;

  MotorData({
    this.macAddress,
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
    } else if (strength >= 2 && strength <= 9) {
      signalBars = 1;
    } else if (strength >= 10 && strength <= 14) {
      signalBars = 2;
    } else if (strength >= 15 && strength <= 19) {
      signalBars = 3;
    } else if (strength >= 20 && strength <= 30) {
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

// Retry command tracking class
class RetryCommand {
  final String motorId;
  final int commandType; // 1 = motor control, 2 = mode change
  final dynamic commandData;
  final int sequenceNumber;
  int retryCount;
  Timer? retryTimer;
  final Function(String) onMaxRetriesReached;

  RetryCommand({
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

class MqttService {
  static final MqttService _instance = MqttService._internal();

  factory MqttService({Map<String, Motor>? initialMotors}) {
    if (initialMotors != null) {
      _instance.motors = initialMotors;
      _instance._populateMotorDataFromMotors();
    }
    return _instance;
  }

  MqttServerClient? mqttClient;
  late Map<String, MotorData> motorDataMap;
  bool isConnected = false;
  String statusMessage = 'Connecting to MQTT broker...';
  DateTime? lastMessageTime;
  final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);

  Map<String, Motor> motors = {};
  bool _isDataLoaded = false;
  final Map<String, DateTime> _lastAckTimes = {};
  final Map<String, DateTime> _lastCommandTimes = {};

  // Retry mechanism
  final Map<String, RetryCommand> _pendingCommands = {};
  static const int _maxRetries = 2;
  static const Duration _firstRetryDelay = Duration(seconds: 3);
  static const Duration _secondRetryDelay = Duration(seconds: 5);

  // Status message notifier for UI
  final ValueNotifier<String?> commandStatusNotifier =
      ValueNotifier<String?>(null);

  final Random _random = Random();

  MqttService._internal() {
    motorDataMap = {};
  }

  int _generateRandomSequence() {
    return _random.nextInt(251); // Generates 0 to 250 inclusive
  }

  ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;

  void updateMotors(Map<String, Motor> newMotors) {
    motors = newMotors;
    _populateMotorDataFromMotors();
    _dataUpdateNotifier.value++;
  }

  Motor? getMotorByMacAndGroup(String mac, String groupId) {
    final key = '$mac-$groupId';
    return motors[key];
  }

  void _populateMotorDataFromMotors() {
    motorDataMap.clear();
    for (var entry in motors.entries) {
      final motor = entry.value;
      final key = entry.key;

      motorDataMap[key] = MotorData(
        macAddress: motor.starter?.macAddress,
        groupId: key.split('-').last,
        title: motor.name,
      )
        ..state = motor.state ?? 0
        ..motorMode = motor.mode ?? '--'
        ..modeIndex = _getSimplifiedModeIndex(motor.mode ?? '--')
        ..controller.value = motor.state == 1
        ..modeswitchcontroller.value =
            _getSimplifiedModeIndex(motor.mode ?? '--')
        ..hasReceivedData = false;

      if (motor.starter?.starterParameters?.isNotEmpty ?? false) {
        final params = motor.starter!.starterParameters!.first;
        motorDataMap[key]!
          ..voltageRed = params.lineVoltageR?.toString() ?? '0'
          ..voltageYellow = params.lineVoltageY?.toString() ?? '0'
          ..voltageBlue = params.lineVoltageB?.toString() ?? '0'
          ..currentRed = params.currentR?.toString() ?? '0'
          ..currentYellow = params.currentY?.toString() ?? '0'
          ..currentBlue = params.currentB?.toString() ?? '0'
          ..fault = params.fault ?? 0;
      }

      if (motor.starter?.power != null) {
        motorDataMap[key]!.power = motor.starter!.power!;
      }
    }
    _isDataLoaded = true;
    debugPrint('Motor data populated: ${motorDataMap.length} motors');
    _dataUpdateNotifier.value++;
  }

  DateTime? getLastAckTime(String motorId) {
    return _lastAckTimes[motorId];
  }

  int? _getSimplifiedModeIndex(String mode) {
    if (mode.contains('AUTO')) return 1;
    if (mode.contains('MANUAL')) return 0;
    return null;
  }

  String _modeFromSimplifiedIndex(int index) {
    switch (index) {
      case 1:
        return 'REMOTE+AUTO';
      case 0:
        return 'REMOTE+MANUAL';
      default:
        return '--';
    }
  }

  int? _fullModeToSimplified(int fullModeIndex) {
    switch (fullModeIndex) {
      case 0:
      case 2:
        return 0;
      case 1:
      case 3:
        return 1;
      default:
        return null;
    }
  }

  int _simplifiedToFullMode(int simplifiedIndex) {
    switch (simplifiedIndex) {
      case 1:
        return 3;
      case 0:
        return 2;
      default:
        return 3;
    }
  }

  Future<void> resubscribeToTopics() async {
    if (mqttClient == null || !isConnected) {
      debugPrint('⚠️ Cannot resubscribe: MQTT not connected');
      return;
    }

    debugPrint('🔄 Resubscribing to motor topics...');

    // Get unique MAC addresses from current motors
    final Set<String> macAddresses = {};
    for (var motor in motors.values) {
      if (motor.starter?.macAddress != null) {
        macAddresses.add(motor.starter!.macAddress!);
      }
    }

    debugPrint('📡 Found ${macAddresses.length} unique MAC addresses');

    // Subscribe to topics for each MAC address
    for (var mac in macAddresses) {
      try {
        mqttClient!.subscribe('peepul/$mac/cmd', MqttQos.atMostOnce);
        mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
        debugPrint('✓ Subscribed to topics for MAC: $mac');
      } catch (e) {
        debugPrint('✗ Failed to subscribe to MAC $mac: $e');
      }
    }

    debugPrint('✅ Resubscription complete');
    _dataUpdateNotifier.value++;
  }

  Future<void> initializeMqttClient() async {
    if (mqttClient != null && isConnected) {
      debugPrint('Disconnecting existing MQTT client');
      mqttClient!.disconnect();
    }

    const int port = 8883;
    String broker = 'e0be1176.ala.asia-southeast1.emqxsl.com';
    String username = 'ss_user';
    String password = '123456';

    const uuid = Uuid();
    final String clientId = 'idhara_${uuid.v4()}';

    debugPrint('Initializing MQTT client with broker: $broker');

    mqttClient = MqttServerClient(broker, clientId);
    mqttClient!.logging(on: false);
    mqttClient!.keepAlivePeriod = 60;
    mqttClient!.connectTimeoutPeriod = 10000;
    mqttClient!.autoReconnect = true;
    mqttClient!.onConnected = _onConnected;
    mqttClient!.onDisconnected = _onDisconnected;
    mqttClient!.onSubscribed = _onSubscribed;
    mqttClient!.onAutoReconnect = _onAutoReconnect;
    mqttClient!.onAutoReconnected = _onAutoReconnected;
    mqttClient!.secure = true;
    mqttClient!.port = port;

    final connMessage =
        MqttConnectMessage().authenticateAs(username, password).startClean();
    mqttClient!.connectionMessage = connMessage;

    try {
      debugPrint('Connecting to MQTT broker...');
      await mqttClient?.connect();
      debugPrint('MQTT connection initiated');
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
      return;
    }

    mqttClient!.updates!.listen(_onMessageReceived, onError: (e) {
      debugPrint('MQTT Stream Error: $e');
      statusMessage = 'Stream error: $e';
      _dataUpdateNotifier.value++;
    });
  }

  void _onConnected() {
    isConnected = true;
    statusMessage = 'Connected. Subscribing to topics...';
    debugPrint('MQTT Connected successfully');

    int subscriptionCount = 0;
    for (var motor in motors.values) {
      if (motor.starter?.macAddress != null) {
        final mac = motor.starter!.macAddress!;
        mqttClient!.subscribe('peepul/$mac/cmd', MqttQos.atMostOnce);
        mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
        subscriptionCount++;
      }
    }

    debugPrint('Total subscriptions: $subscriptionCount motors');
    _dataUpdateNotifier.value++;
  }

  void _onDisconnected() {
    isConnected = false;
    statusMessage = 'Disconnected. Displaying latest data from API...';
    debugPrint('MQTT Disconnected');

    // Cancel all pending retry timers
    for (var command in _pendingCommands.values) {
      command.cancelTimer();
    }
    _pendingCommands.clear();

    _dataUpdateNotifier.value++;
  }

  void _onSubscribed(String topic) {
    statusMessage = 'Subscribed to $topic';
    debugPrint('Subscribed to topic: $topic');
    _dataUpdateNotifier.value++;
  }

  void _onAutoReconnect() {
    debugPrint('MQTT Auto reconnecting...');
  }

  void _onAutoReconnected() {
    debugPrint('MQTT Auto reconnected');
    for (var motor in motors.values) {
      if (motor.starter?.macAddress != null) {
        final mac = motor.starter!.macAddress!;
        mqttClient!.subscribe('peepul/$mac/cmd', MqttQos.atMostOnce);
        mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
      }
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    lastMessageTime = DateTime.now();
    debugPrint('==== MQTT Messages Received: ${messages.length} ====');

    for (var message in messages) {
      final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message);
      final topic = message.topic;

      debugPrint('Topic: $topic');
      debugPrint('Payload: $payload');

      try {
        final data = jsonDecode(payload);
        final type = data['T'] as int?;
        final payloadData = data['D'];

        debugPrint('Message Type (T): $type');

        if (type == null || payloadData == null) {
          debugPrint('Invalid message: Missing T or D field');
          continue;
        }

        final topicParts = topic.split('/');
        if (topicParts.length < 2) {
          debugPrint('Invalid topic format: $topic');
          continue;
        }
        final mac = topicParts[1];
        debugPrint('Extracted MAC: $mac');

        switch (type) {
          case 31:
            _handleMotorControlAck(mac, payloadData);
            break;
          case 32:
            _handleModeChangeAck(mac, payloadData);
            break;
          case 35:
            _handleLiveData(mac, payloadData);
            break;
          case 40:
            _handleHeartbeat(mac, payloadData);
            break;
          case 41:
            _handleLiveData(mac, payloadData);
            break;
          default:
            debugPrint('Unknown message type: $type');
        }
      } catch (e, stackTrace) {
        statusMessage = 'Invalid data format received';
      }
    }

    debugPrint(
        'Notifying UI update - Current value: ${_dataUpdateNotifier.value}');
    _dataUpdateNotifier.value++;
    debugPrint('New notification value: ${_dataUpdateNotifier.value}');
  }

  void _handleHeartbeat(String mac, dynamic payloadData) {
    debugPrint('=== Heartbeat (Type 40) ===');
    debugPrint('MAC: $mac');
    debugPrint('Payload Data: $payloadData');

    if (payloadData is! Map<String, dynamic>) {
      debugPrint('Invalid heartbeat payload type: ${payloadData.runtimeType}');
      return;
    }

    final signalQuality = payloadData['s_q'] as int?;
    final networkType = payloadData['nwt'] as int?;

    if (signalQuality == null) {
      debugPrint('No signal quality data in heartbeat');
      return;
    }

    debugPrint('Signal Quality: $signalQuality, Network Type: $networkType');

    // Find the specific motor that sent heartbeat
    String? targetMotorId;
    DateTime? latestActivity;

    // First check for motors with pending commands
    for (var entry in motorDataMap.entries) {
      if (entry.key.startsWith(mac)) {
        final hasPending = _pendingCommands.containsKey('${entry.key}_1') ||
            _pendingCommands.containsKey('${entry.key}_2');
        if (hasPending) {
          targetMotorId = entry.key;
          break;
        }
      }
    }

    // If no pending command, find motor with most recent activity
    if (targetMotorId == null) {
      for (var entry in motorDataMap.entries) {
        if (entry.key.startsWith(mac)) {
          final lastAck = _lastAckTimes[entry.key];
          if (lastAck != null &&
              (latestActivity == null || lastAck.isAfter(latestActivity))) {
            latestActivity = lastAck;
            targetMotorId = entry.key;
          }
        }
      }
    }

    // If still no motor found, default to G01
    targetMotorId ??= '$mac-G01';

    // Update ONLY the target motor
    final motorData = motorDataMap[targetMotorId];
    if (motorData != null) {
      motorData.updateSignalStrength(signalQuality);
      motorData.hasReceivedData = true;
      debugPrint(
          '✓ Updated signal for $targetMotorId: $signalQuality (${motorData.signalBars} bars)');
    }

    _dataUpdateNotifier.value++;
  }

  void _handleMotorControlAck(String mac, dynamic payloadData) {
    debugPrint('=== Motor Control ACK (Type 31) ===');
    debugPrint('MAC: $mac');
    debugPrint('Payload Data: $payloadData');

    final newState = payloadData as int?;

    if (newState == null) {
      debugPrint('Invalid state in ACK: $payloadData');
      return;
    }

    // Find the motor that either:
    // 1. Has a pending command (user initiated)
    // 2. Matches this MAC (device initiated)
    String? targetMotorId;
    bool hasPendingCommand = false;

    // First, check for pending command
    for (var entry in motorDataMap.entries) {
      if (entry.key.startsWith(mac)) {
        final hasPending = _pendingCommands.containsKey('${entry.key}_1');
        if (hasPending) {
          targetMotorId = entry.key;
          hasPendingCommand = true;
          break;
        }
      }
    }

    // If no pending command, find the motor from live data or default to G01
    if (targetMotorId == null) {
      // Check if any motor with this MAC has recent activity
      DateTime? latestActivity;
      for (var entry in motorDataMap.entries) {
        if (entry.key.startsWith(mac)) {
          final lastAck = _lastAckTimes[entry.key];
          if (lastAck != null &&
              (latestActivity == null || lastAck.isAfter(latestActivity))) {
            latestActivity = lastAck;
            targetMotorId = entry.key;
          }
        }
      }

      // If still no motor found, default to G01
      targetMotorId ??= '$mac-G01';

      debugPrint(
          '⚠️ No pending command - ACK from device. Updating $targetMotorId');
    }

    // Update the motor state
    final motorData = motorDataMap[targetMotorId];
    if (motorData != null) {
      motorData.state = newState;
      motorData.controller.value = (newState == 1);
      motorData.hasReceivedData = true;
      _lastAckTimes[targetMotorId] = DateTime.now();

      // Clear pending command if it exists
      if (hasPendingCommand) {
        _clearPendingCommand(targetMotorId, 1);
        debugPrint(
            '✓ Updated $targetMotorId state to $newState (from user command)');
      } else {
        debugPrint('✓ Updated $targetMotorId state to $newState (from device)');
      }
    }

    _dataUpdateNotifier.value++;
  }

  void _handleModeChangeAck(String mac, dynamic payloadData) {
    debugPrint('=== Mode Change ACK (Type 32) ===');
    debugPrint('MAC: $mac');
    debugPrint('Payload Data: $payloadData');

    final newModeIndex = payloadData as int?;

    if (newModeIndex == null || (newModeIndex != 0 && newModeIndex != 1)) {
      debugPrint('Invalid mode in ACK: $payloadData (expected 0 or 1)');
      return;
    }

    // Find the motor that either has pending command or matches MAC
    String? targetMotorId;
    bool hasPendingCommand = false;

    // First, check for pending mode command
    for (var entry in motorDataMap.entries) {
      if (entry.key.startsWith(mac)) {
        final hasPending = _pendingCommands.containsKey('${entry.key}_2');
        if (hasPending) {
          targetMotorId = entry.key;
          hasPendingCommand = true;
          break;
        }
      }
    }

    // If no pending command, find motor from recent activity or default to G01
    if (targetMotorId == null) {
      DateTime? latestActivity;
      for (var entry in motorDataMap.entries) {
        if (entry.key.startsWith(mac)) {
          final lastAck = _lastAckTimes[entry.key];
          if (lastAck != null &&
              (latestActivity == null || lastAck.isAfter(latestActivity))) {
            latestActivity = lastAck;
            targetMotorId = entry.key;
          }
        }
      }

      targetMotorId ??= '$mac-G01';

      debugPrint(
          '⚠️ No pending mode command - ACK from device. Updating $targetMotorId');
    }

    // Update the motor mode
    final motorData = motorDataMap[targetMotorId];
    if (motorData != null) {
      motorData.modeIndex = newModeIndex;
      motorData.modeswitchcontroller.value = newModeIndex;
      motorData.motorMode = newModeIndex == 1 ? 'AUTO' : 'MANUAL';
      motorData.hasReceivedData = true;
      _lastAckTimes[targetMotorId] = DateTime.now();

      if (hasPendingCommand) {
        _clearPendingCommand(targetMotorId, 2);
        debugPrint(
            '✓ Updated $targetMotorId mode to $newModeIndex (from user command)');
      } else {
        debugPrint(
            '✓ Updated $targetMotorId mode to $newModeIndex (from device)');
      }
    }

    _dataUpdateNotifier.value++;
  }

  // void _handleLiveData(String mac, dynamic payloadData) {
  //   debugPrint('_handleLiveData called for MAC: $mac');

  //   if (payloadData is! Map<String, dynamic>) {
  //     debugPrint('Invalid payload data type: ${payloadData.runtimeType}');
  //     return;
  //   }

  //   int updatedMotors = 0;

  //   for (var entry in payloadData.entries) {
  //     final groupId = entry.key;
  //     if (groupId == 'ct') continue;

  //     debugPrint('Processing group: $groupId');

  //     final groupData = entry.value as Map<String, dynamic>?;
  //     if (groupData == null) {
  //       debugPrint('Group data is null for $groupId');
  //       continue;
  //     }

  //     final fullMotorId = '$mac-$groupId';
  //     debugPrint('Full Motor ID: $fullMotorId');

  //     var motorData = motorDataMap[fullMotorId];
  //     if (motorData == null) {
  //       debugPrint('Creating new MotorData for $fullMotorId');
  //       motorData =
  //           MotorData(macAddress: mac, groupId: groupId, title: groupId);
  //       motorDataMap[fullMotorId] = motorData;
  //     }

  //     debugPrint('Group data keys: ${groupData.keys}');

  //     if (groupData.containsKey('p_v')) {
  //       debugPrint('Processing $groupId with full data');

  //       final newState = groupData['m_s'] ?? 0;
  //       motorData.state = newState;
  //       if (motorData.controller.value != (newState == 1)) {
  //         motorData.controller.value = (newState == 1);
  //       }

  //       final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
  //       motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
  //       motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
  //       motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';

  //       final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
  //       motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
  //       motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
  //       motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';

  //       motorData.power = groupData['pwr'] ?? 0;
  //       motorData.fault = groupData['flt'] ?? 0;
  //       motorData.alert = groupData['alt'] ?? 0;

  //       if (groupData.containsKey('mode')) {
  //         final modeValue = groupData['mode'] as int?;
  //         if (modeValue != null) {
  //           motorData.modeIndex = modeValue;
  //           motorData.modeswitchcontroller.value = modeValue;
  //           motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
  //         }
  //       }
  //     } else if (groupData.containsKey('pwr')) {
  //       debugPrint('Processing $groupId with partial data');

  //       motorData.power = groupData['pwr'] ?? 0;

  //       if (groupData.containsKey('mode')) {
  //         final modeValue = groupData['mode'] as int?;
  //         if (modeValue != null) {
  //           motorData.modeIndex = modeValue;
  //           motorData.modeswitchcontroller.value = modeValue;
  //           motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
  //         }
  //       }

  //       if (groupData.containsKey('llv')) {
  //         final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
  //         motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
  //         motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
  //         motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
  //       }

  //       if (groupData.containsKey('amp')) {
  //         final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
  //         motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
  //         motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
  //         motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
  //       }

  //       if (groupData.containsKey('m_s')) {
  //         motorData.state = groupData['m_s'] ?? 0;
  //         motorData.controller.value = motorData.state == 1;
  //         debugPrint('Updated motor state: ${motorData.state}');
  //       }
  //     } else if (groupData.containsKey('mode')) {
  //       if (groupData.containsKey('pwr')) {
  //         motorData.power = groupData['pwr'] ?? 0;
  //         debugPrint('Updated power: ${motorData.power}');
  //       }

  //       final modeValue = groupData['mode'] as int?;
  //       if (modeValue != null) {
  //         motorData.modeIndex = modeValue;
  //         motorData.modeswitchcontroller.value = modeValue;
  //         motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
  //       }

  //       if (groupData.containsKey('llv')) {
  //         final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
  //         motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
  //         motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
  //         motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
  //       }

  //       if (groupData.containsKey('amp')) {
  //         final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
  //         motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
  //         motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
  //         motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
  //       }
  //     } else {
  //       debugPrint('Unknown payload structure for $groupId: ${groupData.keys}');
  //     }

  //     motorData.hasReceivedData = true;
  //     motorDataMap[fullMotorId] = motorData;
  //     _lastAckTimes[fullMotorId] = DateTime.now();
  //   }

  //   debugPrint('Total motors in map: ${motorDataMap.length}');
  //   _dataUpdateNotifier.value++;
  // }
  void _handleLiveData(String mac, dynamic payloadData) {
    debugPrint('_handleLiveData called for MAC: $mac');

    if (payloadData is! Map<String, dynamic>) {
      debugPrint('Invalid payload data type: ${payloadData.runtimeType}');
      return;
    }

    int updatedMotors = 0;

    for (var entry in payloadData.entries) {
      final groupId = entry.key;
      if (groupId == 'ct') continue;

      debugPrint('Processing group: $groupId');

      final groupData = entry.value as Map<String, dynamic>?;
      if (groupData == null) {
        debugPrint('Group data is null for $groupId');
        continue;
      }

      final fullMotorId = '$mac-$groupId';
      debugPrint('Full Motor ID: $fullMotorId');

      var motorData = motorDataMap[fullMotorId];
      if (motorData == null) {
        debugPrint('Creating new MotorData for $fullMotorId');
        motorData =
            MotorData(macAddress: mac, groupId: groupId, title: groupId);
        motorDataMap[fullMotorId] = motorData;
      }

      debugPrint('Group data keys: ${groupData.keys}');

      if (groupData.containsKey('p_v')) {
        debugPrint('Processing $groupId with full data');

        final newState = (groupData['m_s'] ?? groupData['mtr_sts']) ?? 0;
        motorData.state = newState;
        if (motorData.controller.value != (newState == 1)) {
          motorData.controller.value = (newState == 1);
        }

        final llv = (groupData['llv'] ?? groupData['ll_v']) as List<dynamic>? ??
            [0, 0, 0];
        motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
        motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
        motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';

        final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
        motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
        motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
        motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';

        motorData.power = groupData['pwr'] ?? 0;
        motorData.fault = groupData['flt'] ?? 0;
        motorData.alert = groupData['alt'] ?? 0;

        if (groupData.containsKey('mode')) {
          final modeValue = groupData['mode'] as int?;
          if (modeValue != null) {
            motorData.modeIndex = modeValue;
            motorData.modeswitchcontroller.value = modeValue;
            motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
          }
        }
      } else if (groupData.containsKey('pwr')) {
        debugPrint('Processing $groupId with partial data');

        motorData.power = groupData['pwr'] ?? 0;

        if (groupData.containsKey('mode')) {
          final modeValue = groupData['mode'] as int?;
          if (modeValue != null) {
            motorData.modeIndex = modeValue;
            motorData.modeswitchcontroller.value = modeValue;
            motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
          }
        }

        if (groupData.containsKey('llv') || groupData.containsKey('ll_v')) {
          final llv =
              (groupData['llv'] ?? groupData['ll_v']) as List<dynamic>? ??
                  [0, 0, 0];
          motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
          motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
          motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
        }

        // FIXED: Reset current values to 0 if 'amp' is not present
        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
        } else {
          // No amp data in payload - set all currents to 0
          motorData.currentRed = '0';
          motorData.currentYellow = '0';
          motorData.currentBlue = '0';
          debugPrint(
              'No amp data in payload - reset currents to 0 for $groupId');
        }

        if (groupData.containsKey('m_s') || groupData.containsKey('mtr_sts')) {
          motorData.state = (groupData['m_s'] ?? groupData['mtr_sts']) ?? 0;
          motorData.controller.value = motorData.state == 1;
          debugPrint('Updated motor state: ${motorData.state}');
        }
      } else if (groupData.containsKey('mode')) {
        if (groupData.containsKey('pwr')) {
          motorData.power = groupData['pwr'] ?? 0;
          debugPrint('Updated power: ${motorData.power}');
        }

        final modeValue = groupData['mode'] as int?;
        if (modeValue != null) {
          motorData.modeIndex = modeValue;
          motorData.modeswitchcontroller.value = modeValue;
          motorData.motorMode = modeValue == 1 ? 'AUTO' : 'MANUAL';
        }

        if (groupData.containsKey('llv') || groupData.containsKey('ll_v')) {
          final llv =
              (groupData['llv'] ?? groupData['ll_v']) as List<dynamic>? ??
                  [0, 0, 0];
          motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
          motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
          motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
        }

        // FIXED: Reset current values to 0 if 'amp' is not present
        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
        } else {
          // No amp data in payload - set all currents to 0
          motorData.currentRed = '0';
          motorData.currentYellow = '0';
          motorData.currentBlue = '0';
          debugPrint(
              'No amp data in payload - reset currents to 0 for $groupId');
        }
      } else {
        debugPrint('Unknown payload structure for $groupId: ${groupData.keys}');
      }

      motorData.hasReceivedData = true;
      motorDataMap[fullMotorId] = motorData;
      _lastAckTimes[fullMotorId] = DateTime.now();
    }

    debugPrint('Total motors in map: ${motorDataMap.length}');
    _dataUpdateNotifier.value++;
  }

  Map<String, MotorData> getMotorDataForLocation(int? locationId) {
    if (locationId == null) {
      return motorDataMap;
    }

    final result = Map<String, MotorData>.fromEntries(
      motorDataMap.entries.where((entry) {
        final motor = motors[entry.key];
        return motor?.location?.id == locationId;
      }),
    );

    return result;
  }

  // Clear pending command and cancel retry timer
  void _clearPendingCommand(String motorId, int commandType) {
    final key = '${motorId}_$commandType';
    final command = _pendingCommands[key];
    if (command != null) {
      debugPrint(
          '✓ ACK received for $motorId (type $commandType), canceling retry timer');
      command.cancelTimer();
      _pendingCommands.remove(key);
    }
  }

  // Schedule retry for a command
  void _scheduleRetry(String motorId, int commandType, dynamic commandData,
      int sequenceNumber) {
    final key = '${motorId}_$commandType';

    final command = _pendingCommands[key] ??
        RetryCommand(
          motorId: motorId,
          commandType: commandType,
          commandData: commandData,
          sequenceNumber: sequenceNumber,
          onMaxRetriesReached: (String message) {
            commandStatusNotifier.value = message;
            _dataUpdateNotifier.value++;
          },
        );

    final retryDelay =
        command.retryCount == 0 ? _firstRetryDelay : _secondRetryDelay;
    final delaySeconds = command.retryCount == 0 ? 5 : 3;

    command.retryTimer = Timer(retryDelay, () async {
      if (command.retryCount < _maxRetries) {
        command.retryCount++;
        debugPrint(
            '⏱ Retry ${command.retryCount}/$_maxRetries for $motorId (type $commandType) after ${delaySeconds}s');

        try {
          if (commandType == 1) {
            await _publishMotorCommandInternal(motorId, commandData as int,
                sequenceNumber: command.sequenceNumber, isRetry: true);
          } else if (commandType == 2) {
            await _publishModeCommandInternal(motorId, commandData as int,
                sequenceNumber: command.sequenceNumber, isRetry: true);
          }

          _scheduleRetry(
              motorId, commandType, commandData, command.sequenceNumber);
        } catch (e) {
          debugPrint('✗ Retry failed for $motorId: $e');
          _pendingCommands.remove(key);
        }
      } else {
        debugPrint('❌ Max retries reached for $motorId (type $commandType)');

        // Remove pending command so future ACKs can still update
        _pendingCommands.remove(key);

        final motorName = motors.entries
                .firstWhere((e) => e.key.startsWith(motorId.split('-')[0]),
                    orElse: () => MapEntry('', Motor()))
                .value
                .aliasName ??
            'Motor';

        final commandTypeName = commandType == 1 ? 'switch' : 'mode';
        command.onMaxRetriesReached('Failed $motorName to publish.');

        debugPrint(
            '⚠️ Pending command removed. Will accept ACK if it arrives later.');
      }
    });

    _pendingCommands[key] = command;
  }

  // Internal publish method for motor control
  Future<void> _publishMotorCommandInternal(String motorId, int state,
      {int? sequenceNumber, bool isRetry = false}) async {
    if (mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }

    final parts = motorId.split('-');
    if (parts.length != 2) {
      throw Exception('Invalid motorId format: $motorId');
    }

    final mac = parts[0];
    final topic = 'peepul/$mac/cmd';

    final seq = sequenceNumber ?? _generateRandomSequence();

    final payload = {
      "T": 1,
      "S": seq,
      "D": state,
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    if (!isRetry) {
      debugPrint('📤 Motor command sent for $motorId (state: $state)');
      debugPrint('📤 Payload: $message');
    } else {
      debugPrint('🔄 Motor command retry sent for $motorId (state: $state)');
    }
  }

  // Internal publish method for mode control
  Future<void> _publishModeCommandInternal(String motorId, int simplifiedMode,
      {int? sequenceNumber, bool isRetry = false}) async {
    if (mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }

    final parts = motorId.split('-');
    if (parts.length != 2) {
      throw Exception('Invalid motorId format: $motorId');
    }

    final mac = parts[0];
    final topic = 'peepul/$mac/cmd';

    final seq = sequenceNumber ?? _generateRandomSequence();

    final payload = {
      "T": 2,
      "S": seq,
      "D": simplifiedMode,
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    if (!isRetry) {
      debugPrint('📤 Mode command sent for $motorId (mode: $simplifiedMode)');
      debugPrint('📤 Payload: $message');
    } else {
      debugPrint(
          '🔄 Mode command retry sent for $motorId (mode: $simplifiedMode)');
    }
  }

  Future<void> publishMotorCommand(String motorId, int state) async {
    if (mqttClient == null || !isConnected) {
      debugPrint('Cannot publish: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      return;
    }

    final lastCommandTime = _lastCommandTimes[motorId];
    if (lastCommandTime != null &&
        DateTime.now().difference(lastCommandTime).inSeconds < 2) {
      debugPrint('Command throttled for $motorId');
      return;
    }

    _lastAckTimes.remove(motorId);
    _lastCommandTimes[motorId] = DateTime.now();

    final sequenceNumber = _generateRandomSequence();

    try {
      await _publishMotorCommandInternal(motorId, state,
          sequenceNumber: sequenceNumber);
      statusMessage = 'Motor command sent successfully';

      // Schedule retry mechanism
      _scheduleRetry(motorId, 1, state, sequenceNumber);
    } catch (e) {
      statusMessage = 'Failed to publish motor command: $e';
      _lastCommandTimes.remove(motorId);
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> publishModeCommand(String motorId, int simplifiedMode) async {
    if (mqttClient == null || !isConnected) {
      debugPrint('Cannot publish: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      return;
    }

    _lastAckTimes.remove(motorId);

    final sequenceNumber = _generateRandomSequence();

    try {
      await _publishModeCommandInternal(motorId, simplifiedMode,
          sequenceNumber: sequenceNumber);
      statusMessage = 'Motor command sent successfully';

      _scheduleRetry(motorId, 2, simplifiedMode, sequenceNumber);
    } catch (e) {
      statusMessage = 'Failed to publish motor command: $e';
      _lastCommandTimes.remove(motorId);
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  void dispose() {
    mqttClient?.disconnect();
    for (var motorData in motorDataMap.values) {
      motorData.dispose();
    }
  }
}
