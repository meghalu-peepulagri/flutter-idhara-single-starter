import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsController extends GetxController {
  var voltage = <Voltage>[].obs;
  var current = <Current>[].obs;
  var isMotorDetailsLoading = false.obs;

  var motorDetails = Rxn<MotorDetails>();
  var isLoadingVoltage = true.obs;
  var isLoadingCurrent = true.obs;
  var isLoadingruntime = false.obs;
  var isLoadingtotalruntime = false.obs;
  var isLoadingLocations = false.obs;
  var daterange = <DateTime?>[DateTime.now(), DateTime.now()].obs;
  var isModalOpen = false.obs;

  var selectedTitle = ''.obs;
  var motorRuntimeData = <Runtime>[].obs;
  var selectedMotorId = Rxn<int?>();
  var selectedStarterId = Rxn<int?>();
  var selectedDate = DateTime.now().obs;
  var isRefreshing = false.obs;
  TextEditingController controller = TextEditingController();
  var chartData = <TimeSegment>[].obs;
  var powerChartData = <TimeSegment>[].obs;
  final sharedPointNotifier = ValueNotifier<dynamic>(null);
  final sharedTimeNotifier = ValueNotifier<DateTime?>(null);
  final ValueNotifier<dynamic> valueNotifier = ValueNotifier(null);
  var voltageTrackball = Rxn<TrackballBehavior>();
  var currentTrackball = Rxn<TrackballBehavior>();
  final ScrollController monthScrollController = ScrollController();
  var motorId = Rxn<int>();
  var motorName = ''.obs;
  var deviceId = ''.obs;
  var motorState = 0.obs;
  var motorMode = ''.obs;
  var locationName = ''.obs;
  RxString faultMessage = ''.obs;
  dynamic motorData;
  final motortotalRuntime = ''.obs;
  final connectivity = Connectivity();
  var hasInternet = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      motorId.value = args['motorId'];
    }

    if (motorId.value != null) {
      fetchMotorDetails();
    }

    // Fetch initial data
    fetchallApis();
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
    connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    hasInternet.value = result != ConnectivityResult.none;
  }

  fetchallApis() async {
    clearAllData();

    selectedDate.value = DateTime.now();
    selectedMotorId.value = null;

    await Future.wait([
      fetchRuntime(daterange),
      fetchavgcurrent(daterange),
      fetchtotalkvar(daterange),
    ]);
  }

  Future<void> onrefresh() async {
    isRefreshing.value = true;
    voltageTrackball.value?.hide();
    currentTrackball.value?.hide();
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
        fetchavgcurrent(daterange),
        fetchtotalkvar(daterange),
      ]);
    } catch (e) {
      isRefreshing.value = false;
    } finally {
      isRefreshing.value = false;
    }
  }

  // clearAllData() {
  //   motorRuntimeData.clear();
  //   chartData.clear();
  //   voltage.clear();
  //   current.clear();
  //   sharedPointNotifier.value = null;
  //   sharedTimeNotifier.value = null;
  //   valueNotifier.value = null;
  // }
  clearAllData({bool isHardClear = true}) {
    if (isHardClear) {
      motorRuntimeData.clear();
      chartData.clear();
      voltage.clear();
      current.clear();
      motortotalRuntime.value = '';
    }

    sharedPointNotifier.value = null;
    sharedTimeNotifier.value = null;
    valueNotifier.value = null;
  }

  // Method to be called when calendar date range is selected
  Future<void> onDateRangeSelected() async {
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
        fetchavgcurrent(daterange),
        fetchtotalkvar(daterange),
      ]);
    } catch (e) {
      // Handle error
      print('Error fetching data: $e');
    }
  }

  // Single date selection from week view
  Future<void> selectSingleDate(DateTime date) async {
    // Normalize date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Set both start and end to same date for single date selection
    daterange.value = [normalizedDate, normalizedDate];
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
        fetchavgcurrent(daterange),
        fetchtotalkvar(daterange),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  // Check if current selection is a date range
  bool isDateRange() {
    if (daterange.first == null || daterange.last == null) return false;
    return daterange.first != daterange.last;
  }

  leftClick() async {
    // Move the date range backward by one day
    if (daterange.first != null && daterange.last != null) {
      daterange.value = [
        daterange.first!.subtract(const Duration(days: 1)),
        daterange.last!.subtract(const Duration(days: 1))
      ];
    }
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
        fetchavgcurrent(daterange),
        fetchtotalkvar(daterange),
      ]);
    } catch (e) {
      // Handle error
    }
  }

  // Right arrow click - move forward (only if not going into future)
  rightClick() async {
    // Normalize today's date to midnight for comparison
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Calculate what the next end date would be
    final nextEndDate = daterange.last!.add(const Duration(days: 1));
    final nextEndDateNormalized =
        DateTime(nextEndDate.year, nextEndDate.month, nextEndDate.day);

    // Check if next date would be after today
    if (nextEndDateNormalized.isAfter(today)) {
      Get.snackbar(
        'Invalid Date',
        'Cannot select future dates',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }

    // Move the date range forward by one day
    if (daterange.first != null && daterange.last != null) {
      daterange.value = [
        daterange.first!.add(const Duration(days: 1)),
        daterange.last!.add(const Duration(days: 1))
      ];
    }
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
        fetchavgcurrent(daterange),
        fetchtotalkvar(daterange),
      ]);
    } catch (e) {
      // Handle error
    }
  }

  Duration durationconvert(String str) {
    final regex = RegExp(r'(\d+)\s*h\s*(\d+)\s*m\s*(\d+)\s*sec');
    final match = regex.firstMatch(str);

    if (match != null) {
      int hours = int.parse(match.group(1)!);
      int minutes = int.parse(match.group(2)!);
      int seconds = int.parse(match.group(3)!);

      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } else {
      return const Duration();
    }
  }

  // Convert Runtime data to TimeSegment for chart display
  List<TimeSegment> convertRuntimeToTimeSegments(List<Runtime> runtimes) {
    List<TimeSegment> segments = [];

    for (var runtime in runtimes) {
      if (runtime.startTime != null && runtime.endTime != null) {
        Duration duration = runtime.endTime!.difference(runtime.startTime!);

        // Determine state based on motorState
        String state = 'OFFLINE';
        if (runtime.motorState == 1) {
          state = 'ON';
        } else if (runtime.motorState == 0) {
          state = 'OFF';
        }

        segments.add(TimeSegment(
          runtime.startTime!,
          runtime.endTime!,
          state,
          duration,
        ));
      }
    }

    return segments;
  }

  List<TimeSegment> convertRuntimeToPowerSegments(List<Runtime> runtimes) {
    List<TimeSegment> segments = [];

    for (var runtime in runtimes) {
      // Only create power segment if powerStart exists
      if (runtime.powerStart != null) {
        DateTime powerStart = runtime.powerStart!;
        DateTime powerEnd;

        // If powerEnd is null, use current time (ongoing power state)
        if (runtime.powerEnd != null) {
          powerEnd = runtime.powerEnd!;
        } else {
          // Power is still ongoing, use current time
          powerEnd = DateTime.now();
        }

        Duration duration = powerEnd.difference(powerStart);

        // Determine state based on powerState
        String state = 'POWER_OFFLINE';
        if (runtime.powerState == 1) {
          state = 'POWER_ON';
        } else if (runtime.powerState == 0) {
          state = 'POWER_OFF';
        }

        segments.add(TimeSegment(
          powerStart,
          powerEnd,
          state,
          duration,
        ));

        print(
            "Created power segment: $state from $powerStart to $powerEnd (${runtime.powerEnd == null ? 'ONGOING' : 'COMPLETED'})");
      }
    }

    return segments;
  }

  Future<void> fetchRuntime(List<DateTime?> dateRange) async {
    if (!isRefreshing.value) {
      isLoadingruntime.value = true;
    }

    try {
      final response = await AnalyticsRepositoryImpl().getMotorRunTime(
          DateFormat('yyyy-MM-dd').format(dateRange.first!),
          DateFormat('yyyy-MM-dd').format(dateRange.last!),
          state: 'on');

      if (response != null && response.data != null) {
        motorRuntimeData.value = response.data!.records ?? [];
        motortotalRuntime.value = response.data!.totalRunOnTime ?? '';
        print("DEBUG: Total records: ${motorRuntimeData.length}");
        for (var record in motorRuntimeData) {
          print(
              "Motor: ${record.startTime} -> ${record.endTime}, State: ${record.motorState}");
          print(
              "Power: ${record.powerStart} -> ${record.powerEnd}, State: ${record.powerState}");
        }
        // Convert Runtime data to TimeSegment for chart
        chartData.value = convertRuntimeToTimeSegments(response.data!.records!);
        powerChartData.value =
            convertRuntimeToPowerSegments(response.data!.records!);

        print("DEBUG: Motor segments: ${chartData.length}");
        print("DEBUG: Power segments: ${powerChartData.length}");
      } else {
        motorRuntimeData.clear();
        chartData.clear();
        powerChartData.clear();
      }
    } catch (e) {
      motorRuntimeData.clear();
      chartData.clear();
      powerChartData.clear();
      print('Error fetching runtime: $e');
    } finally {
      isLoadingruntime.value = false;
    }
  }

  Future<void> fetchtotalkvar(List<DateTime?> dateRange) async {
    if (!isRefreshing.value) {
      isLoadingVoltage.value = true;
    }
    try {
      final response = await AnalyticsRepositoryImpl().getVoltage(
          DateFormat('yyyy-MM-dd').format(dateRange.first!),
          DateFormat('yyyy-MM-dd').format(dateRange.last!));
      if (response != null && response.data != null) {
        voltage.value = response.data!;
        isLoadingVoltage.value = false;
      } else {
        voltage.clear();
      }
    } catch (e) {
      voltage.clear();
      isLoadingVoltage.value = false;
    } finally {
      isLoadingVoltage.value = false;
    }
  }

  Future<void> fetchavgcurrent(List<DateTime?> dateRange) async {
    if (!isRefreshing.value) {
      isLoadingCurrent.value = true;
    }
    try {
      final response = await AnalyticsRepositoryImpl().getCurrent(
          DateFormat('yyyy-MM-dd').format(dateRange.first!),
          DateFormat('yyyy-MM-dd').format(dateRange.last!));
      if (response != null && response.data != null) {
        current.value = response.data!;
        isLoadingCurrent.value = false;
      } else {
        current.clear();
      }
    } catch (e) {
      current.clear();
      isLoadingCurrent.value = false;
    } finally {
      isLoadingCurrent.value = false;
    }
  }

  Future<void> fetchMotorDetails() async {
    try {
      isMotorDetailsLoading.value = true;

      final response = await MotorsRepositoryImpl().getMotorDetails();

      if (response != null && response.data != null) {
        motorDetails.value = response.data;

        motorName.value = (response.data!.aliasName != null &&
                response.data!.aliasName!.isNotEmpty)
            ? response.data!.aliasName!
            : response.data!.name!;
        deviceId.value = response.data!.starter?.macAddress ?? 'N/A';
        motorState.value = response.data!.state ?? 0;
        motorMode.value = response.data!.mode ?? 'N/A';
        locationName.value =
            response.data?.location?.name?.trim().isNotEmpty == true
                ? response.data!.location!.name!
                : 'No Location';
        faultMessage.value =
            response.data!.starter!.starterParameters!.first.faultDescription ??
                'N/A';
      }
      print("line 268 -----------> ${response!.data}");
    } catch (e) {
      debugPrint('Motor details error: $e');
    } finally {
      isMotorDetailsLoading.value = false;
    }
  }

  @override
  void onClose() {
    monthScrollController.dispose();
    super.onClose();
  }
}

class TimeSegment {
  final DateTime start;
  final DateTime end;
  final String type; // "ON", "OFF", or "OFFLINE"
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
