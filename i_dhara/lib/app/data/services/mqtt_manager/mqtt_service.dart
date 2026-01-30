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
  int? hvf;
  int? lvf;
  int power = 0;
  int fault = 0;
  int alert = 0;

  String runTime = '-';
  bool hasReceivedData = false;
  String? macAddress;
  String? pcbNumber;
  String? groupId;
  String? title;

  // NEW: Track which identifier is actually working
  String? activeIdentifier;
  IdentifierType? activeIdentifierType;

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

enum IdentifierType { mac, pcb }

class RetryCommand {
  final String motorId;
  final int commandType;
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
  final StreamController<Map<String, dynamic>> defaultSettingsController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get settingstream =>
      defaultSettingsController.stream;
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

  // NEW: Track which identifier-group combinations have received data
  final Map<String, String> _workingIdentifiers =
      {}; // motorKey -> actual working identifier-group

  final Map<String, RetryCommand> _pendingCommands = {};
  static const int _maxRetries = 2;
  static const Duration _firstRetryDelay = Duration(seconds: 5);
  static const Duration _secondRetryDelay = Duration(seconds: 3);

  final ValueNotifier<String?> commandStatusNotifier =
      ValueNotifier<String?>(null);
  final Random _random = Random();

  MqttService._internal() {
    motorDataMap = {};
  }

  int _generateRandomSequence() {
    return _random.nextInt(251);
  }

  ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;

  void updateMotors(Map<String, Motor> newMotors) {
    motors = newMotors;
    _populateMotorDataFromMotors();
    _dataUpdateNotifier.value++;
  }

  Motor? getMotorByMacAndGroup(String identifier, String groupId) {
    final key = '$identifier-$groupId';
    return motors[key];
  }

  void _populateMotorDataFromMotors() {
    motorDataMap.clear();
    for (var entry in motors.entries) {
      final motor = entry.value;
      final key = entry.key;

      final parts = key.split('-');
      final identifier = parts[0];
      final groupId = parts.length > 1 ? parts[1] : 'G01';

      motorDataMap[key] = MotorData(
        macAddress: motor.starter?.macAddress,
        pcbNumber: motor.starter?.pcbNumber,
        groupId: groupId,
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

  // NEW: Get the working identifier for a motor
  String? getWorkingIdentifier(String motorKey) {
    return _workingIdentifiers[motorKey];
  }

  Future<void> resubscribeToTopics() async {
    if (mqttClient == null || !isConnected) {
      return;
    }

    final Set<String> subscribedIdentifiers = {};

    for (var motor in motors.values) {
      if (motor.starter != null) {
        final mac = motor.starter!.macAddress;
        final pcb = motor.starter!.pcbNumber;

        if (mac != null &&
            mac.isNotEmpty &&
            !subscribedIdentifiers.contains(mac)) {
          try {
            mqttClient!.subscribe('peepul/$mac/cmd', MqttQos.atMostOnce);
            mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
            subscribedIdentifiers.add(mac);
            debugPrint('✓ Resubscribed to MAC: $mac');
          } catch (e) {
            debugPrint('✗ Failed to resubscribe to MAC $mac: $e');
          }
        }

        if (pcb != null &&
            pcb.isNotEmpty &&
            !subscribedIdentifiers.contains(pcb)) {
          try {
            mqttClient!.subscribe('peepul/$pcb/cmd', MqttQos.atMostOnce);
            mqttClient!.subscribe('peepul/$pcb/status', MqttQos.atMostOnce);
            subscribedIdentifiers.add(pcb);
            debugPrint('✓ Resubscribed to PCB: $pcb');
          } catch (e) {
            debugPrint('✗ Failed to resubscribe to PCB $pcb: $e');
          }
        }
      }
    }

    debugPrint(
        '✓ Resubscription complete: ${subscribedIdentifiers.length} identifiers');
    _dataUpdateNotifier.value++;
  }

  Future<void> initializeMqttClient() async {
    if (mqttClient != null && isConnected) {
      mqttClient!.disconnect();
    }

    const int port = 8883;
    String broker = 'e0be1176.ala.asia-southeast1.emqxsl.com';
    String username = 'ss_user';
    String password = '123456';

    const uuid = Uuid();
    final String clientId = 'idhara_${uuid.v4()}';

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
      await mqttClient?.connect();
      debugPrint('✓ MQTT connection initiated');
    } catch (e) {
      debugPrint('✗ MQTT Connection Error: $e');
      return;
    }

    mqttClient!.updates!.listen(_onMessageReceived, onError: (e) {
      statusMessage = 'Stream error: $e';
      _dataUpdateNotifier.value++;
    });
  }

  void _onConnected() {
    isConnected = true;
    statusMessage = 'Connected. Subscribing to topics...';
    debugPrint('✓ MQTT Connected successfully');

    int subscriptionCount = 0;
    Set<String> subscribedIdentifiers = {};

    for (var motor in motors.values) {
      if (motor.starter != null) {
        final mac = motor.starter!.macAddress;
        final pcb = motor.starter!.pcbNumber;

        if (mac != null &&
            mac.isNotEmpty &&
            !subscribedIdentifiers.contains(mac)) {
          mqttClient!.subscribe('peepul/$mac/cmd', MqttQos.atMostOnce);
          mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
          subscribedIdentifiers.add(mac);
          subscriptionCount++;
          debugPrint('✓ Subscribed to MAC: $mac');
        }

        if (pcb != null &&
            pcb.isNotEmpty &&
            !subscribedIdentifiers.contains(pcb)) {
          mqttClient!.subscribe('peepul/$pcb/cmd', MqttQos.atMostOnce);
          mqttClient!.subscribe('peepul/$pcb/status', MqttQos.atMostOnce);
          subscribedIdentifiers.add(pcb);
          subscriptionCount++;
          debugPrint('✓ Subscribed to PCB: $pcb');
        }
      }
    }

    debugPrint('✓ Total subscriptions: $subscriptionCount identifiers');
    _dataUpdateNotifier.value++;
  }

  void _onDisconnected() {
    isConnected = false;
    statusMessage = 'Disconnected. Displaying latest data from API...';
    debugPrint('✗ MQTT Disconnected');

    for (var command in _pendingCommands.values) {
      command.cancelTimer();
    }
    _pendingCommands.clear();

    _dataUpdateNotifier.value++;
  }

  void _onSubscribed(String topic) {
    statusMessage = 'Subscribed to $topic';
    debugPrint('✓ Subscribed to topic: $topic');
    _dataUpdateNotifier.value++;
  }

  void _onAutoReconnect() {
    debugPrint('⟳ MQTT Auto reconnecting...');
  }

  void _onAutoReconnected() {
    isConnected = true;
    statusMessage = 'Connected. Subscribing to topics...';
    debugPrint('✓ MQTT Auto-reconnected successfully');

    int subscriptionCount = 0;
    Set<String> subscribedIdentifiers = {};

    for (var motor in motors.values) {
      if (motor.starter != null) {
        final mac = motor.starter!.macAddress;
        final pcb = motor.starter!.pcbNumber;

        if (mac != null &&
            mac.isNotEmpty &&
            !subscribedIdentifiers.contains(mac)) {
          mqttClient!.subscribe('peepul/$mac/cmd', MqttQos.atMostOnce);
          mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
          subscribedIdentifiers.add(mac);
          subscriptionCount++;
          debugPrint('✓ Resubscribed to MAC: $mac');
        }

        if (pcb != null &&
            pcb.isNotEmpty &&
            !subscribedIdentifiers.contains(pcb)) {
          mqttClient!.subscribe('peepul/$pcb/cmd', MqttQos.atMostOnce);
          mqttClient!.subscribe('peepul/$pcb/status', MqttQos.atMostOnce);
          subscribedIdentifiers.add(pcb);
          subscriptionCount++;
          debugPrint('✓ Resubscribed to PCB: $pcb');
        }
      }
    }

    debugPrint('✓ Total resubscriptions: $subscriptionCount identifiers');
    _dataUpdateNotifier.value++;
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    lastMessageTime = DateTime.now();
    debugPrint('==== MQTT Messages Received: ${messages.length} ====');

    for (var message in messages) {
      final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message);
      final topic = message.topic;

      try {
        final data = jsonDecode(payload);
        final type = data['T'] as int?;
        final payloadData = data['D'];

        if (type == null || payloadData == null) {
          continue;
        }

        final topicParts = topic.split('/');
        if (topicParts.length < 2) {
          continue;
        }
        final identifier = topicParts[1];

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
            _handleLiveData(identifier, payloadData);
            break;
          case 40:
            _handleHeartbeat(identifier, payloadData);
            break;
          case 41:
            _handleLiveData(identifier, payloadData);
            break;
          default:
            debugPrint('Unknown message type: $type');
        }
      } catch (e, stackTrace) {
        debugPrint('✗ Error processing message: $e');
        statusMessage = 'Invalid data format received';
      }
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

  void _handleHeartbeat(String identifier, dynamic payloadData) {
    if (payloadData is! Map<String, dynamic>) {
      return;
    }

    final signalQuality = payloadData['s_q'] as int?;
    final networkType = payloadData['nwt'] as int?;

    if (signalQuality == null) {
      return;
    }

    // Find the specific motor that sent heartbeat
    String? targetMotorId;
    DateTime? latestActivity;

    // First check for motors with pending commands
    for (var entry in motorDataMap.entries) {
      final motorData = entry.value;
      final matchesMac = motorData.macAddress == identifier;
      final matchesPcb = motorData.pcbNumber == identifier;

      if (matchesMac || matchesPcb) {
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
        final motorData = entry.value;
        final matchesMac = motorData.macAddress == identifier;
        final matchesPcb = motorData.pcbNumber == identifier;

        if (matchesMac || matchesPcb) {
          final lastAck = _lastAckTimes[entry.key];
          if (lastAck != null &&
              (latestActivity == null || lastAck.isAfter(latestActivity))) {
            latestActivity = lastAck;
            targetMotorId = entry.key;
          }
        }
      }
    }

    // If still no motor found, find any motor with this identifier and default to G01
    if (targetMotorId == null) {
      for (var entry in motorDataMap.entries) {
        final motorData = entry.value;
        if (motorData.macAddress == identifier ||
            motorData.pcbNumber == identifier) {
          targetMotorId = entry.key;
          break;
        }
      }

      // Last resort: construct G01 key
      targetMotorId ??= '$identifier-G01';
    }

    // Update ONLY the target motor
    final motorData = motorDataMap[targetMotorId];
    if (motorData != null) {
      motorData.updateSignalStrength(signalQuality);
      motorData.hasReceivedData = true;
    }

    _dataUpdateNotifier.value++;
  }

  void _handleMotorControlAck(String identifier, dynamic payloadData) {
    final newState = payloadData as int?;
    if (newState == null) return;

    // Find motor with pending command for this identifier
    String? targetMotorId;

    for (var entry in motorDataMap.entries) {
      final motorData = entry.value;
      final matchesMac = motorData.macAddress == identifier;
      final matchesPcb = motorData.pcbNumber == identifier;

      if (matchesMac || matchesPcb) {
        final hasPending = _pendingCommands.containsKey('${entry.key}_1');
        if (hasPending) {
          targetMotorId = entry.key;
          break;
        }
      }
    }

    // If no pending command, update the motor with working identifier
    if (targetMotorId == null) {
      targetMotorId = _workingIdentifiers.entries
          .firstWhere((e) => e.value.startsWith(identifier),
              orElse: () => const MapEntry('', ''))
          .key;

      if (targetMotorId.isEmpty) {
        // Find any motor with this identifier
        for (var entry in motorDataMap.entries) {
          final motorData = entry.value;
          if (motorData.macAddress == identifier ||
              motorData.pcbNumber == identifier) {
            targetMotorId = entry.key;
            break;
          }
        }
      }
    }

    if (targetMotorId != null && targetMotorId.isNotEmpty) {
      final motorData = motorDataMap[targetMotorId];
      if (motorData != null) {
        motorData.state = newState;
        motorData.controller.value = (newState == 1);
        motorData.hasReceivedData = true;
        _lastAckTimes[targetMotorId] = DateTime.now();

        // Track working identifier
        final parts = targetMotorId.split('-');
        _workingIdentifiers[targetMotorId] =
            identifier + (parts.length > 1 ? '-${parts[1]}' : '');

        _clearPendingCommand(targetMotorId, 1);
        debugPrint('✓ Motor control ACK for $targetMotorId: state=$newState');
      }
    }

    _dataUpdateNotifier.value++;
  }

  void _handleModeChangeAck(String identifier, dynamic payloadData) {
    final newModeIndex = payloadData as int?;

    if (newModeIndex == null || (newModeIndex != 0 && newModeIndex != 1)) {
      return;
    }
    String? targetMotorId;
    bool hasPendingCommand = false;

    // First, check for pending mode command
    for (var entry in motorDataMap.entries) {
      final motorData = entry.value;
      final matchesMac = motorData.macAddress == identifier;
      final matchesPcb = motorData.pcbNumber == identifier;

      if (matchesMac || matchesPcb) {
        final hasPending = _pendingCommands.containsKey('${entry.key}_2');
        if (hasPending) {
          targetMotorId = entry.key;
          hasPendingCommand = true;
          break;
        }
      }
    }

    // If no pending command, find motor from working identifiers
    if (targetMotorId == null) {
      final workingEntry = _workingIdentifiers.entries.firstWhere(
          (e) => e.value.startsWith(identifier),
          orElse: () => const MapEntry('', ''));

      if (workingEntry.key.isNotEmpty) {
        targetMotorId = workingEntry.key;
      }
    }

    // If not in working identifiers, find from recent activity
    if (targetMotorId == null) {
      DateTime? latestActivity;
      for (var entry in motorDataMap.entries) {
        final motorData = entry.value;
        final matchesMac = motorData.macAddress == identifier;
        final matchesPcb = motorData.pcbNumber == identifier;

        if (matchesMac || matchesPcb) {
          final lastAck = _lastAckTimes[entry.key];
          if (lastAck != null &&
              (latestActivity == null || lastAck.isAfter(latestActivity))) {
            latestActivity = lastAck;
            targetMotorId = entry.key;
          }
        }
      }
    }

    // Last resort: default to G01
    targetMotorId ??= '$identifier-G01';

    // Update the motor mode
    if (motorDataMap.containsKey(targetMotorId)) {
      final motorData = motorDataMap[targetMotorId]!;
      motorData.modeIndex = newModeIndex;
      motorData.modeswitchcontroller.value = newModeIndex;
      motorData.motorMode = newModeIndex == 1 ? 'AUTO' : 'MANUAL';
      motorData.hasReceivedData = true;
      _lastAckTimes[targetMotorId] = DateTime.now();
      final parts = targetMotorId.split('-');
      _workingIdentifiers[targetMotorId] =
          identifier + (parts.length > 1 ? '-${parts[1]}' : '');
      _clearPendingCommand(targetMotorId, 2);
      debugPrint(
          '✓ Mode change ACK for $targetMotorId: mode=$newModeIndex, hasPending=$hasPendingCommand (identifier: $identifier)');
    }
    _dataUpdateNotifier.value++;
  }

  void _handleLiveData(String identifier, dynamic payloadData) {
    if (payloadData is! Map<String, dynamic>) {
      return;
    }

    int updatedMotors = 0;

    for (var entry in payloadData.entries) {
      final groupId = entry.key;
      if (groupId == 'ct') continue;

      final groupData = entry.value as Map<String, dynamic>?;
      if (groupData == null) {
        continue;
      }

      final fullMotorId = '$identifier-$groupId';
      final isG04 = groupId == 'G04'; // Check if this is G04

      var motorData = motorDataMap[fullMotorId];
      if (motorData == null) {
        motorData =
            MotorData(macAddress: identifier, groupId: groupId, title: groupId);
        motorDataMap[fullMotorId] = motorData;
      }

      if (groupData.containsKey('p_v')) {
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

        // For G04: preserve existing values if 'amp' is not present
        // For others: reset to 0 if 'amp' is not present
        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
        } else if (!isG04) {
          // Reset to 0 only for non-G04 groups
          motorData.currentRed = '0';
          motorData.currentYellow = '0';
          motorData.currentBlue = '0';
        }
        // For G04: don't reset currents if 'amp' is not present - preserve existing values

        if (groupData.containsKey('flt')) {
          motorData.fault = groupData['flt'] ?? 0;
        } else if (!isG04) {
          motorData.fault = 0;
        }
        // For G04: don't reset fault if not present

        if (groupData.containsKey('alt')) {
          motorData.alert = groupData['alt'] ?? 0;
        } else if (!isG04) {
          motorData.alert = 0;
        }
        // For G04: don't reset alert if not present

        if (groupData.containsKey('m_s') || groupData.containsKey('mtr_sts')) {
          motorData.state = (groupData['m_s'] ?? groupData['mtr_sts']) ?? 0;
          motorData.controller.value = motorData.state == 1;
        }
      } else if (groupData.containsKey('mode')) {
        if (groupData.containsKey('pwr')) {
          motorData.power = groupData['pwr'] ?? 0;
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
        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
        } else if (!isG04) {
          // Reset to 0 only for non-G04 groups
          motorData.currentRed = '0';
          motorData.currentYellow = '0';
          motorData.currentBlue = '0';
        }

        if (groupData.containsKey('flt')) {
          motorData.fault = groupData['flt'] ?? 0;
        } else if (!isG04) {
          motorData.fault = 0;
        }

        if (groupData.containsKey('alt')) {
          motorData.alert = groupData['alt'] ?? 0;
        } else if (!isG04) {
          motorData.alert = 0;
        }
      } else {}

      motorData.hasReceivedData = true;
      motorDataMap[fullMotorId] = motorData;
      _lastAckTimes[fullMotorId] = DateTime.now();
    }

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

  void _clearPendingCommand(String motorId, int commandType) {
    final key = '${motorId}_$commandType';
    final command = _pendingCommands[key];
    if (command != null) {
      command.cancelTimer();
      _pendingCommands.remove(key);
      debugPrint(
          '✓ ACK received for $motorId (type $commandType), canceling retry timer');
    }
  }

  void _scheduleRetry(String motorId, int commandType, dynamic commandData,
      int sequenceNumber, int lvf, int hvf, String pcb, int drf, int olf) {
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
    command.retryTimer = Timer(retryDelay, () async {
      if (command.retryCount < _maxRetries) {
        command.retryCount++;
        try {
          if (commandType == 1) {
            await _publishMotorCommandInternal(motorId, commandData as int,
                sequenceNumber: command.sequenceNumber, isRetry: true);
          } else if (commandType == 2) {
            await _publishModeCommandInternal(motorId, commandData as int,
                sequenceNumber: command.sequenceNumber, isRetry: true);
          } else if (commandType == 4) {
            await _publishDefaultSettingCommandInternal(
                commandData, lvf, hvf, pcb, drf, olf,
                sequenceNumber: command.sequenceNumber, isRetry: true);
          }
          _scheduleRetry(motorId, commandType, commandData,
              command.sequenceNumber, lvf, hvf, pcb, drf, olf);
        } catch (e) {
          _pendingCommands.remove(key);
        }
      } else {
        _pendingCommands.remove(key);
        final motorName = motors.entries
                .firstWhere((e) => e.key == motorId,
                    orElse: () => MapEntry('', Motor()))
                .value
                .aliasName ??
            'Motor';
        command.onMaxRetriesReached('$motorName: No response from the device.');
      }
    });
    _pendingCommands[key] = command;
  }

  Future<void> publishUpdateSettings(int lvf, int hvf, String pcb, int drf,
      int olf, Map<String, dynamic> payload) async {
    if (mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      return;
    }
    final seq = _generateRandomSequence();

    try {
      await _publishDefaultSettingCommandInternal(
          payload, lvf, hvf, pcb, sequenceNumber: seq, drf, olf);
      statusMessage = 'Motor command sent successfully';
      _scheduleRetry('', 4, payload, seq, lvf, hvf, pcb, drf, olf);
    } catch (e) {
      statusMessage = 'Failed to publish motor command: $e';
      // _lastCommandTimes.remove();
      _dataUpdateNotifier.value++;
      rethrow;
    }
  }

  Future<void> _publishMotorCommandInternal(String motorId, int state,
      {int? sequenceNumber, bool isRetry = false}) async {
    if (mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }

    final parts = motorId.split('-');
    if (parts.length != 2) {
      throw Exception('Invalid motorId format: $motorId');
    }

    final identifier = parts[0];
    final topic = 'peepul/$identifier/cmd';

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
      debugPrint(
          '📤 Motor command sent for $motorId (state: $state) to topic: $topic');
    } else {
      debugPrint('🔄 Motor command retry sent for $motorId (state: $state)');
    }
  }

  // Internal publish method for mode control
  Future<void> _publishDefaultSettingCommandInternal(
      dynamic commandData, int lvf, int hvf, String pcbnumber, int drf, int olf,
      {int? sequenceNumber, bool isRetry = false}) async {
    if (mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }
    final topic = 'peepul/$pcbnumber/cmd';

    final seq = sequenceNumber ?? _generateRandomSequence();

    final payload = {"T": 1, "S": seq, "D": commandData};

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    if (!isRetry) {
      debugPrint(' Payload: $message');
    } else {}
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

    final identifier = parts[0];
    final topic = 'peepul/$identifier/cmd';

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
      debugPrint(' Mode command sent for $motorId (mode: $simplifiedMode)');
      debugPrint(' Payload: $message');
    } else {}
  }

  Future<void> publishMotorCommand(String motorId, int state) async {
    if (mqttClient == null || !isConnected) {
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
      _scheduleRetry(motorId, 1, state, sequenceNumber, 0, 0, '', 0, 0);
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
      print('Cannot publish: MQTT not connected');
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

      _scheduleRetry(
          motorId, 2, simplifiedMode, sequenceNumber, 0, 0, '', 0, 0);
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
