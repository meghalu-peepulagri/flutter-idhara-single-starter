import 'dart:async';

import 'package:flutter/foundation.dart';

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
