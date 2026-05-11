import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:i_dhara/app/core/config/env.dart';
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
  int power;
  int fault = 0;
  int alert = 0;
  String runTime = '-';
  DateTime? stateChangedAt;

  /// Fault code bitmask to short description mapping
  static const Map<int, String> faultCodeMap = {
    0x01: 'Dry Run',
    0x02: 'Overload',
    0x04: 'Locked Rotor',
    0x08: 'Current Imbalance',
    0x10: 'Frequent Start',
    0x20: 'Phase Failure',
    0x40: 'Low Voltage',
    0x80: 'High Voltage',
    0x100: 'Voltage Imbalance',
    0x200: 'Phase Reversal',
    0x400: 'Frequency Deviation',
    0x1000: 'Output Phase',
  };

  /// Decode a fault bitmask into a list of short fault descriptions
  static List<String> decodeFaultDescriptions(int faultCode) {
    final faults = <String>[];
    for (final entry in faultCodeMap.entries) {
      if (faultCode & entry.key != 0) {
        faults.add('${entry.value} Fault');
      }
    }
    return faults;
  }

  bool hasReceivedData = false;

  // Active schedule info keyed by schedule ID, updated from live data sch field
  final Map<int, ScheduleInfo> schedules = {};

  String? macAddress;
  String? pcbNumber;
  String? groupId;
  String? title;

  bool hasReceivedLiveData = false;

  int signalStrength = 0;
  int signalBars = 0;
  bool? testRunSignal;
  bool? testrunPowerSupply;
  bool? testrunVoltageRange;

  DateTime? lastSignalUpdate;

  MotorData(
      {this.macAddress,
      this.pcbNumber,
      this.groupId,
      this.title,
      this.power = 0});

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

class ScheduleInfo {
  final int id;
  final int startTime;
  final int runtime;
  final int endTime;
  final int missedTimes;
  final int failureEpoch;
  final int failureReason; // 1=Power Loss, 2=Fault, 3=Mode Change
  final int startEpoch; // st_ep — unix epoch (seconds) for the schedule start
  final int endEpoch; // ed_ep — unix epoch (seconds) for the schedule end

  ScheduleInfo({
    required this.id,
    required this.startTime,
    required this.runtime,
    required this.endTime,
    required this.missedTimes,
    required this.failureEpoch,
    required this.failureReason,
    required this.startEpoch,
    required this.endEpoch,
  });
}

/// Tracks pending commands for retry mechanism
class PendingCommand {
  final String motorId;
  final int
      commandType; // 1 = motor control, 2 = mode change, 4 = settings, 21 = fault clear
  final dynamic commandData;
  final int sequenceNumber;
  final String? pcbnumber; // For settings commands (type 4)
  int retryCount;
  Timer? retryTimer;
  final Function(String) onMaxRetriesReached;

  /// For multi-schedule create (T:23). When set, the retry loop keeps firing
  /// even after a partial ACK — we only stop once every expected scheduleId
  /// has been acknowledged across one or more device ACKs.
  final List<int>? expectedScheduleIds;

  /// Accumulated acked scheduleIds across all publish attempts. Union of
  /// every T:33 ACK bitmask received for this command.
  final Set<int> ackedScheduleIds = <int>{};

  PendingCommand({
    required this.motorId,
    required this.commandType,
    required this.commandData,
    required this.sequenceNumber,
    this.retryCount = 0,
    required this.onMaxRetriesReached,
    this.pcbnumber,
    this.expectedScheduleIds,
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

  final StreamController<String> scheduleAckTimeoutController =
      StreamController<String>.broadcast();
  Stream<String> get scheduleAckTimeoutStream =>
      scheduleAckTimeoutController.stream;

  final StreamController<Map<String, dynamic>> scheduleFinalResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get scheduleFinalResultStream =>
      scheduleFinalResultController.stream;

  final StreamController<Map<String, dynamic>>
      scheduleActionFinalResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get scheduleActionFinalResultStream =>
      scheduleActionFinalResultController.stream;

  final StreamController<Map<String, dynamic>> _scheduleLiveDataController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get scheduleLiveDataStream =>
      _scheduleLiveDataController.stream;

  final StreamController<Map<String, dynamic>> modeAckErrorController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get modeAckErrorStream =>
      modeAckErrorController.stream;

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

  final ValueNotifier<String?> faultClearResultNotifier =
      ValueNotifier<String?>(null);

  // Command tracking
  final Map<String, PendingCommand> _pendingCommands = {};
  final Map<String, DateTime> _lastCommandTimes = {};
  final Map<String, DateTime> _lastAckTimes = {};

  final Set<String> _expiredActionKeys = {};

  final Set<String> _expiredScheduleKeys = {};

  final Map<String, List<int>> _publishedScheduleIds = {};

  // Test run tracking - motors in test run mode should ignore type 31 and 32
  final Set<String> _testRunMotors = {};

  // Retry settings
  static const int _maxRetries = 2;
  static const Duration _firstRetryDelay = Duration(seconds: 10);
  static const Duration _secondRetryDelay = Duration(seconds: 10);
  static const Duration _finalWaitDelay = Duration(seconds: 3);

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

  Future<void> publishScheduleCommand({
    required String identifier,
    required int scheduleId,
    required int startTimeHHMM,
    required int endTimeHHMM,
    required int startDateYYMMDD,
    required int endDateYYMMDD,
    required bool isCyclic,
    int? cyclicOnMinutes,
    int? cyclicOffMinutes,
    required int powerRecovery,
    required int enabled,
    int? sequenceNumber,
    bool isEdit = false,

    /// 1 = first schedule on this motor, 2 = motor already has schedules
    int idx = 1,
  }) async {
    if (_mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    if (identifier.trim().isEmpty) {
      throw Exception('Invalid identifier for schedule publish');
    }

    final seq = sequenceNumber ?? _random.nextInt(251);

    // Reconstruct full DateTime from YYMMDD + HHMM for epoch conversion
    final stYear = 2000 + (startDateYYMMDD ~/ 10000);
    final stMonth = (startDateYYMMDD % 10000) ~/ 100;
    final stDay = startDateYYMMDD % 100;
    final stHour = startTimeHHMM ~/ 100;
    final stMin = startTimeHHMM % 100;

    final edYear = 2000 + (endDateYYMMDD ~/ 10000);
    final edMonth = (endDateYYMMDD % 10000) ~/ 100;
    final edDay = endDateYYMMDD % 100;
    final edHour = endTimeHHMM ~/ 100;
    final edMin = endTimeHHMM % 100;

    final stEpoch = DateTime(stYear, stMonth, stDay, stHour, stMin)
            .millisecondsSinceEpoch ~/
        1000;
    final edEpoch = DateTime(edYear, edMonth, edDay, edHour, edMin)
            .millisecondsSinceEpoch ~/
        1000;

    final scheduleItem = <String, dynamic>{
      'id': scheduleId,
      'sd': startDateYYMMDD,
      'ed': endDateYYMMDD,
      'st': startTimeHHMM,
      'et': endTimeHHMM,
      'st_ep': stEpoch,
      'ed_ep': edEpoch,
      'en': enabled,
      if (isCyclic) ...{
        'cy': 1,
        'on': cyclicOnMinutes,
        'off': cyclicOffMinutes,
        'pwr_rec': 0,
      } else ...{
        'pwr_rec': powerRecovery,
      },
    };

    final payload = <String, dynamic>{
      'T': 3,
      'S': seq,
      'D': {
        'idx': idx,
        'last': 1,
        'sch_cnt': 1,
        'plr': 30,
        'm1': [scheduleItem],
      },
    };

    final commandKey = 'schedule_$identifier';
    _lastAckTimes.remove(commandKey);
    // Clear expired status so a fresh command's ACK is accepted
    _expiredScheduleKeys.remove(commandKey);
    _publishedScheduleIds[commandKey] = [scheduleId];

    await _publishScheduleCommandInternal(
      payload,
      identifier,
      sequenceNumber: seq,
    );
    _registerPendingCommand(
      commandKey,
      23, // both create and edit use type 23
      payload,
      seq,
      pcbnumber: identifier,
    );
    statusMessage = 'Schedule command sent successfully';
    _dataUpdateNotifier.value++;
  }

  Future<void> publishMultipleSchedulesCommand({
    required String identifier,
    required List<Map<String, dynamic>> items,
    int plr = 30,
    int? sequenceNumber,

    /// 1 = first schedule on this motor, 2 = motor already has schedules
    int idx = 1,
    bool trackExpectedAcks = false,
  }) async {
    if (_mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    if (identifier.trim().isEmpty) {
      throw Exception('Invalid identifier for schedule publish');
    }

    if (items.isEmpty) {
      throw Exception('No schedule items to publish');
    }

    // Sort ascending by id
    final sorted = List<Map<String, dynamic>>.from(items)
      ..sort(
          (a, b) => ((a['id'] as int?) ?? 0).compareTo((b['id'] as int?) ?? 0));

    final seq = sequenceNumber ?? _random.nextInt(251);

    final payload = <String, dynamic>{
      'T': 3,
      'S': seq,
      'D': {
        'idx': idx,
        'last': 1,
        'sch_cnt': sorted.length,
        'plr': plr,
        'm1': sorted,
      },
    };

    final commandKey = 'schedule_$identifier';
    _lastAckTimes.remove(commandKey);
    _expiredScheduleKeys.remove(commandKey);
    _publishedScheduleIds[commandKey] = sorted
        .map((m) => (m['id'] as int?) ?? 0)
        .where((id) => id > 0)
        .toList();

    await _publishScheduleCommandInternal(
      payload,
      identifier,
      sequenceNumber: seq,
    );
    _registerPendingCommand(
      commandKey,
      23,
      payload,
      seq,
      pcbnumber: identifier,
      expectedScheduleIds: trackExpectedAcks
          ? sorted
              .map((m) => (m['id'] as int?) ?? 0)
              .where((i) => i > 0)
              .toList()
          : null,
    );
    statusMessage = 'Multi schedule command sent successfully';
    _dataUpdateNotifier.value++;
  }

  Future<void> publishScheduleActionCommand({
    required String identifier,
    required int scheduleId,
    required int cmd,
    int? sequenceNumber,
  }) async {
    await publishBulkScheduleActionCommand(
      identifier: identifier,
      scheduleIds: [scheduleId],
      cmd: cmd,
      sequenceNumber: sequenceNumber,
    );
  }

  Future<void> publishBulkScheduleActionCommand({
    required String identifier,
    required List<int> scheduleIds,
    required int cmd,
    int? sequenceNumber,
    bool trackExpectedAcks = false,
  }) async {
    if (_mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    if (identifier.trim().isEmpty) {
      throw Exception('Invalid identifier for schedule action');
    }

    if (scheduleIds.isEmpty) {
      throw Exception('No schedule IDs provided');
    }

    final seq = sequenceNumber ?? _random.nextInt(251);

    // Compute combined bitmask for all scheduleIds
    final ids = scheduleIds.fold(0, (acc, id) => acc | (1 << (id - 1)));

    final payload = <String, dynamic>{
      'T': 24,
      'S': seq,
      'D': {
        'm1': {
          'cmd': cmd,
          'ids': ids,
        },
      },
    };

    final commandKey = 'schedule_action_$identifier';
    final alreadyInFlight = _pendingCommands.containsKey('${commandKey}_24');
    _lastAckTimes.remove(commandKey);
    // Clear expired status so a fresh command's ACK is accepted
    _expiredActionKeys.remove(commandKey);

    if (!alreadyInFlight) {
      _registerPendingCommand(
        commandKey,
        24,
        payload,
        seq,
        pcbnumber: identifier,
        expectedScheduleIds: trackExpectedAcks ? scheduleIds : null,
      );
      try {
        await _publishScheduleCommandInternal(
          payload,
          identifier,
          sequenceNumber: seq,
        );
      } catch (e) {
        _clearPendingCommand(commandKey, 24);
        rethrow;
      }
    } else {
      debugPrint(
          '⚠️ Schedule action already in-flight for $identifier — skipping duplicate publish');
    }
    statusMessage = 'Schedule action command sent successfully';
    _dataUpdateNotifier.value++;
  }

  Future<void> _publishScheduleCommandInternal(
    Map<String, dynamic> schedulePayload,
    String identifier, {
    int? sequenceNumber,
    bool isRetry = false,
  }) async {
    if (_mqttClient == null || !isConnected) {
      throw Exception('MQTT not connected');
    }

    final topic = 'peepul/$identifier/cmd';
    final payload = Map<String, dynamic>.from(schedulePayload);
    if (sequenceNumber != null) {
      payload['S'] = sequenceNumber;
    }
    final message = jsonEncode(payload);
    final builder = MqttClientPayloadBuilder()..addString(message);
    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    if (!isRetry) {
      debugPrint('✓ Published Schedule Command -> $topic');
      debugPrint('   Payload: $message');
    } else {
      debugPrint('🔄 Re-published Schedule Command -> $topic');
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

  void _onConnected() {
    isConnected = true;
    statusMessage = 'Connected';
    debugPrint('✓ MQTT Connected');
    debugPrint('   Motors count: ${_motors.length}');
    debugPrint('   MotorDataMap count: ${_motorDataMap.length}');
    // Use Future.delayed to ensure listener is attached before subscribing
    Future.delayed(
        const Duration(milliseconds: 500), () => _subscribeToAllTopics());
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
    // Use Future.delayed to ensure listener is attached before subscribing
    Future.delayed(
        const Duration(milliseconds: 500), () => _subscribeToAllTopics());
    _dataUpdateNotifier.value++;
  }

  void _subscribeToAllTopics() {
    if (_mqttClient == null) {
      debugPrint('⚠️ Cannot subscribe: MQTT client is null');
      return;
    }

    debugPrint('=== Starting topic subscription ===');
    debugPrint('   MQTT Client state: ${_mqttClient!.connectionStatus?.state}');
    debugPrint('   Motors count: ${_motors.length}');

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
            _handleLiveDataRequest(identifier, payloadData);
          case 41:
            _handleLiveData(identifier, payloadData);
            break;
          case 40:
            _handleHeartbeat(identifier, payloadData);
            break;
          case 33:
            _handleScheduleAck(identifier, data as Map<String, dynamic>);
            break;
          case 54:
            _handleScheduleActionAck(identifier, payloadData);
            break;
          case 52:
            _handleFaultClearAck(identifier, payloadData);
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
    debugPrint('🔧 TYPE 31 received: identifier=$identifier');

    if (isIdentifierInTestRun(identifier)) {
      debugPrint(
          '   ✅ T:31 for test run motor — clearing retry, skipping state update');
      final testRunMotorId = _findMotorWithPendingCommand(identifier, 1) ??
          _findAnyMotorWithIdentifier(identifier);
      if (testRunMotorId != null) {
        _lastAckTimes[testRunMotorId] = DateTime.now();
        _clearPendingCommand(testRunMotorId, 1);
      }
      _dataUpdateNotifier.value++;
      return;
    }
    debugPrint('   ✓ Not in test run - processing normally');

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

    if (newState != 0 && newState != 1) {
      debugPrint(
          '   ⚠️ Motor ACK: Invalid state=$newState (expected 0 or 1) — reverting to previous state');
      final revertId = _findMotorWithPendingCommand(identifier, 1) ??
          _findAnyMotorWithIdentifier(identifier);
      if (revertId != null) {
        final revertData = _motorDataMap[revertId];
        if (revertData != null) {
          // Restore notifier so any UI listener sees the correct previous state.
          revertData.controller.value = revertData.state == 1;
          _clearPendingCommand(revertId, 1);
        }
      }
      _dataUpdateNotifier.value++;
      return;
    }

    debugPrint('📥 Motor Control ACK: identifier=$identifier, state=$newState');
    debugPrint('   Pending commands: ${_pendingCommands.keys.toList()}');
    debugPrint('   MotorDataMap keys: ${_motorDataMap.keys.toList()}');

    // Find motor with this identifier that has a pending command
    final motorId = _findMotorWithPendingCommand(identifier, 1);

    if (motorId != null) {
      // Check if motor is in test run mode - if yes, skip updating state/mode
      if (_testRunMotors.contains(motorId)) {
        debugPrint(
            '   ⚠️ Motor $motorId is in test run mode - skipping type 31 ACK');
        _lastAckTimes[motorId] = DateTime.now();
        _clearPendingCommand(motorId, 1);
        return;
      }

      final motorData = _motorDataMap[motorId];
      if (motorData != null) {
        if (motorData.state != newState) {
          motorData.stateChangedAt = DateTime.now();
        }
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
        // Check if motor is in test run mode - if yes, skip updating state/mode
        if (_testRunMotors.contains(fallbackId)) {
          debugPrint(
              '   ⚠️ Motor $fallbackId is in test run mode - skipping type 31 ACK');
          _lastAckTimes[fallbackId] = DateTime.now();
          return;
        }

        final motorData = _motorDataMap[fallbackId];
        if (motorData != null) {
          if (motorData.state != newState) {
            motorData.stateChangedAt = DateTime.now();
          }
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
    debugPrint('🔧 TYPE 32 received: identifier=$identifier');

    if (isIdentifierInTestRun(identifier)) {
      return; // EXIT - do NOTHING
    }
    debugPrint('   ✓ Not in test run - processing normally');

    // Parse mode from various formats
    int? newMode;
    if (payloadData is int) {
      newMode = payloadData;
    } else if (payloadData is String) {
      newMode = int.tryParse(payloadData);
    } else if (payloadData is double) {
      newMode = payloadData.toInt();
    }

    if (newMode != null && modeAckErrorMessage(newMode) != null) {
      debugPrint('   ⚠️ Mode ACK error code=$newMode for $identifier');
      final revertId = _findMotorWithPendingCommand(identifier, 2) ??
          _findAnyMotorWithIdentifier(identifier);
      if (revertId != null) {
        final revertData = _motorDataMap[revertId];
        if (revertData != null) {
          revertData.modeswitchcontroller.value = revertData.modeIndex;
          _clearPendingCommand(revertId, 2);
        }
      }
      modeAckErrorController.add({
        'identifier': identifier,
        'code': newMode,
      });
      _dataUpdateNotifier.value++;
      return;
    }

    if (newMode == scheduleModeDeviceCode) {
      newMode = scheduleModeUiIndex;
    }

    if (newMode == null || (newMode != 0 && newMode != 1 && newMode != 2)) {
      final revertId = _findMotorWithPendingCommand(identifier, 2) ??
          _findAnyMotorWithIdentifier(identifier);
      if (revertId != null) {
        final revertData = _motorDataMap[revertId];
        if (revertData != null) {
          revertData.modeswitchcontroller.value = revertData.modeIndex;
          _clearPendingCommand(revertId, 2);
        }
      }
      _dataUpdateNotifier.value++;
      return;
    }

    String modeLabel(int m) =>
        m == 1 ? 'AUTO' : (m == 2 ? 'SCHEDULE' : 'MANUAL');

    debugPrint(
        '📥 Mode Change ACK: identifier=$identifier, mode=$newMode (${modeLabel(newMode)})');
    debugPrint('   Pending commands: ${_pendingCommands.keys.toList()}');
    debugPrint('   MotorDataMap keys: ${_motorDataMap.keys.toList()}');

    // Find motor with this identifier that has a pending command
    final motorId = _findMotorWithPendingCommand(identifier, 2);

    if (motorId != null) {
      // Check if motor is in test run mode - if yes, skip updating state/mode
      if (_testRunMotors.contains(motorId)) {
        debugPrint(
            '   ⚠️ Motor $motorId is in test run mode - skipping type 32 ACK');
        _lastAckTimes[motorId] = DateTime.now();
        _clearPendingCommand(motorId, 2);
        return;
      }

      final motorData = _motorDataMap[motorId];
      if (motorData != null) {
        motorData.modeIndex = newMode;
        motorData.modeswitchcontroller.value = newMode;
        motorData.motorMode = modeLabel(newMode);
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
        // Check if motor is in test run mode - if yes, skip updating state/mode
        if (_testRunMotors.contains(fallbackId)) {
          debugPrint(
              '   ⚠️ Motor $fallbackId is in test run mode - skipping type 32 ACK');
          _lastAckTimes[fallbackId] = DateTime.now();
          return;
        }

        final motorData = _motorDataMap[fallbackId];
        if (motorData != null) {
          motorData.modeIndex = newMode;
          motorData.modeswitchcontroller.value = newMode;
          motorData.motorMode = modeLabel(newMode);
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

  /// Handle fault clear acknowledgment (type 52)
  /// ACK payload: {"T": 52, "S": 89, "D": 1, "ct": "2025/12/30,13:42:30"}
  void _handleFaultClearAck(String identifier, dynamic payloadData) {
    debugPrint('🔧 TYPE 52 (Fault Clear ACK) received: identifier=$identifier');

    // Find motor with pending fault clear command (type 21)
    final motorId = _findMotorWithPendingCommand(identifier, 21);

    if (motorId != null) {
      final motorData = _motorDataMap[motorId];
      if (motorData != null) {
        motorData.fault = 0;
        motorData.hasReceivedData = true;
        _lastAckTimes[motorId] = DateTime.now();
        debugPrint('   ✓ Fault Clear ACK processed: $motorId -> fault cleared');
      }
      _clearPendingCommand(motorId, 21);
      faultClearResultNotifier.value = null; // reset first
      faultClearResultNotifier.value = motorId;
    } else {
      // No pending command — update any matching motor
      final fallbackId = _findAnyMotorWithIdentifier(identifier);
      if (fallbackId != null) {
        final motorData = _motorDataMap[fallbackId];
        if (motorData != null) {
          motorData.fault = 0;
          motorData.hasReceivedData = true;
          _lastAckTimes[fallbackId] = DateTime.now();
          debugPrint(
              '   ✓ Fault Clear ACK processed (fallback): $fallbackId -> fault cleared');
        }
        faultClearResultNotifier.value = null;
        faultClearResultNotifier.value = fallbackId;
      } else {
        debugPrint(
            '   ⚠️ Could not find motor for fault clear identifier=$identifier');
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
      if (groupData == null)
        continue;
      else {}
      final pwr = groupData["pwr"];

      final fullMotorId = '$identifier-$groupId';

      // Get or create motor data
      var motorData = _motorDataMap[fullMotorId];
      if (motorData == null) {
        // Search for existing entry with same physical motor in this group
        // (key may differ if _buildMotorDataMap used MAC but MQTT uses PCB)
        for (var existingEntry in _motorDataMap.entries) {
          final data = existingEntry.value;
          if (data.groupId == groupId &&
              (data.macAddress == identifier || data.pcbNumber == identifier)) {
            motorData = data;
            // Also register under the new key for future direct lookups
            _motorDataMap[fullMotorId] = motorData;
            debugPrint(
                '   Reusing existing MotorData ${existingEntry.key} as $fullMotorId');
            break;
          }
        }
      }
      if (motorData == null) {
        debugPrint('   Creating new MotorData for $fullMotorId');
        motorData = MotorData(
            macAddress: identifier,
            pcbNumber: identifier,
            groupId: groupId,
            title: groupId,
            power: pwr);
        _motorDataMap[fullMotorId] = motorData;
      }

      _updateMotorDataFromPayload(motorData, groupData, groupId == 'G04');

      // Parse sch only for G01 and G02
      if (groupId == 'G01' || groupId == 'G02') {
        _parseSchedule(motorData, groupData);
      }

      motorData.hasReceivedData = true;
      motorData.hasReceivedLiveData = true;
      _lastAckTimes[fullMotorId] = DateTime.now();
      debugPrint(
          '   ✓ Updated $fullMotorId: state=${motorData.state}, mode=${motorData.motorMode}');
      debugPrint(
          '   ✓ MotorData mac=${motorData.macAddress}, pcb=${motorData.pcbNumber}');
      debugPrint(
          '   ✓ Voltages: R=${motorData.voltageRed}, Y=${motorData.voltageYellow}, B=${motorData.voltageBlue}');
    }

    // Force notify listeners
    debugPrint(
        '📢 Notifying listeners: dataUpdateNotifier=${_dataUpdateNotifier.value + 1}');
    _liveDataNotifier.value++;
    _dataUpdateNotifier.value++;
  }

  /// Handle live data (type 35, 41)
  void _handleLiveDataRequest(String identifier, dynamic payloadData) {
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
      if (groupData == null)
        continue;
      else {}
      final pwr = groupData["pwr"];

      final fullMotorId = '$identifier-$groupId';

      // Get or create motor data
      var motorData = _motorDataMap[fullMotorId];
      if (motorData == null) {
        for (var existingEntry in _motorDataMap.entries) {
          final data = existingEntry.value;
          if (data.groupId == groupId &&
              (data.macAddress == identifier || data.pcbNumber == identifier)) {
            motorData = data;
            // Also register under the new key for future direct lookups
            _motorDataMap[fullMotorId] = motorData;
            debugPrint(
                '   Reusing existing MotorData ${existingEntry.key} as $fullMotorId');
            break;
          }
        }
      }
      if (motorData == null) {
        debugPrint('   Creating new MotorData for $fullMotorId');
        motorData = MotorData(
            macAddress: identifier,
            pcbNumber: identifier,
            groupId: groupId,
            title: groupId,
            power: pwr);
        _motorDataMap[fullMotorId] = motorData;
      }
      _updateMotorDataFromPayload(motorData, groupData, groupId == 'G04');

      // Parse sch only for G01 and G02
      if (groupId == 'G01' || groupId == 'G02') {
        _parseSchedule(motorData, groupData);
      }

      motorData.testRunSignal = true;
      // T:35 live data only verifies power supply and voltage range.
      // Network connectivity (testRunSignal) is verified ONLY by T:40 heartbeat.
      motorData.testrunPowerSupply = true;
      motorData.testrunVoltageRange = true;
      motorData.updateSignalStrength(13);
      motorData.hasReceivedData = true;
      motorData.hasReceivedLiveData = true;
      _lastAckTimes[fullMotorId] = DateTime.now();
      debugPrint(
          '   ✓ Updated $fullMotorId: state=${motorData.state}, mode=${motorData.motorMode}');
      debugPrint(
          '   ✓ MotorData mac=${motorData.macAddress}, pcb=${motorData.pcbNumber}');
      debugPrint(
          '   ✓ Voltages: R=${motorData.voltageRed}, Y=${motorData.voltageYellow}, B=${motorData.voltageBlue}');
    }

    final keysToCancel = <String>[];
    for (final entry in _pendingCommands.entries) {
      if (!entry.key.endsWith('_5')) continue;
      final motorId = entry.key.substring(0, entry.key.length - 2);
      final motorData = _motorDataMap[motorId];
      if (motorData != null &&
          (motorData.macAddress == identifier ||
              motorData.pcbNumber == identifier)) {
        keysToCancel.add(entry.key);
      }
    }
    if (keysToCancel.isNotEmpty) {
      for (final key in keysToCancel) {
        _pendingCommands[key]?.cancelTimer();
        _pendingCommands.remove(key);
        debugPrint('✓ T:35 ACK from $identifier — cancelled T:5 retry: $key');
      }
    } else {
      debugPrint(
          '✓ T:35 ACK received from $identifier (no pending T:5 command)');
    }

    debugPrint(
        '📢 Notifying listeners: dataUpdateNotifier=${_dataUpdateNotifier.value + 1}');
    _liveDataNotifier.value++;
    _heartbeatNotifier.value++;
    _dataUpdateNotifier.value++;
  }

  void handleDefaultSettings(String identifier, dynamic payloadData) {
    try {
      final type = payloadData as int;
      final map = {"D": type, "topic": identifier};

      // Clear any "No response from device" message since ACK was received
      commandStatusNotifier.value = null;

      // Clear pending settings command to stop retries immediately upon ACK
      final command = _pendingCommands['_4'];
      if (command != null) {
        // Cancel the retry timer and remove the pending command
        command.cancelTimer();
        _clearPendingCommand('', 4);
        debugPrint(
            '✓ Settings ACK received from $identifier: $type (Retries stopped)');
      } else {
        debugPrint(
            '✓ Settings ACK received from $identifier: $type (No pending command)');
      }
      defaultSettingsController.add(map);
    } catch (e) {
      // ignore
    }
  }

  static const int scheduleModeDeviceCode = 6;
  static const int scheduleModeUiIndex = 2;

  static String? modeAckErrorMessage(int ackCode) {
    switch (ackCode) {
      case 2:
        return 'Already in Auto mode';
      case 3:
        return 'Already in Manual mode';
      case 4:
        return 'Invalid request';
      case 5:
        return 'Feature enabled';
      case 7:
        return 'Already in Schedule mode';
      default:
        return null;
    }
  }

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

  void _handleScheduleAck(String identifier, Map<String, dynamic> message) {
    final scheduleCommandKey = 'schedule_$identifier';

    // Late ACKs (after retries exhausted) are still processed — the device
    // confirmation is the source of truth, and dropping it would leave fresh
    // schedules stuck in PENDING forever even though the device accepted them.
    final isLate = _expiredScheduleKeys.contains(scheduleCommandKey);
    if (isLate) {
      debugPrint('ℹ️ Late T:33 ACK for $identifier — processing anyway');
      _expiredScheduleKeys.remove(scheduleCommandKey);
    }

    final dRaw = message['D'];
    int ackCode;
    int successFlag;
    List<int> ackedScheduleIds;

    if (dRaw is Map<String, dynamic>) {
      final idsRaw = dRaw['ids'];
      final bitmask = idsRaw is int ? idsRaw : int.tryParse('$idsRaw') ?? 0;
      final ackRaw = dRaw['ack'];
      ackCode = ackRaw is int ? ackRaw : int.tryParse('$ackRaw') ?? 0;
      successFlag = ackCode == 1 ? 1 : 0;
      final decoded = <int>[];
      for (int bit = 0; bit < 32; bit++) {
        if ((bitmask >> bit) & 1 == 1) decoded.add(bit + 1);
      }
      ackedScheduleIds = ackCode == 1 ? decoded : const <int>[];
      _publishedScheduleIds.remove(scheduleCommandKey);
    } else {
      successFlag = dRaw is int ? dRaw : int.tryParse('$dRaw') ?? 0;
      ackCode = successFlag == 1 ? 1 : 0;
      // remove() (not lookup): a duplicate/retransmit ACK arrives with no
      // published context → empty list → controller skips, which is correct.
      final publishedIds =
          _publishedScheduleIds.remove(scheduleCommandKey) ?? const <int>[];
      ackedScheduleIds =
          successFlag == 1 ? List<int>.from(publishedIds) : const <int>[];
      debugPrint('✓ Schedule ACK from $identifier (legacy): D=$successFlag '
          'published=$publishedIds → emit=$ackedScheduleIds');
    }

    commandStatusNotifier.value = null;

    final isSuccess = ackCode == 1;

    final pendingKey = '${scheduleCommandKey}_23';
    final pending = _pendingCommands[pendingKey];
    final expected = pending?.expectedScheduleIds;
    bool emitFinal = false;
    bool finalSuccess = false;

    if (expected != null && expected.isNotEmpty) {
      if (isSuccess) {
        pending!.ackedScheduleIds.addAll(ackedScheduleIds);
        final allCovered = expected.every(pending.ackedScheduleIds.contains);
        if (allCovered) {
          _clearPendingCommand(scheduleCommandKey, 23);
          emitFinal = true;
          finalSuccess = true;
        } else {
          debugPrint(
              '⏳ Partial schedule ACK: ${pending.ackedScheduleIds.toList()} of $expected — keeping retry alive');
        }
      } else {
        _clearPendingCommand(scheduleCommandKey, 23);
        _expiredScheduleKeys.add(scheduleCommandKey);
        emitFinal = true;
        finalSuccess = false;
      }
    } else {
      _clearPendingCommand(scheduleCommandKey, 23);
      if (!isSuccess) {
        _expiredScheduleKeys.add(scheduleCommandKey);
      }
    }

    final ackMap = <String, dynamic>{
      'topic': identifier,
      'schedule_ids': ackedScheduleIds,
      'D': successFlag,
      'ack_code': ackCode,
      'type': 33,
    };
    scheduleAckController.add(ackMap);

    if (emitFinal) {
      scheduleFinalResultController.add(<String, dynamic>{
        'topic': identifier,
        'expected': List<int>.from(expected!),
        'acked': pending!.ackedScheduleIds.toList()..sort(),
        'success': finalSuccess,
        'ack_code': ackCode,
      });
    }
  }

  /// Handle schedule action ACK (type 54) — stop/resume/delete
  /// Payload D: {"ids": <bitmask>, "ack": <1=stop, 2=resume, 3=delete>}
  void _handleScheduleActionAck(String identifier, dynamic payloadData) {
    if (payloadData is! Map<String, dynamic>) {
      debugPrint('⚠️ Invalid schedule action ACK payload: $payloadData');
      return;
    }

    final idsRaw = payloadData['ids'];
    final ackRaw = payloadData['ack'];

    final ids = idsRaw is int ? idsRaw : int.tryParse('$idsRaw');
    final ack = ackRaw is int ? ackRaw : int.tryParse('$ackRaw');

    if (ids == null || ack == null) {
      debugPrint(
          '⚠️ Schedule action ACK missing required fields (ids/ack): $payloadData');
      return;
    }

    // Decode ALL set bits to recover all acknowledged scheduleIds
    final List<int> ackedScheduleIds = [];
    for (int bit = 0; bit < 32; bit++) {
      if ((ids >> bit) & 1 == 1) ackedScheduleIds.add(bit + 1);
    }
    final scheduleId = ackedScheduleIds.isNotEmpty ? ackedScheduleIds.last : 0;

    final commandKey = 'schedule_action_$identifier';

    // Ignore late ACKs that arrive after retries were exhausted
    if (_expiredActionKeys.contains(commandKey)) {
      debugPrint('⚠️ Late T:54 ACK ignored (retries exhausted): $identifier');
      return;
    }

    commandStatusNotifier.value = null;

    // Pull the in-flight pending action so we can: (a) accumulate partial
    // acks across retries, (b) compare ack code against the cmd we sent.
    final pendingKey = '${commandKey}_24';
    final pending = _pendingCommands[pendingKey];
    final expected = pending?.expectedScheduleIds;
    int? sentCmd;
    if (pending != null && pending.commandData is Map) {
      final d = (pending.commandData as Map)['D'];
      if (d is Map) {
        final m1 = d['m1'];
        if (m1 is Map) sentCmd = m1['cmd'] as int?;
      }
    }
    final isSuccess = sentCmd != null && ack == sentCmd;

    bool emitFinal = false;
    bool finalSuccess = false;

    if (expected != null && expected.isNotEmpty) {
      if (isSuccess) {
        pending!.ackedScheduleIds.addAll(ackedScheduleIds);
        final allCovered = expected.every(pending.ackedScheduleIds.contains);
        if (allCovered) {
          _clearPendingCommand(commandKey, 24);
          _expiredActionKeys.add(commandKey);
          emitFinal = true;
          finalSuccess = true;
        } else {
          debugPrint(
              '⏳ Partial T:54 ACK: ${pending.ackedScheduleIds.toList()} of $expected — keeping retry alive');
        }
      } else {
        // Device-side error code — retrying won't help, stop now.
        _clearPendingCommand(commandKey, 24);
        _expiredActionKeys.add(commandKey);
        emitFinal = true;
        finalSuccess = false;
      }
    } else {
      // Untracked (single-action path): legacy behaviour.
      _clearPendingCommand(commandKey, 24);
    }

    // Note: success is `ack == cmd` (the controller knows the cmd it sent).
    // Codes {0, 4, 5, 6} are device-side errors — see scheduleActionAckErrorMessage.
    final ackMap = <String, dynamic>{
      'topic': identifier,
      'id': scheduleId,
      'ids': ackedScheduleIds,
      'ack': ack,
    };
    scheduleActionAckController.add(ackMap);

    if (emitFinal) {
      scheduleActionFinalResultController.add(<String, dynamic>{
        'topic': identifier,
        'expected': List<int>.from(expected!),
        'acked': pending!.ackedScheduleIds.toList()..sort(),
        'cmd': sentCmd,
        'success': finalSuccess,
        'ack_code': ack,
      });
    }

    debugPrint(
        '✓ Schedule Action ACK received from $identifier: ids=$ids, ack=$ack, scheduleIds=$ackedScheduleIds');
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

    // Update signal on ALL matching motors (not just the first match)
    // This ensures signal is updated regardless of which entry the UI reads
    bool found = false;

    for (var entry in _motorDataMap.entries) {
      final motorData = entry.value;
      if (motorData.macAddress == identifier ||
          motorData.pcbNumber == identifier) {
        motorData.updateSignalStrength(signalQuality);
        motorData.testRunSignal = true;
        // testRunSignal reflects live signal quality:
        // bars > 0 → connected, bars == 0 → no signal.
        // motorData.testRunSignal = motorData.signalBars > 0;
        motorData.hasReceivedData = true;
        found = true;
        debugPrint(
            '   ✓ Updated signal for ${entry.key}: bars=${motorData.signalBars}, testRunSignal=${motorData.testRunSignal}');
      }
    }

    if (!found) {
      debugPrint('   ⚠️ No motor found for identifier=$identifier');
    }

    _heartbeatNotifier.value++;
    _dataUpdateNotifier.value++;
    _liveDataNotifier.value++;
  }

  int testRunSignalStrength(int strength) {
    if (strength < 2 || strength > 31) {
      return 0;
    } else if (strength <= 9) {
      return 1;
    } else if (strength <= 14) {
      return 2;
    } else if (strength <= 19) {
      return 3;
    } else if (strength <= 30) {
      return 4;
    } else {
      return 0;
    }
  }

  /// Update motor data from live data payload
  void _updateMotorDataFromPayload(
      MotorData motorData, Map<String, dynamic> data, bool isG04) {
    // State
    if (data.containsKey('m_s') || data.containsKey('mtr_sts')) {
      final newState = (data['m_s'] ?? data['mtr_sts']) ?? 0;
      // Track state change time for runtime calculation
      if (motorData.stateChangedAt == null || motorData.state != newState) {
        motorData.stateChangedAt = DateTime.now();
      }
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

  /// Parse sch field from a G01/G02 group payload and store in motorData.schedules.
  void _parseSchedule(MotorData motorData, Map<String, dynamic> groupData) {
    final schRaw = groupData['sch'];
    if (schRaw is! Map<String, dynamic>) return;

    final idRaw = schRaw['id'];
    final scheduleId = idRaw is int ? idRaw : int.tryParse('$idRaw');
    if (scheduleId == null) return;

    final info = ScheduleInfo(
      id: scheduleId,
      startTime: (schRaw['st'] as num?)?.toInt() ?? 0,
      runtime: (schRaw['rt'] as num?)?.toInt() ?? 0,
      endTime: (schRaw['et'] as num?)?.toInt() ?? 0,
      missedTimes: (schRaw['mm'] as num?)?.toInt() ?? 0,
      failureEpoch: (schRaw['fe'] as num?)?.toInt() ?? 0,
      failureReason: (schRaw['fr'] as num?)?.toInt() ?? 0,
      startEpoch: (schRaw['st_ep'] as num?)?.toInt() ?? 0,
      endEpoch: (schRaw['et_ep'] as num?)?.toInt() ?? 0,
    );
    motorData.schedules[scheduleId] = info;

    // Notify MotorScheduleController so the list updates without a refresh
    _scheduleLiveDataController.add({
      'scheduleId': scheduleId,
      'runtime': info.runtime,
      'startTime': info.startTime,
      'endTime': info.endTime,
      'missedTimes': info.missedTimes,
      'failureEpoch': info.failureEpoch,
      'failureReason': info.failureReason,
      'startEpoch': info.startEpoch,
      'endEpoch': info.endEpoch,
    });
    debugPrint(
        '   ✓ Schedule[$scheduleId] updated: rt=${schRaw['rt']}, fr=${schRaw['fr']}, st_ep=${schRaw['st_ep']}, et_ep=${schRaw['et_ep']}');
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

    // Get PCB number from motor data, or fall back to the identifier from motorId
    final motorData = _motorDataMap[motorId];

    final String identifier = motorId.substring(0, lastDashIndex);

    final topic = 'peepul/$identifier/cmd';

    final payload = jsonEncode({"T": type, "S": seq, "D": data});
    final builder = MqttClientPayloadBuilder()..addString(payload);

    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    debugPrint(
        ' Published: $motorId (T=$type, D=$data) -> $topic (PCB: $identifier)');
  }

  void _registerPendingCommand(String motorId, int type, dynamic data, int seq,
      {String? pcbnumber, List<int>? expectedScheduleIds}) {
    final key = '${motorId}_$type';

    // Cancel any existing timer for this key to prevent duplicate retries.
    _pendingCommands.remove(key)?.cancelTimer();

    final command = PendingCommand(
      motorId: motorId,
      commandType: type,
      commandData: data,
      sequenceNumber: seq,
      onMaxRetriesReached: (message) {
        commandStatusNotifier.value = message;
        _dataUpdateNotifier.value++;
      },
      pcbnumber: pcbnumber,
      expectedScheduleIds: expectedScheduleIds,
    );

    _scheduleRetry(command);
    _pendingCommands[key] = command;

    debugPrint('   Registered pending: $key');
  }

  void _scheduleRetry(PendingCommand command) {
    final delay = command.retryCount == 0
        ? _firstRetryDelay
        : command.retryCount == 1
            ? _secondRetryDelay
            : _finalWaitDelay;

    command.retryTimer = Timer(delay, () async {
      final key = '${command.motorId}_${command.commandType}';

      // Check if command was already acked
      if (!_pendingCommands.containsKey(key)) return;

      if (command.retryCount < _maxRetries) {
        command.retryCount++;

        try {
          if (command.commandType == 4 && command.pcbnumber != null) {
            // Settings command
            await _publishDefaultSettingCommandInternal(
              command.commandData,
              command.pcbnumber!,
              sequenceNumber: command.sequenceNumber,
              isRetry: true,
            );
            debugPrint(
                '🔄 Retry ${command.retryCount}: Settings (${command.pcbnumber})');
          } else if ((command.commandType == 23 || command.commandType == 24) &&
              command.pcbnumber != null) {
            // Schedule create (23) or schedule action (24) command
            await _publishScheduleCommandInternal(
              command.commandData as Map<String, dynamic>,
              command.pcbnumber!,
              sequenceNumber: command.sequenceNumber,
              isRetry: true,
            );
            debugPrint(
                '🔄 Retry ${command.retryCount}: Schedule (${command.pcbnumber})');
          } else {
            // Motor control or mode change command
            await _publishCommand(
              command.motorId,
              command.commandType,
              command.commandData as int,
              command.sequenceNumber,
            );
            debugPrint('🔄 Retry ${command.retryCount}: ${command.motorId}');
          }
          _scheduleRetry(command);
        } catch (e) {
          debugPrint('✗ Retry failed: $e');
          _pendingCommands.remove(key);
        }
      } else {
        // Max retries reached
        _pendingCommands.remove(key);

        if (command.commandType == 23) {
          // Mark schedule create command as expired so late ACKs are ignored
          _expiredScheduleKeys.add(command.motorId);
          // Drop tracked publish-ids — there's no surviving ACK to consume them
          _publishedScheduleIds.remove(command.motorId);
          command.onMaxRetriesReached('Schedule: No response from device');
          final expected = command.expectedScheduleIds;
          if (expected != null && expected.isNotEmpty) {
            // Tracked multi-publish: surface a final result with whatever
            // accumulated, so the controller can render the partial / fail
            // toast. Skip the timeout stream — the result stream carries
            // richer info and the toast logic owns the messaging.
            scheduleFinalResultController.add(<String, dynamic>{
              'topic': command.pcbnumber ?? command.motorId,
              'expected': List<int>.from(expected),
              'acked': command.ackedScheduleIds.toList()..sort(),
              'success': false,
            });
          } else {
            // Notify listeners (controllers) so they can show a snackbar.
            // Identifier (pcb) is what the controller correlates to a motor;
            // fall back to motorId if pcb wasn't supplied.
            scheduleAckTimeoutController
                .add(command.pcbnumber ?? command.motorId);
          }
        } else if (command.commandType == 24) {
          // Mark schedule action command as expired so late ACKs are ignored
          _expiredActionKeys.add(command.motorId);
          command
              .onMaxRetriesReached('Schedule Action: No response from device');
          final expected = command.expectedScheduleIds;
          if (expected != null && expected.isNotEmpty) {
            int? sentCmd;
            if (command.commandData is Map) {
              final d = (command.commandData as Map)['D'];
              if (d is Map) {
                final m1 = d['m1'];
                if (m1 is Map) sentCmd = m1['cmd'] as int?;
              }
            }
            scheduleActionFinalResultController.add(<String, dynamic>{
              'topic': command.pcbnumber ?? command.motorId,
              'expected': List<int>.from(expected),
              'acked': command.ackedScheduleIds.toList()..sort(),
              'cmd': sentCmd,
              'success': false,
            });
          }
        } else if (command.commandType == 4) {
          command
              .onMaxRetriesReached('Device Settings: No response from device');
        } else {
          final rawMotorName = (_motors.entries
                      .firstWhere((e) => e.key == command.motorId,
                          orElse: () => MapEntry('', Motor()))
                      .value
                      .aliasName ??
                  'Motor')
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ');

          final motorName = rawMotorName.length > 16
              ? '${rawMotorName.substring(0, 16)}...'
              : rawMotorName;

          if (command.commandType != 5) {
            command.onMaxRetriesReached('$motorName: No response from device');
          }
        }
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

  /// Cancel pending schedule action retries (T:24) for the given identifier.
  /// Called when the user dismisses the confirmation dialog while retries are
  /// still in-flight, so we stop republishing stop/resume/delete commands.
  /// Any late T:54 ACK that arrives afterwards is ignored via _expiredActionKeys.
  void cancelScheduleActionRetries(String identifier) {
    if (identifier.trim().isEmpty) return;
    final commandKey = 'schedule_action_$identifier';
    _clearPendingCommand(commandKey, 24);
    _expiredActionKeys.add(commandKey);
    commandStatusNotifier.value = null;
    debugPrint('✓ Cancelled schedule action retries for $identifier');
  }

  /// Cancel pending schedule create / republish retries (T:23) for the given
  /// identifier. Stops the 10s/10s/3s retry loop so the MQTT-side timeout
  /// never fires `scheduleAckTimeoutController` (which would otherwise show a
  /// "No response from device" snackbar after the user cancelled the dialog).
  void cancelScheduleCreateRetries(String identifier) {
    if (identifier.trim().isEmpty) return;
    final commandKey = 'schedule_$identifier';
    _clearPendingCommand(commandKey, 23);
    _expiredScheduleKeys.add(commandKey);
    _publishedScheduleIds.remove(commandKey);
    commandStatusNotifier.value = null;
    debugPrint('✓ Cancelled schedule create retries for $identifier');
  }

  /// Clear all pending commands for a specific motor (used after test run completion)
  void clearAllPendingCommandsForMotor(String motorId) {
    final keysToRemove = <String>[];

    // Find all pending commands for this motor
    for (var key in _pendingCommands.keys) {
      if (key.startsWith('${motorId}_')) {
        keysToRemove.add(key);
      }
    }

    // Cancel timers and remove commands
    for (var key in keysToRemove) {
      final command = _pendingCommands[key];
      if (command != null) {
        command.cancelTimer();
        _pendingCommands.remove(key);
        debugPrint('✓ Cleared pending command after test run: $key');
      }
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint(
          '✓ Stopped ${keysToRemove.length} pending command(s) for $motorId to prevent retries');
    }
  }
}
