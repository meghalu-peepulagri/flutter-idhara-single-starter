// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:uuid/uuid.dart';

// class MotorData {
//   ValueNotifier<bool> controller = ValueNotifier<bool>(false);
//   ValueNotifier<int?> modeswitchcontroller = ValueNotifier<int?>(null);
//   bool? pendingCommand;

//   String voltageRed = '0';
//   String voltageYellow = '0';
//   String voltageBlue = '0';
//   String currentRed = '0';
//   String currentYellow = '0';
//   String currentBlue = '0';
//   int state = 0;
//   String motorMode = '_';
//   int? modeIndex; // 0 = Auto, 1 = Manual (simplified)
//   int power = 0;
//   int fault = 0;
//   int alert = 0;

//   String runTime = '-';
//   bool hasReceivedData = false;
//   String? macAddress;
//   String? groupId;
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
//   late Map<String, MotorData> motorDataMap;
//   bool isConnected = false;
//   String statusMessage = 'Connecting to MQTT broker...';
//   DateTime? lastMessageTime;
//   final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);

//   Map<String, Motor> motors = {};
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
//       final key = entry.key;

//       motorDataMap[key] = MotorData(
//         macAddress: motor.starter?.macAddress,
//         groupId: key.split('-').last,
//         title: motor.name,
//       )
//         ..state = motor.state ?? 0
//         ..motorMode = motor.mode ?? '--'
//         ..modeIndex = _getSimplifiedModeIndex(motor.mode ?? '--')
//         ..controller.value = motor.state == 1
//         ..modeswitchcontroller.value =
//             _getSimplifiedModeIndex(motor.mode ?? '--')
//         ..hasReceivedData = false;

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

//   int? _getSimplifiedModeIndex(String mode) {
//     if (mode.contains('AUTO')) return 0;
//     if (mode.contains('MANUAL')) return 1;
//     return null;
//   }

//   String _modeFromSimplifiedIndex(int index) {
//     switch (index) {
//       case 0:
//         return 'REMOTE+AUTO';
//       case 1:
//         return 'REMOTE+MANUAL';
//       default:
//         return '--';
//     }
//   }

//   int? _fullModeToSimplified(int fullModeIndex) {
//     switch (fullModeIndex) {
//       case 0: // LOCAL+MANUAL
//       case 2: // REMOTE+MANUAL
//         return 1; // Manual
//       case 1: // LOCAL+AUTO
//       case 3: // REMOTE+AUTO
//         return 0; // Auto
//       default:
//         return null;
//     }
//   }

//   int _simplifiedToFullMode(int simplifiedIndex) {
//     switch (simplifiedIndex) {
//       case 0: // Auto
//         return 3; // REMOTE+AUTO
//       case 1: // Manual
//         return 2; // REMOTE+MANUAL
//       default:
//         return 3;
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
//     mqttClient!.logging(on: false);
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
//     for (var motor in motors.values) {
//       if (motor.starter?.macAddress != null) {
//         final mac = motor.starter!.macAddress!;
//         mqttClient!.subscribe('peepul/$mac/tele', MqttQos.atMostOnce);
//         mqttClient!.subscribe('peepul/$mac/status', MqttQos.atMostOnce);
//       }
//     }
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

//         final topicParts = topic.split('/');
//         if (topicParts.length < 2) {
//           debugPrint('Invalid topic format: $topic');
//           continue;
//         }
//         final mac = topicParts[1];
//         debugPrint('Extracted MAC: $mac');

//         switch (type) {
//           case 31: // MOTOR CONTROL ACK (from device)
//             debugPrint('Handling MOTOR CONTROL ACK (31)');
//             _handleMotorControlAck(mac, payloadData);
//             break;
//           case 32: // MODE CHANGE ACK (from device)
//             debugPrint('Handling MODE CHANGE ACK (32)');
//             _handleModeChangeAck(mac, payloadData);
//             break;
//           case 35: // LIVE DATA REQUEST ACK
//             debugPrint('Handling LIVE DATA REQUEST ACK (35)');
//             _handleLiveData(mac, payloadData);
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

//     debugPrint(
//         'Notifying UI update - Current value: ${_dataUpdateNotifier.value}');
//     _dataUpdateNotifier.value++;
//     debugPrint('New notification value: ${_dataUpdateNotifier.value}');
//   }

//   void _handleMotorControlAck(String mac, dynamic payloadData) {
//     debugPrint('=== Motor Control ACK (Type 31) ===');
//     debugPrint('MAC: $mac');
//     debugPrint('Payload Data: $payloadData');

//     // payloadData should be the state (0 or 1)
//     final newState = payloadData as int?;

//     if (newState == null) {
//       debugPrint('Invalid state in ACK: $payloadData');
//       return;
//     }

//     debugPrint(
//         'New state from ACK: $newState (${newState == 1 ? "ON" : "OFF"})');

//     // Update all motors with this MAC address
//     int updatedCount = 0;
//     for (var entry in motorDataMap.entries) {
//       if (entry.key.startsWith(mac)) {
//         final motorData = entry.value;
//         motorData.state = newState;
//         motorData.controller.value = (newState == 1);
//         motorData.hasReceivedData = true;
//         _lastAckTimes[entry.key] = DateTime.now();
//         updatedCount++;

//         debugPrint(
//             '✓ Updated motor ${entry.key}: state=$newState, controller=${motorData.controller.value}');
//       }
//     }

//     debugPrint('Updated $updatedCount motors with new state from ACK');
//   }

//   void _handleModeChangeAck(String mac, dynamic payloadData) {
//     debugPrint('=== Mode Change ACK (Type 32) ===');
//     debugPrint('MAC: $mac');
//     debugPrint('Payload Data: $payloadData');

//     // payloadData should be the mode index (0 = Auto, 1 = Manual)
//     final newModeIndex = payloadData as int?;

//     if (newModeIndex == null || (newModeIndex != 0 && newModeIndex != 1)) {
//       debugPrint('Invalid mode in ACK: $payloadData (expected 0 or 1)');
//       return;
//     }

//     debugPrint(
//         'New mode from ACK: $newModeIndex (${newModeIndex == 0 ? "Auto" : "Manual"})');

//     // Update all motors with this MAC address
//     int updatedCount = 0;
//     for (var entry in motorDataMap.entries) {
//       if (entry.key.startsWith(mac)) {
//         final motorData = entry.value;
//         motorData.modeIndex = newModeIndex;
//         motorData.modeswitchcontroller.value = newModeIndex;
//         motorData.motorMode = _modeFromSimplifiedIndex(newModeIndex);
//         motorData.hasReceivedData = true;
//         _lastAckTimes[entry.key] = DateTime.now();
//         updatedCount++;

//         debugPrint(
//             '✓ Updated motor ${entry.key}: mode=${motorData.motorMode}, index=$newModeIndex');
//       }
//     }

//     debugPrint('Updated $updatedCount motors with new mode from ACK');
//   }

//   void _handleLiveData(String mac, dynamic payloadData) {
//     debugPrint('_handleLiveData called for MAC: $mac');

//     if (payloadData is! Map<String, dynamic>) {
//       debugPrint('Invalid payload data type: ${payloadData.runtimeType}');
//       return;
//     }

//     int updatedMotors = 0;

//     for (var entry in payloadData.entries) {
//       final groupId = entry.key;
//       if (groupId == 'ct') continue;

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

//       debugPrint('Group data keys: ${groupData.keys}');

//       if (groupData.containsKey('p_v')) {
//         debugPrint('Processing G01 with full data');
//         final newState = groupData['m_s'] ?? 0;
//         motorData.state = newState;
//         if (motorData.controller.value != (newState == 1)) {
//           motorData.controller.value = (newState == 1);
//         }
//         debugPrint(
//             'Motor state: ${motorData.state}, Controller: ${motorData.controller.value}');

//         final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
//         motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
//         motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
//         motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';

//         final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
//         motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
//         motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
//         motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';

//         motorData.power = groupData['pwr'] ?? 0;
//         motorData.fault = groupData['flt'] ?? 0;
//         motorData.alert = groupData['alt'] ?? 0;

//         if (groupData.containsKey('mode')) {
//           final fullModeValue = groupData['mode'] as int?;
//           if (fullModeValue != null) {
//             motorData.modeIndex = _fullModeToSimplified(fullModeValue);
//             motorData.modeswitchcontroller.value = motorData.modeIndex;

//             switch (fullModeValue) {
//               case 0:
//                 motorData.motorMode = 'LOCAL+MANUAL';
//                 break;
//               case 1:
//                 motorData.motorMode = 'LOCAL+AUTO';
//                 break;
//               case 2:
//                 motorData.motorMode = 'REMOTE+MANUAL';
//                 break;
//               case 3:
//                 motorData.motorMode = 'REMOTE+AUTO';
//                 break;
//               default:
//                 motorData.motorMode = '--';
//             }

//             debugPrint(
//                 'Mode: ${motorData.motorMode} (simplified index: ${motorData.modeIndex})');
//           }
//         }
//       } else if (groupData.containsKey('pwr')) {
//         debugPrint('Processing G02/G03 with partial data');
//         motorData.power = groupData['pwr'] ?? 0;

//         if (groupData.containsKey('mode')) {
//           final fullModeValue = groupData['mode'] as int?;
//           if (fullModeValue != null) {
//             motorData.modeIndex = _fullModeToSimplified(fullModeValue);
//             motorData.modeswitchcontroller.value = motorData.modeIndex;
//           }
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
//         debugPrint('Processing G04 with mode only');
//         motorData.power = groupData['pwr'] ?? 0;
//         final fullModeValue = groupData['mode'] as int?;
//         if (fullModeValue != null) {
//           motorData.modeIndex = _fullModeToSimplified(fullModeValue);
//           motorData.modeswitchcontroller.value = motorData.modeIndex;
//         }
//       }

//       motorData.hasReceivedData = true;
//       motorDataMap[fullMotorId] = motorData;
//       _lastAckTimes[fullMotorId] = DateTime.now();

//       debugPrint('Motor $fullMotorId updated successfully');
//     }

//     debugPrint('Total motors in map: ${motorDataMap.length}');
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
//     final topic = 'peepul/$mac/status';

//     // PUBLISH with type 1 for motor control command
//     final payload = {
//       "T": 1,
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
//       debugPrint('========================================');
//       debugPrint('Published motor command to: $topic');
//       debugPrint('Motor ID: $motorId');
//       debugPrint('State: $state (${state == 1 ? "ON" : "OFF"})');
//       debugPrint('Payload: $message');
//       debugPrint('Waiting for ACK (Type 31) on: peepul/$mac/status');
//       debugPrint('========================================');
//     } catch (e) {
//       statusMessage = 'Failed to publish motor command: $e';
//       debugPrint('Failed to publish motor command: $e');
//       _lastCommandTimes.remove(motorId);
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishModeCommand(String motorId, int simplifiedMode) async {
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
//     final topic = 'peepul/$mac/status';

//     // PUBLISH with type 2 for mode change command
//     final payload = {
//       "T": 2,
//       "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       "D": simplifiedMode, // Send 0 or 1 directly
//     };

//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     _lastAckTimes.remove(motorId);

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
//       statusMessage = 'Mode command sent successfully';
//       debugPrint('========================================');
//       debugPrint('Published mode command to: $topic');
//       debugPrint('Motor ID: $motorId');
//       debugPrint('Group ID: $groupId');
//       debugPrint(
//           'Mode: $simplifiedMode (${simplifiedMode == 0 ? "Auto" : "Manual"})');
//       debugPrint('Payload: $message');
//       debugPrint('Waiting for ACK (Type 32) on: peepul/$mac/status');
//       debugPrint('========================================');

//       _lastAckTimes[motorId] = DateTime.now();
//     } catch (e) {
//       statusMessage = 'Failed to publish mode command: $e';
//       debugPrint('Failed to publish mode command: $e');
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishGroupedMotorCommands(
//     List<Map<String, dynamic>> motorCommands,
//   ) async {
//     if (mqttClient == null || !isConnected) {
//       debugPrint('Cannot publish: MQTT not connected');
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       throw Exception('MQTT not connected');
//     }

//     Map<String, List<Map<String, dynamic>>> commandsByMac = {};

//     for (var command in motorCommands) {
//       final motorId = command['motorId'] as String;
//       final parts = motorId.split('-');
//       if (parts.length != 2) continue;

//       final mac = parts[0];
//       final groupId = parts[1];
//       final state = command['state'] as int;

//       if (!commandsByMac.containsKey(mac)) {
//         commandsByMac[mac] = [];
//       }

//       commandsByMac[mac]!.add({
//         'groupId': groupId,
//         'state': state,
//         'motorId': motorId,
//       });
//     }

//     for (var entry in commandsByMac.entries) {
//       final mac = entry.key;
//       final commands = entry.value;
//       final topic = 'peepul/$mac/status';

//       final Map<String, dynamic> groupStates = {};
//       for (var cmd in commands) {
//         groupStates[cmd['groupId']] = cmd['state'];
//       }

//       // PUBLISH with type 1 for grouped motor control commands
//       final payload = {
//         "T": 1,
//         "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         "D": groupStates,
//       };

//       final message = jsonEncode(payload);
//       final builder = MqttClientPayloadBuilder();
//       builder.addString(message);

//       for (var cmd in commands) {
//         _lastAckTimes.remove(cmd['motorId']);
//         _lastCommandTimes[cmd['motorId']] = DateTime.now();
//       }

//       try {
//         mqttClient!
//             .publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
//         debugPrint('========================================');
//         debugPrint('Published grouped motor command to: $topic');
//         debugPrint('Payload: $message');
//         debugPrint('Motors affected: ${commands.length}');
//         debugPrint('========================================');
//       } catch (e) {
//         statusMessage = 'Failed to publish grouped command: $e';
//         debugPrint('Failed to publish grouped command: $e');
//         rethrow;
//       }
//     }

//     statusMessage = 'Grouped motor commands sent successfully';
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
  String? groupId;
  String? title;

  // Signal strength properties
  int signalStrength = 0; // Raw signal strength value (0-30)
  int signalBars = 0; // Number of bars (0-4)
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

  // Calculate signal bars based on signal strength
  void updateSignalStrength(int strength) {
    signalStrength = strength;
    lastSignalUpdate = DateTime.now();

    // Determine signal bars based on strength
    if (strength < 2 || strength > 31) {
      signalBars = 0; // Invalid signal
    } else if (strength >= 2 && strength <= 9) {
      signalBars = 1; // Weak signal
    } else if (strength >= 10 && strength <= 14) {
      signalBars = 2; // Fair signal
    } else if (strength >= 15 && strength <= 19) {
      signalBars = 3; // Good signal
    } else if (strength >= 20 && strength <= 30) {
      signalBars = 4; // Excellent signal
    } else {
      signalBars = 0; // Invalid
    }

    debugPrint('Signal strength updated: $strength -> $signalBars bars');
  }

  // Check if signal data is stale (older than 60 seconds)
  bool isSignalStale() {
    if (lastSignalUpdate == null) return true;
    return DateTime.now().difference(lastSignalUpdate!).inSeconds > 60;
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

  // Add this method to your MqttService class

  /// Get the last ACK time for a motor ID
  DateTime? getLastAckTime(String motorId) {
    return _lastAckTimes[motorId];
  }

  int? _getSimplifiedModeIndex(String mode) {
    if (mode.contains('AUTO')) return 0;
    if (mode.contains('MANUAL')) return 1;
    return null;
  }

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

  int? _fullModeToSimplified(int fullModeIndex) {
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

  int _simplifiedToFullMode(int simplifiedIndex) {
    switch (simplifiedIndex) {
      case 0: // Auto
        return 3; // REMOTE+AUTO
      case 1: // Manual
        return 2; // REMOTE+MANUAL
      default:
        return 3;
    }
  }

  Future<void> initializeMqttClient() async {
    if (mqttClient != null && isConnected) {
      debugPrint('Disconnecting existing MQTT client');
      mqttClient!.disconnect();
    }

    const int port = 8883;
    String broker = 'h42c786f.ala.asia-southeast1.emqxsl.com';
    String username = 'test_user';
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
    for (var motor in motors.values) {
      if (motor.starter?.macAddress != null) {
        final mac = motor.starter!.macAddress!;
        mqttClient!.subscribe('peepul/$mac/tele', MqttQos.atMostOnce);
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
          case 31: // MOTOR CONTROL ACK (from device)
            debugPrint('Handling MOTOR CONTROL ACK (31)');
            _handleMotorControlAck(mac, payloadData);
            break;
          case 32: // MODE CHANGE ACK (from device)
            debugPrint('Handling MODE CHANGE ACK (32)');
            _handleModeChangeAck(mac, payloadData);
            break;
          case 35: // LIVE DATA REQUEST ACK
            debugPrint('Handling LIVE DATA REQUEST ACK (35)');
            _handleLiveData(mac, payloadData);
            break;
          case 40: // HEART BEAT with Signal Strength
            debugPrint('Handling HEARTBEAT with Signal Strength (40)');
            _handleHeartbeat(mac, payloadData);
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

    // Update signal strength for all motors with this MAC address
    int updatedCount = 0;
    for (var entry in motorDataMap.entries) {
      if (entry.key.startsWith(mac)) {
        final motorData = entry.value;
        motorData.updateSignalStrength(signalQuality);
        motorData.hasReceivedData = true;
        updatedCount++;

        debugPrint(
            '✓ Updated signal for ${entry.key}: strength=$signalQuality, bars=${motorData.signalBars}');
      }
    }

    debugPrint('Updated signal strength for $updatedCount motors');
  }

  void _handleMotorControlAck(String mac, dynamic payloadData) {
    debugPrint('=== Motor Control ACK (Type 31) ===');
    debugPrint('MAC: $mac');
    debugPrint('Payload Data: $payloadData');

    // payloadData should be the state (0 or 1)
    final newState = payloadData as int?;

    if (newState == null) {
      debugPrint('Invalid state in ACK: $payloadData');
      return;
    }

    debugPrint(
        'New state from ACK: $newState (${newState == 1 ? "ON" : "OFF"})');

    // Update all motors with this MAC address
    int updatedCount = 0;
    for (var entry in motorDataMap.entries) {
      if (entry.key.startsWith(mac)) {
        final motorData = entry.value;
        motorData.state = newState;
        motorData.controller.value = (newState == 1);
        motorData.hasReceivedData = true;
        _lastAckTimes[entry.key] = DateTime.now();
        updatedCount++;

        debugPrint(
            '✓ Updated motor ${entry.key}: state=$newState, controller=${motorData.controller.value}');
      }
    }

    debugPrint('Updated $updatedCount motors with new state from ACK');
  }

  void _handleModeChangeAck(String mac, dynamic payloadData) {
    debugPrint('=== Mode Change ACK (Type 32) ===');
    debugPrint('MAC: $mac');
    debugPrint('Payload Data: $payloadData');

    // payloadData should be the mode index (0 = Auto, 1 = Manual)
    final newModeIndex = payloadData as int?;

    if (newModeIndex == null || (newModeIndex != 0 && newModeIndex != 1)) {
      debugPrint('Invalid mode in ACK: $payloadData (expected 0 or 1)');
      return;
    }

    debugPrint(
        'New mode from ACK: $newModeIndex (${newModeIndex == 0 ? "Auto" : "Manual"})');

    // Update all motors with this MAC address
    int updatedCount = 0;
    for (var entry in motorDataMap.entries) {
      if (entry.key.startsWith(mac)) {
        final motorData = entry.value;
        motorData.modeIndex = newModeIndex;
        motorData.modeswitchcontroller.value = newModeIndex;
        motorData.motorMode = _modeFromSimplifiedIndex(newModeIndex);
        motorData.hasReceivedData = true;
        _lastAckTimes[entry.key] = DateTime.now();
        updatedCount++;

        debugPrint(
            '✓ Updated motor ${entry.key}: mode=${motorData.motorMode}, index=$newModeIndex');
      }
    }

    debugPrint('Updated $updatedCount motors with new mode from ACK');
  }

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

      // G01 - Full data with p_v
      if (groupData.containsKey('p_v')) {
        debugPrint('Processing $groupId with full data');

        // Update motor state
        final newState = groupData['m_s'] ?? 0;
        motorData.state = newState;
        if (motorData.controller.value != (newState == 1)) {
          motorData.controller.value = (newState == 1);
        }
        debugPrint(
            'Motor state: ${motorData.state}, Controller: ${motorData.controller.value}');

        // Update voltages
        final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
        motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
        motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
        motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';

        // Update currents
        final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
        motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
        motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
        motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';

        // Update power, fault, alert
        motorData.power = groupData['pwr'] ?? 0;
        motorData.fault = groupData['flt'] ?? 0;
        motorData.alert = groupData['alt'] ?? 0;

        // Update mode if present
        if (groupData.containsKey('mode')) {
          final modeValue = groupData['mode'] as int?;
          if (modeValue != null) {
            // Mode is already simplified: 0 = Auto, 1 = Manual
            motorData.modeIndex = modeValue;
            motorData.modeswitchcontroller.value = modeValue;
            motorData.motorMode = modeValue == 0 ? 'AUTO' : 'MANUAL';

            debugPrint(
                'Mode: ${motorData.motorMode} (index: ${motorData.modeIndex})');
          }
        }
      }
      // G02/G03 - Partial data with power
      else if (groupData.containsKey('pwr')) {
        debugPrint('Processing $groupId with partial data');

        // Update power
        motorData.power = groupData['pwr'] ?? 0;

        // Update mode if present
        if (groupData.containsKey('mode')) {
          final modeValue = groupData['mode'] as int?;
          if (modeValue != null) {
            // Mode is already simplified: 0 = Auto, 1 = Manual
            motorData.modeIndex = modeValue;
            motorData.modeswitchcontroller.value = modeValue;
            motorData.motorMode = modeValue == 0 ? 'AUTO' : 'MANUAL';

            debugPrint(
                'Mode: ${motorData.motorMode} (index: ${motorData.modeIndex})');
          }
        }

        // Update voltages if present
        if (groupData.containsKey('llv')) {
          final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
          motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
          motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
          motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
          debugPrint(
              'Updated voltages: R=${motorData.voltageRed}, Y=${motorData.voltageYellow}, B=${motorData.voltageBlue}');
        }

        // Update currents if present
        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
          debugPrint(
              'Updated currents: R=${motorData.currentRed}, Y=${motorData.currentYellow}, B=${motorData.currentBlue}');
        }

        // Update motor state if present
        if (groupData.containsKey('m_s')) {
          motorData.state = groupData['m_s'] ?? 0;
          motorData.controller.value = motorData.state == 1;
          debugPrint('Updated motor state: ${motorData.state}');
        }
      }
      // G04 - Mode only (don't overwrite existing data)
      else if (groupData.containsKey('mode')) {
        debugPrint('Processing $groupId with mode only');

        // Only update power if it's explicitly provided
        if (groupData.containsKey('pwr')) {
          motorData.power = groupData['pwr'] ?? 0;
          debugPrint('Updated power: ${motorData.power}');
        } else {
          debugPrint(
              'Power not in payload, keeping existing value: ${motorData.power}');
        }

        // Update mode
        final modeValue = groupData['mode'] as int?;
        if (modeValue != null) {
          // Mode is already simplified: 0 = Auto, 1 = Manual
          motorData.modeIndex = modeValue;
          motorData.modeswitchcontroller.value = modeValue;
          motorData.motorMode = modeValue == 0 ? 'AUTO' : 'MANUAL';

          debugPrint(
              'Mode: ${motorData.motorMode} (index: ${motorData.modeIndex})');
        }

        // Update voltages if present (shouldn't be in G04, but check anyway)
        if (groupData.containsKey('llv')) {
          final llv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
          motorData.voltageRed = llv.isNotEmpty ? llv[0].toString() : '0';
          motorData.voltageYellow = llv.length > 1 ? llv[1].toString() : '0';
          motorData.voltageBlue = llv.length > 2 ? llv[2].toString() : '0';
          debugPrint(
              'Updated voltages: R=${motorData.voltageRed}, Y=${motorData.voltageYellow}, B=${motorData.voltageBlue}');
        } else {
          debugPrint('Voltages not in payload, keeping existing values');
        }

        // Update currents if present (shouldn't be in G04, but check anyway)
        if (groupData.containsKey('amp')) {
          final amp = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
          motorData.currentRed = amp.isNotEmpty ? amp[0].toString() : '0';
          motorData.currentYellow = amp.length > 1 ? amp[1].toString() : '0';
          motorData.currentBlue = amp.length > 2 ? amp[2].toString() : '0';
          debugPrint(
              'Updated currents: R=${motorData.currentRed}, Y=${motorData.currentYellow}, B=${motorData.currentBlue}');
        } else {
          debugPrint('Currents not in payload, keeping existing values');
        }
      }
      // Unknown payload structure
      else {
        debugPrint('Unknown payload structure for $groupId: ${groupData.keys}');
      }

      motorData.hasReceivedData = true;
      motorDataMap[fullMotorId] = motorData;
      _lastAckTimes[fullMotorId] = DateTime.now();

      debugPrint('Motor $fullMotorId updated successfully');
      debugPrint(
          'Current values - Power: ${motorData.power}, VoltageR: ${motorData.voltageRed}, Mode: ${motorData.motorMode}');
    }

    debugPrint('Total motors in map: ${motorDataMap.length}');
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

    // PUBLISH with type 1 for motor control command
    final payload = {
      "T": 1,
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
      debugPrint('========================================');
      debugPrint('Published motor command to: $topic');
      debugPrint('Motor ID: $motorId');
      debugPrint('State: $state (${state == 1 ? "ON" : "OFF"})');
      debugPrint('Payload: $message');
      debugPrint('Waiting for ACK (Type 31) on: peepul/$mac/status');
      debugPrint('========================================');
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

    // PUBLISH with type 2 for mode change command
    final payload = {
      "T": 2,
      "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "D": simplifiedMode, // Send 0 or 1 directly
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _lastAckTimes.remove(motorId);

    try {
      mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      statusMessage = 'Mode command sent successfully';
      debugPrint('========================================');
      debugPrint('Published mode command to: $topic');
      debugPrint('Motor ID: $motorId');
      debugPrint('Group ID: $groupId');
      debugPrint(
          'Mode: $simplifiedMode (${simplifiedMode == 0 ? "Auto" : "Manual"})');
      debugPrint('Payload: $message');
      debugPrint('Waiting for ACK (Type 32) on: peepul/$mac/status');
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

    for (var entry in commandsByMac.entries) {
      final mac = entry.key;
      final commands = entry.value;
      final topic = 'peepul/$mac/status';

      final Map<String, dynamic> groupStates = {};
      for (var cmd in commands) {
        groupStates[cmd['groupId']] = cmd['state'];
      }

      // PUBLISH with type 1 for grouped motor control commands
      final payload = {
        "T": 1,
        "S": DateTime.now().millisecondsSinceEpoch ~/ 1000,
        "D": groupStates,
      };

      final message = jsonEncode(payload);
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

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
