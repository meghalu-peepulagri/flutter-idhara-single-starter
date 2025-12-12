// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/core/config/env.dart';
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

//   String runTime = '-';
//   String automationMode = '--';
//   bool hasReceivedData = false;
//   String? pondId;
//   String? ipv6;
//   String? mac;
//   String? title;
//   String? faultCode;
//   String? alertCode;
//   String? power;

//   MotorData(
//       {this.pondId,
//       this.ipv6,
//       this.mac,
//       this.title,
//       this.faultCode,
//       this.alertCode});

//   MotorData.fromMap(Map<String, dynamic> map) {
//     voltageRed = map['voltageRed'] ?? '0';
//     voltageYellow = map['voltageYellow'] ?? '0';
//     voltageBlue = map['voltageBlue'] ?? '0';
//     currentRed = map['currentRed'] ?? '0';
//     currentYellow = map['currentYellow'] ?? '0';
//     currentBlue = map['currentBlue'] ?? '0';
//     state = map['state'] ?? 0;
//     motorMode = map['mode'];

//     power = map['power'];
//     modeIndex = map['modeIndex'];

//     runTime = map['runTime'] ?? '-';
//     automationMode = map['automationMode'] ?? '--';
//     faultCode = map['faultCode'];
//     alertCode = map['alertCode'];
//     pondId = map['pondId'];
//     ipv6 = map['ipv6'];
//     mac = map['mac'];
//     title = map['title'];
//     controller.value = state == 1 || state == 6;
//     modeswitchcontroller.value = modeIndex;
//     hasReceivedData = true;
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'voltageRed': voltageRed,
//       'mode': motorMode,
//       'voltageYellow': voltageYellow,
//       'voltageBlue': voltageBlue,
//       'currentRed': currentRed,
//       'currentYellow': currentYellow,
//       'currentBlue': currentBlue,
//       'modeIndex': modeIndex,
//       'state': state,
//       'runTime': runTime,
//       'automationMode': automationMode,
//       'faultCode': faultCode,
//       'alertCode': alertCode,
//       'pondId': pondId,
//       'ipv6': ipv6,
//       'mac': mac,
//       'title': title,
//       "power": power
//     };
//   }

//   void dispose() {
//     controller.dispose();
//     modeswitchcontroller.dispose();
//   }
// }

// class MqttService {
//   static final MqttService _instance = MqttService._internal();
//   static String? mainGateway;
//   static String? topic1;
//   static String? topic2;
//   static String? topic3;
//   static String? topic4;

//   // Factory constructor to allow initial population of pondMotorMap
//   factory MqttService(
//       {Map<String, List<Map<String, String>>>? initialPondMotorMap}) {
//     if (initialPondMotorMap != null) {
//       _instance.pondMotorMap = initialPondMotorMap;
//       _instance._populateMotorDataMapFromPondMotorMap();
//     }
//     _instance._initializeService();
//     return _instance;
//   }

//   MqttServerClient? mqttClient;
//   late Map<String, MotorData>
//       motorDataMap; // Stores motor data by fullMotorId (ipv6-motorRefId)
//   bool isConnected = false;
//   String statusMessage = 'Connecting to MQTT broker...';
//   DateTime? lastMessageTime;
//   final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);
//   Map<String, List<Map<String, String>>> pondMotorMap =
//       {}; // Maps pond IDs to lists of motor details
//   bool _isDataLoaded = false;
//   final Map<String, DateTime> _lastAckTimes =
//       {}; // Tracks last acknowledgment times
//   final Map<String, DateTime> _lastCommandTimes =
//       {}; // Tracks last command times
//   Map<String, Map<String, Motor>> deviceDataMap = {};
//   MqttService._internal() {
//     motorDataMap = {};
//     _initializeService();
//   }

//   ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;

//   // Method to manually update pondMotorMap from outside the class
//   void updatePondMotorMap(
//       Map<String, List<Map<String, String>>> newPondMotorMap) {
//     pondMotorMap = newPondMotorMap;
//     _dataUpdateNotifier.value++;
//   }

//   Motor? getDeviceByMac(String mac) {
//     for (var pondEntry in deviceDataMap.entries) {
//       if (pondEntry.value.containsKey(mac)) {
//         return pondEntry.value[mac];
//       }
//     }
//     return null; // Not found
//   }

//   void updateDeviceModeByMac(String mac, String newMode) {
//     for (var pondEntry in deviceDataMap.entries) {
//       if (pondEntry.value.containsKey(mac)) {
//         pondEntry.value[mac]!.mode = newMode;

//         dataUpdateNotifier.value++;
//         return;
//       }
//     }
//   }

//   // Initializes the service by requesting permissions and fetching initial data
//   Future<void> _initializeService() async {
//     // await _requestPermissions();

//     await initializeMqttClient();
//     // if (gateway != null && gateway.isNotEmpty) {

//     // }
//   }

//   void _populateMotorDataMapFromPondMotorMap() {
//     motorDataMap.clear();
//     for (var entry in pondMotorMap.entries) {
//       final pondId = entry.key;
//       for (var motor in entry.value) {
//         final fullMotorId = motor['id']!;
//         final ipv6 = motor['ipv6']!;
//         final mac = motor['mac'];
//         final motorRefId = motor['motorRefId']!;
//         final title = motor['motorName'];

//         motorDataMap[fullMotorId] = MotorData(
//             pondId: pondId,
//             ipv6: ipv6,
//             mac: mac,
//             title: title,
//             faultCode: motor['faultCode'],
//             alertCode: motor['alertCode'])
//           ..power = motor['power']
//           ..motorMode = motor['mode'] ?? ""
//           ..modeIndex = int.tryParse(motor['modeIndex']!)
//           ..state = int.tryParse(motor['state']!) ?? 0
//           ..voltageRed = motor['voltageRed']!
//           ..voltageYellow = motor['voltageYellow']!
//           ..voltageBlue = motor['voltageBlue']!
//           ..currentRed = motor['currentRed']!
//           ..currentYellow = motor['currentYellow']!
//           ..currentBlue = motor['currentBlue']!
//           ..automationMode = motor['motor_mode'] ?? '--'
//           ..hasReceivedData = true;
//         final newId = "$mac - $motorRefId";

//         // try {
//         //   ModesController modeController = Get.find<ModesController>();

//         //   modeController.switchIndexes[newId] =
//         //       motorDataMap[fullMotorId]!.modeIndex!;
//         // } catch (e) {}
//       }
//     }
//     _isDataLoaded = true;
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> initializeMqttClient() async {
//     if (mqttClient != null && isConnected) {
//       mqttClient!.disconnect();
//     }
// //e2b4bba3.ala.asia-southeast1.emqxsl.com
//     // const String broker = 'e2b4bba3.ala.asia-southeast1.emqxsl.com';
//     // const String username = 'pa_prod_starter';
//     // const String password = 'Starter@446688';
//     const int port = 8883;
//     String broker = AppEnvironment.mqttBroker;
//     String username = AppEnvironment.mqttUsername;
//     String password = AppEnvironment.mqttPassword;
//     String statusTopic = 'gateways/+/devices/live_data';
//     String ackTopic = 'gateways/+/devices/motor_control/ack';
//     String ackTopic1 = 'gateways/+/devices/motors/mode/ack';
//     String ackTopic2 = 'gateways/+/devices/mode_change/ack';

//     // final String clientId = SharedPreference.getClientId();

//     const uuid = Uuid();
//     final String clientId = '123456_${uuid.v4()}';

//     mqttClient = MqttServerClient(broker, clientId);
//     mqttClient!.logging(on: true);
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

//     final connMessage = MqttConnectMessage()
//         .authenticateAs(username, password)
//         // .withWillTopic('willtopic')
//         // .withWillMessage('Will message')
//         .startClean();
//     // .withWillQos(MqttQos.atLeastOnce);
//     mqttClient!.connectionMessage = connMessage;
//     try {
//       await mqttClient?.connect();
//     } catch (e) {
//       return;
//     }

//     mqttClient!.updates!.listen(_onMessageReceived, onError: (e) {
//       statusMessage = 'Stream error: $e';
//       _dataUpdateNotifier.value++;
//     });
//   }

//   // Attempts to connect to MQTT broker with retries
//   Future<void> _connectWithRetry(
//       {required String topic, int delaySeconds = 5}) async {
//     int retryCount = 0;
//     while (!isConnected && retryCount < 5) {
//       try {
//         await mqttClient!.connect();
//         isConnected = true;
//         statusMessage = 'Connected. Waiting for data on topic: $topic';

//         mqttClient!.subscribe(topic, MqttQos.atLeastOnce);
//         return;
//       } catch (e) {
//         isConnected = false;
//         statusMessage = 'Reconnecting... ($e)';
//         _dataUpdateNotifier.value++;
//         retryCount++;
//         await Future.delayed(Duration(seconds: delaySeconds));
//       }
//     }
//     if (!isConnected) {
//       statusMessage = 'Connection failed after multiple attempts';
//     }
//   }

//   void _onConnected() {
//     isConnected = true;
//     statusMessage = 'Connected. Waiting for device data...';
//     topic1 = 'gateways/+/devices/live_data';
//     topic2 = 'gateways/+/devices/motor_control/ack';
//     topic3 = 'gateways/+/devices/motors/mode/ack';
//     topic4 = 'gateways/+/devices/mode_change/ack';

//     mqttClient!.subscribe(topic1!, MqttQos.atLeastOnce);
//     mqttClient!.subscribe(topic2!, MqttQos.atLeastOnce);
//     mqttClient!.subscribe(topic3!, MqttQos.atLeastOnce);
//     mqttClient!.subscribe(topic4!, MqttQos.atLeastOnce);

//     _dataUpdateNotifier.value++;
//   }

//   void _onDisconnected() {
//     isConnected = false;
//     statusMessage = 'Disconnected. Displaying latest data from API...';
//     _dataUpdateNotifier.value++;
//   }

//   void _onSubscribed(String topic) {
//     statusMessage = 'Subscribed to $topic. Waiting for data...';
//     _dataUpdateNotifier.value++;
//   }

//   void _onAutoReconnect() {}

//   void _onAutoReconnected() {
//     topic1 = 'gateways/+/devices/live_data';
//     topic2 = 'gateways/+/devices/motor_control/ack';
//     topic3 = 'gateways/+/devices/motors/mode/ack';
//     topic4 = 'gateways/+/devices/mode_change/ack';
//     mqttClient!.subscribe(topic1!, MqttQos.atLeastOnce);
//     mqttClient!.subscribe(topic2!, MqttQos.atLeastOnce);
//     mqttClient!.subscribe(topic3!, MqttQos.atLeastOnce);
//     mqttClient!.subscribe(topic4!, MqttQos.atLeastOnce);
//   }

//   bool _isRecentAck(String motorId) {
//     final lastAckTime = _lastAckTimes[motorId];
//     if (lastAckTime == null) return false;
//     final timeSinceAck = DateTime.now().difference(lastAckTime);
//     return timeSinceAck.inSeconds < 5;
//   }

//   // Handles incoming MQTT messages and updates motorDataMap
//   void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
//     lastMessageTime = DateTime.now();
//     for (var message in messages) {
//       final payload = MqttPublishPayload.bytesToStringAsString(
//           (message.payload as MqttPublishMessage).payload.message);
//       final topic = message.topic;

//       try {
//         final data = jsonDecode(payload);
//         if (topic.endsWith('/devices/mode_change/ack')) {
//           final devices = data['dev'] as List<dynamic>?;

//           if (devices == null) {
//             continue;
//           }

//           for (var device in devices) {
//             final deviceData = device as Map<String, dynamic>;

//             final deviceMac = deviceData['d_id'] as String?;

//             deviceData.entries.where((e) => e.key != 'd_id').forEach((entry) {
//               final motorRefId = entry.key; // 'mtr_1', 'mtr_2', etc.
//               final modeValue = entry.value as int?;
//               if (modeValue == null || modeValue >= 4) return;
//               final mode = switch (modeValue) {
//                 0 => "LOCAL + MANUAL",
//                 1 => "LOCAL + AUTO",
//                 2 => "REMOTE + MANUAL",
//                 3 => "REMOTE + AUTO",
//                 _ => '--',
//               };
//               modeConversion(String val) {
//                 if (val.contains('AUTO')) {
//                   return 0;
//                 } else if (val.contains('MANUAL')) {
//                   return 1;
//                 } else {
//                   return null;
//                 }
//               }

//               updateDeviceModeByMac(deviceMac!, mode);
//               final fullMotorId = '$deviceMac-$motorRefId';
//               final motorData = motorDataMap[fullMotorId];
//               if (motorData != null) {
//                 motorData.motorMode = mode;
//                 motorDataMap[fullMotorId] = motorData;
//                 try {
//                   final newId = "${motorData.mac} - $motorRefId";
//                   final modeController = Get.find<ModesController>();
//                   modeController.switchIndexes[newId] = modeConversion(mode)!;
//                 } catch (e) {}
//               }
//               _lastAckTimes[fullMotorId] = DateTime.now();
//             });
//           }
//           _dataUpdateNotifier.value++;
//           continue;
//         }
//         if (topic.endsWith('/devices/motors/mode/ack')) {
//           final devices = data['dev'] as List<dynamic>?;

//           if (devices == null) {
//             continue;
//           }

//           for (var device in devices) {
//             final deviceData = device as Map<String, dynamic>;
//             final deviceMac = deviceData['d_id'] as String?;
//             final modeValue = deviceData['mode'];
//             if (deviceMac == null) {
//               continue;
//             }
//             final mode = switch (modeValue) {
//               0 => "LOCAL + MANUAL",
//               1 => "LOCAL + AUTO",
//               2 => "REMOTE + MANUAL",
//               3 => "REMOTE + AUTO",
//               _ => '--',
//             };
//             updateDeviceModeByMac(deviceMac, mode);
//           }
//           _dataUpdateNotifier.value++;
//           continue;
//         }

//         if (topic.endsWith('/motor_control/ack')) {
//           final devices = data['dev'] as List<dynamic>?;
//           if (devices == null) {
//             continue;
//           }

//           for (var device in devices) {
//             final deviceData = device as Map<String, dynamic>;
//             final deviceMac = deviceData['d_id'] as String?;
//             if (deviceMac == null) {
//               continue;
//             }

//             final pondId = _getPondIdForMac(deviceMac);

//             // Process each key-value pair except 'd_id'
//             for (var entry in deviceData.entries) {
//               if (entry.key == 'd_id') continue;
//               final motorRefId = entry.key;
//               final state = entry.value as int?;

//               if (state == null || state >= 2) return;
//               // final fullMotorId = '$deviceMac-$motorRefId';
//               final fullMotorId = '$deviceMac-$motorRefId';
//               final motorTitle = _getMotorTitle(deviceMac, motorRefId);

//               final motorData = motorDataMap[fullMotorId] ??
//                   MotorData(pondId: pondId, mac: deviceMac, title: motorTitle);

//               motorData.state = state;
//               motorData.controller.value = state == 1 || state == 6;

//               motorDataMap[fullMotorId] = motorData;
//               _lastAckTimes[fullMotorId] = DateTime.now();
//             }
//           }
//           continue;
//         }

//         if (topic.endsWith('/live_data')) {
//           final deviceMac = data['d_id'] as String?;
//           final motorsData = data['mtr'] as List<dynamic>?;
//           final power = data['pwr'].toString();
//           final deviceMode = data['mode'] as int?;
//           String mainMode;
//           if (deviceMode != null) {
//             mainMode = switch (deviceMode) {
//               0 => 'LOCAL+MANUAL',
//               1 => 'LOCAL+AUTO',
//               2 => 'REMOTE+MANUAL',
//               3 => 'REMOTE+AUTO',
//               _ => '--',
//             };
//             try {
//               updateDeviceModeByMac(deviceMac!, mainMode);
//             } catch (e) {}
//           }

//           if (deviceMac == null || motorsData == null) {
//             continue;
//           }

//           for (var motor in motorsData) {
//             String motorRefId;
//             motor['mtr_id'] == 1 ? motorRefId = "mtr_1" : motorRefId = "mtr_2";

//             final current = motor['amp'] as List<dynamic>? ?? [0, 0, 0];
//             final state = motor['mtr_sts'] as int?;
//             final faultCode = motor['flt'] as int?;
//             final alertCode = motor['alt'] as int?;
//             // Modified: Use mode from motor data instead of top-level mode
//             final motorMode = motor['mode'] as int?;

//             if (motorMode != null) {
//               mainMode = switch (motorMode) {
//                 0 => 'LOCAL+MANUAL',
//                 1 => 'LOCAL+AUTO',
//                 2 => 'REMOTE+MANUAL',
//                 3 => 'REMOTE+AUTO',
//                 _ => '--',
//               };

//               // Modified: Update device mode with motor-specific mode
//               try {
//                 updateDeviceModeByMac(deviceMac, mainMode);
//               } catch (e) {}
//             }

//             if (state == null || state >= 2) {
//               continue;
//             }
//             final fullMotorId = '$deviceMac-$motorRefId';
//             final pondId = _getPondIdForMac(deviceMac);
//             final motorTitle = _getMotorTitle(deviceMac, motorRefId);

//             final motorData = motorDataMap[fullMotorId] ??
//                 MotorData(pondId: pondId, mac: deviceMac, title: motorTitle);

//             final lv = data['ll_v'] as List<dynamic>? ?? [0, 0, 0];
//             motorData.modeswitchcontroller.value = motorMode;

//             modeConversion(String val) {
//               if (val.contains('AUTO')) {
//                 return 0;
//               } else if (val.contains('MANUAL')) {
//                 return 1;
//               } else {
//                 return null;
//               }
//             }

//             try {
//               if (mainMode.isNotEmpty) {
//                 final newId = "${motor.mac} - $motorRefId";
//                 final modeController = Get.find<ModesController>();
//                 modeController.switchIndexes[newId] = modeConversion(mainMode)!;
//               }
//             } catch (e) {}
//             motorData.voltageRed = lv.isNotEmpty ? lv[0].toString() : '0';
//             motorData.voltageYellow = lv.length > 1 ? lv[1].toString() : '0';
//             motorData.voltageBlue = lv.length > 2 ? lv[2].toString() : '0';
//             motorData.currentRed =
//                 current.isNotEmpty ? current[0].toString() : '0';
//             motorData.currentYellow =
//                 current.length > 1 ? current[1].toString() : '0';
//             motorData.currentBlue =
//                 current.length > 2 ? current[2].toString() : '0';
//             motorData.power = power;
//             motorData.state = state;
//             motorData.controller.value = state == 1;
//             // Modified: Set automationMode to motor-specific mode
//             motorData.automationMode = mainMode;
//             motorData.motorMode = mainMode;
//             motorData.faultCode =
//                 faultCode?.toString();
//             motorData.alertCode =
//                 alertCode?.toString();
//             motorData.hasReceivedData = true;

//             motorDataMap[fullMotorId] = motorData;
//             _lastAckTimes[fullMotorId] = DateTime.now();

//             // Added: Publish the mode to MQTT broker
//             final modePayload = {
//               "dev": [
//                 {
//                   "d_id": deviceMac,
//                   motorRefId: motorMode,
//                 }
//               ]
//             };
//             // publishModeCommand(modePayload);
//           }
//           continue;
//         }

//         final motorsData = data['mtr'];
//         final mac = data['d_id'] as String?;
//         // final motorMode = data['mode'] as int?;
//         final power = data['pwr'].toString();
//         // final mode;
//         // switch (motorMode) {
//         //   case 0:
//         //     mode = 'LOCAL + MANUAL';
//         //     break;
//         //   case 1:
//         //     mode = 'LOCAL + AUTO';
//         //     break;
//         //   case 2:
//         //     mode = 'REMOTE + MANUAL';
//         //     break;
//         //   case 3:
//         //     mode = 'REMOTE + AUTO';
//         //     break;
//         //   default:
//         //     mode = '--';
//         //     break;
//         // }

//         // updateDeviceModeByMac(mac ?? '', mode);
//         // if (mac == null) {
//         //   continue;
//         // }

//         if (mac == null) {
//           continue;
//         }

//         if (motorsData != null) {
//           List<Map<String, dynamic>> motorsList = motorsData is List
//               ? motorsData.cast<Map<String, dynamic>>()
//               : [motorsData];

//           for (var motor in motorsList) {
//             final String motorRefId;
//             motor['mtr_id'] == 1 ? motorRefId = "mtr_1" : motorRefId = "mtr_2";
//             final fullMotorId = '$mac-$motorRefId';
//             final pondId = _getPondIdForMac(mac);
//             final motorTitle = _getMotorTitle(mac, motorRefId);

//             final currentMotor = motorDataMap[fullMotorId] ??
//                 MotorData(pondId: pondId, mac: mac, title: motorTitle);

//             if (currentMotor.hasReceivedData && _isRecentAck(fullMotorId)) {
//               continue;
//             }

//             currentMotor.hasReceivedData = true;

//             final lv = data['ll_v'] as List<dynamic>? ?? [0, 0, 0];
//             currentMotor.voltageRed = lv.isNotEmpty ? lv[0].toString() : '0';
//             currentMotor.voltageYellow = lv.length > 1 ? lv[1].toString() : '0';
//             currentMotor.voltageBlue = lv.length > 2 ? lv[2].toString() : '0';

//             final current = motor['amp'] as List<dynamic>? ?? [0, 0, 0];
//             currentMotor.currentRed =
//                 current.isNotEmpty ? current[0].toString() : '0';
//             currentMotor.currentYellow =
//                 current.length > 1 ? current[1].toString() : '0';
//             currentMotor.currentBlue =
//                 current.length > 2 ? current[2].toString() : '0';
//             currentMotor.power = power;
//             currentMotor.state = motor['mtr_sts']?.toInt() ?? 0;
//             currentMotor.controller.value = currentMotor.state == 1;
//             // currentMotor.modeswitchcontroller.value = currentMotor.modeIndex;

//             currentMotor.runTime = data['t'] != null ? '${data['t']}s' : '-';
//             // currentMotor.automationMode = mode;
//             final motorMode = motor['mode'] as int?;

//             final mode = switch (motorMode) {
//               0 => 'LOCAL + MANUAL',
//               1 => 'LOCAL + AUTO',
//               2 => 'REMOTE + MANUAL',
//               3 => 'REMOTE + AUTO',
//               _ => '--',
//             };

//             final modePayload = {
//               "dev": [
//                 {
//                   "d_id": mac,
//                   motorRefId: motorMode,
//                 }
//               ]
//             };
//             // publishModeCommand(modePayload);

//             currentMotor.automationMode = mode;
//             currentMotor.faultCode =
//                 motor['flt']?.toString();
//             currentMotor.alertCode =
//                 motor['alt']?.toString();

//             motorDataMap[fullMotorId] = currentMotor;
//           }
//         }
//       } catch (e, stackTrace) {
//         statusMessage = 'Invalid data format received';
//       }
//     }
//     _dataUpdateNotifier.value++;
//   }

//   String? _getPondIdForMac(String mac) {
//     for (var entry in pondMotorMap.entries) {
//       for (var motor in entry.value) {
//         if (motor['id']!.startsWith(mac)) {
//           return entry.key;
//         }
//       }
//     }
//     return null;
//   }

//   String? _getMotorTitle(String mac, String motorRefId) {
//     for (var entry in pondMotorMap.entries) {
//       for (var motor in entry.value) {
//         if (motor['id'] == '$mac-$motorRefId') {
//           return motor['title'];
//         }
//       }
//     }
//     return motorRefId;
//   }

//   // Filters motor data for a specific pond ID using pondMotorMap

//   Map<String, MotorData> getMotorDataForPond(String selectedPondId) {
//     final macsForPond = pondMotorMap[selectedPondId]
//             ?.map((motor) => motor['id']?.split('-')[0] ?? '')
//             .toSet()
//             .toList() ??
//         [];

//     final result = Map<String, MotorData>.fromEntries(
//       motorDataMap.entries.where((entry) {
//         final motorMac = entry.value.mac;
//         final isMatch = macsForPond.contains(motorMac);

//         return isMatch;
//       }),
//     );

//     return result;
//   }

//   // Publishes a motor command to the MQTT broker
//   Future<void> publishMotorCommand(
//       String pondId, String motorId, int state) async {
//     if (mqttClient == null || !isConnected) {
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       return;
//     }

//     final lastCommandTime = _lastCommandTimes[motorId];
//     if (lastCommandTime != null &&
//         DateTime.now().difference(lastCommandTime).inSeconds < 2) {
//       return;
//     }

//     final currentMotorData = motorDataMap[motorId];
//     if (currentMotorData != null && currentMotorData.state == state) {
//       return;
//     }

//     final parts = motorId.split('-');
//     final mac = parts.length > 1 ? parts[0] : pondId;

//     final motorRefId = parts.length > 1 ? parts[1] : motorId;

//     final topic =
//         'gateways/${SharedPreference.getpeepulagri()}/devices/motor_control';

//     final payload = {
//       "dev": [
//         {
//           "d_id": mac,
//           motorRefId: state,
//         }
//       ]
//     };
//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     _lastAckTimes.remove(motorId);
//     _lastCommandTimes[motorId] = DateTime.now();

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

//       statusMessage = 'Command sent successfully';
//     } catch (e) {
//       statusMessage = 'Failed to publish command: $e';
//       _lastCommandTimes.remove(motorId);
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishGroupedMotorCommand(
//       List<Map<String, dynamic>> devList) async {
//     if (mqttClient == null || !isConnected) {
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       return;
//     }

//     final topic =
//         'gateways/${SharedPreference.getpeepulagri()}/devices/motor_control';

//     final payload = {"dev": devList};
//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

//       statusMessage = 'Grouped command sent successfully';
//     } catch (e) {
//       statusMessage = 'Failed to publish grouped command: $e';
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishSchedule(Map<String, dynamic> schedule) async {
//     if (mqttClient == null || !isConnected) {
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       return;
//     }

//     final topic =
//         'gateways/${SharedPreference.getpeepulagri()}/devices/schedule';

//     final payload = schedule;

//     //  {"dev": devList};
//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

//       statusMessage = 'Grouped command sent successfully';
//       print(statusMessage);
//     } catch (e) {
//       statusMessage = 'Failed to publish grouped command: $e';
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishModeCommand(Map<String, dynamic> payload) async {
//     if (mqttClient == null || !isConnected) {
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;

//       return;
//     }

//     final topic =
//         'gateways/${SharedPreference.getpeepulagri()}/devices/mode_change';

//     // 'gateways/${SharedPreference.getpeepulagri()}/devices/motors/mode';

//     // final payload = payload;
//     // {

//     // "dev": [
//     //   {
//     //     "d_id": mac,
//     //     "mtr_1": mode,
//     //   }
//     // ]
//     // };
//     final message = jsonEncode(payload);
//     final builder = MqttClientPayloadBuilder();
//     builder.addString(message);

//     try {
//       mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
//       statusMessage = 'Command sent successfully';
//       if (statusMessage == 'Command sent successfully') {
//         final modeController = Get.find<ModesController>();
//       }
//     } catch (e) {
//       statusMessage = 'Failed to publish command: $e';

//       // _lastCommandTimes.remove(motorId);
//       _dataUpdateNotifier.value++;
//       rethrow;
//     }
//     _dataUpdateNotifier.value++;
//   }

//   Future<void> publishModeChanges() async {
//     if (mqttClient == null || !isConnected) {
//       statusMessage = 'MQTT not connected';
//       _dataUpdateNotifier.value++;
//       return;
//     }
//     final modeController = Get.find<ModesController>();
//     if (modeController.selectModes.isEmpty) {
//       return;
//     }

//     final devList = modeController.selectModes
//         .map((modeEntry) {
//           final mac = modeEntry['id'] as String?;
//           final motorRefId = modeEntry['mtr'] as String?;
//           final modeValue = modeEntry['mode'] as int?;
//           if (mac == null || motorRefId == null || modeValue == null) {
//             return null;
//           }
//           return {
//             "d_id": mac,
//             motorRefId: modeValue,
//           };
//         })
//         .where((entry) => entry != null)
//         .cast<Map<String, dynamic>>()
//         .toList();

//     if (devList.isEmpty) {
//       return;
//     }

//     final payload = {"dev": devList};
//     await publishModeCommand(payload);
//   }

//   // Returns a list of all pond IDs from pondMotorMap
//   List<String> getPondIds() => pondMotorMap.keys.toList();

//   // Cleans up resources by disconnecting the MQTT client
//   void dispose() {
//     mqttClient?.disconnect();
//   }
// }

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/core/config/env.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

class MotorData {
  ValueNotifier<bool> controller = ValueNotifier<bool>(false);
  String voltageRed = '0';
  String voltageYellow = '0';
  String voltageBlue = '0';
  String currentRed = '0';
  String currentYellow = '0';
  String currentBlue = '0';
  int state = 0;
  String motorMode = '_';
  String? faultCode;
  String? alertCode;
  String? power;
  bool hasReceivedData = false;
  String? mac;
  String? motorRefId;
  String? title;

  MotorData({
    this.mac,
    this.motorRefId,
    this.title,
    this.faultCode,
    this.alertCode,
  });

  void updateFromPayload(Map<String, dynamic> data, String groupKey) {
    final groupData = data[groupKey] as Map<String, dynamic>?;
    if (groupData == null) return;

    // Update power
    if (groupData.containsKey('pwr')) {
      power = groupData['pwr'].toString();
    }

    // Update mode
    if (groupData.containsKey('mode')) {
      final modeValue = groupData['mode'] as int?;
      motorMode = _getModeString(modeValue);
    }

    // Update line voltages
    if (groupData.containsKey('llv')) {
      final lv = groupData['llv'] as List<dynamic>? ?? [0, 0, 0];
      voltageRed = lv.isNotEmpty ? lv[0].toString() : '0';
      voltageYellow = lv.length > 1 ? lv[1].toString() : '0';
      voltageBlue = lv.length > 2 ? lv[2].toString() : '0';
    }

    // Update motor state
    if (groupData.containsKey('m_s')) {
      state = groupData['m_s'] as int? ?? 0;
      controller.value = state == 1;
    }

    // Update current (amp)
    if (groupData.containsKey('amp')) {
      final current = groupData['amp'] as List<dynamic>? ?? [0, 0, 0];
      currentRed = current.isNotEmpty ? current[0].toString() : '0';
      currentYellow = current.length > 1 ? current[1].toString() : '0';
      currentBlue = current.length > 2 ? current[2].toString() : '0';
    }

    // Update fault code
    if (groupData.containsKey('flt')) {
      faultCode = groupData['flt']?.toString();
    }

    // Update alert code
    if (groupData.containsKey('alt')) {
      alertCode = groupData['alt']?.toString();
    }

    hasReceivedData = true;
  }

  String _getModeString(int? mode) {
    return switch (mode) {
      0 => 'LOCAL + MANUAL',
      1 => 'LOCAL + AUTO',
      2 => 'REMOTE + MANUAL',
      3 => 'REMOTE + AUTO',
      _ => '--',
    };
  }

  void dispose() {
    controller.dispose();
  }
}

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;

  MqttServerClient? mqttClient;
  Map<String, MotorData> motorDataMap = {};
  bool isConnected = false;
  String statusMessage = 'Connecting to MQTT broker...';
  DateTime? lastMessageTime;
  final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);

  // Motor ID format: {mac}-{motorRefId}
  // motorRefId can be "G01", "G02", "mtr_1", "mtr_2"
  Map<String, String> macToMotorRefMap = {};

  MqttService._internal();

  ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;

  Future<void> initializeMqttClient() async {
    if (mqttClient != null && isConnected) {
      mqttClient!.disconnect();
    }

    const int port = 8883;
    String broker = AppEnvironment.mqttBroker;
    String username = AppEnvironment.mqttUsername;
    String password = AppEnvironment.mqttPassword;

    const uuid = Uuid();
    final String clientId = 'idhara_${uuid.v4()}';

    mqttClient = MqttServerClient(broker, clientId);
    mqttClient!.logging(on: false);
    mqttClient!.keepAlivePeriod = 60;
    mqttClient!.connectTimeoutPeriod = 10000;
    mqttClient!.autoReconnect = true;
    mqttClient!.onConnected = _onConnected;
    mqttClient!.onDisconnected = _onDisconnected;
    mqttClient!.onAutoReconnect = _onAutoReconnect;
    mqttClient!.onAutoReconnected = _onAutoReconnected;
    mqttClient!.secure = true;
    mqttClient!.port = port;

    final connMessage =
        MqttConnectMessage().authenticateAs(username, password).startClean();

    mqttClient!.connectionMessage = connMessage;

    try {
      await mqttClient?.connect();
    } catch (e) {
      debugPrint('MQTT Connection Error: $e');
      return;
    }

    mqttClient!.updates!.listen(_onMessageReceived, onError: (e) {
      statusMessage = 'Stream error: $e';
      _dataUpdateNotifier.value++;
    });
  }

  void _onConnected() {
    isConnected = true;
    statusMessage = 'Connected. Waiting for device data...';

    // Subscribe to all device telemetry topics
    mqttClient!.subscribe('peepul/+/tele', MqttQos.atLeastOnce);

    // Subscribe to all device status topics
    mqttClient!.subscribe('peepul/+/status', MqttQos.atLeastOnce);

    _dataUpdateNotifier.value++;
    debugPrint('MQTT Connected and subscribed to topics');
  }

  void _onDisconnected() {
    isConnected = false;
    statusMessage = 'Disconnected. Attempting to reconnect...';
    _dataUpdateNotifier.value++;
    debugPrint('MQTT Disconnected');
  }

  void _onAutoReconnect() {
    debugPrint('MQTT Auto-reconnecting...');
  }

  void _onAutoReconnected() {
    debugPrint('MQTT Auto-reconnected');
    // Resubscribe to topics
    mqttClient!.subscribe('peepul/+/tele', MqttQos.atLeastOnce);
    mqttClient!.subscribe('peepul/+/status', MqttQos.atLeastOnce);
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    lastMessageTime = DateTime.now();

    for (var message in messages) {
      final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message);
      final topic = message.topic;

      try {
        final data = jsonDecode(payload);

        // Extract MAC address from topic (peepul/{mac}/tele or peepul/{mac}/status)
        final topicParts = topic.split('/');
        if (topicParts.length < 2) continue;

        final mac = topicParts[1];
        final topicType = topicParts.length > 2 ? topicParts[2] : '';

        // Handle telemetry data (live data)
        if (topicType == 'tele') {
          _handleTelemetryData(data, mac);
        }
        // Handle status data (ACK messages)
        else if (topicType == 'status') {
          _handleStatusData(data, mac);
        }
      } catch (e, stackTrace) {
        debugPrint('Error parsing MQTT message: $e');
        debugPrint('StackTrace: $stackTrace');
        statusMessage = 'Invalid data format received';
      }
    }

    _dataUpdateNotifier.value++;
  }

  void _handleTelemetryData(Map<String, dynamic> data, String mac) {
    final type = data['T'] as int?;

    // Type 35 is LIVE DATA
    if (type != 41) return;

    final deviceData = data['D'] as Map<String, dynamic>?;
    if (deviceData == null) return;

    // Process each group (G01, G02, G03, G04)
    for (var entry in deviceData.entries) {
      final groupKey = entry.key;
      if (groupKey == 'ct') continue; // Skip timestamp

      // Group keys are like "G01", "G02", etc.
      final motorId = '$mac-$groupKey';

      // Get or create motor data
      final motorData = motorDataMap[motorId] ??
          MotorData(
            mac: mac,
            motorRefId: groupKey,
            title: groupKey,
          );

      // Update motor data from payload
      motorData.updateFromPayload(data['D'], groupKey);

      motorDataMap[motorId] = motorData;
    }
  }

  void _handleStatusData(Map<String, dynamic> data, String mac) {
    final type = data['T'] as int?;
    final statusData = data['D'];

    // Type 31 is MOTOR CONTROL ACK
    // Type 32 is MODE CHANGE ACK
    if (type == 31) {
      _handleMotorControlAck(statusData, mac);
    } else if (type == 32) {
      _handleModeChangeAck(statusData, mac);
    }
  }

  void _handleMotorControlAck(dynamic statusData, String mac) {
    // statusData should be 1 for success
    if (statusData == 1) {
      debugPrint('Motor control ACK received for $mac');
      // The actual state update will come through telemetry
    }
  }

  void _handleModeChangeAck(dynamic statusData, String mac) {
    // statusData should be 1 for success
    if (statusData == 1) {
      debugPrint('Mode change ACK received for $mac');
      // The actual mode update will come through telemetry
    }
  }

  Future<void> publishMotorCommand(String motorId, int state) async {
    if (mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    final parts = motorId.split('-');
    if (parts.length != 2) {
      throw Exception('Invalid motor ID format');
    }

    final mac = parts[0];
    final groupKey = parts[1];

    // Topic format: peepul/{mac}/ctrl
    final topic = 'peepul/$mac/ctrl';

    // Payload format for motor control
    final payload = {
      "T": 21, // Motor control type
      "D": {
        groupKey: {
          "m_s": state, // 0 = OFF, 1 = ON
        }
      }
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      statusMessage = 'Command sent successfully';
      debugPrint('Published motor command: $message to $topic');
    } catch (e) {
      statusMessage = 'Failed to publish command: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }

    _dataUpdateNotifier.value++;
  }

  Future<void> publishModeCommand(String motorId, int mode) async {
    if (mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    final parts = motorId.split('-');
    if (parts.length != 2) {
      throw Exception('Invalid motor ID format');
    }

    final mac = parts[0];
    final groupKey = parts[1];

    // Topic format: peepul/{mac}/ctrl
    final topic = 'peepul/$mac/ctrl';

    // Payload format for mode change
    final payload = {
      "T": 22, // Mode change type
      "D": {
        groupKey: {
          "mode":
              mode, // 0=LOCAL+MANUAL, 1=LOCAL+AUTO, 2=REMOTE+MANUAL, 3=REMOTE+AUTO
        }
      }
    };

    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    try {
      mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      statusMessage = 'Mode command sent successfully';
      debugPrint('Published mode command: $message to $topic');
    } catch (e) {
      statusMessage = 'Failed to publish mode command: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }

    _dataUpdateNotifier.value++;
  }

  MotorData? getMotorData(String motorId) {
    return motorDataMap[motorId];
  }

  void dispose() {
    mqttClient?.disconnect();
    for (var motor in motorDataMap.values) {
      motor.dispose();
    }
    motorDataMap.clear();
  }
}
