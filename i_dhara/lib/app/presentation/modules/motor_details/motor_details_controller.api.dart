part of 'motor_details_controller.dart';

// ---------------------------------------------------------------------------
// Background isolate helpers (top-level — required by compute())
// ---------------------------------------------------------------------------

class _SegmentInput {
  final List<Runtime> records;
  final DateTime now;
  const _SegmentInput(this.records, this.now);
}

class _SegmentResults {
  final List<TimeSegment> motorOn;
  final List<TimeSegment> motorOff;
  final List<TimeSegment> powerOn;
  final List<TimeSegment> powerOff;
  const _SegmentResults(
      this.motorOn, this.motorOff, this.powerOn, this.powerOff);
}

Duration _parseDuration(String str) {
  final match = RegExp(r'(\d+)\s*h\s*(\d+)\s*m\s*(\d+)\s*sec').firstMatch(str);
  if (match == null) return Duration.zero;
  return Duration(
    hours: int.tryParse(match.group(1) ?? '0') ?? 0,
    minutes: int.tryParse(match.group(2) ?? '0') ?? 0,
    seconds: int.tryParse(match.group(3) ?? '0') ?? 0,
  );
}

/// Single O(n) pass — replaces 4 separate passes and fixes the O(n²) bug in
/// the original [convertRuntimeToTimeSegments] (which scanned forward on every
/// motor-ON record to detect the "last" one).
_SegmentResults _processSegments(_SegmentInput input) {
  final records = input.records;
  final now = input.now;

  // Pre-scan once (O(n)) to find the last motor-ON and last power-ON indices.
  int lastMotorOnIdx = -1;
  for (int i = records.length - 1; i >= 0; i--) {
    if (records[i].motorState == 1) {
      lastMotorOnIdx = i;
      break;
    }
  }

  final motorOn = <TimeSegment>[];
  final motorOff = <TimeSegment>[];
  final powerOn = <TimeSegment>[];
  final powerOff = <TimeSegment>[];

  for (int i = 0; i < records.length; i++) {
    final r = records[i];

    // ── Motor ON ──────────────────────────────────────────────────────────
    if (r.motorState == 1 && r.startTime != null) {
      DateTime? endTime;
      Duration? duration;

      if (r.endTime != null) {
        endTime = r.endTime!;
        duration = r.duration != null
            ? _parseDuration(r.duration!)
            : endTime.difference(r.startTime!);
      } else if (i == lastMotorOnIdx) {
        // Still-running session: extend to now
        endTime = now;
        duration = now.difference(r.startTime!);
      }

      if (endTime != null && duration != null && duration.inSeconds > 0) {
        motorOn.add(TimeSegment(r.startTime!, endTime, 'ON', duration));
      }
    }

    // ── Motor OFF ─────────────────────────────────────────────────────────
    if (r.motorState == 0 && r.startTime != null && r.endTime != null) {
      final duration = r.endTime!.difference(r.startTime!);
      if (duration.inSeconds > 0) {
        motorOff
            .add(TimeSegment(r.startTime!, r.endTime!, 'MOTOR_OFF', duration));
      }
    }

    // ── Power ON ──────────────────────────────────────────────────────────
    if (r.powerState == 1 && r.powerStart != null) {
      DateTime? endTime;
      Duration? duration;

      if (r.powerEnd != null && r.powerDuration != null) {
        endTime = r.powerEnd!;
        duration = _parseDuration(r.powerDuration!);
      } else if (r.powerEnd == null &&
          r.powerDuration == null &&
          i == records.length - 1) {
        // Still-running power session (last record overall)
        endTime = now;
        duration = now.difference(r.powerStart!);
      }

      if (endTime != null && duration != null) {
        powerOn.add(TimeSegment(r.powerStart!, endTime, 'POWER_ON', duration));
      }
    }

    // ── Power OFF ─────────────────────────────────────────────────────────
    if (r.powerState == 0 && r.powerStart != null && r.powerEnd != null) {
      final duration = r.powerEnd!.difference(r.powerStart!);
      if (duration.inSeconds > 0) {
        powerOff.add(
            TimeSegment(r.powerStart!, r.powerEnd!, 'POWER_OFF', duration));
      }
    }
  }

  return _SegmentResults(motorOn, motorOff, powerOn, powerOff);
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
      if (selectedTabIndex.value == AnalyticsController.analyticsTabIndex) {
        await fetchRuntime(daterange);
      }
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

      if (selectedTabIndex.value == AnalyticsController.analyticsTabIndex) {
        futures.add(fetchRuntime(daterange));
      }

      if (selectedTabIndex.value == AnalyticsController.scheduleTabIndex &&
          Get.isRegistered<MotorScheduleController>()) {
        final scheduleController = Get.find<MotorScheduleController>();
        futures.add(scheduleController.fetchSchedules(isRefresh: true));
      }

      if (selectedTabIndex.value == AnalyticsController.logsTabIndex) {
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
      voltage.clear();
      current.clear();
      motortotalRuntime.value = '';
    }
    sharedPointNotifier.value = null;
    sharedTimeNotifier.value = null;
    valueNotifier.value = null;
  }

  /// Downsamples records to at most [maxCount] entries.
  /// Takes the last [maxCount] records so the most recent (including any
  /// currently-running segment) is always preserved.
  List<Runtime> _downsampleRecords(List<Runtime> records,
      {int maxCount = 300}) {
    if (records.length <= maxCount) return records;
    return records.sublist(records.length - maxCount);
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
      final response = await AnalyticsRepositoryImpl().getMotorRunTime(
        DateFormat('yyyy-MM-dd').format(dateRange.first!),
        DateFormat('yyyy-MM-dd').format(dateRange.last!),
      );

      if (response != null && response.data != null) {
        final allRecords = response.data!.records ?? [];
        final records = _downsampleRecords(allRecords);
        motorRuntimeData.value = records;

        // Use the API's total — strip seconds (HH:MM:SS → HH:MM)
        final raw = response.data!.totalRunOnTime ?? '';
        final timeParts = raw.split(':');
        motortotalRuntime.value =
            timeParts.length == 3 ? '${timeParts[0]}:${timeParts[1]}' : raw;

        if (records.isNotEmpty) {
          // Process all segment types in a single O(n) pass on a background
          // isolate — keeps the UI thread free while building chart data.
          final results = await compute(
            _processSegments,
            _SegmentInput(records, DateTime.now()),
          );

          chartData.value = results.motorOn;
          motorOffChartData.value = results.motorOff;
          powerChartData.value = results.powerOn;
          powerOffChartData.value = results.powerOff;

          // Calculate power total runtime from isolate results
          Duration totalPowerDuration = Duration.zero;
          for (final segment in results.powerOn) {
            totalPowerDuration += segment.duration;
          }
          final int hours = totalPowerDuration.inHours;
          final int minutes = totalPowerDuration.inMinutes % 60;
          powerTotalRuntime.value = '$hours h $minutes m';
        }
      } else {
        motorRuntimeData.clear();
        chartData.clear();
        powerChartData.clear();
        motortotalRuntime.value = '';
        powerTotalRuntime.value = '';
      }
    } catch (e) {
      motorRuntimeData.clear();
      chartData.clear();
      powerChartData.clear();
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

  TimeSegment(
    this.start,
    this.end,
    this.type,
    this.duration,
  );

  @override
  String toString() {
    return '\n\n$type (${start.toIso8601String()} → ${end.toIso8601String()}) , $duration';
  }
}
