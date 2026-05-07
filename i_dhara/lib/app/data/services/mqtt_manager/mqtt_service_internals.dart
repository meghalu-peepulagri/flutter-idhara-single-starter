part of 'mqtt_service.dart';

/// Low-level helpers: payload-to-MotorData mapping, motor lookup by identifier,
/// command publishing primitives, and the retry / pending-command machinery.
extension MqttInternals on MqttService {
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
        ? _kFirstRetryDelay
        : command.retryCount == 1
            ? _kSecondRetryDelay
            : _kFinalWaitDelay;

    command.retryTimer = Timer(delay, () async {
      final key = '${command.motorId}_${command.commandType}';

      // Check if command was already acked
      if (!_pendingCommands.containsKey(key)) return;

      if (command.retryCount < _kMaxRetries) {
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
