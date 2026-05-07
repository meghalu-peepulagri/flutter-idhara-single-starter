part of 'mqtt_service.dart';

/// Schedule create + bulk action publish methods for [MqttService].
extension MqttPublishSchedule on MqttService {
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

  /// Publish multiple schedules in a single T:3 command.
  /// Items MUST be complete MQTT schedule maps (same shape as the single
  /// [publishScheduleCommand] builds). Items are sorted by `id` ascending
  /// before publishing, as the device expects ascending order.
  Future<void> publishMultipleSchedulesCommand({
    required String identifier,
    required List<Map<String, dynamic>> items,
    int plr = 30,
    int? sequenceNumber,

    /// 1 = first schedule on this motor, 2 = motor already has schedules
    int idx = 1,

    /// When true, the retry loop keeps firing on partial ACKs until every
    /// scheduleId in [items] is acked or the retries exhaust. Used by the
    /// multi-schedule create flow to drive the partial / full result toast.
    /// Republish flows leave this false and keep the legacy "any ACK clears
    /// the retry" behaviour.
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

  /// Publish schedule action command (T:24) for a single schedule.
  /// cmd: 1=stop, 2=resume, 3=delete
  /// ids = 2^(scheduleId - 1): bitmask representation of the schedule ID
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

  /// Publish schedule action command (T:24) for multiple schedules at once.
  /// cmd: 1=stop, 2=resume, 3=delete
  /// ids bitmask = OR of 2^(scheduleId - 1) for each scheduleId
  Future<void> publishBulkScheduleActionCommand({
    required String identifier,
    required List<int> scheduleIds,
    required int cmd,
    int? sequenceNumber,

    /// When true, the retry loop keeps firing on partial T:54 ACKs until
    /// every scheduleId is acked or the retries exhaust — same pattern as
    /// [publishMultipleSchedulesCommand]. The bulk-action controller path
    /// uses this to drive the partial / full result snackbar.
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
      // Register BEFORE the async publish. await yields control to the event
      // loop, so a concurrent call could pass the alreadyInFlight check above
      // if we only set the key after the await. Registering first (synchronous)
      // ensures any racing call sees the key immediately and skips.
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
        // If the initial publish fails, cancel the retry loop so it doesn't
        // keep retrying a command that was never sent.
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
}
