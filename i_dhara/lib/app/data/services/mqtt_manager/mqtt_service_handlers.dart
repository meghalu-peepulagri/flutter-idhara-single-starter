part of 'mqtt_service.dart';

/// MQTT incoming-message handlers (motor control / mode / fault / live data /
/// heartbeat / schedule ACKs) for [MqttService].
extension MqttHandlers on MqttService {
  /// Handle motor ON/OFF acknowledgment (type 31)
  void _handleMotorControlAck(String identifier, dynamic payloadData) {
    debugPrint('🔧 TYPE 31 received: identifier=$identifier');

    // ========== TEST RUN: ACK received — stop retries, skip state update ==========
    // When in test run, T:31 ACK stops the retry loop but must NOT update motor
    // state — the test run manages the motor lifecycle independently.
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

    // Validate: ACK state must be 0 or 1. Anything else is treated as a
    // failure — revert the motor to its previous state so the UI is correct.
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

    // ========== CRITICAL: BLOCK TYPE 32 FOR TEST RUN MOTORS ==========
    // ========== CRITICAL: COMPLETELY IGNORE TYPE 32 IN TEST RUN ==========
    // If in test run, IGNORE COMPLETELY - no ACK time, no mode change, NOTHING
    if (isIdentifierInTestRun(identifier)) {
      debugPrint('   🚫🚫🚫 COMPLETELY IGNORING TYPE 32 - Test run active');
      debugPrint('   → NOT recording ACK time');
      debugPrint('   → NOT updating mode');
      debugPrint('   → Test run will NOT complete from this message');
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

    if (newMode == null || (newMode != 0 && newMode != 1)) {
      debugPrint(
          '   ⚠️ Mode ACK: Invalid mode value: $payloadData (parsed as $newMode) — reverting to previous mode');
      // Explicitly restore the mode notifier so the UI snaps back to the
      // previous mode instead of staying in a stale/intermediate state.
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

    debugPrint(
        '📥 Mode Change ACK: identifier=$identifier, mode=$newMode (${newMode == 1 ? "AUTO" : "MANUAL"})');
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
      if (groupData == null) {
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
      if (groupData == null) {
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

    // Cancel all pending T:5 commands for motors matching this identifier.
    // Keys are formatted as '${motorId}_5', so we scan for any ending in '_5'
    // whose motorId maps to a motor with a matching MAC or PCB address.
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

    // Force notify listeners
    // T:35 live data only fires liveDataNotifier — NOT heartbeatNotifier.
    // heartbeatNotifier is reserved for T:40 heartbeat (network signal only).
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
    } catch (_) {
      // ignore
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

    // Firmware payload shape: {"T":33, "S":<seq>, "D":<success_int>}
    //   D = success flag (1 = success, 0 = failure).
    //   S = sequence number — not read here; correlation isn't needed because
    //       any T:33 on this identifier confirms the last publish on this key.
    // The firmware does NOT report which scheduleIds were stored — it just
    // confirms the last publish. So the source of truth for "which ids to
    // acknowledge" is our own _publishedScheduleIds, recorded at publish time.
    // Firmware D may be either:
    //   - the new shape: { "ids": <bitmask>, "ack": <code> } — ackCode and
    //     scheduleIds come straight off the device payload, or
    //   - a legacy plain int (1=success / 0=failure), in which case the
    //     scheduleIds we trust are whatever we last published on this key.
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

    // For tracked multi-schedule publishes, the retry loop must keep firing
    // until EVERY expected scheduleId has been acked. We accumulate across
    // ACKs and only clear the pending command when the union covers the
    // expected set; otherwise we leave the retry timer alone. Any non-1
    // ack code is a device-side error — we stop retries immediately and
    // emit a final result with whatever has accumulated so far.
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
        // Device returned an error code — retrying the same payload won't
        // help, so stop the retry loop and surface a final failure carrying
        // whatever earlier publishes managed to ack.
        _clearPendingCommand(scheduleCommandKey, 23);
        _expiredScheduleKeys.add(scheduleCommandKey);
        emitFinal = true;
        finalSuccess = false;
      }
    } else {
      // Untracked publish (single create / republish / edit): clear once
      // the device responds, regardless of success or error.
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
}
