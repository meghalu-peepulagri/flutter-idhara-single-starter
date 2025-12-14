// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:uuid/uuid.dart';

// class MotorData {
//   ValueNotifier<bool> controller = ValueNotifier<bool>(false);
//   ValueNotifier<int?> modeswitchcontroller = ValueNotifier<int?>(null);

//   String voltageRed = '0';
//   String voltageYellow = '0';
//   String voltageBlue = '0';
//   String currentRed = '0';
//   String currentYellow = '0';
//   String currentBlue = '0';
//   int state = 0;
//   String motorMode = '_';
//   int? modeIndex;
//   int power = 0;
//   int fault = 0;
//   int alert = 0;

//   String runTime = '-';
//   bool hasReceivedData = false;
//   String? macAddress;
//   String? groupId; // G01, G02, G03, G04
//   String? title;

//   MotorData({
//     this.macAddress,
//     this.groupId,
//     this.title,
//   });

//   void dispose() {
//     controller.dispose();
//     modeswitchcontroller.dispose();
//   }
// }

// class MqttService {
//   static final MqttService _instance = MqttService._internal();

//   factory MqttService({Map<String, Motor>? initialMotors}) {
//     if (initialMotors != null) {
//       _instance.motors = initialMotors;
//       _instance._populateMotorDataFromMotors();
//     }
//     return _instance;
//   }

//   MqttServerClient? mqttClient;
//   late Map<String, MotorData> motorDataMap; // key: "mac-groupId"
//   bool isConnected = false;
//   String statusMessage = 'Connecting to MQTT broker...';
//   DateTime? lastMessageTime;
//   final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);

//   Map<String, Motor> motors = {}; // Stores Motor objects by mac-groupId
//   bool _isDataLoaded = false;
//   final Map<String, DateTime> _lastAckTimes = {};
//   final Map<String, DateTime> _lastCommandTimes = {};

//   MqttService._internal() {
//     motorDataMap = {};
//   }

//   ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;

//   void updateMotors(Map<String, Motor> newMotors) {
//     motors = newMotors;
//     _populateMotorDataFromMotors();
//     _dataUpdateNotifier.value++;
//   }

//   Motor? getMotorByMacAndGroup(String mac, String groupId) {
//     final key = '$mac-$groupId';
//     return motors[key];
//   }

//   void _populateMotorDataFromMotors() {
//     motorDataMap.clear();
//     for (var entry in motors.entries) {
//       final motor = entry.value;
//       final key = entry.key; // mac-groupId

//       motorDataMap[key] = MotorData(
//         macAddress: motor.starter?.macAddress,
//         groupId: key.split('-').last,
//         title: motor.name,
//       )
//         ..state = motor.state ?? 0
//         ..motorMode = motor.mode ?? '--'
//         ..modeIndex = _getModeIndex(motor.mode ?? '--')
//         ..controller.value = motor.state == 1
//         ..modeswitchcontroller.value = _getModeIndex(motor.mode ?? '--')
//         ..hasReceivedData =
//             false; // Set to false initially, will be true when MQTT data arrives

//       // Update from latest starter parameters if available
//       if (motor.starter?.starterParameters?.isNotEmpty ?? false) {
//         final params = motor.starter!.starterParameters!.first;
//         motorDataMap[key]!
//           ..voltageRed = params.lineVoltageR?.toString() ?? '0'
//           ..voltageYellow = params.lineVoltageY?.toString() ?? '0'
//           ..voltageBlue = params.lineVoltageB?.toString() ?? '0'
//           ..currentRed = params.currentR?.toString() ?? '0'
//           ..currentYellow = params.currentY?.toString() ?? '0'
//           ..currentBlue = params.currentB?.toString() ?? '0'
//           ..fault = params.fault ?? 0;
//       }

//       if (motor.starter?.power != null) {
//         motorDataMap[key]!.power = motor.starter!.power!;
//       }
//     }
//     _isDataLoaded = true;
//     debugPrint('Motor data populated: ${motorDataMap.length} motors');
//     _dataUpdateNotifier.value++;
//   }

//   int? _getModeIndex(String mode) {
//     if (mode.contains('AUTO')) return 0;
//     if (mode.contains('MANUAL')) return 1;
//     return null;
//   }

//   String _modeFromIndex(int index) {
//     switch (index) {
//       case 0:
//         return 'LOCAL+MANUAL';
//       case 1:
//         return 'LOCAL+AUTO';
//       case 2:
//         return 'REMOTE+MANUAL';
//       case 3:
//         return 'REMOTE+AUTO';
//       default:
//         return '--';
//     }
//   }

//   Future<void> initializeMqttClient() async {
//     if (mqttClient != null && isConnected) {
//       debugPrint('Disconnecting existing MQTT client');
//       mqttClient!.disconnect();
//     }

//     const int port = 8883;
//     String broker = 'aeef18e4.ala.asia-southeast1.emqxsl.com';
//     String username = 'admin';
//     String password = '123456';

//     const uuid = Uuid();
//     final String clientId = 'idhara_${uuid.v4()}';

//     debugPrint('Initializing MQTT client with broker: $broker');

//     mqttClient = MqttServerClient(broker, clientId);
//     mqttClient!.logging(on: false); // Set to true for debugging
//     mqttClient!.keepAlivePeriod = 60;
//     mqttClient!.connectTimeoutPeriod = 10000;
//     mqttClient!.autoReconnect = true;
//     mqttClient!.onConnected = _onConnected;
//     mqttClient!.onDisconnected = _onDisconnected;
//     mqttClient!.onSubscribed = _onSubscribed;
//     mqttClient!.onAutoReconnect = _onAutoReconnect;
//     mqttClient!.onAutoReconnected = _onAutoReconnected;
//     mqttClient!.secure = true;
//     mqttClient!.port = port;

//     final connMessage =
//         MqttConnectMessage().authenticateAs(username, password).startClean();
//     mqttClient!.connectionMessage = connMessage;

//     try {
//       debugPrint('Connecting to MQTT broker...');
//       await mqttClient?.connect();
//       debugPrint('MQTT connection initiated');
//     } catch (e) {
//       debugPrint('MQTT Connection Error: $e');
//       return;
//     }

//     mqttClient!.updates!.listen(_onMessageReceived, onError: (e) {
//       debugPrint('MQTT Stream Error: $e');
//       statusMessage = 'Stream error: $e';
//       _dataUpdateNotifier.value++;
//     });
//   }

//   void _onConnected() {
//     isConnected = true;
//     statusMessage = 'Connected. Subscribing to topics...';
//     debugPrint('MQTT Connected successfully');

//     // Subscribe to all motor topics
//     int subscriptionCount = 0;
//     for (var motor in motors.values) {
//       if (motor.starter?.macAddress != null) {
//         final mac = motor.starter!.macAddress!;
//         mqttClient!.subscribe('peepul/$mac/tele', MqttQos.atMostOnce);
//         mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
//         subscriptionCount++;
//         debugPrint('Subscribed to peepul/$mac/tele and peepul/$mac/status');
//       }
//     }

//     debugPrint('Total subscriptions: $subscriptionCount motors');
//     _dataUpdateNotifier.value++;
//   }

//   void _onDisconnected() {
//     isConnected = false;
//     statusMessage = 'Disconnected. Displaying latest data from API...';
//     debugPrint('MQTT Disconnected');
//     _dataUpdateNotifier.value++;
//   }

//   void _onSubscribed(String topic) {
//     statusMessage = 'Subscribed to $topic';
//     debugPrint('Subscribed to topic: $topic');
//     _dataUpdateNotifier.value++;
//   }

//   void _onAutoReconnect() {
//     debugPrint('MQTT Auto reconnecting...');
//   }

//   void _onAutoReconnected() {
//     debugPrint('MQTT Auto reconnected');
//     // Resubscribe to all topics
//     for (var motor in motors.values) {
//       if (motor.starter?.macAddress != null) {
//         final mac = motor.starter!.macAddress!;
//         mqttClient!.subscribe('peepul/$mac/tele', MqttQos.atMostOnce);
//         mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
//       }
//     }
//   }

//   bool _isRecentAck(String motorId) {
//     final lastAckTime = _lastAckTimes[motorId];
//     if (lastAckTime == null) return false;
//     final timeSinceAck = DateTime.now().difference(lastAckTime);
//     return timeSinceAck.inSeconds < 5;
//   }

//   void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
//     lastMessageTime = DateTime.now();
//     debugPrint('==== MQTT Messages Received: ${messages.length} ====');

//     for (var message in messages) {
//       final payload = MqttPublishPayload.bytesToStringAsString(
//           (message.payload as MqttPublishMessage).payload.message);
//       final topic = message.topic;

//       debugPrint('Topic: $topic');
//       debugPrint('Payload: $payload');

//       try {
//         final data = jsonDecode(payload);
//         final type = data['T'] as int?;
//         final payloadData = data['D'];

//         debugPrint('Message Type (T): $type');

//         if (type == null || payloadData == null) {
//           debugPrint('Invalid message: Missing T or D field');
//           continue;
//         }

//         // Extract MAC from topic: peepul/{mac}/tele or peepul/{mac}/status
//         final topicParts = topic.split('/');
//         if (topicParts.length < 2) {
//           debugPrint('Invalid topic format: $topic');
//           continue;
//         }
//         final mac = topicParts[1];
//         debugPrint('Extracted MAC: $mac');

//         // Handle different message types
//         switch (type) {
//           case 35: // LIVE DATA REQUEST ACK
//             debugPrint('Handling LIVE DATA REQUEST ACK (35)');
//             _handleLiveData(mac, payloadData);
//             break;
//           case 31: // MOTOR CONTROL ACK
//             debugPrint('Handling MOTOR CONTROL ACK (31)');
//             _handleMotorControlAck(mac, payloadData);
//             break;
//           case 32: // MODE CHANGE ACK
//             debugPrint('Handling MODE CHANGE ACK (32)');
//             _handleModeChangeAck(mac, payloadData);
//             break;
//           case 40: // HEART BEAT
//             debugPrint('Heartbeat received from $mac');
//             break;
//           case 41: // LIVE DATA
//             debugPrint('Handling LIVE DATA (41)');
//             _handleLiveData(mac, payloadData);
//             break;
//           default:
//             debugPrint('Unknown message type: $type');
//         }
//       } catch (e, stackTrace) {
//         debugPrint('Error parsing MQTT message: $e');
//         debugPrint('StackTrace: $stackTrace');
//         statusMessage = 'Invalid data format received';
//       }
//     }

//     // CRITICAL: Notify listeners after processing all messages
//     debugPrint(
//         'Notifying UI update - Current value: ${_dataUpdateNotifier.value}');
//     _dataUpdateNotifier.value++;
//     debugPrint('New notification value: ${_dataUpdateNotifier.value}');
//   }

//   void _handleLiveData(String mac, dynamic payloadData) {
//     debugPrint('_handleLiveData called for MAC: $mac');

//     if (payloadData is! Map<String, dynamic>) {
//       debugPrint('Invalid payload data type: ${payloadData.runtimeType}');
//       return;
//     }

//     int updatedMotors = 0;

//     for (var entry in payloadData.entries) {
//       final groupId = entry.key; // G01, G02, G03, G04
//       if (groupId == 'ct') continue; // Skip timestamp

//       debugPrint('Processing group: $groupId');

//       final groupData = entry.value as Map<String, dynamic>?;
//       if (groupData == null) {
//         debugPrint('Group data is null for $groupId');
//         continue;
//       }

//       final fullMotorId = '$mac-$groupId';
//       debugPrint('Full Motor ID: $fullMotorId');

//       var motorData = motorDataMap[fullMotorId];
//       if (motorData == null) {
//         debugPrint('Creating new MotorData for $fullMotorId');
//         motorData =
//             MotorData(macAddress: mac, groupId: groupId, title: groupId);
//         motorDataMap[fullMotorId] = motorData;
//       }

//       // Update based on available fields
//       debugPrint('Group data keys: ${groupData.keys}');

//       if (groupData.containsKey('p_v')) {
//         // This is G01 with full data
//         debugPrint('Processing G01 with full data');
//         motorData.state = groupData['m_s'] ?? 0;
//         motorData.controller.value = motorData.state == 1;
//         debugPrint(
//             'Motor state: ${motorData.state}, Controller: ${motorData.controller.value}');

//         final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
//         motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
//         motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
//         motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
//         debugPrint(
//             'Voltages: R=${motorData.voltageRed}, Y=${motorData.voltageYellow}, B=${motorData.voltageBlue}');

//         final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
//         motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
//         motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
//         motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
//         debugPrint(
//             'Currents: R=${motorData.currentRed}, Y=${motorData.currentYellow}, B=${motorData.currentBlue}');

//         motorData.power = groupData['pwr'] ?? 0;
//         motorData.fault = groupData['flt'] ?? 0;
//         motorData.alert = groupData['alt'] ?? 0;
//         debugPrint(
//             'Power: ${motorData.power}, Fault: ${motorData.fault}, Alert: ${motorData.alert}');

//         if (groupData.containsKey('mode')) {
//           final modeValue = groupData['mode'] as int?;
//           motorData.motorMode = _modeFromIndex(modeValue ?? 0);
//           motorData.modeIndex = _getModeIndex(motorData.motorMode);
//           motorData.modeswitchcontroller.value = motorData.modeIndex;
//           debugPrint(
//               'Mode: ${motorData.motorMode} (index: ${motorData.modeIndex})');
//         }
//       } else if (groupData.containsKey('pwr')) {
//         // G02, G03 - partial data
//         debugPrint('Processing G02/G03 with partial data');
//         motorData.power = groupData['pwr'] ?? 0;

//         if (groupData.containsKey('mode')) {
//           final modeValue = groupData['mode'] as int?;
//           motorData.motorMode = _modeFromIndex(modeValue ?? 0);
//           motorData.modeIndex = _getModeIndex(motorData.motorMode);
//           motorData.modeswitchcontroller.value = motorData.modeIndex;
//         }

//         if (groupData.containsKey('llv')) {
//           final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
//           motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
//           motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
//           motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
//         }

//         if (groupData.containsKey('amp')) {
//           final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
//           motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
//           motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
//           motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
//         }

//         if (groupData.containsKey('m_s')) {
//           motorData.state = groupData['m_s'] ?? 0;
//           motorData.controller.value = motorData.state == 1;
//         }
//       } else if (groupData.containsKey('mode')) {
//         // G04 - only power and mode
//         debugPrint('Processing G04 with mode only');
//         motorData.power = groupData['pwr'] ?? 0;
//         final modeValue = groupData['mode'] as int?;
//         motorData.motorMode = _modeFromIndex(modeValue ?? 0);
//         motorData.modeIndex = _getModeIndex(motorData.motorMode);
//         motorData.modeswitchcontroller.value = motorData.modeIndex;
//       }

//       motorData.hasReceivedData = true;
//       motorDataMap[fullMotorId] = motorData;
//       _lastAckTimes[fullMotorId] = DateTime.now();
//       updatedMotors++;

//       debugPrint('Motor $fullMotorId updated successfully');
//     }

//     debugPrint('Total motors updated in this message: $updatedMotors');
//     debugPrint('Total motors in map: ${motorDataMap.length}');
//   }

//   void _handleMotorControlAck(String mac, dynamic payloadData) {
//     final ackStatus = payloadData as int?;
//     debugPrint('Motor control ACK status: $ackStatus for MAC: $mac');
//     if (ackStatus == 1) {
//       debugPrint('Motor control acknowledged for $mac');
//       // Update all motors with this MAC
//       for (var key in motorDataMap.keys) {
//         if (key.startsWith(mac)) {
//           _lastAckTimes[key] = DateTime.now();
//         }
//       }
//     }
//   }

//   void _handleModeChangeAck(String mac, dynamic payloadData) {
//     final ackStatus = payloadData as int?;
//     debugPrint('Mode change ACK status: $ackStatus for MAC: $mac');
//     if (ackStatus == 1) {
//       debugPrint('Mode change acknowledged for $mac');
//       // Update all motors with this MAC
//       for (var key in motorDataMap.keys) {
//         if (key.startsWith(mac)) {
//           _lastAckTimes[key] = DateTime.now();
//         }
//       }
//     }
//   }

//   Map<String, MotorData> getMotorDataForLocation(int? locationId) {
//     if (locationId == null) {
//       return motorDataMap;
//     }

//     final result = Map<String, MotorData>.fromEntries(
//       motorDataMap.entries.where((entry) {
//         final motor = motors[entry.key];
//         return motor?.location?.id == locationId;
//       }),
//     );

//     return result;
//   }

//   Future<void> publishMotorCommand(String motorId, int state) async {
//     if (mqttClient == null || !isConnected) {
//       debugPrint('Cannot publish: MQTT not connected');
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       return;
//     }

//     final lastCommandTime = _lastCommandTimes[motorId];
//     if (lastCommandTime != null &&
//         DateTime.now().difference(lastCommandTime).inSeconds < 2) {
//       debugPrint('Command throttled for $motorId');
//       return;
//     }

//     final parts = motorId.split('-');
//     if (parts.length != 2) {
//       debugPrint('Invalid motorId format: $motorId');
//       return;
//     }

//     final mac = parts[0];
//     final groupId = parts[1];

//     final topic = 'peepul/$mac/status';

//     final payload = {
//       "T": 31, // MOTOR CONTROL
//       "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       "D": state,
//     };

//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     _lastAckTimes.remove(motorId);
//     _lastCommandTimes[motorId] = DateTime.now();

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
//       statusMessage = 'Motor command sent successfully';
//       debugPrint('Published motor command to $topic: $message');
//     } catch (e) {
//       statusMessage = 'Failed to publish motor command: $e';
//       debugPrint('Failed to publish motor command: $e');
//       _lastCommandTimes.remove(motorId);
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishModeCommand(String motorId, int mode) async {
//     if (mqttClient == null || !isConnected) {
//       debugPrint('Cannot publish: MQTT not connected');
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       return;
//     }

//     final parts = motorId.split('-');
//     if (parts.length != 2) {
//       debugPrint('Invalid motorId format: $motorId');
//       return;
//     }

//     final mac = parts[0];
//     final groupId = parts[1];

//     final topic = 'peepul/$mac/status ';

//     final payload = {
//       "T": 32, // MODE CHANGE
//       "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       "D": mode,
//     };

//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
//       statusMessage = 'Mode command sent successfully';
//       debugPrint('Published mode command to $topic: $message');
//     } catch (e) {
//       statusMessage = 'Failed to publish mode command: $e';
//       debugPrint('Failed to publish mode command: $e');
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   void dispose() {
//     mqttClient?.disconnect();
//     for (var motorData in motorDataMap.values) {
//       motorData.dispose();
//     }
//   }
// }

import 'dart:convert';

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
  int? modeIndex; // 0 = Auto, 1 = Manual (simplified)
  int power = 0;
  int fault = 0;
  int alert = 0;

  String runTime = '-';
  bool hasReceivedData = false;
  String? macAddress;
  String? groupId; // G01, G02, G03, G04
  String? title;

  MotorData({
    this.macAddress,
    this.groupId,
    this.title,
  });

  void dispose() {
    controller.dispose();
    modeswitchcontroller.dispose();
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
  late Map<String, MotorData> motorDataMap; // key: "mac-groupId"
  bool isConnected = false;
  String statusMessage = 'Connecting to MQTT broker...';
  DateTime? lastMessageTime;
  final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);

  Map<String, Motor> motors = {}; // Stores Motor objects by mac-groupId
  bool _isDataLoaded = false;
  final Map<String, DateTime> _lastAckTimes = {};
  final Map<String, DateTime> _lastCommandTimes = {};

  MqttService._internal() {
    motorDataMap = {};
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
      final key = entry.key; // mac-groupId

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

      // Update from latest starter parameters if available
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

  // Simplified mode index: 0 = Auto, 1 = Manual
  int? _getSimplifiedModeIndex(String mode) {
    if (mode.contains('AUTO')) return 0;
    if (mode.contains('MANUAL')) return 1;
    return null;
  }

  // Convert simplified index to full mode string
  String _modeFromSimplifiedIndex(int index) {
    switch (index) {
      case 0:
        return 'REMOTE+AUTO';
      case 1:
        return 'REMOTE+MANUAL';
      default:
        return '--';
    }
  }

  // Convert full mode index (0-3) from MQTT to simplified index (0-1)
  int? _fullModeToSimplified(int fullModeIndex) {
    // Full mode mapping:
    // 0 = LOCAL+MANUAL
    // 1 = LOCAL+AUTO
    // 2 = REMOTE+MANUAL
    // 3 = REMOTE+AUTO

    switch (fullModeIndex) {
      case 0: // LOCAL+MANUAL
      case 2: // REMOTE+MANUAL
        return 1; // Manual
      case 1: // LOCAL+AUTO
      case 3: // REMOTE+AUTO
        return 0; // Auto
      default:
        return null;
    }
  }

  // Convert simplified index (0-1) to full mode index for MQTT
  int _simplifiedToFullMode(int simplifiedIndex) {
    // Always use REMOTE modes
    switch (simplifiedIndex) {
      case 0: // Auto
        return 3; // REMOTE+AUTO
      case 1: // Manual
        return 2; // REMOTE+MANUAL
      default:
        return 3; // Default to REMOTE+AUTO
    }
  }

  Future<void> initializeMqttClient() async {
    if (mqttClient != null && isConnected) {
      debugPrint('Disconnecting existing MQTT client');
      mqttClient!.disconnect();
    }

    const int port = 8883;
    String broker = 'aeef18e4.ala.asia-southeast1.emqxsl.com';
    String username = 'admin';
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

    // Subscribe to all motor topics
    int subscriptionCount = 0;
    for (var motor in motors.values) {
      if (motor.starter?.macAddress != null) {
        final mac = motor.starter!.macAddress!;
        mqttClient!.subscribe('peepul/$mac/tele', MqttQos.atMostOnce);
        mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
        subscriptionCount++;
        debugPrint('Subscribed to peepul/$mac/tele and peepul/$mac/status');
      }
    }

    debugPrint('Total subscriptions: $subscriptionCount motors');
    _dataUpdateNotifier.value++;
  }

  void _onDisconnected() {
    isConnected = false;
    statusMessage = 'Disconnected. Displaying latest data from API...';
    debugPrint('MQTT Disconnected');
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
    // Resubscribe to all topics
    for (var motor in motors.values) {
      if (motor.starter?.macAddress != null) {
        final mac = motor.starter!.macAddress!;
        mqttClient!.subscribe('peepul/$mac/tele', MqttQos.atMostOnce);
        mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
      }
    }
  }

  bool _isRecentAck(String motorId) {
    final lastAckTime = _lastAckTimes[motorId];
    if (lastAckTime == null) return false;
    final timeSinceAck = DateTime.now().difference(lastAckTime);
    return timeSinceAck.inSeconds < 5;
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

        // Extract MAC from topic
        final topicParts = topic.split('/');
        if (topicParts.length < 2) {
          debugPrint('Invalid topic format: $topic');
          continue;
        }
        final mac = topicParts[1];
        debugPrint('Extracted MAC: $mac');

        // Handle different message types
        switch (type) {
          case 35: // LIVE DATA REQUEST ACK
            debugPrint('Handling LIVE DATA REQUEST ACK (35)');
            _handleLiveData(mac, payloadData);
            break;
          case 31: // MOTOR CONTROL ACK
            debugPrint('Handling MOTOR CONTROL ACK (31)');
            _handleMotorControlAck(mac, payloadData);
            break;
          case 32: // MODE CHANGE ACK
            debugPrint('Handling MODE CHANGE ACK (32)');
            _handleModeChangeAck(mac, payloadData);
            break;
          case 40: // HEART BEAT
            debugPrint('Heartbeat received from $mac');
            break;
          case 41: // LIVE DATA
            debugPrint('Handling LIVE DATA (41)');
            _handleLiveData(mac, payloadData);
            break;
          default:
            debugPrint('Unknown message type: $type');
        }
      } catch (e, stackTrace) {
        debugPrint('Error parsing MQTT message: $e');
        debugPrint('StackTrace: $stackTrace');
        statusMessage = 'Invalid data format received';
      }
    }

    // Notify listeners after processing all messages
    debugPrint(
        'Notifying UI update - Current value: ${_dataUpdateNotifier.value}');
    _dataUpdateNotifier.value++;
    debugPrint('New notification value: ${_dataUpdateNotifier.value}');
  }

  void _handleLiveData(String mac, dynamic payloadData) {
    debugPrint('_handleLiveData called for MAC: $mac');

    if (payloadData is! Map<String, dynamic>) {
      debugPrint('Invalid payload data type: ${payloadData.runtimeType}');
      return;
    }

    int updatedMotors = 0;

    for (var entry in payloadData.entries) {
      final groupId = entry.key; // G01, G02, G03, G04
      if (groupId == 'ct') continue; // Skip timestamp

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

      // Update based on available fields
      debugPrint('Group data keys: ${groupData.keys}');

      if (groupData.containsKey('p_v')) {
        // This is G01 with full data
        debugPrint('Processing G01 with full data');
        // motorData.state = groupData['m_s'] ?? 0;
        // motorData.controller.value = motorData.state == 1;
        final newState = groupData['m_s'] ?? 0;
        motorData.state = newState;
// Only update controller if state actually changed
        if (motorData.controller.value != (newState == 1)) {
          motorData.controller.value = (newState == 1);
        }
        debugPrint(
            'Motor state: ${motorData.state}, Controller: ${motorData.controller.value}');

        final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
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

        // Handle mode - convert full mode to simplified
        if (groupData.containsKey('mode')) {
          final fullModeValue = groupData['mode'] as int?;
          if (fullModeValue != null) {
            motorData.modeIndex = _fullModeToSimplified(fullModeValue);
            motorData.modeswitchcontroller.value = motorData.modeIndex;

            // Update motorMode string for display
            switch (fullModeValue) {
              case 0:
                motorData.motorMode = 'LOCAL+MANUAL';
                break;
              case 1:
                motorData.motorMode = 'LOCAL+AUTO';
                break;
              case 2:
                motorData.motorMode = 'REMOTE+MANUAL';
                break;
              case 3:
                motorData.motorMode = 'REMOTE+AUTO';
                break;
              default:
                motorData.motorMode = '--';
            }

            debugPrint(
                'Mode: ${motorData.motorMode} (simplified index: ${motorData.modeIndex})');
          }
        }
      } else if (groupData.containsKey('pwr')) {
        // G02, G03 - partial data
        debugPrint('Processing G02/G03 with partial data');
        motorData.power = groupData['pwr'] ?? 0;

        if (groupData.containsKey('mode')) {
          final fullModeValue = groupData['mode'] as int?;
          if (fullModeValue != null) {
            motorData.modeIndex = _fullModeToSimplified(fullModeValue);
            motorData.modeswitchcontroller.value = motorData.modeIndex;
          }
        }

        if (groupData.containsKey('llv')) {
          final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
          motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
          motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
          motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
        }

        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
        }

        if (groupData.containsKey('m_s')) {
          motorData.state = groupData['m_s'] ?? 0;
          motorData.controller.value = motorData.state == 1;
        }
      } else if (groupData.containsKey('mode')) {
        // G04 - only power and mode
        debugPrint('Processing G04 with mode only');
        motorData.power = groupData['pwr'] ?? 0;
        final fullModeValue = groupData['mode'] as int?;
        if (fullModeValue != null) {
          motorData.modeIndex = _fullModeToSimplified(fullModeValue);
          motorData.modeswitchcontroller.value = motorData.modeIndex;
        }
      }

      motorData.hasReceivedData = true;
      motorDataMap[fullMotorId] = motorData;
      _lastAckTimes[fullMotorId] = DateTime.now();
      updatedMotors++;

      debugPrint('Motor $fullMotorId updated successfully');
    }

    debugPrint('Total motors updated in this message: $updatedMotors');
    debugPrint('Total motors in map: ${motorDataMap.length}');
  }

  void _handleMotorControlAck(String mac, dynamic payloadData) {
    final ackStatus = payloadData as int?;
    debugPrint('Motor control ACK status: $ackStatus for MAC: $mac');
    if (ackStatus == 1) {
      debugPrint('Motor control acknowledged for $mac');
      for (var key in motorDataMap.keys) {
        if (key.startsWith(mac)) {
          _lastAckTimes[key] = DateTime.now();
        }
      }
    }
  }

  void _handleModeChangeAck(String mac, dynamic payloadData) {
    final ackStatus = payloadData as int?;
    debugPrint('Mode change ACK status: $ackStatus for MAC: $mac');
    if (ackStatus == 1) {
      debugPrint('Mode change acknowledged for $mac');
      for (var key in motorDataMap.keys) {
        if (key.startsWith(mac)) {
          _lastAckTimes[key] = DateTime.now();
        }
      }
    }
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

    final parts = motorId.split('-');
    if (parts.length != 2) {
      debugPrint('Invalid motorId format: $motorId');
      return;
    }

    final mac = parts[0];
    final topic = 'peepul/$mac/status';

    final payload = {
      "T": 31, // MOTOR CONTROL
      "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "D": state,
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _lastAckTimes.remove(motorId);
    _lastCommandTimes[motorId] = DateTime.now();

    try {
      mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      statusMessage = 'Motor command sent successfully';
      debugPrint('Published motor command to $topic: $message');
    } catch (e) {
      statusMessage = 'Failed to publish motor command: $e';
      debugPrint('Failed to publish motor command: $e');
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

    final parts = motorId.split('-');
    if (parts.length != 2) {
      debugPrint('Invalid motorId format: $motorId');
      return;
    }

    final mac = parts[0];
    final groupId = parts[1];
    final topic = 'peepul/$mac/status';

    // Convert simplified mode (0=Auto, 1=Manual) to full mode
    final fullMode = _simplifiedToFullMode(simplifiedMode);

    final payload = {
      "T": 32, // MODE CHANGE
      "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "D": fullMode,
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _lastAckTimes.remove(motorId);

    try {
      mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      statusMessage = 'Mode command sent successfully';
      debugPrint('========================================');
      debugPrint('Published mode command to topic: $topic');
      debugPrint('Motor ID: $motorId');
      debugPrint('Group ID: $groupId');
      debugPrint(
          'Simplified mode: $simplifiedMode (${simplifiedMode == 0 ? "Auto" : "Manual"})');
      debugPrint(
          'Full mode sent: $fullMode (${_modeFromSimplifiedIndex(simplifiedMode)})');
      debugPrint('Payload: $message');
      debugPrint('========================================');

      _lastAckTimes[motorId] = DateTime.now();
    } catch (e) {
      statusMessage = 'Failed to publish mode command: $e';
      debugPrint('Failed to publish mode command: $e');
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> publishGroupedMotorCommands(
    List<Map<String, dynamic>> motorCommands,
  ) async {
    if (mqttClient == null || !isConnected) {
      debugPrint('Cannot publish: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    // Group commands by MAC address
    Map<String, List<Map<String, dynamic>>> commandsByMac = {};

    for (var command in motorCommands) {
      final motorId = command['motorId'] as String;
      final parts = motorId.split('-');
      if (parts.length != 2) continue;

      final mac = parts[0];
      final groupId = parts[1];
      final state = command['state'] as int;

      if (!commandsByMac.containsKey(mac)) {
        commandsByMac[mac] = [];
      }

      commandsByMac[mac]!.add({
        'groupId': groupId,
        'state': state,
        'motorId': motorId,
      });
    }

    // Send commands for each MAC address
    for (var entry in commandsByMac.entries) {
      final mac = entry.key;
      final commands = entry.value;
      final topic = 'peepul/$mac/status';

      // Build payload with all group commands
      final Map<String, dynamic> groupStates = {};
      for (var cmd in commands) {
        groupStates[cmd['groupId']] = cmd['state'];
      }

      final payload = {
        "T": 31, // MOTOR CONTROL
        "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "D": groupStates, // Multiple groups in one payload
      };

      final message = jsonEncode(payload);
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      // Clear ack times for all motors in this command
      for (var cmd in commands) {
        _lastAckTimes.remove(cmd['motorId']);
        _lastCommandTimes[cmd['motorId']] = DateTime.now();
      }

      try {
        mqttClient!
            .publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        debugPrint('========================================');
        debugPrint('Published grouped motor command to: $topic');
        debugPrint('Payload: $message');
        debugPrint('Motors affected: ${commands.length}');
        debugPrint('========================================');
      } catch (e) {
        statusMessage = 'Failed to publish grouped command: $e';
        debugPrint('Failed to publish grouped command: $e');
        rethrow;
      }
    }

    statusMessage = 'Grouped motor commands sent successfully';
    _dataUpdateNotifier.value++;
  }

  void dispose() {
    mqttClient?.disconnect();
    for (var motorData in motorDataMap.values) {
      motorData.dispose();
    }
  }
}
