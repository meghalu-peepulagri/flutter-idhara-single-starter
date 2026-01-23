// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/dashboard/motor_model.dart';
// import 'package:i_dhara/app/data/models/graphs/current_model.dart';
// import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
// import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
// import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
// import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
// import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
// import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class AnalyticsController extends GetxController {
//   // --- Data Variables ---
//   var motorDetails = Rxn<MotorDetails>();
//   var daterange = <DateTime?>[DateTime.now(), DateTime.now()].obs;

//   // Graphs Data
//   var voltage = <Voltage>[].obs;
//   var current = <Current>[].obs;
//   var motorRuntimeData = <Runtime>[].obs;
//   var chartData = <TimeSegment>[].obs;
//   var powerChartData = <TimeSegment>[].obs;

//   // --- UI State Variables ---
//   var isMotorDetailsLoading = false.obs;
//   var isLoadingPowerRuntime = false.obs;
//   var isLoadingVoltage = true.obs;
//   var isLoadingCurrent = true.obs;
//   var isLoadingruntime = false.obs;
//   var isLoadingtotalruntime = false.obs;
//   var isRefreshing = false.obs;
//   var isModalOpen = false.obs;
//   var selectedTabIndex = 0.obs;
//   var hasInternet = true.obs;

//   // --- Display Values ---
//   var motorName = ''.obs;
//   var deviceId = ''.obs;
//   var motorState = 0.obs;
//   var motorMode = 'Auto'.obs;
//   var locationName = ''.obs;
//   var hp = ''.obs;
//   var timeStamp = ''.obs;
//   var faultMessage = ''.obs;
//   var motortotalRuntime = ''.obs;
//   var powerTotalRuntime = ''.obs;

//   // --- Helpers / Controllers ---
//   TextEditingController controller =
//       TextEditingController(); // Unused? Kept for safety
//   final sharedPointNotifier = ValueNotifier<dynamic>(null);
//   final sharedTimeNotifier = ValueNotifier<DateTime?>(null);
//   final ValueNotifier<dynamic> valueNotifier = ValueNotifier(null);
//   var voltageTrackball = Rxn<TrackballBehavior>();
//   var currentTrackball = Rxn<TrackballBehavior>();
//   final ScrollController monthScrollController = ScrollController();
//   final connectivity = Connectivity();

//   // --- Internal Logic Variables ---
//   var selectedMotorId = Rxn<int?>();
//   var selectedDate = DateTime.now().obs;
//   var motorId = Rxn<int>();

//   // --- MQTT Protocol Variables ---
//   late MqttService mqttService;
//   bool mqttInitialized = false;
//   var localModeIndex = 1.obs; // 0 = Manual, 1 = Auto
//   bool _hasPendingModeCommand = false;
//   int? _pendingModeValue;
//   Timer? _modeAckTimer;
//   static const Duration _ackTimeout = Duration(seconds: 13);
//   var isWaitingForModeAck = false.obs;

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
//       _initializeMqtt();
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

//   void onTabChanged(int newIndex) {
//     final previousIndex = selectedTabIndex.value;

//     // If leaving Analytics tab (index = 1)
//     if (previousIndex == 1 && newIndex != 1) {
//       _clearAnalyticsData();
//     }

//     // If entering Analytics tab again
//     if (newIndex == 1 && previousIndex != 1) {
//       resetDateToToday();
//       clearAllData();
//       fetchRuntime(daterange);
//     }

//     selectedTabIndex.value = newIndex;
//   }

//   void _clearAnalyticsData() {
//     motorRuntimeData.clear();
//     chartData.clear();
//     powerChartData.clear();
//     voltage.clear();
//     current.clear();
//     motortotalRuntime.value = '';
//   }

//   // --- MQTT Logic ---

//   Future<void> _initializeMqtt() async {
//     if (motorDetails.value?.starter == null) {
//       await fetchMotorDetails();
//     }

//     if (motorDetails.value?.starter != null) {
//       final starter = motorDetails.value!.starter!;
//       final mac = starter.macAddress;
//       final pcb = starter.pcbNumber;

//       if ((mac != null && mac.isNotEmpty) || (pcb != null && pcb.isNotEmpty)) {
//         final motor = _convertMotorDetailsToMotor(motorDetails.value!);
//         final motorMap = <String, Motor>{};

//         for (int i = 1; i <= 4; i++) {
//           final groupId = 'G0$i';
//           if (mac != null && mac.isNotEmpty) {
//             motorMap['$mac-$groupId'] = motor;
//           }
//           if (pcb != null && pcb.isNotEmpty) {
//             motorMap['$pcb-$groupId'] = motor;
//           }
//         }

//         mqttService = MqttService(initialMotors: motorMap);
//         await mqttService.initializeMqttClient();
//         mqttInitialized = true;

//         mqttService.dataUpdateNotifier.addListener(_onMqttUpdate);

//         // Wait for connection to stabilize
//         await Future.delayed(const Duration(milliseconds: 1500));
//         _updateFromMqttData();
//       }
//     }
//   }

//   Motor _convertMotorDetailsToMotor(MotorDetails details) {
//     return Motor(
//       id: details.id,
//       name: details.name,
//       aliasName: details.aliasName,
//       hp: details.hp,
//       state: details.state,
//       mode: details.mode,
//     );
//   }

//   void _onMqttUpdate() {
//     _updateFromMqttData();
//   }

//   void _updateFromMqttData() {
//     if (!mqttInitialized || motorDetails.value?.starter == null) return;

//     final motorData = _getMotorData();

//     if (motorData != null && motorData.hasReceivedData) {
//       // Update mode if no pending command
//       if (_hasPendingModeCommand) {
//         final mqttMode = motorData.modeIndex;
//         if (mqttMode == _pendingModeValue) {
//           _modeAckTimer?.cancel();
//           _hasPendingModeCommand = false;
//           _pendingModeValue = null;
//           isWaitingForModeAck.value = false;
//         }
//       } else {
//         final mqttMode = motorData.modeIndex;
//         if (mqttMode != null && localModeIndex.value != mqttMode) {
//           localModeIndex.value = mqttMode;
//           motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';
//         }
//       }

//       // Update other motor details
//       motorState.value = motorData.state;

//       // Update fault if needed (logic can be expanded here)
//     }
//   }

//   MotorData? _getMotorData() {
//     if (!mqttInitialized || motorDetails.value?.starter == null) return null;

//     final mac = motorDetails.value!.starter!.macAddress;
//     final pcb = motorDetails.value!.starter!.pcbNumber;

//     // Check all possible groups to find active data
//     for (int i = 1; i <= 4; i++) {
//       final groupId = 'G0$i';

//       if (mac != null && mac.isNotEmpty) {
//         final key = '$mac-$groupId';
//         final data = mqttService.motorDataMap[key];
//         if (data?.hasReceivedData == true) return data;
//       }

//       if (pcb != null && pcb.isNotEmpty) {
//         final key = '$pcb-$groupId';
//         final data = mqttService.motorDataMap[key];
//         if (data?.hasReceivedData == true) return data;
//       }
//     }
//     return null;
//   }

//   String _getMotorId() {
//     if (motorDetails.value?.starter == null) return '';

//     // Try to get ID from active data first
//     final motorData = _getMotorData();

//     if (motorData != null && motorData.groupId != null) {
//       if (motorData.macAddress != null && motorData.macAddress!.isNotEmpty) {
//         return '${motorData.macAddress}-${motorData.groupId}';
//       } else if (motorData.pcbNumber != null &&
//           motorData.pcbNumber!.isNotEmpty) {
//         return '${motorData.pcbNumber}-${motorData.groupId}';
//       }
//     }

//     // Fallback to construction from static details
//     final mac = motorDetails.value!.starter!.macAddress;
//     final pcb = motorDetails.value!.starter!.pcbNumber;

//     if (mac != null && mac.isNotEmpty) {
//       return '$mac-G01';
//     } else if (pcb != null && pcb.isNotEmpty) {
//       return '$pcb-G01';
//     }

//     return '';
//   }

//   void _startModeAckTimer(int previousValue) {
//     _modeAckTimer?.cancel();
//     _modeAckTimer = Timer(_ackTimeout, () {
//       if (_hasPendingModeCommand) {
//         if (kDebugMode) {
//           print(
//               'Mode ACK timeout - reverting to previous mode: $previousValue');
//         }
//         localModeIndex.value = previousValue;
//         motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
//         _hasPendingModeCommand = false;
//         _pendingModeValue = null;
//         isWaitingForModeAck.value = false;
//       }
//     });
//   }

//   Future<void> handleModeChange(int newModeIndex) async {
//     if (!mqttInitialized || isWaitingForModeAck.value) return;

//     final mId = _getMotorId();
//     if (mId.isEmpty) {
//       if (kDebugMode) print('Cannot change mode: Invalid motor ID');
//       return;
//     }

//     final previousValue = localModeIndex.value;

//     isWaitingForModeAck.value = true;
//     localModeIndex.value = newModeIndex;
//     motorMode.value = newModeIndex == 1 ? 'Auto' : 'Manual';
//     _hasPendingModeCommand = true;
//     _pendingModeValue = newModeIndex;

//     _startModeAckTimer(previousValue);

//     try {
//       await mqttService.publishModeCommand(mId, newModeIndex);
//     } catch (e) {
//       _modeAckTimer?.cancel();
//       localModeIndex.value = previousValue;
//       motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
//       _hasPendingModeCommand = false;
//       _pendingModeValue = null;
//       isWaitingForModeAck.value = false;
//       if (kDebugMode) print('Error changing mode: $e');
//     }
//   }

//   // --- Date & Runtime Logic ---

//   void resetDateToToday() {
//     final today = DateTime.now();
//     final normalizedToday = DateTime(today.year, today.month, today.day);
//     daterange.value = [normalizedToday, normalizedToday];
//   }

//   Future<void> fetchallApis() async {
//     clearAllData();
//     selectedDate.value = DateTime.now();
//     selectedMotorId.value = null;

//     try {
//       await fetchRuntime(daterange);
//     } catch (e) {
//       if (kDebugMode) print('Error in fetchallApis: $e');
//     }
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

//       if (mqttInitialized) {
//         _updateFromMqttData();
//       }
//     } catch (e) {
//       if (kDebugMode) print('Error onRefresh: $e');
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   void clearAllData({bool isHardClear = true}) {
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

//   Future<void> onDateRangeSelected() async {
//     clearAllData();
//     try {
//       await fetchRuntime(daterange);
//     } catch (e) {
//       if (kDebugMode) print('Error fetching data: $e');
//     }
//   }

//   Future<void> selectSingleDate(DateTime date) async {
//     final normalizedDate = DateTime(date.year, date.month, date.day);
//     daterange.value = [normalizedDate, normalizedDate];
//     clearAllData();

//     try {
//       await fetchRuntime(daterange);
//     } catch (e) {
//       if (kDebugMode) print('Error fetching data: $e');
//     }
//   }

//   bool isDateRange() {
//     if (daterange.isEmpty || daterange.length < 2) return false;
//     if (daterange.first == null || daterange.last == null) return false;
//     return daterange.first != daterange.last;
//   }

//   void leftClick() async {
//     if (daterange.isNotEmpty &&
//         daterange.first != null &&
//         daterange.last != null) {
//       daterange.value = [
//         daterange.first!.subtract(const Duration(days: 1)),
//         daterange.last!.subtract(const Duration(days: 1))
//       ];
//       clearAllData();
//       try {
//         await fetchRuntime(daterange);
//       } catch (e) {
//         // Silently ignore navigation errors
//       }
//     }
//   }

//   void rightClick() async {
//     final today =
//         DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
//     if (daterange.isEmpty || daterange.last == null) return;

//     final nextEndDate = daterange.last!.add(const Duration(days: 1));
//     final nextEndDateNormalized =
//         DateTime(nextEndDate.year, nextEndDate.month, nextEndDate.day);

//     if (nextEndDateNormalized.isAfter(today)) {
//       return;
//     }

//     if (daterange.isNotEmpty &&
//         daterange.first != null &&
//         daterange.last != null) {
//       daterange.value = [
//         daterange.first!.add(const Duration(days: 1)),
//         daterange.last!.add(const Duration(days: 1))
//       ];
//       clearAllData();
//       try {
//         await fetchRuntime(daterange);
//       } catch (e) {
//         // Silently ignore navigation errors
//       }
//     }
//   }

//   Duration durationconvert(String str) {
//     final regex = RegExp(r'(\d+)\s*h\s*(\d+)\s*m\s*(\d+)\s*sec');
//     final match = regex.firstMatch(str);

//     if (match != null) {
//       int hours = int.tryParse(match.group(1) ?? '0') ?? 0;
//       int minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
//       int seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
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
//     if (dateRange.isEmpty ||
//         dateRange.first == null ||
//         dateRange.last == null) {
//       if (kDebugMode) print('Invalid date range for runtime fetch');
//       return;
//     }

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

//         if (response.data!.records != null) {
//           chartData.value =
//               convertRuntimeToTimeSegments(response.data!.records!);
//           powerChartData.value =
//               convertRuntimeToPowerSegments(response.data!.records!);
//         }
//       } else {
//         motorRuntimeData.clear();
//         chartData.clear();
//         powerChartData.clear();
//       }
//     } catch (e) {
//       motorRuntimeData.clear();
//       chartData.clear();
//       powerChartData.clear();
//       if (kDebugMode) print('Error fetching runtime: $e');
//     } finally {
//       isLoadingruntime.value = false;
//     }
//   }

//   Future<void> fetchMotorDetails() async {
//     if (!isRefreshing.value) {
//       isMotorDetailsLoading.value = true;
//     }
//     try {
//       final response = await MotorsRepositoryImpl().getMotorDetails();

//       if (response != null && response.data != null) {
//         motorDetails.value = response.data;
//         final data = response.data!;

//         motorName.value = (data.aliasName != null && data.aliasName!.isNotEmpty)
//             ? data.aliasName!
//             : data.name ?? 'Unknown Motor';

//         hp.value = data.hp?.toString() ?? 'N/A';
//         deviceId.value = data.starter?.starterNumber ?? 'N/A';
//         motorState.value = data.state ?? 0;

//         // Set initial mode
//         final apiMode = data.mode ?? 'AUTO';
//         localModeIndex.value = apiMode.toUpperCase().contains('MANUAL') ? 0 : 1;
//         motorMode.value = localModeIndex.value == 1 ? 'Auto' : 'Manual';

//         locationName.value = data.location?.name?.trim().isNotEmpty == true
//             ? data.location!.name!
//             : 'No Location';

//         final starterParams = data.starter?.starterParameters;
//         if (starterParams != null && starterParams.isNotEmpty) {
//           faultMessage.value = starterParams.first.faultDescription ?? 'N/A';

//           if (starterParams.first.timeStamp != null) {
//             DateTime timestamp = starterParams.first.timeStamp!;
//             DateTime istTime =
//                 timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));
//             timeStamp.value =
//                 DateFormat('dd MMM yyyy, hh:mm a').format(istTime);
//           } else {
//             timeStamp.value = 'N/A';
//           }
//         } else {
//           faultMessage.value = 'N/A';
//           timeStamp.value = 'N/A';
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) print('Motor details error: $e');
//     } finally {
//       isMotorDetailsLoading.value = false;
//     }
//   }

//   @override
//   void onClose() {
//     _modeAckTimer?.cancel();
//     if (mqttInitialized) {
//       mqttService.dataUpdateNotifier.removeListener(_onMqttUpdate);
//       mqttService.dispose();
//     }
//     monthScrollController.dispose();
//     controller.dispose();
//     super.dispose();
//   }
// }

// class TimeSegment {
//   final DateTime start;
//   final DateTime end;
//   final String type;
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
import 'package:flutter/foundation.dart';
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
import 'package:i_dhara/app/presentation/components/tabs/motor_logs_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsController extends GetxController {
  // --- Data Variables ---
  var motorDetails = Rxn<MotorDetails>();
  var daterange = <DateTime?>[DateTime.now(), DateTime.now()].obs;

  // Graphs Data
  var voltage = <Voltage>[].obs;
  var current = <Current>[].obs;
  var motorRuntimeData = <Runtime>[].obs;
  var chartData = <TimeSegment>[].obs;
  var powerChartData = <TimeSegment>[].obs;

  // --- UI State Variables ---
  var isMotorDetailsLoading = false.obs;
  var isLoadingPowerRuntime = false.obs;
  var isLoadingVoltage = true.obs;
  var isLoadingCurrent = true.obs;
  var isLoadingruntime = false.obs;
  var isLoadingtotalruntime = false.obs;
  var isRefreshing = false.obs;
  var isModalOpen = false.obs;
  var selectedTabIndex = 0.obs;
  var hasInternet = true.obs;

  // --- Display Values ---
  var motorName = ''.obs;
  var deviceId = ''.obs;
  var motorState = 0.obs;
  var motorMode = 'Auto'.obs;
  var locationName = ''.obs;
  var hp = ''.obs;
  var timeStamp = ''.obs;
  var faultMessage = ''.obs;
  var motortotalRuntime = ''.obs;
  var powerTotalRuntime = ''.obs;

  // --- Helpers / Controllers ---
  TextEditingController controller = TextEditingController();
  final sharedPointNotifier = ValueNotifier<dynamic>(null);
  final sharedTimeNotifier = ValueNotifier<DateTime?>(null);
  final ValueNotifier<dynamic> valueNotifier = ValueNotifier(null);
  var voltageTrackball = Rxn<TrackballBehavior>();
  var currentTrackball = Rxn<TrackballBehavior>();
  final ScrollController monthScrollController = ScrollController();
  final connectivity = Connectivity();

  // --- Internal Logic Variables ---
  var selectedMotorId = Rxn<int?>();
  var selectedDate = DateTime.now().obs;
  var motorId = Rxn<int>();

  // --- MQTT Protocol Variables ---
  late MqttService mqttService;
  bool mqttInitialized = false;
  var localModeIndex = 1.obs; // 0 = Manual, 1 = Auto
  bool _hasPendingModeCommand = false;
  int? _pendingModeValue;
  Timer? _modeAckTimer;
  static const Duration _ackTimeout = Duration(seconds: 13);
  var isWaitingForModeAck = false.obs;
  var canChangeMode = true.obs;
  var signalQuality = 0.obs;

  // NEW: Track if we're using an existing MQTT instance
  final bool _isUsingExistingMqttInstance = false;

  // NEW: Stream subscription for MQTT updates
  StreamSubscription? _mqttUpdateSubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      motorId.value = args['motorId'];
    }

    if (motorId.value != null) {
      _initializeSequentially();
    }
    resetDateToToday();
    fetchallApis();
  }

  Future<void> _initializeSequentially() async {
    await fetchMotorDetails();
    await _initializeMqtt();
    _updateCanChangeMode();
  }

  void _initConnectivity() async {
    final connectivityResult = await connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
    connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results.first);
      if (mqttInitialized) {
        _updateCanChangeMode(); // NEW: Recompute on network change
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    hasInternet.value = result != ConnectivityResult.none;
  }

  void onTabChanged(int newIndex) {
    final previousIndex = selectedTabIndex.value;

    if (previousIndex == 1 && newIndex != 1) {
      _clearAnalyticsData();
    }

    if (newIndex == 1 && previousIndex != 1) {
      resetDateToToday();
      clearAllData();
      fetchRuntime(daterange);
    }

    selectedTabIndex.value = newIndex;
  }

  void _clearAnalyticsData() {
    motorRuntimeData.clear();
    chartData.clear();
    powerChartData.clear();
    voltage.clear();
    current.clear();
    motortotalRuntime.value = '';
  }

  // --- MQTT Logic ---

  Future<void> _initializeMqtt() async {
    if (motorDetails.value?.starter == null) {
      if (kDebugMode)
        print('⚠ Analytics: Motor details not loaded, cannot initialize MQTT');
      return;
    }

    final starter = motorDetails.value!.starter!;
    final mac = starter.macAddress;
    final pcb = starter.pcbNumber;

    if (kDebugMode) {
      print('=== Analytics MQTT Initialization ===');
      print('MAC Address: ${mac ?? "NULL"}');
      print('PCB Number: ${pcb ?? "NULL"}');
    }

    if ((mac == null || mac.isEmpty) && (pcb == null || pcb.isEmpty)) {
      if (kDebugMode) print('⚠ Analytics: No MAC or PCB available');
      return;
    }

    final motor = _convertMotorDetailsToMotor(motorDetails.value!);
    final motorMap = <String, Motor>{};

    // Build motor map for all 4 groups
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';
      if (mac != null && mac.isNotEmpty) {
        final key = '$mac-$groupId';
        motorMap[key] = motor;
        if (kDebugMode) print('✓ Analytics: Added motor map entry: $key');
      }
      if (pcb != null && pcb.isNotEmpty) {
        final key = '$pcb-$groupId';
        motorMap[key] = motor;
        if (kDebugMode) print('✓ Analytics: Added motor map entry: $key');
      }
    }

    if (kDebugMode)
      print('✓ Analytics: Total motor map entries: ${motorMap.length}');

    // CRITICAL: Get the singleton instance and update its motors
    mqttService = MqttService(initialMotors: motorMap);

    // Check if already connected, if not initialize
    if (!mqttService.isConnected) {
      if (kDebugMode) print('⚠ Analytics: MQTT not connected, initializing...');
      await mqttService.initializeMqttClient();
    } else {
      if (kDebugMode)
        print('✓ Analytics: MQTT already connected, updating motors');
      mqttService.updateMotors(motorMap);

      // Force resubscribe to topics for this motor
      await mqttService.resubscribeToTopics();
    }

    mqttInitialized = true;

    // Add listener for MQTT updates
    mqttService.dataUpdateNotifier.addListener(_onMqttDataUpdate);

    // Wait for connection to stabilize
    await Future.delayed(const Duration(milliseconds: 2000));

    // Check if we have data
    if (kDebugMode) {
      print('📊 Analytics: Checking motor data availability...');
      final motorData = getMotorData();
      if (motorData != null && motorData.hasReceivedData) {
        print('✓ Analytics: Motor data found!');
        print('  State: ${motorData.state}');
        print('  Mode: ${motorData.modeIndex}');
      } else {
        print('⚠ Analytics: No motor data yet, waiting for MQTT messages...');
        print('  Motor data map size: ${mqttService.motorDataMap.length}');

        // Print all keys in the map
        if (mqttService.motorDataMap.isNotEmpty) {
          print('  Available keys:');
          for (var key in mqttService.motorDataMap.keys) {
            final data = mqttService.motorDataMap[key];
            print('    $key: hasData=${data?.hasReceivedData}');
          }
        }
      }
    }

    // Initial update
    _updateFromMqttData();
    _updateCanChangeMode();

    if (kDebugMode) {
      print('✓ Analytics: MQTT initialization complete');
      print('✓ Analytics: Listener added for MQTT updates');
    }
  }

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

  // CRITICAL FIX: Proper MQTT update handler

  void _onMqttDataUpdate() {
    if (kDebugMode) {
      print('🔄 Analytics: MQTT data update notification received');
    }
    _updateFromMqttData();
  }

  void _updateFromMqttData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) {
      if (kDebugMode) print('⚠ Analytics: MQTT not ready or no motor details');
      return;
    }

    final motorData = getMotorData();

    if (motorData != null && motorData.hasReceivedData) {
      if (kDebugMode) {
        print('📥 Analytics: Processing MQTT data update');
        print(
            '  Motor Data - State: ${motorData.state}, Mode: ${motorData.modeIndex}');
        print('  Has Pending Command: $_hasPendingModeCommand');
        print('  Pending Value: $_pendingModeValue');
      }

      // Handle mode ACK
      if (_hasPendingModeCommand) {
        final mqttMode = motorData.modeIndex;
        if (kDebugMode) {
          print('⏳ Analytics: Waiting for mode ACK');
          print('  Expected: $_pendingModeValue');
          print('  Received: $mqttMode');
        }

        if (mqttMode == _pendingModeValue) {
          if (kDebugMode) {
            print('✅ Analytics: Mode ACK MATCHED!');
          }

          _modeAckTimer?.cancel();
          _hasPendingModeCommand = false;
          _pendingModeValue = null;
          isWaitingForModeAck.value = false;

          // Force UI update
          localModeIndex.value = mqttMode!;
          motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';

          if (kDebugMode) {
            print('✓ Analytics: UI updated successfully');
            print('  localModeIndex: ${localModeIndex.value}');
            print('  motorMode: ${motorMode.value}');
          }
        } else {
          if (kDebugMode) {
            print('⏳ Analytics: ACK mismatch - still waiting');
          }
        }
      } else {
        // Normal mode update (no pending command)
        final mqttMode = motorData.modeIndex;
        if (mqttMode != null && localModeIndex.value != mqttMode) {
          if (kDebugMode) {
            print('🔄 Analytics: Mode updated from MQTT (no pending command)');
            print('  Old mode: ${localModeIndex.value}');
            print('  New mode: $mqttMode');
          }
          localModeIndex.value = mqttMode;
          motorMode.value = mqttMode == 1 ? 'Auto' : 'Manual';
        }
      }

      // Update motor state
      if (motorState.value != motorData.state) {
        if (kDebugMode) {
          print('🔄 Analytics: State updated to ${motorData.state}');
        }
        motorState.value = motorData.state;
      }
    } else {
      if (kDebugMode) {
        print('⚠ Analytics: No valid motor data available');
      }
    }

    _updateCanChangeMode();
  }

  MotorData? getMotorData() {
    if (!mqttInitialized || motorDetails.value?.starter == null) return null;

    final mac = motorDetails.value!.starter!.macAddress;
    final pcb = motorDetails.value!.starter!.pcbNumber;

    // Check all possible groups to find active data
    for (int i = 1; i <= 4; i++) {
      final groupId = 'G0$i';

      if (mac != null && mac.isNotEmpty) {
        final key = '$mac-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          if (kDebugMode) print('✓ Analytics: Found data for MAC key=$key');
          return data;
        }
      }

      if (pcb != null && pcb.isNotEmpty) {
        final key = '$pcb-$groupId';
        final data = mqttService.motorDataMap[key];
        if (data?.hasReceivedData == true) {
          if (kDebugMode) print('✓ Analytics: Found data for PCB key=$key');
          return data;
        }
      }
    }

    if (kDebugMode)
      print('⚠ Analytics: No motor data found with received data');
    return null;
  }

  String _getMotorId() {
    if (motorDetails.value?.starter == null) return '';

    final motorData = getMotorData();

    if (motorData != null && motorData.groupId != null) {
      if (motorData.macAddress != null && motorData.macAddress!.isNotEmpty) {
        final motorId = '${motorData.macAddress}-${motorData.groupId}';
        if (kDebugMode)
          print('✓ Analytics: Using active MAC motor ID: $motorId');
        return motorId;
      } else if (motorData.pcbNumber != null &&
          motorData.pcbNumber!.isNotEmpty) {
        final motorId = '${motorData.pcbNumber}-${motorData.groupId}';
        if (kDebugMode)
          print('✓ Analytics: Using active PCB motor ID: $motorId');
        return motorId;
      }
    }

    final mac = motorDetails.value!.starter!.macAddress;
    final pcb = motorDetails.value!.starter!.pcbNumber;

    if (mac != null && mac.isNotEmpty) {
      final motorId = '$mac-G01';
      if (kDebugMode)
        print('✓ Analytics: Using fallback MAC motor ID: $motorId');
      return motorId;
    } else if (pcb != null && pcb.isNotEmpty) {
      final motorId = '$pcb-G01';
      if (kDebugMode)
        print('✓ Analytics: Using fallback PCB motor ID: $motorId');
      return motorId;
    }

    if (kDebugMode) print('⚠ Analytics: No valid motor ID found');
    return '';
  }

  void _updateCanChangeMode() {
    if (motorDetails.value?.starter == null) {
      canChangeMode.value = false;
      return;
    }

    final isAvailable =
        (motorDetails.value!.starter!.macAddress?.isNotEmpty == true) ||
            (motorDetails.value!.starter!.pcbNumber?.isNotEmpty == true);

    if (!isAvailable) {
      canChangeMode.value = false;
      return;
    }

    final motorData = getMotorData();
    final signalBars = _getSignalBars(motorData);
    canChangeMode.value = hasInternet.value && signalBars > 0;

    if (kDebugMode) {
      print(
          '🔧 Analytics: canChangeMode updated to ${canChangeMode.value} (network: ${hasInternet.value}, signal: $signalBars)');
    }
  }

  int _getSignalBars(MotorData? motorData) {
    if (motorData?.hasReceivedData == true && !motorData!.isSignalStale()) {
      return motorData.signalBars;
    }
    final signal = motorDetails.value?.starter?.signalQuality;
    if (signal == null || signal < 2 || signal > 31) return 0;
    if (signal < 10) return 1;
    if (signal < 15) return 2;
    if (signal < 20) return 3;
    return 4;
  }

  void _startModeAckTimer(int previousValue) {
    _modeAckTimer?.cancel();
    _modeAckTimer = Timer(_ackTimeout, () {
      if (_hasPendingModeCommand) {
        if (kDebugMode) {
          print(
              '⚠ Analytics: Mode ACK timeout - reverting to previous mode: $previousValue');
        }
        localModeIndex.value = previousValue;
        motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
        _hasPendingModeCommand = false;
        _pendingModeValue = null;
        isWaitingForModeAck.value = false;
      }
    });
  }

  Future<void> handleModeChange(int newModeIndex) async {
    if (!mqttInitialized || isWaitingForModeAck.value) {
      if (kDebugMode)
        print(
            '⚠ Analytics: Cannot change mode - MQTT not ready or waiting for ACK');
      return;
    }

    final mId = _getMotorId();
    if (mId.isEmpty) {
      if (kDebugMode)
        print('⚠ Analytics: Cannot change mode - Invalid motor ID');
      return;
    }

    final previousValue = localModeIndex.value;

    if (kDebugMode) {
      print('=== Analytics Mode Change Request ===');
      print('Motor ID: $mId');
      print('Current Mode: $previousValue');
      print('New Mode: $newModeIndex');
      print('Topic: peepul/${mId.split('-')[0]}/cmd');
    }

    // Optimistically update UI
    isWaitingForModeAck.value = true;
    localModeIndex.value = newModeIndex;
    motorMode.value = newModeIndex == 1 ? 'Auto' : 'Manual';
    _hasPendingModeCommand = true;
    _pendingModeValue = newModeIndex;

    _startModeAckTimer(previousValue);

    try {
      await mqttService.publishModeCommand(mId, newModeIndex);
      if (kDebugMode) print('✓ Analytics: Mode command published successfully');
    } catch (e) {
      if (kDebugMode) print('✗ Analytics: Error publishing mode command: $e');
      _modeAckTimer?.cancel();
      localModeIndex.value = previousValue;
      motorMode.value = previousValue == 1 ? 'Auto' : 'Manual';
      _hasPendingModeCommand = false;
      _pendingModeValue = null;
      isWaitingForModeAck.value = false;
    }
  }

  // --- Date & Runtime Logic ---

  void resetDateToToday() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    daterange.value = [normalizedToday, normalizedToday];
  }

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

  // Future<void> onrefresh() async {
  //   isRefreshing.value = true;
  //   resetDateToToday();
  //   voltageTrackball.value?.hide();
  //   currentTrackball.value?.hide();
  //   clearAllData();

  //   try {
  //     await Future.wait([
  //       fetchMotorDetails(),
  //       fetchRuntime(daterange),
  //       logsController.fetchMotorFaults(),
  //     ]);

  //     if (mqttInitialized) {
  //       _updateFromMqttData();
  //     }
  //   } catch (e) {
  //     if (kDebugMode) print('Error onRefresh: $e');
  //   } finally {
  //     isRefreshing.value = false;
  //   }
  // }
  Future<void> onrefresh() async {
    isRefreshing.value = true;
    resetDateToToday();
    voltageTrackball.value?.hide();
    currentTrackball.value?.hide();
    clearAllData();

    try {
      // Create a list of futures to wait for
      final futures = <Future>[];

      futures.add(fetchMotorDetails());

      // Only fetch runtime if we're on the runtime tab
      if (selectedTabIndex.value == 1) {
        futures.add(fetchRuntime(daterange));
      }

      // Fetch motor logs if we're on the logs tab
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
      } catch (e) {}
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
      } catch (e) {}
    }
  }

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

    for (var runtime in runtimes) {
      // Only process records where:
      // 1. Motor state is 1 (ON)
      // 2. Start and end times exist
      // 3. Duration exists or can be calculated
      if (runtime.motorState != 1) continue;
      if (runtime.startTime == null) continue;

      DateTime startTime = runtime.startTime!;
      DateTime endTime;
      Duration duration;

      // Handle end time and duration
      if (runtime.endTime != null) {
        endTime = runtime.endTime!;
        if (runtime.duration != null) {
          duration = durationconvert(runtime.duration!);
        } else {
          duration = endTime.difference(startTime);
        }
      } else {
        // If no end time, skip this segment (incomplete data)
        continue;
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

  // List<TimeSegment> convertRuntimeToTimeSegments(List<Runtime> runtimes) {
  //   List<TimeSegment> segments = [];

  //   for (var runtime in runtimes) {
  //     if (runtime.startTime != null && runtime.endTime != null) {
  //       Duration duration = runtime.endTime!.difference(runtime.startTime!);

  //       String state = 'OFFLINE';
  //       if (runtime.motorState == 1) {
  //         state = 'ON';
  //       } else if (runtime.motorState == 0) {
  //         state = 'OFF';
  //       }

  //       segments.add(TimeSegment(
  //         runtime.startTime!,
  //         runtime.endTime!,
  //         state,
  //         duration,
  //       ));
  //     }
  //   }
  //   return segments;
  // }

  // List<TimeSegment> convertRuntimeToPowerSegments(List<Runtime> runtimes) {
  //   final List<TimeSegment> segments = [];

  //   DateTime? lastPowerTime;
  //   int? lastPowerState;

  //   runtimes.sort((a, b) =>
  //       (a.timeStamp ?? DateTime(0)).compareTo(b.timeStamp ?? DateTime(0)));

  //   for (final runtime in runtimes) {
  //     if (runtime.powerState == null) continue;

  //     DateTime? startTime = runtime.powerStart ?? lastPowerTime;
  //     if (startTime == null) continue;

  //     DateTime endTime = runtime.powerEnd ??
  //         (runtime.powerState == lastPowerState ? DateTime.now() : startTime);

  //     String state = runtime.powerState == 1
  //         ? 'POWER_ON'
  //         : runtime.powerState == 0
  //             ? 'POWER_OFF'
  //             : 'POWER_OFFLINE';

  //     Duration duration;
  //     if (runtime.powerDuration != null) {
  //       duration = durationconvert(runtime.powerDuration!);
  //     } else {
  //       duration = endTime.difference(startTime);
  //     }

  //     if (duration.inSeconds > 0) {
  //       segments.add(
  //         TimeSegment(
  //           startTime,
  //           endTime,
  //           state,
  //           duration,
  //         ),
  //       );
  //     }

  //     lastPowerTime = endTime;
  //     lastPowerState = runtime.powerState;
  //   }
  //   return segments;
  // }
  // List<TimeSegment> convertRuntimeToPowerSegments(List<Runtime> runtimes) {
  //   final List<TimeSegment> segments = [];

  //   // Sort by timestamp to process in order
  //   final sortedRuntimes = List<Runtime>.from(runtimes);
  //   sortedRuntimes.sort((a, b) =>
  //       (a.timeStamp ?? DateTime(0)).compareTo(b.timeStamp ?? DateTime(0)));

  //   for (int i = 0; i < sortedRuntimes.length; i++) {
  //     final runtime = sortedRuntimes[i];

  //     // Only process records where power state is 1 (POWER ON)
  //     if (runtime.powerState != 1) continue;
  //     if (runtime.powerStart == null) continue;

  //     DateTime startTime = runtime.powerStart!;
  //     DateTime endTime;
  //     Duration duration;

  //     // Handle end time and duration
  //     if (runtime.powerEnd != null) {
  //       // Power end exists - use it
  //       endTime = runtime.powerEnd!;
  //       if (runtime.powerDuration != null) {
  //         duration = durationconvert(runtime.powerDuration!);
  //       } else {
  //         duration = endTime.difference(startTime);
  //       }
  //     } else {
  //       // Power end is null - this is an ONGOING power session
  //       // Use the next record's power_start/start_time or current time
  //       DateTime? nextTime;

  //       // Look for the next record's timestamp
  //       if (i + 1 < sortedRuntimes.length) {
  //         final nextRecord = sortedRuntimes[i + 1];
  //         // Use power_start if available, otherwise use start_time
  //         nextTime = nextRecord.powerStart ?? nextRecord.startTime;
  //       }

  //       // If we found a next time, use it; otherwise use current time
  //       endTime = nextTime ?? DateTime.now();
  //       duration = endTime.difference(startTime);
  //     }

  //     // Only add if duration is positive
  //     if (duration.inSeconds > 0) {
  //       segments.add(
  //         TimeSegment(
  //           startTime,
  //           endTime,
  //           'POWER_ON',
  //           duration,
  //         ),
  //       );
  //     }
  //   }

  //   return segments;
  // } //power

  List<TimeSegment> convertRuntimeToPowerSegments(List<Runtime> runtimes) {
    final List<TimeSegment> segments = [];

    for (final runtime in runtimes) {
      // Only POWER ON records
      if (runtime.powerState != 1) continue;
      if (runtime.powerStart == null) continue;

      final DateTime startTime = runtime.powerStart!;
      DateTime endTime;
      Duration duration;

      if (runtime.powerEnd == null) {
        // 🔴 STILL RUNNING
        endTime = startTime; // keep same to avoid fake duration
        duration = Duration.zero;
      } else {
        // 🟢 COMPLETED SESSION
        endTime = runtime.powerEnd!;

        if (runtime.powerDuration != null) {
          duration = durationconvert(runtime.powerDuration!);
        } else {
          duration = endTime.difference(startTime);
        }
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

  // Future<void> fetchRuntime(List<DateTime?> dateRange) async {
  //   if (dateRange.isEmpty ||
  //       dateRange.first == null ||
  //       dateRange.last == null) {
  //     if (kDebugMode) print('Invalid date range for runtime fetch');
  //     return;
  //   }

  //   if (!isRefreshing.value) {
  //     isLoadingruntime.value = true;
  //   }

  //   try {
  //     final response = await AnalyticsRepositoryImpl().getMotorRunTime(
  //       DateFormat('yyyy-MM-dd').format(dateRange.first!),
  //       DateFormat('yyyy-MM-dd').format(dateRange.last!),
  //       // state: 'on'
  //     );

  //     if (response != null && response.data != null) {
  //       motorRuntimeData.value = response.data!.records ?? [];
  //       motortotalRuntime.value = response.data!.totalRunOnTime ?? '';

  //       if (response.data!.records != null) {
  //         chartData.value =
  //             convertRuntimeToTimeSegments(response.data!.records!);
  //         powerChartData.value =
  //             convertRuntimeToPowerSegments(response.data!.records!);
  //       }
  //     } else {
  //       motorRuntimeData.clear();
  //       chartData.clear();
  //       powerChartData.clear();
  //     }
  //   } catch (e) {
  //     motorRuntimeData.clear();
  //     chartData.clear();
  //     powerChartData.clear();
  //     if (kDebugMode) print('Error fetching runtime: $e');
  //   } finally {
  //     isLoadingruntime.value = false;
  //   }
  // }
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

  @override
  void onClose() {
    _modeAckTimer?.cancel();
    _mqttUpdateSubscription?.cancel();
    if (mqttInitialized) {
      mqttService.dataUpdateNotifier.removeListener(_onMqttDataUpdate);
      mqttService.dispose();
    }
    monthScrollController.dispose();
    controller.dispose();
    super.onClose();
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
