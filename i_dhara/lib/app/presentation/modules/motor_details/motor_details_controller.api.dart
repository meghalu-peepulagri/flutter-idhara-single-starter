part of 'motor_details_controller.dart';

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
        if (kDebugMode) print('Error in leftClick: $e');
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
        if (kDebugMode) print('Error in rightClick: $e');
      }
    }
  }

  Future<void> onDateRangeSelected() async {
    clearAllData();
    try {
      await fetchRuntime(daterange);
    } catch (e) {
      if (kDebugMode) print('Error fetching data: $e');
    }
  }

  Future<void> selectSingleDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    daterange.value = [normalizedDate, normalizedDate];
    clearAllData();

    try {
      await fetchRuntime(daterange);
    } catch (e) {
      if (kDebugMode) print('Error fetching data: $e');
    }
  }

  // --- API Handling ---

  Future<void> fetchallApis() async {
    clearAllData();
    selectedDate.value = DateTime.now();
    selectedMotorId.value = null;

    try {
      await fetchRuntime(daterange);
    } catch (e) {
      if (kDebugMode) print('Error in fetchallApis: $e');
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
      if (kDebugMode) print('Error onRefresh: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  void clearAllData({bool isHardClear = true}) {
    if (isHardClear) {
      motorRuntimeData.clear();
      chartData.clear();
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

  Future<void> fetchRuntime(List<DateTime?> dateRange) async {
    if (dateRange.isEmpty ||
        dateRange.first == null ||
        dateRange.last == null) {
      if (kDebugMode) print('Invalid date range for runtime fetch');
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
        motorRuntimeData.value = response.data!.records ?? [];

        // Use the API's total or calculate from filtered data
        motortotalRuntime.value = response.data!.totalRunOnTime ?? '';

        if (response.data!.records != null) {
          chartData.value =
              convertRuntimeToTimeSegments(response.data!.records!);
          powerChartData.value =
              convertRuntimeToPowerSegments(response.data!.records!);
          powerOffChartData.value =
              convertRuntimeToPowerOffSegments(response.data!.records!);

          // Calculate power total runtime
          Duration totalPowerDuration = Duration.zero;
          for (var segment in powerChartData) {
            totalPowerDuration += segment.duration;
          }

          // Format power total runtime
          int hours = totalPowerDuration.inHours;
          int minutes = (totalPowerDuration.inMinutes % 60);
          int seconds = (totalPowerDuration.inSeconds % 60);
          powerTotalRuntime.value = '$hours h $minutes m $seconds sec';
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
      if (kDebugMode) print('Error fetching runtime: $e');
    } finally {
      isLoadingruntime.value = false;
    }
  }

  Future<void> fetchMotorDetails() async {
    if (!isRefreshing.value) {
      isMotorDetailsLoading.value = true;
    }
    try {
      final response = await MotorsRepositoryImpl().getMotorDetails();

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

        if (kDebugMode) {
          print('=== Motor Details Loaded ===');
          print('Motor Name: ${motorName.value}');
          print('MAC: ${data.starter?.macAddress ?? "NULL"}');
          print('PCB: ${data.starter?.pcbNumber ?? "NULL"}');
          print('Mode: ${motorMode.value}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Motor details error: $e');
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
