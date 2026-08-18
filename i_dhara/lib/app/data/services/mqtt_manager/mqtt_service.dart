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
  String? motorReference;
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

    if (strength < 2 || strength > 40) {
      signalBars = 0;
    } else if (strength <= 9) {
      signalBars = 1;
    } else if (strength <= 14) {
      signalBars = 2;
    } else if (strength <= 19) {
      signalBars = 3;
    } else if (strength <= 40) {
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
  final int? failureEpoch;
  final int failureReason; // 1=Power Loss, 2=Fault, 3=Mode Change
  final int startEpoch; // st — unix epoch (seconds) for the schedule start
  final int endEpoch; // et — unix epoch (seconds) for the schedule end
  final int? scheduleStatus;

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
    this.scheduleStatus,
  });
}

/// Tracks pending commands for retry mechanism
class PendingCommand {
  final String motorId;
  final int
      commandType; // see MqttService topic* constants
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

  /// When non-null, this PendingCommand owns several parallel T:3 payloads
  /// (one per filtered date in a batched schedule create). On each retry
  /// tick the service re-publishes all of them; a single ACK covering
  /// [expectedScheduleIds] satisfies the whole batch.
  final List<Map<String, dynamic>>? batchedPayloads;

  /// Multi-motor: when set, control/test-run (T:1) payloads wrap D per motor
  /// as D:{<motorReference>: value}. Null for single-motor (flat D).
  final String? motorReference;

  PendingCommand({
    required this.motorId,
    required this.commandType,
    required this.commandData,
    required this.sequenceNumber,
    this.retryCount = 0,
    required this.onMaxRetriesReached,
    this.pcbnumber,
    this.expectedScheduleIds,
    this.batchedPayloads,
    this.motorReference,
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

  void restoreMotorRegistry(Map<String, Motor> newMotors) {
    _motors = newMotors;
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
    String? motorReference,
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
      await _publishCommand(motorId, type, data, seq,
          motorReference: motorReference);
      statusMessage = 'Test run command sent';
      _registerPendingCommand(motorId, type, data, seq,
          motorReference: motorReference);

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
      _registerPendingCommand('', topicCalibration, payload, seq,
          pcbnumber: pcb);
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

    final payload = {
      "T": _wireType(pcbnumber, topicCalibration),
      "S": seq,
      "D": commandData
    };

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
    const key = '_$topicCalibration';
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

    /// Batch index in a multi-batch publish. Single-message paths (single
    /// create / edit) always publish as batch 0.
    int last = 0,
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
      if (isEdit) 'cid': scheduleId,
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
        'last': last,
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
      scheduleCreateCommandType, // both create and edit share this key
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

    /// Batch index — 0 for a single-batch publish. Callers that emit several
    /// batches sequentially increment this per batch.
    int last = 0,
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
        'last': last,
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
      scheduleCreateCommandType,
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

  /// Publish a list of per-date schedule messages in parallel batches.
  ///
  /// Each entry in [dateMessages] is the `m1[]` for one filtered date — every
  /// item inside already has `sd == ed == that date`. The method chunks the
  /// list into groups of [batchSize] (default 8), fires every message in a
  /// chunk in parallel with `D.last = batchIndex`, then waits for either a
  /// device ACK covering the chunk's expected scheduleIds or for
  /// [perBatchAckWindow] to elapse before moving on to the next chunk.
  ///
  /// Returns `true` only when every chunk completed with a successful ACK.
  /// Per-message retries (10s / 10s / 3s) are handled by the existing
  /// retry machinery — a `PendingCommand` with [PendingCommand.batchedPayloads]
  /// set fans out republishes across all messages in the active chunk.
  Future<bool> publishSchedulesBatched({
    required String identifier,
    required List<List<Map<String, dynamic>>> dateMessages,
    required int idx,
    int batchSize = 8, // kept for API compat — unused, all messages share one batch
    int plr = 30,
    Duration perBatchAckWindow = const Duration(seconds: 23),
    Duration interBatchDelay = const Duration(milliseconds: 200),

    /// When `true` (default) the batch registers a `PendingCommand` that
    /// drives the 10s/10s/3s retry-on-no-ACK loop, re-firing every MQTT
    /// message on each retry. When `false` the caller fires once and the
    /// method returns without waiting.
    bool autoRetry = true,
  }) async {
    if (_mqttClient == null || !isConnected) {
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }
    if (identifier.trim().isEmpty) {
      throw Exception('Invalid identifier for schedule publish');
    }
    if (dateMessages.isEmpty) return true;

    // All MQTT messages go out as ONE logical batch — they fire
    // back-to-back at t=0 (so a 12-entry create publishes 8 then 4
    // immediately), and a single shared retry timer re-fires every
    // message at t=10s, t=20s. `D.last` is set per message: 1 for the
    // final message in the sequence (or the only message in a single-
    // payload case), 0 for the rest.
    return _publishOneScheduleBatch(
      identifier: identifier,
      messages: dateMessages,
      idx: idx,
      plr: plr,
      ackWindow: perBatchAckWindow,
      autoRetry: autoRetry,
    );
  }

  Future<bool> _publishOneScheduleBatch({
    required String identifier,
    required List<List<Map<String, dynamic>>> messages,
    required int idx,
    required int plr,
    required Duration ackWindow,
    bool autoRetry = true,
  }) async {
    // Build a payload per MQTT message. Each message's m1[] is sorted by
    // `id` so the device sees consistent ordering. `D.last` is set per
    // message: 1 for the final (or only) payload, 0 for the rest, so
    // the device knows when the full sequence has arrived.
    //
    // `D.sch_cnt` carries the TOTAL schedule count across the whole
    // sequence (every m1 entry in every message), not the m1 length of
    // the current payload — so the device can sanity-check that it
    // received every scheduled record once all `last=0` messages
    // followed by a single `last=1` have arrived.
    final totalScheduleCount = messages.fold<int>(
      0,
      (acc, m1) => acc + m1.length,
    );
    final payloads = <Map<String, dynamic>>[];
    final expectedIds = <int>{};
    for (int m = 0; m < messages.length; m++) {
      final m1 = messages[m];
      if (m1.isEmpty) continue;
      final sorted = List<Map<String, dynamic>>.from(m1)
        ..sort((a, b) =>
            ((a['id'] as int?) ?? 0).compareTo((b['id'] as int?) ?? 0));
      for (final item in sorted) {
        final id = (item['id'] as int?) ?? 0;
        if (id > 0) expectedIds.add(id);
      }
      final isFinal = m == messages.length - 1;
      final seq = _random.nextInt(251);
      payloads.add(<String, dynamic>{
        'T': 3,
        'S': seq,
        'D': {
          'idx': idx,
          'last': isFinal ? 1 : 0,
          'sch_cnt': totalScheduleCount,
          'plr': plr,
          'm1': sorted,
        },
      });
    }
    if (payloads.isEmpty) return true;

    final commandKey = 'schedule_$identifier';
    _lastAckTimes.remove(commandKey);
    _expiredScheduleKeys.remove(commandKey);
    _publishedScheduleIds[commandKey] = expectedIds.toList();

    // Subscribe to the ACK + timeout streams BEFORE publishing so a fast
    // device ACK during Future.wait doesn't slip past. We intentionally
    // do NOT set `expectedScheduleIds` on the PendingCommand — that would
    // cause the service to emit `scheduleFinalResult` per batch, which the
    // controller's listener turns into a duplicate "X of Y" toast for
    // every batch. Instead we treat the first successful T:33 ACK as
    // "batch done" and let the schedule_page caller render a single final
    // snackbar.
    final completer = Completer<bool>();
    final ackSub = scheduleAckStream.listen((ack) {
      if (completer.isCompleted) return;
      final topic = (ack['topic'] ?? '').toString();
      if (topic != identifier) return;
      final ackCode =
          (ack['ack_code'] as int?) ?? (ack['D'] as int? ?? 0);
      completer.complete(ackCode == 1);
    });
    final timeoutSub = scheduleAckTimeoutStream.listen((timedOutId) {
      if (completer.isCompleted) return;
      if (timedOutId != identifier) return;
      completer.complete(false);
    });

    try {
      // Fire all publishes in parallel — one socket failure shouldn't
      // sink the whole batch.
      await Future.wait(payloads.map((p) async {
        try {
          await _publishScheduleCommandInternal(
            p,
            identifier,
            sequenceNumber: (p['S'] as num?)?.toInt(),
          );
        } catch (e) {
          debugPrint('   ✗ Initial batch publish failed: $e');
        }
      }));

      statusMessage = 'Schedule batch (${payloads.length} msgs) sent';
      _dataUpdateNotifier.value++;

      if (!autoRetry) {
        // Pre-expanded retry mode — the caller already put 3 copies of
        // each unique payload into the batch list, so no in-MQTT retry
        // timer is needed. We don't block on an ACK either; the wire-level
        // 3-send guarantee is enough.
        return true;
      }

      _registerPendingCommand(
        commandKey,
        scheduleCreateCommandType,
        // Use the first payload as the "anchor" commandData; retries iterate
        // batchedPayloads instead. This keeps existing code paths that read
        // commandData (e.g. legacy ACK handling) working.
        payloads.first,
        (payloads.first['S'] as num).toInt(),
        pcbnumber: identifier,
        batchedPayloads: payloads,
      );

      return await completer.future.timeout(ackWindow, onTimeout: () {
        // Retries will have already fired within the window; if no success
        // result landed by now, the device didn't ACK.
        return false;
      });
    } finally {
      await ackSub.cancel();
      await timeoutSub.cancel();
    }
  }

  Future<void> publishScheduleActionCommand({
    required String identifier,
    required int scheduleId,
    required int cmd,
    int? sequenceNumber,
    String motorReference = 'm1',
    bool isMultiMotor = false,
  }) async {
    await publishBulkScheduleActionCommand(
      identifier: identifier,
      scheduleIds: [scheduleId],
      cmd: cmd,
      sequenceNumber: sequenceNumber,
      motorReference: motorReference,
      isMultiMotor: isMultiMotor,
    );
  }

  Future<void> publishBulkScheduleActionCommand({
    required String identifier,
    required List<int> scheduleIds,
    required int cmd,
    int? sequenceNumber,
    bool trackExpectedAcks = false,
    String motorReference = 'm1',
    bool isMultiMotor = false,
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

    final motorKey = motorReference == 'm2' ? 'm2' : 'm1';
    final payload = <String, dynamic>{
      'T': _wireType(identifier, topicScheduleUpdate),
      'S': seq,
      'D': isMultiMotor
          ? {
              'cmd': cmd,
              motorKey: {
                'ids': ids,
              },
            }
          : {
              'm1': {
                'cmd': cmd,
                'ids': ids,
              },
            },
    };

    final commandKey = 'schedule_action_$identifier';
    final alreadyInFlight =
        _pendingCommands.containsKey('${commandKey}_$topicScheduleUpdate');
    _lastAckTimes.remove(commandKey);
    // Clear expired status so a fresh command's ACK is accepted
    _expiredActionKeys.remove(commandKey);

    if (!alreadyInFlight) {
      _registerPendingCommand(
        commandKey,
        topicScheduleUpdate,
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
        _clearPendingCommand(commandKey, topicScheduleUpdate);
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

  /// Publish fault clear command.
  /// Payload version 1.0: T:7, S:seq, D:1 (flat, unchanged).
  /// Payload version 2.0 — single AND dual motor starters: T:7, S:seq,
  /// D:{"<motorReference>":1}, scoped to just the motor being cleared.
  Future<void> publishFaultClearCommand(String motorId,
      {String? motorReference}) async {
    if (_mqttClient == null || !isConnected) {
      debugPrint('✗ Cannot publish fault clear: MQTT not connected');
      statusMessage = 'MQTT not connected';
      _dataUpdateNotifier.value++;
      throw Exception('MQTT not connected');
    }

    final lastDashIndex = motorId.lastIndexOf('-');
    if (lastDashIndex <= 0) {
      throw Exception('Invalid motorId format: $motorId');
    }
    final identifier = motorId.substring(0, lastDashIndex);

    _lastAckTimes.remove(motorId);
    final seq = _random.nextInt(251);

    final motorKey = motorReference == 'm2' ? 'm2' : 'm1';
    final usesObjectPayload = _usesObjectPayload(identifier);
    final dynamic data = usesObjectPayload ? {motorKey: 1} : 1;

    try {
      await _publishFaultClear(identifier, data, seq);
      statusMessage = 'Fault clear command sent';
      // The device's fault-clear ACK is flat (D:1) — it never echoes back
      // which motor it cleared — so remember the motor we actually asked
      // for here; _handleFaultClearAck scopes the local fault-flag update
      // to this instead of trusting the ACK payload.
      _registerPendingCommand(
          motorId, MqttService.topicDeviceFaultsClear, data, seq,
          motorReference: usesObjectPayload ? motorKey : null);
    } catch (e) {
      debugPrint('✗ Failed to publish fault clear command: $e');
      statusMessage = 'Failed to publish fault clear: $e';
      _dataUpdateNotifier.value++;
      rethrow;
    }
    _dataUpdateNotifier.value++;
  }

  Future<void> _publishFaultClear(
      String identifier, dynamic data, int seq) async {
    final topic = 'peepul/$identifier/cmd';
    final payload = jsonEncode(
        {'T': MqttService.topicDeviceFaultsClear, 'S': seq, 'D': data});
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    debugPrint('✓ Published Fault Clear -> $topic: $payload');
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
    // A dashboard/motor-details refresh rebuilds this map from the freshly
    // fetched API records, whose starterParameters hold the LAST-STORED
    // (past) voltages/currents — not what the device is publishing right now.
    // Snapshot whatever live values MQTT already delivered so they survive
    // the rebuild; otherwise the UI falls back to the API values and visibly
    // jumps back to the present reading only when the next T:35/41 arrives.
    final previous = Map<String, MotorData>.from(_motorDataMap);
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

      // A payload-version 2.0 single-motor starter talks in motor-scoped
      // objects (D:{"m1":…}) exactly like a dual-motor one, so its MotorData
      // needs the reference for the multi-motor live-data and ACK paths to
      // resolve to THIS entry — the one the UI reads — instead of matching
      // nothing (or building a parallel entry). Use the API's motor_reference
      // when present and fall back to 'm1' when it isn't.
      // Scoped to single-motor starters: dual-motor is left exactly as it was,
      // and 1.x never reaches here because it publishes flat payloads.
      final starterSupport =
          (motor.starter?.motorSupportType ?? '').toUpperCase();
      if (!starterSupport.contains('MULTI') &&
          motor.starter?.usesObjectPayload == true) {
        _motorDataMap[key]!.motorReference =
            motor.motorReference ?? defaultMotorReference;
      }

      _carryOverLiveValues(_motorDataMap[key]!, previous[key]);

      debugPrint(
          '   Added: $key (identifier=$identifier, groupId=$groupId, mac=${motor.starter?.macAddress}, pcb=${motor.starter?.pcbNumber})');
    }

    // Live data may live under a motor-scoped key ('<id>-G01-m1') that the
    // registry itself never builds. Keep those rows when their base key is
    // still present so the multi-motor / payload-2.0 lookups keep resolving
    // to real readings after a refresh.
    for (final entry in previous.entries) {
      if (_motorDataMap.containsKey(entry.key)) continue;
      if (!entry.value.hasReceivedLiveData) continue;
      final lastDash = entry.key.lastIndexOf('-');
      if (lastDash <= 0) continue;
      final baseKey = entry.key.substring(0, lastDash);
      if (_motorDataMap.containsKey(baseKey)) {
        _motorDataMap[entry.key] = entry.value;
      }
    }

    debugPrint('=== motorDataMap built: ${_motorDataMap.length} entries ===');
    _dataUpdateNotifier.value++;
  }

  void _carryOverLiveValues(MotorData fresh, MotorData? prior) {
    if (prior == null || !prior.hasReceivedData) return;

    fresh.hasReceivedData = true;
    fresh.signalStrength = prior.signalStrength;
    fresh.signalBars = prior.signalBars;
    fresh.lastSignalUpdate = prior.lastSignalUpdate;
    fresh.schedules
      ..clear()
      ..addAll(prior.schedules);

    if (!prior.hasReceivedLiveData) return;

    fresh.hasReceivedLiveData = true;
    fresh.voltageRed = prior.voltageRed;
    fresh.voltageYellow = prior.voltageYellow;
    fresh.voltageBlue = prior.voltageBlue;
    fresh.currentRed = prior.currentRed;
    fresh.currentYellow = prior.currentYellow;
    fresh.currentBlue = prior.currentBlue;
    fresh.power = prior.power;
    fresh.state = prior.state;
    fresh.motorMode = prior.motorMode;
    fresh.modeIndex = prior.modeIndex;
    fresh.runTime = prior.runTime;
    fresh.stateChangedAt = prior.stateChangedAt;
    fresh.controller.value = prior.state == 1;
    fresh.modeswitchcontroller.value = prior.modeIndex;
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

        // v1.0 firmware answers calibration/schedule-action/live-data(-request)
        // and heartbeat on its own older wire numbers — translate those back
        // to the internal ids the switch below dispatches on. No-op for v2.0.
        final effectiveType = _internalType(identifier, type);

        debugPrint(
            '📩 MQTT Message: topic=$topic, type=$type (effective=$effectiveType), identifier=$identifier');

        switch (effectiveType) {
          case topicMotorControlAck:
            _handleMotorControlAck(identifier, payloadData);
            break;
          case topicModeChangeAck:
            _handleModeChangeAck(identifier, payloadData);
            break;
          case topicCalibrationAck:
            handleDefaultSettings(identifier, payloadData);
            break;
          case topicLiveDataRequestAck:
            _handleLiveDataRequest(identifier, payloadData);
          case topicLiveData:
            _handleLiveData(identifier, payloadData);
            break;
          case topicHeartBeat:
            _handleHeartbeat(identifier, payloadData);
            break;
          case topicSchedulingCreateAck:
            _handleScheduleAck(identifier, data as Map<String, dynamic>);
            break;
          case topicScheduleUpdateAck:
            _handleScheduleActionAck(identifier, payloadData);
            break;
          case topicFaultsClearAck:
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

  void _handleMultiMotorControlAck(
      String identifier, Map<String, dynamic> payloadData) {
    payloadData.forEach((motorKey, rawState) {
      int? state;
      if (rawState is int) {
        state = rawState;
      } else if (rawState is String) {
        state = int.tryParse(rawState);
      } else if (rawState is double) {
        state = rawState.toInt();
      }
      final s = state;
      if (s == null || (s != 0 && s != 1)) return;

      for (final entry in _motorDataMap.entries) {
        final md = entry.value;
        if (md.motorReference == motorKey &&
            (md.macAddress == identifier || md.pcbNumber == identifier)) {
          if (md.state != s) md.stateChangedAt = DateTime.now();
          md.state = s;
          md.controller.value = (s == 1);
          md.hasReceivedData = true;
          _lastAckTimes[entry.key] = DateTime.now();
          // Stop the retry ladder, same as the flat single-motor path.
          _clearPendingCommand(entry.key, 1);
        }
      }
    });
    _dataUpdateNotifier.value++;
  }

  void _handleMultiMotorModeAck(
      String identifier, Map<String, dynamic> payloadData) {
    payloadData.forEach((motorKey, rawMode) {
      int? mode;
      if (rawMode is int) {
        mode = rawMode;
      } else if (rawMode is String) {
        mode = int.tryParse(rawMode);
      } else if (rawMode is double) {
        mode = rawMode.toInt();
      }
      var m = mode;
      if (m == null) return;
      if (m == scheduleModeDeviceCode) m = scheduleModeUiIndex;
      if (m != 0 && m != 1 && m != 2) return;

      for (final entry in _motorDataMap.entries) {
        final md = entry.value;
        if (md.motorReference == motorKey &&
            (md.macAddress == identifier || md.pcbNumber == identifier)) {
          md.modeIndex = m;
          md.modeswitchcontroller.value = m;
          md.motorMode = m == 1
              ? 'AUTO'
              : (m == scheduleModeUiIndex ? 'SCHEDULE' : 'MANUAL');
          md.hasReceivedData = true;
          // Resolve the command the same way the flat path does, so the UI
          // stops waiting and the retry ladder doesn't re-publish after ACK.
          _lastAckTimes[entry.key] = DateTime.now();
          _clearPendingCommand(entry.key, 2);
        }
      }
    });
    _dataUpdateNotifier.value++;
  }

  /// Reads the motor reference out of a multi-motor `D` object, e.g.
  /// `{"m2": 1}` -> `'m2'`. Returns null for a flat single-motor `D`, which
  /// keeps every single-motor payload on its original code path.
  String? multiMotorAckReference(dynamic payloadData) {
    if (payloadData is! Map) return null;
    for (final motorKey in const ['m1', 'm2']) {
      if (payloadData[motorKey] is num) return motorKey;
    }
    return null;
  }

  /// True when [motorId] ('<identifier>-<groupId>') and the topic [identifier]
  /// are the same physical starter. They differ whenever commands are addressed
  /// by MAC but the device publishes on its PCB number (or the reverse), so
  /// resolve the pairing through any MotorData carrying both.
  bool _isSameStarter(String motorId, String identifier) {
    final dash = motorId.lastIndexOf('-');
    final motorIdentifier =
        dash > 0 ? motorId.substring(0, dash) : motorId;
    if (motorIdentifier == identifier) return true;
    for (final motorData in _motorDataMap.values) {
      final mac = motorData.macAddress;
      final pcb = motorData.pcbNumber;
      if (mac != motorIdentifier && pcb != motorIdentifier) continue;
      if (mac == identifier || pcb == identifier) return true;
    }
    return false;
  }

  /// Multi-motor T:31 for a motor under test. The card registers its command id
  /// ('<identifier>-<groupId>', never suffixed) via [addTestRunMotor] and polls
  /// [getLastAckTime] with that same id, so the ACK is stamped there.
  /// Returns false when no test-run motor claims this ACK.
  bool _handleMultiMotorTestRunAck(String identifier, String ackRef) {
    for (final motorId in _testRunMotors) {
      if (!_isSameStarter(motorId, identifier)) continue;
      final pendingRef = _pendingCommands['${motorId}_1']?.motorReference;
      if (pendingRef != null && pendingRef != ackRef) continue;
      debugPrint(
          '   ✅ T:31 ($ackRef) for test run motor $motorId — clearing retry, skipping state update');
      _lastAckTimes[motorId] = DateTime.now();
      _clearPendingCommand(motorId, 1);
      _dataUpdateNotifier.value++;
      return true;
    }
    return false;
  }

  /// Handle motor ON/OFF acknowledgment (type 31)
  void _handleMotorControlAck(String identifier, dynamic payloadData) {
    debugPrint('🔧 TYPE 31 received: identifier=$identifier');

    final ackRef = multiMotorAckReference(payloadData);
    if (ackRef != null && _handleMultiMotorTestRunAck(identifier, ackRef)) {
      return;
    }

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

    if (payloadData is Map<String, dynamic> &&
        (payloadData.containsKey('m1') || payloadData.containsKey('m2'))) {
      _handleMultiMotorControlAck(identifier, payloadData);
      return;
    }

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

    if (payloadData is Map<String, dynamic> &&
        (payloadData.containsKey('m1') || payloadData.containsKey('m2'))) {
      _handleMultiMotorModeAck(identifier, payloadData);
      return;
    }

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
  /// ACK payload: {"T": 37, "S": 89, "D": 1, "ct": "2025/12/30,13:42:30"}
  /// The ACK is flat (D:1) even on payload 2.0 — it never echoes back which
  /// motor was cleared — so scoping to the acked motor must come from the
  /// motorReference the pending command was published with, not the ACK.
  void _handleFaultClearAck(String identifier, dynamic payloadData) {
    debugPrint('🔧 TYPE 52 (Fault Clear ACK) received: identifier=$identifier');

    void applyFaultClear(String? motorRef) {
      // For a MULTIPLE_MOTORS group, live data lives under motor-scoped keys
      // ('<id>-<groupId>-m1'/'-m2'). A null motorRef here means either a
      // flat 1.0 device (single entry, no motorReference set) or an unknown
      // scope (fallback path) — narrow to motorRef whenever it's known.
      for (final motorData in _motorDataMap.values) {
        if (motorData.macAddress != identifier &&
            motorData.pcbNumber != identifier) {
          continue;
        }
        if (motorRef != null && motorData.motorReference != motorRef) {
          continue;
        }
        motorData.fault = 0;
        motorData.hasReceivedData = true;
      }
    }

    // Find motor with pending fault clear command (type 21)
    final motorId =
        _findMotorWithPendingCommand(identifier, topicDeviceFaultsClear);

    if (motorId != null) {
      final pendingRef =
          _pendingCommands['${motorId}_$topicDeviceFaultsClear']
              ?.motorReference;
      applyFaultClear(pendingRef);
      _lastAckTimes[motorId] = DateTime.now();
      debugPrint('   ✓ Fault Clear ACK processed: $motorId -> fault cleared'
          '${pendingRef != null ? ' ($pendingRef)' : ''}');
      _clearPendingCommand(motorId, topicDeviceFaultsClear);
      // v1.0 (flat D:1) always has pendingRef == null, so this stays the
      // original bare motorId — untouched. Payload 2.0 tags it
      // '<motorId>|<motorReference>' so every card for a MULTIPLE_MOTORS
      // group (which all resolve to the SAME motorId — see _getMotorId)
      // can tell whether this ACK was actually for its own motor.
      faultClearResultNotifier.value = null; // reset first
      faultClearResultNotifier.value =
          pendingRef != null ? '$motorId|$pendingRef' : motorId;
    } else {
      // No pending command to tell us which motor — best effort using
      // whatever the ACK payload itself carries (usually nothing on a flat
      // ACK, in which case every motor for this identifier is cleared).
      final ackRef = multiMotorAckReference(payloadData);
      applyFaultClear(ackRef);
      final fallbackId = _findAnyMotorWithIdentifier(identifier);
      if (fallbackId != null) {
        _lastAckTimes[fallbackId] = DateTime.now();
        debugPrint(
            '   ✓ Fault Clear ACK processed (fallback): $fallbackId -> fault cleared');
        // Strip the '-m1'/'-m2' suffix so this matches the unsuffixed
        // '<id>-<groupId>' motorId the card listens for (see _getMotorId).
        final dash = fallbackId.lastIndexOf('-');
        final suffix = dash > 0 ? fallbackId.substring(dash + 1) : '';
        final baseId =
            (suffix == 'm1' || suffix == 'm2')
                ? fallbackId.substring(0, dash)
                : fallbackId;
        faultClearResultNotifier.value = null;
        faultClearResultNotifier.value =
            ackRef != null ? '$baseId|$ackRef' : baseId;
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

      if (_isMultiMotorGroup(groupData)) {
        _handleMultiMotorGroup(identifier, groupId, groupData);
        continue;
      }

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

      if (_isMultiMotorGroup(groupData)) {
        _handleMultiMotorGroup(identifier, groupId, groupData,
            isTestRunRequest: true);
        continue;
      }

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
      // Multi-motor replies D:{"m2":1}; single-motor stays a flat int and takes
      // the original path untouched. The reference is forwarded as "motor" so
      // the test-run card can ignore an ACK for the other motor.
      final motorReference = multiMotorAckReference(payloadData);
      final int type = motorReference != null
          ? (payloadData[motorReference] as num).toInt()
          : payloadData as int;
      final map = {
        "D": type,
        "topic": identifier,
        if (motorReference != null) "motor": motorReference,
      };

      // Clear any "No response from device" message since ACK was received
      commandStatusNotifier.value = null;

      // Clear pending settings command to stop retries immediately upon ACK
      final command = _pendingCommands['_$topicCalibration'];
      if (command != null) {
        // Cancel the retry timer and remove the pending command
        command.cancelTimer();
        _clearPendingCommand('', topicCalibration);
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

  // ── Device topic IDs ───────────────────────────────────────────────────────
  // Outbound "T" values and the ACK the device answers with. Pending-command
  // bookkeeping is keyed on the same number, so a retry re-publishes with the
  // correct type.
  static const int topicMotorControl = 1;
  static const int topicModeChange = 2;
  static const int topicSchedulingCreate = 3;
  static const int topicScheduleUpdate = 4;
  static const int topicCalibration = 5; // device settings (dvc_c)
  static const int topicDeviceFaultsClear = 7;
  static const int topicLiveDataRequest = 9;

  static const int topicMotorControlAck = 31;
  static const int topicModeChangeAck = 32;
  static const int topicSchedulingCreateAck = 33;
  static const int topicScheduleUpdateAck = 34;
  static const int topicCalibrationAck = 35;
  static const int topicFaultsClearAck = 37;
  static const int topicLiveDataRequestAck = 39;
  static const int topicHeartBeat = 46;
  static const int topicLiveData = 47;

  // ── Legacy (payload v1.0) wire numbers ─────────────────────────────────────
  // v1.0 firmware still speaks the ORIGINAL tag ids for these five commands —
  // only v2.0 firmware (single or dual motor) answers on the numbers above.
  // Everywhere else in the file keeps using the topic* constants above as the
  // single internal id for bookkeeping (pending-command keys, retry-loop
  // branches); [_wireType]/[_internalType] are the only places that convert
  // to/from these v1.0 numbers, based on the specific device's own version.
  static const int _topicCalibrationV1 = 4;
  static const int _topicCalibrationAckV1 = 34;
  static const int _topicScheduleUpdateV1 = 24;
  static const int _topicScheduleUpdateAckV1 = 54;
  static const int _topicLiveDataRequestV1 = 5;
  static const int _topicLiveDataRequestAckV1 = 35;
  static const int _topicLiveDataV1 = 41;
  static const int _topicHeartBeatV1 = 40;

  /// Outbound: internal command id -> the wire "T" this specific [identifier]
  /// actually expects. v2.0 devices already use the internal id as their wire
  /// number, so this is only ever non-identity for a v1.0 identifier.
  int _wireType(String identifier, int internalType) {
    if (_usesObjectPayload(identifier)) return internalType;
    switch (internalType) {
      case topicCalibration:
        return _topicCalibrationV1;
      case topicScheduleUpdate:
        return _topicScheduleUpdateV1;
      case topicLiveDataRequest:
        return _topicLiveDataRequestV1;
      default:
        return internalType;
    }
  }

  /// Inbound: the wire "T" a message from [identifier] arrived with -> the
  /// internal command id the rest of the file dispatches on. Identity for
  /// v2.0 devices; for v1.0 it undoes [_wireType] (plus the ack-only numbers
  /// that have no outbound counterpart: heartbeat and live data).
  int _internalType(String identifier, int wireType) {
    if (_usesObjectPayload(identifier)) return wireType;
    switch (wireType) {
      case _topicCalibrationAckV1:
        return topicCalibrationAck;
      case _topicScheduleUpdateAckV1:
        return topicScheduleUpdateAck;
      case _topicLiveDataRequestV1:
        return topicLiveDataRequest;
      case _topicLiveDataRequestAckV1:
        return topicLiveDataRequestAck;
      case _topicLiveDataV1:
        return topicLiveData;
      case _topicHeartBeatV1:
        return topicHeartBeat;
      default:
        return wireType;
    }
  }

  /// Internal key for the schedule-create pending command. Creates publish on
  /// [topicSchedulingCreate] but are tracked apart from schedule updates.
  static const int scheduleCreateCommandType = 23;

  /// Live-data request. Device-wide, so its D is never wrapped per motor.
  static const int liveDataRequestType = topicLiveDataRequest;

  /// The motor a payload-version 2.0 single-motor starter answers to.
  static const String defaultMotorReference = 'm1';

  /// True when the starter behind [identifier] (its MAC or PCB) runs a payload
  /// version that expects motor-scoped objects. Resolved from the motor list
  /// the screens push in via [updateMotors]; unknown devices stay flat.
  bool _usesObjectPayload(String identifier) {
    for (final motor in _motors.values) {
      final starter = motor.starter;
      if (starter == null) continue;
      if (starter.macAddress == identifier ||
          starter.pcbNumber == identifier) {
        return starter.usesObjectPayload;
      }
    }
    return false;
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
      case 3:
      case 5:
        return 'Index mismatch error';
      case 4:
        return 'Device flash issue';
      case 6:
        return 'JSON parsing error';
      case 7:
        return 'Count mismatch error';
      case 8:
        return 'The schedule time is invalid.';
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
          _clearPendingCommand(scheduleCommandKey, scheduleCreateCommandType);
          emitFinal = true;
          finalSuccess = true;
        } else {
          debugPrint(
              '⏳ Partial schedule ACK: ${pending.ackedScheduleIds.toList()} of $expected — keeping retry alive');
        }
      } else {
        _clearPendingCommand(scheduleCommandKey, scheduleCreateCommandType);
        _expiredScheduleKeys.add(scheduleCommandKey);
        emitFinal = true;
        finalSuccess = false;
      }
    } else {
      _clearPendingCommand(scheduleCommandKey, scheduleCreateCommandType);
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

    Map<String, dynamic> ackSource = payloadData;
    for (final motorKey in const ['m1', 'm2']) {
      final motorAck = payloadData[motorKey];
      if (motorAck is Map<String, dynamic>) {
        ackSource = motorAck;
        break;
      }
    }

    final idsRaw = ackSource['ids'];
    final ackRaw = ackSource['ack'];

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
    final pendingKey = '${commandKey}_$topicScheduleUpdate';
    final pending = _pendingCommands[pendingKey];
    final expected = pending?.expectedScheduleIds;
    int? sentCmd;
    if (pending != null && pending.commandData is Map) {
      final d = (pending.commandData as Map)['D'];
      if (d is Map) {
        if (d['cmd'] is int) {
          sentCmd = d['cmd'] as int?;
        } else {
          final m1 = d['m1'];
          if (m1 is Map) sentCmd = m1['cmd'] as int?;
        }
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
          _clearPendingCommand(commandKey, topicScheduleUpdate);
          _expiredActionKeys.add(commandKey);
          emitFinal = true;
          finalSuccess = true;
        } else {
          debugPrint(
              '⏳ Partial T:54 ACK: ${pending.ackedScheduleIds.toList()} of $expected — keeping retry alive');
        }
      } else {
        // Device-side error code — retrying won't help, stop now.
        _clearPendingCommand(commandKey, topicScheduleUpdate);
        _expiredActionKeys.add(commandKey);
        emitFinal = true;
        finalSuccess = false;
      }
    } else {
      // Untracked (single-action path): legacy behaviour.
      _clearPendingCommand(commandKey, topicScheduleUpdate);
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

    // The fields above hold whichever identifier the API reported. When the
    // device publishes on its other one (MAC vs PCB) nothing matches, so fall
    // back to the map key — live-data entries are keyed '<identifier>-<group>'.
    if (!found) {
      for (var entry in _motorDataMap.entries) {
        if (!entry.key.startsWith('$identifier-')) continue;
        final motorData = entry.value;
        motorData.updateSignalStrength(signalQuality);
        motorData.testRunSignal = true;
        motorData.hasReceivedData = true;
        found = true;
        debugPrint(
            '   ✓ Updated signal by key for ${entry.key}: bars=${motorData.signalBars}');
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
    if (strength < 2 || strength > 40) {
      return 0;
    } else if (strength <= 9) {
      return 1;
    } else if (strength <= 14) {
      return 2;
    } else if (strength <= 19) {
      return 3;
    } else if (strength <= 40) {
      return 4;
    } else {
      return 0;
    }
  }

  bool _isMultiMotorGroup(Map<String, dynamic> groupData) {
    return groupData['m1'] is Map || groupData['m2'] is Map;
  }

  void _handleMultiMotorGroup(
      String identifier, String groupId, Map<String, dynamic> groupData,
      {bool isTestRunRequest = false}) {
    final isG04 = groupId == 'G04';
    final parseSch = groupId == 'G01' || groupId == 'G02';
    for (final motorKey in const ['m1', 'm2']) {
      final motorRaw = groupData[motorKey];
      if (motorRaw is! Map<String, dynamic>) continue;

      final fullMotorId = '$identifier-$groupId-$motorKey';

      var motorData = _motorDataMap[fullMotorId];
      if (motorData == null) {
        for (var existingEntry in _motorDataMap.entries) {
          final data = existingEntry.value;
          if (data.motorReference == motorKey &&
              data.groupId == groupId &&
              (data.macAddress == identifier ||
                  data.pcbNumber == identifier)) {
            motorData = data;
            _motorDataMap[fullMotorId] = motorData;
            break;
          }
        }
      }
      motorData ??= MotorData(
        macAddress: identifier,
        pcbNumber: identifier,
        groupId: groupId,
        title: motorKey,
        power: groupData['pwr'] ?? 0,
      );
      motorData.motorReference = motorKey;
      _motorDataMap[fullMotorId] = motorData;

      final merged = <String, dynamic>{
        ...motorRaw,
        if (groupData.containsKey('pwr')) 'pwr': groupData['pwr'],
        if (groupData.containsKey('llv')) 'llv': groupData['llv'],
        if (groupData.containsKey('ll_v')) 'll_v': groupData['ll_v'],
      };
      _updateMotorDataFromPayload(motorData, merged, isG04);
      if (parseSch) _parseSchedule(motorData, motorRaw);

      if (isTestRunRequest) {
        motorData.testRunSignal = true;
        motorData.testrunPowerSupply = true;
        motorData.testrunVoltageRange = true;
        motorData.updateSignalStrength(13);
      }

      motorData.hasReceivedData = true;
      motorData.hasReceivedLiveData = true;
      _lastAckTimes[fullMotorId] = DateTime.now();
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
      var modeValue = data['mode'] as int?;
      if (modeValue != null) {
        // Translate device code 6 → UI index 2 (Schedule) so the
        // mode tab toggle (which lives in UI-index space: 0=Manual,
        // 1=Auto, 2=Schedule) lines up with what the device reports
        // in live data. Mirrors the same translation in
        // _handleModeChangeAck — T:32 ACKs and T:35 / T:41 live
        // data now converge on the same encoding so a passive sync
        // from any group (G01, G02, G04) lands on the right toggle
        // segment.
        if (modeValue == scheduleModeDeviceCode) {
          modeValue = scheduleModeUiIndex;
        }
        motorData.modeIndex = modeValue;
        motorData.modeswitchcontroller.value = modeValue;
        motorData.motorMode = modeValue == 1
            ? 'AUTO'
            : (modeValue == scheduleModeUiIndex ? 'SCHEDULE' : 'MANUAL');
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

    // Device can send numeric fields as either int (1155) or string
    // ("1155"); `et` is also null while a schedule is still running.
    // A bare `as num?` cast throws TypeError on a String and would kill
    // this whole live tick, so coerce through a tolerant helper.
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int? asIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    final info = ScheduleInfo(
      id: scheduleId,
      startTime: 0,
      runtime: asInt(schRaw['rt']),
      endTime: 0,
      missedTimes: asInt(schRaw['mm']),
      failureEpoch: asIntOrNull(schRaw['fe']),
      failureReason: asInt(schRaw['fr']),
      startEpoch: asInt(schRaw['st']),
      endEpoch: asInt(schRaw['et']),
      scheduleStatus: asIntOrNull(schRaw['ss']),
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
      'scheduleStatus': info.scheduleStatus,
    });
    debugPrint(
        '   ✓ Schedule[$scheduleId] updated: rt=${schRaw['rt']}, fr=${schRaw['fr']}, st=${schRaw['st']}, et=${schRaw['et']}, fe=${schRaw['fe']}, ss=${schRaw['ss']}');
  }

  /// Find motor with pending command of given type for the identifier.
  /// Matches against the pending command's own motorId (via [_isSameStarter])
  /// instead of joining through _motorDataMap keys — those are suffixed with
  /// '-m1'/'-m2' for MULTIPLE_MOTORS groups while a pending command's motorId
  /// (e.g. fault clear, registered as '<id>-<groupId>') never is, so the old
  /// key-join always missed and fell through to the fallback lookup.
  String? _findMotorWithPendingCommand(String identifier, int commandType) {
    // Original v1.0 / single-motor lookup — unchanged. entry.key equals the
    // registered motorId exactly for these (never suffixed), so this always
    // finds the match and the fallback below never runs for them.
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

    // Payload 2.0 MULTIPLE_MOTORS groups register the pending command under
    // the unsuffixed '<id>-<groupId>' motorId while their MotorData entries
    // are keyed '<id>-<groupId>-m1'/'-m2', so the join above can't match
    // there. Fall back to matching the pending command's own motorId
    // directly — this only ever engages for that grouped case.
    for (final entry in _pendingCommands.entries) {
      final command = entry.value;
      if (command.commandType != commandType) continue;
      if (_isSameStarter(command.motorId, identifier)) {
        debugPrint(
            '   Found pending command match (grouped): ${command.motorId}');
        return command.motorId;
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
      String motorId, int type, int data, int seq,
      {String? motorReference}) async {
    final lastDashIndex = motorId.lastIndexOf('-');
    if (lastDashIndex <= 0) {
      throw Exception('Invalid motorId format: $motorId');
    }

    // Get PCB number from motor data, or fall back to the identifier from motorId
    final motorData = _motorDataMap[motorId];

    final String identifier = motorId.substring(0, lastDashIndex);

    final topic = 'peepul/$identifier/cmd';

    // The payload version decides the shape, not the motor count: from 2.0
    // every command — live-data request included — targets a motor as
    // D:{<ref>: value}, the starter's own reference on a dual-motor device,
    // 'm1' on a single-motor one. 1.x stays flat either way.
    final String? effectiveRef = _usesObjectPayload(identifier)
        ? ((motorReference != null && motorReference.isNotEmpty)
            ? motorReference
            : defaultMotorReference)
        : null;

    final dynamic dPayload =
        effectiveRef != null ? {effectiveRef: data} : data;
    // v1.0 firmware answers live-data-request on its own older wire number.
    final wireType =
        type == liveDataRequestType ? _wireType(identifier, type) : type;
    final payload = jsonEncode({"T": wireType, "S": seq, "D": dPayload});
    final builder = MqttClientPayloadBuilder()..addString(payload);

    _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

    debugPrint(
        ' Published: $motorId (T=$type, D=$data) -> $topic (PCB: $identifier)');
  }

  void _registerPendingCommand(String motorId, int type, dynamic data, int seq,
      {String? pcbnumber,
      List<int>? expectedScheduleIds,
      List<Map<String, dynamic>>? batchedPayloads,
      String? motorReference}) {
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
      batchedPayloads: batchedPayloads,
      motorReference: motorReference,
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
          if (command.commandType == topicCalibration &&
              command.pcbnumber != null) {
            // Settings command
            await _publishDefaultSettingCommandInternal(
              command.commandData,
              command.pcbnumber!,
              sequenceNumber: command.sequenceNumber,
              isRetry: true,
            );
            debugPrint(
                '🔄 Retry ${command.retryCount}: Settings (${command.pcbnumber})');
          } else if ((command.commandType == scheduleCreateCommandType ||
                  command.commandType == topicScheduleUpdate) &&
              command.pcbnumber != null) {
            // Schedule create (23) or schedule action (24) command
            if (command.batchedPayloads != null) {
              // Batched create: re-publish every parallel payload. We don't
              // await per-publish failures — one socket error shouldn't stop
              // the others, the retry loop will fire again.
              await Future.wait(command.batchedPayloads!.map((p) async {
                try {
                  await _publishScheduleCommandInternal(
                    p,
                    command.pcbnumber!,
                    sequenceNumber: (p['S'] as num?)?.toInt(),
                    isRetry: true,
                  );
                } catch (e) {
                  debugPrint('   ✗ Batched retry publish failed: $e');
                }
              }));
              debugPrint(
                  '🔄 Retry ${command.retryCount}: Batched ${command.batchedPayloads!.length} schedules (${command.pcbnumber})');
            } else {
              await _publishScheduleCommandInternal(
                command.commandData as Map<String, dynamic>,
                command.pcbnumber!,
                sequenceNumber: command.sequenceNumber,
                isRetry: true,
              );
              debugPrint(
                  '🔄 Retry ${command.retryCount}: Schedule (${command.pcbnumber})');
            }
          } else if (command.commandType == topicDeviceFaultsClear &&
              command.commandData is Map) {
            // Fault clear (payload 2.0): commandData is {"m1":1,"m2":1},
            // not an int — publish it directly instead of via _publishCommand.
            final lastDashIndex = command.motorId.lastIndexOf('-');
            final identifier = lastDashIndex > 0
                ? command.motorId.substring(0, lastDashIndex)
                : command.motorId;
            await _publishFaultClear(
                identifier, command.commandData, command.sequenceNumber);
            debugPrint('🔄 Retry ${command.retryCount}: Fault Clear (${command.motorId})');
          } else {
            // Motor control, mode change, or test-run command
            await _publishCommand(
              command.motorId,
              command.commandType,
              command.commandData as int,
              command.sequenceNumber,
              motorReference: command.motorReference,
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

        if (command.commandType == scheduleCreateCommandType) {
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
        } else if (command.commandType == topicScheduleUpdate) {
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
        } else if (command.commandType == topicCalibration) {
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
    _clearPendingCommand(commandKey, topicScheduleUpdate);
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
    _clearPendingCommand(commandKey, scheduleCreateCommandType);
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
