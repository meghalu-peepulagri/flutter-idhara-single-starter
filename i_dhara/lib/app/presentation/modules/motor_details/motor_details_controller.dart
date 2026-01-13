// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/graphs/current_model.dart';
// import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
// import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
// import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
// import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
// import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class AnalyticsController extends GetxController {
//   var voltage = <Voltage>[].obs;
//   var current = <Current>[].obs;
//   var isMotorDetailsLoading = false.obs;
//   var isLoadingPowerRuntime = false.obs;
//   final powerTotalRuntime = ''.obs;

//   var motorDetails = Rxn<MotorDetails>();
//   var isLoadingVoltage = true.obs;
//   var isLoadingCurrent = true.obs;
//   var isLoadingruntime = false.obs;
//   var isLoadingtotalruntime = false.obs;
//   var isLoadingLocations = false.obs;
//   var daterange = <DateTime?>[DateTime.now(), DateTime.now()].obs;
//   var isModalOpen = false.obs;

//   var selectedTitle = ''.obs;
//   var motorRuntimeData = <Runtime>[].obs;
//   var selectedMotorId = Rxn<int?>();
//   var selectedStarterId = Rxn<int?>();
//   var selectedDate = DateTime.now().obs;
//   var isRefreshing = false.obs;
//   TextEditingController controller = TextEditingController();
//   var chartData = <TimeSegment>[].obs;
//   var powerChartData = <TimeSegment>[].obs;
//   final sharedPointNotifier = ValueNotifier<dynamic>(null);
//   final sharedTimeNotifier = ValueNotifier<DateTime?>(null);
//   final ValueNotifier<dynamic> valueNotifier = ValueNotifier(null);
//   var voltageTrackball = Rxn<TrackballBehavior>();
//   var currentTrackball = Rxn<TrackballBehavior>();
//   final ScrollController monthScrollController = ScrollController();
//   var motorId = Rxn<int>();
//   var motorName = ''.obs;
//   var deviceId = ''.obs;
//   var motorState = 0.obs;
//   var motorMode = ''.obs;
//   var locationName = ''.obs;
//   var hp = ''.obs;
//   var timeStamp = ''.obs;
//   RxString faultMessage = ''.obs;
//   dynamic motorData;
//   final motortotalRuntime = ''.obs;
//   final connectivity = Connectivity();
//   var hasInternet = true.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _initConnectivity();
//     final args = Get.arguments as Map<String, dynamic>?;
//     if (args != null) {
//       motorId.value = args['motorId'];
//     }

//     if (motorId.value != null) {
//       fetchMotorDetails();
//     }
//     resetDateToToday();
//     fetchallApis();
//   }

//   void _initConnectivity() async {
//     final connectivityResult = await connectivity.checkConnectivity();
//     _updateConnectionStatus(connectivityResult.first);
//     connectivity.onConnectivityChanged.listen((results) {
//       _updateConnectionStatus(results.first);
//     });
//   }

//   void _updateConnectionStatus(ConnectivityResult result) {
//     hasInternet.value = result != ConnectivityResult.none;
//   }

//   void resetDateToToday() {
//     final today = DateTime.now();
//     final normalizedToday = DateTime(today.year, today.month, today.day);

//     daterange.value = [normalizedToday, normalizedToday];
//   }

//   fetchallApis() async {
//     clearAllData();

//     selectedDate.value = DateTime.now();
//     selectedMotorId.value = null;

//     await Future.wait([
//       fetchRuntime(daterange),
//     ]);
//   }

//   Future<void> onrefresh() async {
//     isRefreshing.value = true;
//     resetDateToToday();
//     voltageTrackball.value?.hide();
//     currentTrackball.value?.hide();
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchMotorDetails(),
//         fetchRuntime(daterange),
//       ]);
//     } catch (e) {
//       isRefreshing.value = false;
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   clearAllData({bool isHardClear = true}) {
//     if (isHardClear) {
//       motorRuntimeData.clear();
//       chartData.clear();
//       voltage.clear();
//       current.clear();
//       motortotalRuntime.value = '';
//     }

//     sharedPointNotifier.value = null;
//     sharedTimeNotifier.value = null;
//     valueNotifier.value = null;
//   }

//   // Method to be called when calendar date range is selected
//   Future<void> onDateRangeSelected() async {
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchRuntime(daterange),
//       ]);
//     } catch (e) {
//       print('Error fetching data: $e');
//     }
//   }

//   Future<void> selectSingleDate(DateTime date) async {
//     final normalizedDate = DateTime(date.year, date.month, date.day);

//     // Set both start and end to same date for single date selection
//     daterange.value = [normalizedDate, normalizedDate];
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchRuntime(daterange),
//       ]);
//     } catch (e) {
//       print('Error fetching data: $e');
//     }
//   }

//   bool isDateRange() {
//     if (daterange.first == null || daterange.last == null) return false;
//     return daterange.first != daterange.last;
//   }

//   leftClick() async {
//     if (daterange.first != null && daterange.last != null) {
//       daterange.value = [
//         daterange.first!.subtract(const Duration(days: 1)),
//         daterange.last!.subtract(const Duration(days: 1))
//       ];
//     }
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchRuntime(daterange),
//       ]);
//     } catch (e) {}
//   }

//   rightClick() async {
//     final today =
//         DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

//     final nextEndDate = daterange.last!.add(const Duration(days: 1));
//     final nextEndDateNormalized =
//         DateTime(nextEndDate.year, nextEndDate.month, nextEndDate.day);

//     if (nextEndDateNormalized.isAfter(today)) {
//       return;
//     }

//     if (daterange.first != null && daterange.last != null) {
//       daterange.value = [
//         daterange.first!.add(const Duration(days: 1)),
//         daterange.last!.add(const Duration(days: 1))
//       ];
//     }
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchRuntime(daterange),
//       ]);
//     } catch (e) {}
//   }

//   Duration durationconvert(String str) {
//     final regex = RegExp(r'(\d+)\s*h\s*(\d+)\s*m\s*(\d+)\s*sec');
//     final match = regex.firstMatch(str);

//     if (match != null) {
//       int hours = int.parse(match.group(1)!);
//       int minutes = int.parse(match.group(2)!);
//       int seconds = int.parse(match.group(3)!);

//       return Duration(hours: hours, minutes: minutes, seconds: seconds);
//     } else {
//       return const Duration();
//     }
//   }

//   List<TimeSegment> convertRuntimeToTimeSegments(List<Runtime> runtimes) {
//     List<TimeSegment> segments = [];

//     for (var runtime in runtimes) {
//       if (runtime.startTime != null && runtime.endTime != null) {
//         Duration duration = runtime.endTime!.difference(runtime.startTime!);

//         String state = 'OFFLINE';
//         if (runtime.motorState == 1) {
//           state = 'ON';
//         } else if (runtime.motorState == 0) {
//           state = 'OFF';
//         }

//         segments.add(TimeSegment(
//           runtime.startTime!,
//           runtime.endTime!,
//           state,
//           duration,
//         ));
//       }
//     }

//     return segments;
//   }

//   List<TimeSegment> convertRuntimeToPowerSegments(List<Runtime> runtimes) {
//     final List<TimeSegment> segments = [];

//     DateTime? lastPowerTime;
//     int? lastPowerState;

//     runtimes.sort((a, b) =>
//         (a.timeStamp ?? DateTime(0)).compareTo(b.timeStamp ?? DateTime(0)));

//     for (final runtime in runtimes) {
//       if (runtime.powerState == null) continue;

//       DateTime? startTime = runtime.powerStart ?? lastPowerTime;
//       if (startTime == null) continue;

//       DateTime endTime = runtime.powerEnd ??
//           (runtime.powerState == lastPowerState ? DateTime.now() : startTime);

//       String state = runtime.powerState == 1
//           ? 'POWER_ON'
//           : runtime.powerState == 0
//               ? 'POWER_OFF'
//               : 'POWER_OFFLINE';

//       Duration duration;
//       if (runtime.powerDuration != null) {
//         duration = durationconvert(runtime.powerDuration!);
//       } else {
//         duration = endTime.difference(startTime);
//       }

//       if (duration.inSeconds > 0) {
//         segments.add(
//           TimeSegment(
//             startTime,
//             endTime,
//             state,
//             duration,
//           ),
//         );
//       }

//       lastPowerTime = endTime;
//       lastPowerState = runtime.powerState;
//     }

//     return segments;
//   }

//   Future<void> fetchRuntime(List<DateTime?> dateRange) async {
//     if (!isRefreshing.value) {
//       isLoadingruntime.value = true;
//     }

//     try {
//       final response = await AnalyticsRepositoryImpl().getMotorRunTime(
//           DateFormat('yyyy-MM-dd').format(dateRange.first!),
//           DateFormat('yyyy-MM-dd').format(dateRange.last!),
//           state: 'on');

//       if (response != null && response.data != null) {
//         motorRuntimeData.value = response.data!.records ?? [];
//         motortotalRuntime.value = response.data!.totalRunOnTime ?? '';
//         for (var record in motorRuntimeData) {
//           print(
//               "Motor: ${record.startTime} -> ${record.endTime}, State: ${record.motorState}");
//           print(
//               "Power: ${record.powerStart} -> ${record.powerEnd}, State: ${record.powerState}");
//         }
//         chartData.value = convertRuntimeToTimeSegments(response.data!.records!);
//         powerChartData.value =
//             convertRuntimeToPowerSegments(response.data!.records!);
//       } else {
//         motorRuntimeData.clear();
//         chartData.clear();
//         powerChartData.clear();
//       }
//     } catch (e) {
//       motorRuntimeData.clear();
//       chartData.clear();
//       powerChartData.clear();
//       print('Error fetching runtime: $e');
//     } finally {
//       isLoadingruntime.value = false;
//     }
//   }

//   Future<void> fetchMotorDetails() async {
//     if (!isRefreshing.value) {
//       isMotorDetailsLoading.value = true;
//     }
//     try {
//       // isMotorDetailsLoading.value = true;

//       final response = await MotorsRepositoryImpl().getMotorDetails();

//       if (response != null && response.data != null) {
//         motorDetails.value = response.data;

//         motorName.value = (response.data!.aliasName != null &&
//                 response.data!.aliasName!.isNotEmpty)
//             ? response.data!.aliasName!
//             : response.data!.name!;
//         hp.value = response.data!.hp.toString();
//         deviceId.value = response.data!.starter?.starterNumber ?? 'N/A';
//         motorState.value = response.data!.state ?? 0;
//         motorMode.value = response.data!.mode ?? 'N/A';
//         locationName.value =
//             response.data?.location?.name?.trim().isNotEmpty == true
//                 ? response.data!.location!.name!
//                 : 'No Location';
//         faultMessage.value =
//             response.data!.starter!.starterParameters!.first.faultDescription ??
//                 'N/A';
//         if (response.data!.starter?.starterParameters?.first.timeStamp !=
//             null) {
//           DateTime timestamp =
//               response.data!.starter!.starterParameters!.first.timeStamp!;

//           DateTime istTime =
//               timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));

//           timeStamp.value = DateFormat('dd MMM yyyy, hh:mm a').format(istTime);
//         } else {
//           timeStamp.value = 'N/A';
//         }
//       }
//     } catch (e) {
//       print('Motor details error: $e');
//     } finally {
//       isMotorDetailsLoading.value = false;
//     }
//   }

//   @override
//   void onClose() {
//     monthScrollController.dispose();
//     super.onClose();
//   }
// }

// class TimeSegment {
//   final DateTime start;
//   final DateTime end;
//   final String type; // "ON", "OFF"
//   final Duration duration;

//   TimeSegment(
//     this.start,
//     this.end,
//     this.type,
//     this.duration,
//   );

//   @override
//   String toString() {
//     return '\n\n$type (${start.toIso8601String()} → ${end.toIso8601String()}) , $duration';
//   }
// }

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsController extends GetxController {
  var voltage = <Voltage>[].obs;
  var current = <Current>[].obs;
  var isMotorDetailsLoading = false.obs;
  var isLoadingPowerRuntime = false.obs;
  final powerTotalRuntime = ''.obs;

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
  var motorMode = 'Auto'.obs; // Changed to default 'Auto'
  var locationName = ''.obs;
  var hp = ''.obs;
  var timeStamp = ''.obs;
  RxString faultMessage = ''.obs;
  dynamic motorData;
  final motortotalRuntime = ''.obs;
  final connectivity = Connectivity();
  var hasInternet = true.obs;

  // MQTT related properties
  late MqttService mqttService;
  bool mqttInitialized = false;
  var localModeIndex = 1.obs; // 0 = Manual, 1 = Auto
  bool _hasPendingModeCommand = false;
  int? _pendingModeValue;
  Timer? _modeAckTimer;
  static const Duration _ackTimeout = Duration(seconds: 13);
  var isWaitingForModeAck = false.obs;

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
      _initializeMqtt();
    }
    resetDateToToday();
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

  // Initialize MQTT for this specific motor
  Future<void> _initializeMqtt() async {
    if (motorDetails.value?.starter == null) {
      await fetchMotorDetails();
    }

    if (motorDetails.value?.starter != null) {
      final mac = motorDetails.value!.starter!.macAddress;
      final pcb = motorDetails.value!.starter!.pcbNumber;

      if ((mac != null && mac.isNotEmpty) || (pcb != null && pcb.isNotEmpty)) {
        // Convert MotorDetails to Motor for the map
        final motor = _convertMotorDetailsToMotor(motorDetails.value!);
        final motorMap = <String, Motor>{};

        for (int i = 1; i <= 4; i++) {
          final groupId = 'G0$i';
          if (mac != null && mac.isNotEmpty) {
            motorMap['$mac-$groupId'] = motor;
          }
          if (pcb != null && pcb.isNotEmpty) {
            motorMap['$pcb-$groupId'] = motor;
          }
        }

        mqttService = MqttService(initialMotors: motorMap);
        await mqttService.initializeMqttClient();
        mqttInitialized = true;

        // Listen for MQTT updates
        mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

        // Wait for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 1500));

        // Initial update
        _updateFromMqttData();
      }
    }
  }

  // Convert MotorDetails to Motor
  Motor _convertMotorDetailsToMotor(MotorDetails details) {
    return Motor(
      id: details.id,
      name: details.name,
      aliasName: details.aliasName,
      hp: details.hp,
      state: details.state,
      mode: details.mode,
    );
  }

  void _onMqttUpdate() {
    _updateFromMqttData();
  }

  void _updateFromMqttData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) return;

    final motorData = _getMotorData();

    if (motorData != null && motorData.hasReceivedData) {
      // Update mode if no pending command
      if (_hasPendingModeCommand) {
        final mqttMode = motorData.modeIndex;
        if (mqttMode == _pendingModeValue) {
          _modeAckTimer?.cancel();
          _hasPendingModeCommand = false;
          _pendingModeValue = null;
          isWaitingForModeAck.value = false;
        }
      } else {
        final mqttMode = motorData.modeIndex;
        if (mqttMode != null && localModeIndex.value != mqttMode) {
          localModeIndex.value = mqttMode;
          motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';
        }
      }

      // Update other motor details
      motorState.value = motorData.state;

      if (motorData.fault != 0) {
        // Update fault if needed
      }
    }
  }

  MotorData? _getMotorData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) return null;

    final mac = motorDetails.value!.starter!.macAddress;
    final pcb = motorDetails.value!.starter!.pcbNumber;

    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';

      if (mac != null && mac.isNotEmpty) {
        final key = '$mac-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          return data;
        }
      }

      if (pcb != null && pcb.isNotEmpty) {
        final key = '$pcb-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          return data;
        }
      }
    }

    return null;
  }

  String _getMotorId() {
    if (motorDetails.value?.starter == null) return '';

    final motorData = _getMotorData();

    if (motorData != null && motorData.groupId != null) {
      if (motorData.macAddress != null && motorData.macAddress!.isNotEmpty) {
        return '${motorData.macAddress}-${motorData.groupId}';
      } else if (motorData.pcbNumber != null &&
          motorData.pcbNumber!.isNotEmpty) {
        return '${motorData.pcbNumber}-${motorData.groupId}';
      }
    }

    final mac = motorDetails.value!.starter!.macAddress;
    final pcb = motorDetails.value!.starter!.pcbNumber;

    if (mac != null && mac.isNotEmpty) {
      return '$mac-G01';
    } else if (pcb != null && pcb.isNotEmpty) {
      return '$pcb-G01';
    }

    return '';
  }

  void _startModeAckTimer(int previousValue) {
    _modeAckTimer?.cancel();
    _modeAckTimer = Timer(_ackTimeout, () {
      if (_hasPendingModeCommand) {
        print('Mode ACK timeout - reverting to previous mode: $previousValue');
        localModeIndex.value = previousValue;
        motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        isWaitingForModeAck.value = false;
      }
    });
  }

  Future<void> handleModeChange(int newModeIndex) async {
    if (!mqttInitialized || isWaitingForModeAck.value) return;

    final motorId = _getMotorId();
    if (motorId.isEmpty) {
      print('Cannot change mode: Invalid motor ID');
      return;
    }

    final previousValue = localModeIndex.value;

    isWaitingForModeAck.value = true;
    localModeIndex.value = newModeIndex;
    motorMode.value = newModeIndex == 1 ? 'Auto' : 'Manual';
    _hasPendingModeCommand = true;
    _pendingModeValue = newModeIndex;

    _startModeAckTimer(previousValue);

    try {
      await mqttService.publishModeCommand(motorId, newModeIndex);
    } catch (e) {
      _modeAckTimer?.cancel();
      localModeIndex.value = previousValue;
      motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      isWaitingForModeAck.value = false;
      print('Error changing mode: $e');
    }
  }

  void resetDateToToday() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    daterange.value = [normalizedToday, normalizedToday];
  }

  fetchallApis() async {
    clearAllData();

    selectedDate.value = DateTime.now();
    selectedMotorId.value = null;

    await Future.wait([
      fetchRuntime(daterange),
    ]);
  }

  Future<void> onrefresh() async {
    isRefreshing.value = true;
    resetDateToToday();
    voltageTrackball.value?.hide();
    currentTrackball.value?.hide();
    clearAllData();

    try {
      await Future.wait([
        fetchMotorDetails(),
        fetchRuntime(daterange),
      ]);

      // Update from MQTT after refresh
      if (mqttInitialized) {
        _updateFromMqttData();
      }
    } catch (e) {
      isRefreshing.value = false;
    } finally {
      isRefreshing.value = false;
    }
  }

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

  Future<void> onDateRangeSelected() async {
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> selectSingleDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    daterange.value = [normalizedDate, normalizedDate];
    clearAllData();

    try {
      await Future.wait([
        fetchRuntime(daterange),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  bool isDateRange() {
    if (daterange.first == null || daterange.last == null) return false;
    return daterange.first != daterange.last;
  }

  leftClick() async {
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
      ]);
    } catch (e) {}
  }

  rightClick() async {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final nextEndDate = daterange.last!.add(const Duration(days: 1));
    final nextEndDateNormalized =
        DateTime(nextEndDate.year, nextEndDate.month, nextEndDate.day);

    if (nextEndDateNormalized.isAfter(today)) {
      return;
    }

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
      ]);
    } catch (e) {}
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

  List<TimeSegment> convertRuntimeToTimeSegments(List<Runtime> runtimes) {
    List<TimeSegment> segments = [];

    for (var runtime in runtimes) {
      if (runtime.startTime != null && runtime.endTime != null) {
        Duration duration = runtime.endTime!.difference(runtime.startTime!);

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
    final List<TimeSegment> segments = [];

    DateTime? lastPowerTime;
    int? lastPowerState;

    runtimes.sort((a, b) =>
        (a.timeStamp ?? DateTime(0)).compareTo(b.timeStamp ?? DateTime(0)));

    for (final runtime in runtimes) {
      if (runtime.powerState == null) continue;

      DateTime? startTime = runtime.powerStart ?? lastPowerTime;
      if (startTime == null) continue;

      DateTime endTime = runtime.powerEnd ??
          (runtime.powerState == lastPowerState ? DateTime.now() : startTime);

      String state = runtime.powerState == 1
          ? 'POWER_ON'
          : runtime.powerState == 0
              ? 'POWER_OFF'
              : 'POWER_OFFLINE';

      Duration duration;
      if (runtime.powerDuration != null) {
        duration = durationconvert(runtime.powerDuration!);
      } else {
        duration = endTime.difference(startTime);
      }

      if (duration.inSeconds > 0) {
        segments.add(
          TimeSegment(
            startTime,
            endTime,
            state,
            duration,
          ),
        );
      }

      lastPowerTime = endTime;
      lastPowerState = runtime.powerState;
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
        chartData.value = convertRuntimeToTimeSegments(response.data!.records!);
        powerChartData.value =
            convertRuntimeToPowerSegments(response.data!.records!);
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

  Future<void> fetchMotorDetails() async {
    if (!isRefreshing.value) {
      isMotorDetailsLoading.value = true;
    }
    try {
      final response = await MotorsRepositoryImpl().getMotorDetails();

      if (response != null && response.data != null) {
        motorDetails.value = response.data;

        motorName.value = (response.data!.aliasName != null &&
                response.data!.aliasName!.isNotEmpty)
            ? response.data!.aliasName!
            : response.data!.name!;
        hp.value = response.data!.hp.toString();
        deviceId.value = response.data!.starter?.starterNumber ?? 'N/A';
        motorState.value = response.data!.state ?? 0;

        // Set initial mode
        final apiMode = response.data!.mode ?? 'AUTO';
        localModeIndex.value = apiMode.toUpperCase().contains('MANUAL') ? 0 : 1;
        motorMode.value = localModeIndex.value == 1 ? 'Auto' : 'Manual';

        locationName.value =
            response.data?.location?.name?.trim().isNotEmpty == true
                ? response.data!.location!.name!
                : 'No Location';
        faultMessage.value =
            response.data!.starter!.starterParameters!.first.faultDescription ??
                'N/A';
        if (response.data!.starter?.starterParameters?.first.timeStamp !=
            null) {
          DateTime timestamp =
              response.data!.starter!.starterParameters!.first.timeStamp!;

          DateTime istTime =
              timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));

          timeStamp.value = DateFormat('dd MMM yyyy, hh:mm a').format(istTime);
        } else {
          timeStamp.value = 'N/A';
        }
      }
    } catch (e) {
      print('Motor details error: $e');
    } finally {
      isMotorDetailsLoading.value = false;
    }
  }

  @override
  void onClose() {
    _modeAckTimer?.cancel();
    if (mqttInitialized) {
      mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
      mqttService.dispose();
    }
    monthScrollController.dispose();
    super.dispose();
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
