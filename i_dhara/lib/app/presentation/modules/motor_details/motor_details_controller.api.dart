part of 'motor_details_controller.dart';

// ---------------------------------------------------------------------------
// Status-history segment builders (top-level)
// ---------------------------------------------------------------------------

/// Builds Motor ON segments from status-history records.
/// Each record's [timeStamp] marks when the status changed to [status].
/// The segment ends at the next record's timestamp (or now for the last ON).
List<TimeSegment> _buildMotorOnSegments(List<Motorstatus> records) {
  if (records.isEmpty) return [];
  final sorted = List<Motorstatus>.from(records)
    ..sort((a, b) {
      if (a.timeStamp == null) return -1;
      if (b.timeStamp == null) return 1;
      return a.timeStamp!.compareTo(b.timeStamp!);
    });

  final now = DateTime.now();
  final segments = <TimeSegment>[];

  for (int i = 0; i < sorted.length; i++) {
    final r = sorted[i];
    if (r.timeStamp == null) continue;
    final status = (r.status ?? '').toUpperCase().trim();
    if (status != 'ON') continue;

    final start = r.timeStamp!;
    final hasNext = i + 1 < sorted.length && sorted[i + 1].timeStamp != null;
    final end = hasNext ? sorted[i + 1].timeStamp! : now;
    final ongoing = !hasNext;

    final duration = end.difference(start);
    if (duration.inSeconds <= 0) continue;

    segments.add(TimeSegment(start, end, 'MOTOR_ON', duration, isOngoing: ongoing));
  }

  return segments;
}

/// Builds Power ON segments from status-history records.
List<TimeSegment> _buildPowerOnSegments(List<Powerstatus> records) {
  if (records.isEmpty) return [];
  final sorted = List<Powerstatus>.from(records)
    ..sort((a, b) {
      if (a.timeStamp == null) return -1;
      if (b.timeStamp == null) return 1;
      return a.timeStamp!.compareTo(b.timeStamp!);
    });

  final now = DateTime.now();
  final segments = <TimeSegment>[];

  for (int i = 0; i < sorted.length; i++) {
    final r = sorted[i];
    if (r.timeStamp == null) continue;
    final status = (r.status ?? '').toUpperCase().trim();
    if (status != 'ON') continue;

    final start = r.timeStamp!;
    final hasNext = i + 1 < sorted.length && sorted[i + 1].timeStamp != null;
    final end = hasNext ? sorted[i + 1].timeStamp! : now;
    final ongoing = !hasNext;

    final duration = end.difference(start);
    if (duration.inSeconds <= 0) continue;

    segments.add(TimeSegment(start, end, 'POWER_ON', duration, isOngoing: ongoing));
  }

  return segments;
}

/// Clips motor/power ON segments so they end at the moment the device went
/// offline, preventing a running segment from visually spanning an offline gap.
///
/// Scenario: motor ON → device offline (no OFF record arrives) → device back
/// online → motor ON again.  Without clipping the first ON segment would
/// stretch all the way to the next ON record, through the entire offline band.
/// With clipping it stops exactly where the offline period starts.
List<TimeSegment> _clipSegmentsAtOffline(
    List<TimeSegment> segments, List<TimeSegment> offlineSegs) {
  if (offlineSegs.isEmpty) return segments;

  final result = <TimeSegment>[];
  for (final seg in segments) {
    // Find the earliest offline period whose start falls strictly inside
    // this segment (after start, before end).
    DateTime? firstOfflineStart;
    for (final offline in offlineSegs) {
      if (offline.start.isAfter(seg.start) &&
          offline.start.isBefore(seg.end)) {
        if (firstOfflineStart == null ||
            offline.start.isBefore(firstOfflineStart)) {
          firstOfflineStart = offline.start;
        }
      }
    }

    if (firstOfflineStart != null) {
      // Cap the segment at the offline boundary.
      final clippedDuration = firstOfflineStart.difference(seg.start);
      if (clippedDuration.inSeconds > 0) {
        result.add(TimeSegment(
          seg.start,
          firstOfflineStart,
          seg.type,
          clippedDuration,
        ));
      }
      // The part after the offline period is covered by the next ON record.
    } else {
      result.add(seg);
    }
  }
  return result;
}

/// Builds Device Offline segments — shown as dotted grey lines on the graph.
/// Status values treated as offline: 'inactive', 'offline', 'disconnected'.
List<TimeSegment> _buildDeviceOfflineSegments(List<Devicestatus> records) {
  if (records.isEmpty) return [];
  final sorted = List<Devicestatus>.from(records)
    ..sort((a, b) {
      if (a.timeStamp == null) return -1;
      if (b.timeStamp == null) return 1;
      return a.timeStamp!.compareTo(b.timeStamp!);
    });

  final now = DateTime.now();
  const offlineStatuses = {'inactive', 'offline', 'disconnected'};
  final segments = <TimeSegment>[];

  for (int i = 0; i < sorted.length; i++) {
    final r = sorted[i];
    if (r.timeStamp == null) continue;
    final status = (r.status ?? '').toLowerCase().trim();
    if (!offlineStatuses.contains(status)) continue;

    final start = r.timeStamp!;
    final hasNext = i + 1 < sorted.length && sorted[i + 1].timeStamp != null;
    final end = hasNext ? sorted[i + 1].timeStamp! : now;
    final ongoing = !hasNext;

    final duration = end.difference(start);
    if (duration.inSeconds <= 0) continue;

    segments.add(TimeSegment(start, end, 'DEVICE_OFFLINE', duration, isOngoing: ongoing));
  }

  return segments;
}


// ---------------------------------------------------------------------------

extension AnalyticsControllerApi on AnalyticsController {
  // --- Date Handling ---

  void resetDateToToday() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    daterange.value = [normalizedToday, normalizedToday];
  }

  bool isDateRange() {
    if (daterange.isEmpty || daterange.length < 2) return false;
    if (daterange.first == null || daterange.last == null) return false;
    return daterange.first != daterange.last;
  }

  void leftClick() async {
    if (daterange.isNotEmpty &&
        daterange.first != null &&
        daterange.last != null) {
      daterange.value = [
        daterange.first!.subtract(const Duration(days: 1)),
        daterange.last!.subtract(const Duration(days: 1))
      ];
      clearAllData();
      try {
        await fetchRuntime(daterange);
      } catch (e) {
        // ignore
      }
    }
  }

  void rightClick() async {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (daterange.isEmpty || daterange.last == null) return;

    final nextEndDate = daterange.last!.add(const Duration(days: 1));
    final nextEndDateNormalized =
        DateTime(nextEndDate.year, nextEndDate.month, nextEndDate.day);

    if (nextEndDateNormalized.isAfter(today)) {
      return;
    }

    if (daterange.isNotEmpty &&
        daterange.first != null &&
        daterange.last != null) {
      daterange.value = [
        daterange.first!.add(const Duration(days: 1)),
        daterange.last!.add(const Duration(days: 1))
      ];
      clearAllData();
      try {
        await fetchRuntime(daterange);
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> onDateRangeSelected() async {
    clearAllData();
    try {
      await fetchRuntime(daterange);
    } catch (e) {
      // ignore
    }
  }

  Future<void> selectSingleDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    daterange.value = [normalizedDate, normalizedDate];
    clearAllData();

    try {
      await fetchRuntime(daterange);
    } catch (e) {
      // ignore
    }
  }

  // --- API Handling ---

  Future<void> fetchallApis() async {
    clearAllData();
    selectedDate.value = DateTime.now();
    selectedMotorId.value = null;

    try {
      await fetchMotorDetails(enableRetry: true);
    } catch (e) {
      // ignore
    }
  }

  Future<void> onrefresh() async {
    isRefreshing.value = true;
    resetDateToToday();
    voltageTrackball.value?.hide();
    currentTrackball.value?.hide();
    clearAllData();

    try {
      final futures = <Future>[];

      futures.add(fetchMotorDetails());

      if (selectedTabIndex.value == 1) {
        futures.add(fetchRuntime(daterange));
      }

      if (selectedTabIndex.value == 2) {
        final logsController = Get.find<MotorLogsController>();
        futures.add(logsController.refreshCurrentTab());
      }

      await Future.wait(futures);

      if (mqttInitialized) {
        _updateFromMqttData();
      }
    } catch (e) {
      // ignore
    } finally {
      isRefreshing.value = false;
    }
  }

  void clearAllData({bool isHardClear = true}) {
    if (isHardClear) {
      motorRuntimeData.clear();
      chartData.clear();
      motorOffChartData.clear();
      powerChartData.clear();
      powerOffChartData.clear();
      deviceOfflineChartData.clear();
      voltage.clear();
      current.clear();
      motortotalRuntime.value = '';
    }
    sharedPointNotifier.value = null;
    sharedTimeNotifier.value = null;
    valueNotifier.value = null;
  }


  Future<void> fetchRuntime(List<DateTime?> dateRange) async {
    if (dateRange.isEmpty ||
        dateRange.first == null ||
        dateRange.last == null) {
      return;
    }

    if (!isRefreshing.value) {
      isLoadingruntime.value = true;
    }

    try {
      final fromDate = DateFormat('yyyy-MM-dd').format(dateRange.first!);
      final toDate = DateFormat('yyyy-MM-dd').format(dateRange.last!);

      final repo = AnalyticsRepositoryImpl();
      final responses = await Future.wait([
        repo.getMotorStatusHistory(fromDate, toDate),
        repo.getPowerStatusHistory(fromDate, toDate),
        repo.getDeviceStatusHistory(fromDate, toDate),
        repo.getMotorTotalRuntime(fromDate, toDate),
      ]);

      final motorResp = responses[0] as MotorStatusHistoryResponse?;
      final powerResp = responses[1] as PowerStatusHistoryResponse?;
      final deviceResp = responses[2] as DeviceStatusHistoryResponse?;
      final runtimeResp = responses[3] as MotortTotalRuntimeResponse?;

      final motorRecords = motorResp?.data ?? [];
      final powerRecords = powerResp?.data ?? [];
      final deviceRecords = deviceResp?.data ?? [];

      final motorOnSegs = _buildMotorOnSegments(motorRecords);
      final powerOnSegs = _buildPowerOnSegments(powerRecords);
      final deviceOffSegs = _buildDeviceOfflineSegments(deviceRecords);

      // Clip motor/power segments that span into an offline period.
      // If the device went offline while the motor/power was still running
      // (and no OFF record arrived), the segment is capped at the offline
      // start so it does not visually extend through the offline band.
      final clippedMotorSegs = _clipSegmentsAtOffline(motorOnSegs, deviceOffSegs);
      final clippedPowerSegs = _clipSegmentsAtOffline(powerOnSegs, deviceOffSegs);

      chartData.value = clippedMotorSegs;
      powerChartData.value = clippedPowerSegs;
      deviceOfflineChartData.value = deviceOffSegs;
      motorOffChartData.value = [];
      powerOffChartData.value = [];

      // Total motor runtime from API response
      motortotalRuntime.value =
          runtimeResp?.data?.totalOnDurationFormatted ?? '';

      // Total power runtime from clipped ON segments
      Duration totalPower = Duration.zero;
      for (final s in clippedPowerSegs) {
        totalPower += s.duration;
      }
      final ph = totalPower.inHours;
      final pm = totalPower.inMinutes % 60;
      powerTotalRuntime.value =
          clippedPowerSegs.isEmpty ? '' : '$ph h $pm m';
    } catch (e) {
      chartData.clear();
      powerChartData.clear();
      deviceOfflineChartData.clear();
      motortotalRuntime.value = '';
      powerTotalRuntime.value = '';
    } finally {
      isLoadingruntime.value = false;
    }
  }

  Future<void> fetchMotorDetails({bool enableRetry = false}) async {
    if (!isRefreshing.value) {
      isMotorDetailsLoading.value = true;
    }
    try {
      final response = enableRetry
          ? await withRetry(
              call: () => MotorsRepositoryImpl().getMotorDetails(),
              isSuccess: (r) => r != null && r.data != null,
            )
          : await MotorsRepositoryImpl().getMotorDetails();

      if (response != null && response.data != null) {
        motorDetails.value = response.data;
        final data = response.data!;

        motorName.value = (data.aliasName != null && data.aliasName!.isNotEmpty)
            ? data.aliasName!
            : data.name ?? 'Unknown Motor';

        hp.value = data.hp?.toString() ?? 'N/A';
        deviceId.value = data.starter?.starterNumber ?? 'N/A';
        motorState.value = data.state ?? 0;

        final apiMode = data.mode ?? 'AUTO';
        localModeIndex.value = apiMode.toUpperCase().contains('MANUAL') ? 0 : 1;
        motorMode.value = localModeIndex.value == 1 ? 'Auto' : 'Manual';

        locationName.value = data.location?.name?.trim().isNotEmpty == true
            ? data.location!.name!
            : 'No Location';
        signalQuality.value = data.starter?.signalQuality ?? 0;

        final starterParams = data.starter?.starterParameters;
        if (starterParams != null && starterParams.isNotEmpty) {
          faultMessage.value = starterParams.first.faultDescription ?? 'N/A';

          if (starterParams.first.timeStamp != null) {
            DateTime timestamp = starterParams.first.timeStamp!;
            DateTime istTime =
                timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));
            timeStamp.value =
                DateFormat('dd MMM yyyy, hh:mm a').format(istTime);
          } else {
            timeStamp.value = 'N/A';
          }
        } else {
          faultMessage.value = 'N/A';
          timeStamp.value = 'N/A';
        }

        if (kDebugMode) {}
      }
    } catch (e) {
      // ignore
    } finally {
      isMotorDetailsLoading.value = false;
      _updateCanChangeMode();
    }
  }

  // --- Chart Helpers ---

  Duration durationconvert(String str) {
    final regex = RegExp(r'(\d+)\s*h\s*(\d+)\s*m\s*(\d+)\s*sec');
    final match = regex.firstMatch(str);

    if (match != null) {
      int hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      int minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      int seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else {
      return const Duration();
    }
  }

  List<TimeSegment> convertRuntimeToTimeSegments(List<Runtime> runtimes) {
    List<TimeSegment> segments = [];
    final DateTime now = DateTime.now();

    for (int i = 0; i < runtimes.length; i++) {
      var runtime = runtimes[i];

      // Only process  motor state is 1 (ON)
      if (runtime.motorState != 1) continue;
      if (runtime.startTime == null) continue;

      DateTime startTime = runtime.startTime!;
      DateTime endTime;
      Duration duration;

      //  last motor_state == 1 record
      bool isLastMotorOnRecord = true;
      for (int j = i + 1; j < runtimes.length; j++) {
        if (runtimes[j].motorState == 1) {
          isLastMotorOnRecord = false;
          break;
        }
      }

      // Handle end time and duration
      if (runtime.endTime != null) {
        endTime = runtime.endTime!;
        if (runtime.duration != null) {
          duration = durationconvert(runtime.duration!);
        } else {
          duration = endTime.difference(startTime);
        }
      } else {
        if (isLastMotorOnRecord) {
          endTime = now;
          duration = now.difference(startTime);
        } else {
          continue;
        }
      }

      // Only add if duration is positive
      if (duration.inSeconds > 0) {
        segments.add(TimeSegment(
          startTime,
          endTime,
          'ON',
          duration,
        ));
      }
    }

    return segments;
  }

  List<TimeSegment> convertRuntimeToMotorOffSegments(List<Runtime> runtimes) {
    final List<TimeSegment> segments = [];

    for (final runtime in runtimes) {
      if (runtime.motorState != 0) continue;
      if (runtime.startTime == null || runtime.endTime == null) continue;

      final startTime = runtime.startTime!;
      final endTime = runtime.endTime!;
      final duration = endTime.difference(startTime);

      if (duration.inSeconds > 0) {
        segments.add(TimeSegment(startTime, endTime, 'MOTOR_OFF', duration));
      }
    }

    return segments;
  }

  List<TimeSegment> convertRuntimeToPowerSegments(List<Runtime> runtimes) {
    final List<TimeSegment> segments = [];
    final DateTime now = DateTime.now();

    for (int i = 0; i < runtimes.length; i++) {
      final runtime = runtimes[i];

      // Only POWER ON records (power_state == 1)
      if (runtime.powerState != 1) continue;
      if (runtime.powerStart == null) continue;

      final DateTime startTime = runtime.powerStart!;
      DateTime endTime;
      Duration duration;

      // Check  last record in the list
      bool isLastRecord = (i == runtimes.length - 1);

      if (runtime.powerEnd != null && runtime.powerDuration != null) {
        endTime = runtime.powerEnd!;
        duration = durationconvert(runtime.powerDuration!);
      } else if (runtime.powerEnd == null && runtime.powerDuration == null) {
        if (isLastRecord) {
          endTime = now;
          duration = now.difference(startTime);
        } else {
          continue;
        }
      } else {
        continue;
      }

      segments.add(
        TimeSegment(
          startTime,
          endTime,
          'POWER_ON',
          duration,
        ),
      );
    }

    return segments;
  }

  List<TimeSegment> convertRuntimeToPowerOffSegments(List<Runtime> runtimes) {
    final List<TimeSegment> segments = [];

    for (final runtime in runtimes) {
      if (runtime.powerState != 0) continue;
      if (runtime.powerStart == null || runtime.powerEnd == null) continue;

      final startTime = runtime.powerStart!;
      final endTime = runtime.powerEnd!;
      final duration = endTime.difference(startTime);

      if (duration.inSeconds > 0) {
        segments.add(TimeSegment(startTime, endTime, 'POWER_OFF', duration));
      }
    }

    return segments;
  }
}

class TimeSegment {
  final DateTime start;
  final DateTime end;
  final String type;
  final Duration duration;
  /// True when there was no real end in the API response — the segment is
  /// still active (motor still ON, power still ON, device still offline).
  final bool isOngoing;

  TimeSegment(
    this.start,
    this.end,
    this.type,
    this.duration, {
    this.isOngoing = false,
  });

  @override
  String toString() {
    return '\n\n$type (${start.toIso8601String()} → ${end.toIso8601String()}) , $duration';
  }
}
