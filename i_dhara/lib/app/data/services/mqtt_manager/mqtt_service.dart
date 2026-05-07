import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/core/config/env.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

import 'mqtt_models.dart';

export 'mqtt_models.dart';

part 'mqtt_service_dispatcher.dart';
part 'mqtt_service_publish_motor.dart';
part 'mqtt_service_publish_schedule.dart';
part 'mqtt_service_handlers.dart';
part 'mqtt_service_internals.dart';

// ── Top-level constants (shared with part files) ──────────────────────────
const int _kMaxRetries = 2;
const Duration _kFirstRetryDelay = Duration(seconds: 10);
const Duration _kSecondRetryDelay = Duration(seconds: 10);
const Duration _kFinalWaitDelay = Duration(seconds: 3);

/// MQTT Service - Singleton that handles all MQTT communication
class MqttService {
  static final MqttService _instance = MqttService._internal();
  final StreamController<Map<String, dynamic>> defaultSettingsController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> scheduleAckController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get settingstream =>
      defaultSettingsController.stream;
  Stream<Map<String, dynamic>> get scheduleAckStream =>
      scheduleAckController.stream;
  final StreamController<Map<String, dynamic>> scheduleActionAckController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get scheduleActionAckStream =>
      scheduleActionAckController.stream;

  // Emits the device identifier when a schedule-create publish (T:23/T:33)
  // exhausts its retries with no ACK. Listeners (controllers) use this to
  // show the "Device is not responding" snackbar.
  final StreamController<String> scheduleAckTimeoutController =
      StreamController<String>.broadcast();
  Stream<String> get scheduleAckTimeoutStream =>
      scheduleAckTimeoutController.stream;

  // Emits ONCE per tracked multi-schedule publish session — fired either when
  // every expected scheduleId has been acked, or when the retry loop exhausts.
  // Payload: {topic: identifier, expected: List<int>, acked: List<int>}.
  // Only publishes that pass [expectedScheduleIds] into [_registerPendingCommand]
  // produce events on this stream — the controller uses it to drive the
  // bottom result snackbar for the multi-create flow.
  final StreamController<Map<String, dynamic>> scheduleFinalResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get scheduleFinalResultStream =>
      scheduleFinalResultController.stream;

  // Same idea as [scheduleFinalResultStream] but for bulk action commands
  // (T:24 stop / resume / delete). Fires once per tracked bulk action when
  // every expected scheduleId is acked or the retry loop exhausts.
  // Payload: {topic, expected, acked, cmd, success}.
  final StreamController<Map<String, dynamic>>
      scheduleActionFinalResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get scheduleActionFinalResultStream =>
      scheduleActionFinalResultController.stream;

  // Emits {scheduleId, runtime, missedTimes, failureEpoch, failureReason}
  // whenever a live sch field arrives for G01 or G02.
  final StreamController<Map<String, dynamic>> _scheduleLiveDataController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get scheduleLiveDataStream =>
      _scheduleLiveDataController.stream;

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
  bool _messageListenerAttached = false;

  // Motor data
  Map<String, Motor> _motors = {};
  late Map<String, MotorData> _motorDataMap;

  // Notifiers
  final ValueNotifier<int> _dataUpdateNotifier = ValueNotifier(0);
  // Fires only on T:40 (heartbeat / signal updates)
  final ValueNotifier<int> _heartbeatNotifier = ValueNotifier(0);
  // Fires only on T:35 or T:41 (live data: power, voltage, current)
  final ValueNotifier<int> _liveDataNotifier = ValueNotifier(0);
  final ValueNotifier<String?> commandStatusNotifier =
      ValueNotifier<String?>(null);

  /// Notifies when a fault clear command completes.
  /// Value is the motorId on success, or null on failure (timeout handled via commandStatusNotifier).
  final ValueNotifier<String?> faultClearResultNotifier =
      ValueNotifier<String?>(null);

  // Command tracking
  final Map<String, PendingCommand> _pendingCommands = {};
  final Map<String, DateTime> _lastCommandTimes = {};
  final Map<String, DateTime> _lastAckTimes = {};

  final Set<String> _expiredActionKeys = {};

  // Track schedule create command keys whose retries have been exhausted
  // Any T:33 ACK arriving after this is a late ACK and must be ignored
  final Set<String> _expiredScheduleKeys = {};

  // ScheduleIds the app just published per command key. Used in
  // _handleScheduleAck to filter the device's bitmask, which echoes ALL
  // scheduleIds the device currently stores — not just the freshly
  // published ones. Without this filter, ACK'ing a single new schedule
  // would also mark older PENDING schedules as acknowledged.
  final Map<String, List<int>> _publishedScheduleIds = {};

  // Test run tracking - motors in test run mode should ignore type 31 and 32
  final Set<String> _testRunMotors = {};

  final Random _random = Random();

  ValueNotifier<int> get dataUpdateNotifier => _dataUpdateNotifier;
  ValueNotifier<int> get heartbeatNotifier => _heartbeatNotifier;
  ValueNotifier<int> get liveDataNotifier => _liveDataNotifier;
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

  /// Add motor to test run mode (will ignore type 31 and 32)
  void addTestRunMotor(String motorId) {
    _testRunMotors.add(motorId);
    debugPrint('✓ Motor added to test run mode: $motorId');
  }

  /// Remove motor from test run mode
  void removeTestRunMotor(String motorId) {
    _testRunMotors.remove(motorId);
    debugPrint('✓ Motor removed from test run mode: $motorId');
  }

  /// Check if motor is in test run mode
  bool isMotorInTestRun(String motorId) => _testRunMotors.contains(motorId);

  /// Check if any motor with the given identifier (MAC/PCB) is in test run mode
  /// CRITICAL: This checks BOTH MAC and PCB across all groups
  bool isIdentifierInTestRun(String identifier) {
    debugPrint('   🔍 Checking if identifier "$identifier" is in test run...');
    debugPrint('   🔍 Test run motors: ${_testRunMotors.toList()}');

    if (_testRunMotors.isEmpty) {
      debugPrint('   ⚠️ No motors in test run');
      return false;
    }

    // Check 1: Direct match - motor ID starts with identifier
    for (final testRunMotorId in _testRunMotors) {
      if (testRunMotorId.startsWith('$identifier-')) {
        debugPrint('   ✅ DIRECT MATCH: $identifier = $testRunMotorId');
        return true;
      }
    }

    // Check 2: Cross-reference MAC/PCB - check motorDataMap
    debugPrint('   🔍 No direct match, checking MAC/PCB cross-reference...');
    for (final testRunMotorId in _testRunMotors) {
      final motorData = _motorDataMap[testRunMotorId];
      if (motorData != null) {
        final mac = motorData.macAddress;
        final pcb = motorData.pcbNumber;
        debugPrint(
            '   🔍 Motor $testRunMotorId: mac=$mac, pcb=$pcb vs identifier=$identifier');

        if (mac == identifier || pcb == identifier) {
          debugPrint(
              '   ✅ CROSS-MATCH: identifier=$identifier matches motor $testRunMotorId');
          return true;
        }
      }
    }

    debugPrint('   ❌ NO MATCH: identifier=$identifier not in test run');
    return false;
  }

  /// Initialize MQTT connection
  Future<void> initializeMqttClient() async {
    if (_mqttClient != null && isConnected) {
      // Already connected — update subscriptions for the refreshed motor map
      // and notify listeners with current data instead of a costly reconnect.
      _subscribeToAllTopics();
      _dataUpdateNotifier.value++;
      return;
    }

    const int port = 8883;
    String broker = AppEnvironment.mqttBroker;
    String username = AppEnvironment.mqttUsername;
    String password = AppEnvironment.mqttPassword;
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

    if (!_messageListenerAttached) {
      _mqttClient!.updates!.listen(
        _onMessageReceived,
        onError: (e) {
          debugPrint('✗ MQTT Stream error: $e');
          statusMessage = 'Stream error: $e';
          _dataUpdateNotifier.value++;
        },
        onDone: () {
          debugPrint('MQTT Stream closed');
          _messageListenerAttached = false;
        },
      );
      _messageListenerAttached = true;
      debugPrint('✓ MQTT message listener set up');
    } else {
      debugPrint('✓ MQTT message listener already attached');
    }
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

  /// Disconnect MQTT and reset all state without disposing ValueNotifiers.
  /// Call this on logout so the singleton is ready for a fresh connection on
  /// the next login. Do NOT call [dispose()] on logout — that destroys the
  /// shared ValueNotifiers and breaks any active listeners.
  void disconnectOnly() {
    debugPrint('MQTT: disconnectOnly — cleaning up for logout');
    for (var cmd in _pendingCommands.values) {
      cmd.cancelTimer();
    }
    _pendingCommands.clear();
    _testRunMotors.clear();
    _mqttClient?.disconnect();
    _mqttClient = null;
    _messageListenerAttached = false;
    isConnected = false;
    _motors = {};
    _motorDataMap.clear();
    _dataUpdateNotifier.value++;
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
        ..testRunSignal = motor.testrunSignal
        ..testrunPowerSupply = motor.testrunPower
        ..testrunVoltageRange = motor.testrunVoltageRange
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

  /// Maps a T:33 schedule ACK code to a user-facing error message.
  /// Returns null for ack=1 (SUCCESS) — the caller should not show a snackbar
  /// in that case.
  static String? scheduleAckErrorMessage(int ackCode) {
    switch (ackCode) {
      case 1:
        return null; // SUCCESS
      case 0:
        return 'Schedule failed';
      case 2:
        return 'Waiting for next schedule';
      case 4:
        return 'Device flash issue';
      case 5:
        return 'Index mismatch error';
      case 6:
        return 'JSON parsing error';
      case 7:
        return 'Count mismatch error';
      default:
        return 'Schedule failed (code $ackCode)';
    }
  }

  /// Maps a T:54 schedule action ACK code to a user-facing error message.
  /// Action ACK semantics: success is `ack == cmd` (1=stop, 2=resume,
  /// 3=delete) — the controller checks that match itself. This helper only
  /// covers the device-side error codes; returns null otherwise so the
  /// caller knows it was either a success or an unexpected mismatch.
  static String? scheduleActionAckErrorMessage(int ackCode) {
    switch (ackCode) {
      case 0:
        return 'Schedule action failed';
      case 4:
        return 'Device flash issue';
      case 5:
        return 'Index mismatch error';
      case 6:
        return 'JSON parsing error';
      default:
        return null;
    }
  }
}
