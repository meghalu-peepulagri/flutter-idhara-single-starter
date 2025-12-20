// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/graphs/current_model.dart';
// import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
// import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
// import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class AnalyticsController extends GetxController {
//   var voltage = <Voltage>[].obs;
//   var current = <Current>[].obs;
//   var isLoadingVoltage = true.obs;
//   var isLoadingCurrent = true.obs;
//   var isLoadingruntime = false.obs;
//   var isLoadingtotalruntime = false.obs;
//   var isLoadingLocations = false.obs;
//   var daterange = <DateTime?>[DateTime.now(), DateTime.now()].obs;
//   var isModalOpen = false.obs;

//   var selectedTitle = ''.obs;
//   var motorRuntimeData = <MotorRunTimeResponse>[].obs;
//   // var offLinePeriods = <OffLinePeriod>[].obs;
//   // var motortotalRuntimeData = Rxn<TotalRuntime?>();
//   var selectedMotorId = Rxn<int?>();
//   var selectedStarterId = Rxn<int?>();
//   var selectedDate = DateTime.now().obs;
//   var isRefreshing = false.obs;
//   TextEditingController controller = TextEditingController();
//   var chartData = <TimeSegment>[].obs;

//   // var motorList = <Dropdown>[].obs;
//   final sharedPointNotifier = ValueNotifier<dynamic>(null);
//   final sharedTimeNotifier = ValueNotifier<DateTime?>(null);
//   final ValueNotifier<dynamic> valueNotifier = ValueNotifier(null);
//   var voltageTrackball = Rxn<TrackballBehavior>();
//   var currentTrackball = Rxn<TrackballBehavior>();

//   fetchallApis() async {
//     clearAllData();
//     daterange.clear();
//     daterange.addAll([DateTime.now(), DateTime.now()]);

//     selectedDate.value = DateTime.now();
//     selectedMotorId.value = null;
//     // fetchMotorsList().then((_) async {
//     //   // if (selectedMotorId.value == null && motorList.isNotEmpty) {
//     //   //   SharedPreference.setmotorId(motorList.first.id!);
//     //   //   selectedTitle.value = motorList.first.title!.toString();
//     //   //     if(motorList.first.starterId !=null){
//     //   //     SharedPreference.setdevicestarterId(motorList.first.starterId.toString());

//     //   //   }
//     //   // }
//     //   await Future.wait([
//     //     // fetchRuntime(daterange),
//     //     // fetchtotalRuntime(daterange),
//     //     fetchavgcurrent(daterange),
//     //     fetchtotalkvar(daterange),
//     //   ]);
//     // });
//   }

//   // void motorOnChanged(String? value) async {
//   //   clearAllData();
//   //   try {
//   //     for (var i in motorList) {
//   //       if (i.title!.toLowerCase() == value!.toLowerCase()) {
//   //         print("line 72 ----------> ${i.title} ${i.id}");
//   //         selectedMotorId.value = i.id;
//   //         if(i.starterId ==null){
//   //           selectedStarterId.value = 0;

//   //         }else{
//   //           selectedStarterId.value = i.starterId!;

//   //         }
//   //       }
//   //     }
//   //     if (selectedMotorId.value != null) {
//   //       selectedTitle.value = value!;

//   //       SharedPreference.setmotorId(selectedMotorId.value!);
//   //       SharedPreference.setdevicestarterId(selectedStarterId.value.toString());
//   //       await Future.wait([
//   //         fetchRuntime(daterange),
//   //         fetchtotalRuntime(daterange),
//   //         fetchavgcurrent(daterange),
//   //         fetchtotalkvar(daterange),
//   //       ]);
//   //     }
//   //   } catch (e) {
//   //     await fetchRuntime(daterange);
//   //     await fetchtotalRuntime(daterange);
//   //     await fetchavgcurrent(daterange);
//   //     await fetchtotalkvar(daterange);
//   //   }
//   // }

//   Future<void> onrefresh() async {
//     isRefreshing.value = true;
//     voltageTrackball.value?.hide();
//     currentTrackball.value?.hide();
//     clearAllData();
//     // daterange.clear();
//     try {
//       // selectedDate.value = DateTime.now();
//       // daterange.addAll([DateTime.now(), DateTime.now()]);
//       // selectedMotorId.value = null;
//       // await fetchMotorsList().then((_) async {
//       // if (selectedMotorId.value == null && motorList.isNotEmpty) {
//       //   SharedPreference.setmotorId(motorList.first.id!);
//       //   selectedTitle.value = motorList.first.title!.toString();
//       // }
//       await Future.wait([
//         // fetchRuntime(daterange),
//         // fetchtotalRuntime(daterange),
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//       // });
//     } catch (e) {
//       isRefreshing.value = false;
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   clearAllData() {
//     // motorRuntimeData.clear();
//     chartData.clear();
//     voltage.clear();
//     current.clear();
//     // selectedTitle.value = '';
//     // motortotalRuntimeData.value = null;
//     sharedPointNotifier.value = null;
//     sharedTimeNotifier.value = null;
//     valueNotifier.value = null;
//   }

//   // double get interval {
//   //   final regex = RegExp(r'(\d+)\s*h\s*(\d+)\s*m\s*(\d+)\s*sec');
//   //   if (motortotalRuntimeData.value != null) {
//   //     final match =
//   //         regex.firstMatch(motortotalRuntimeData.value!.totalRuntimeHours!);
//   //     if (match != null) {
//   //       int hours = int.parse(match.group(1)!);
//   //       int minutes = int.parse(match.group(2)!);
//   //       int seconds = int.parse(match.group(3)!);
//   //       final _duration = Duration(
//   //         hours: hours,
//   //         minutes: minutes,
//   //         seconds: seconds,
//   //       );
//   //       if (_duration.inMinutes >= 10 && _duration.inMinutes < 40) {
//   //         return 5;
//   //       } else if (_duration.inMinutes >= 40 && _duration.inMinutes < 60) {
//   //         return 10;
//   //       } else if (_duration.inHours == 1) {
//   //         return 10;
//   //       } else if (_duration.inHours == 2) {
//   //         return 20;
//   //       } else if (_duration.inHours == 3 || _duration.inHours == 4) {
//   //         return 30;
//   //       } else if (_duration.inHours == 5) {
//   //         return 50;
//   //       } else if (_duration.inHours <= 10 && _duration.inHours >= 5) {
//   //         return 120;
//   //       } else if (_duration.inHours >= 10 && _duration.inHours <= 30) {
//   //         return 360;
//   //       } else if (_duration.inHours > 30) {
//   //         return _duration.inHours * 30;
//   //       } else if (_duration.inMinutes == 0 && _duration.inHours == 0) {
//   //         return 0;
//   //       } else {
//   //         return 2;
//   //       }
//   //     }
//   //   }
//   //   return 1;
//   // }

//   // Future<void> fetchMotorsList() async {
//   //   if (!isRefreshing.value) {
//   //     isLoadingLocations.value = true;
//   //   }
//   //   try {
//   //     final response = await MotorsRepositoryImpl().getMotorListDropdown();
//   //     if (response != null) {
//   //       motorList.value = response.data!;
//   //     }
//   //   } catch (e) {
//   //     motorList.clear();
//   //     isLoadingLocations.value = false;
//   //   } finally {
//   //     isLoadingLocations.value = false;
//   //   }
//   // }

//   leftClick() async {
//     selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
//     clearAllData();
//     try {
//       await Future.wait([
//         // fetchtotalRuntime(daterange), // Fetch total runtime first
//         // fetchRuntime(daterange),
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//     } catch (e) {
//       // Handle error
//     }
//   }

//   fetchdate() async {
//     selectedDate.value = selectedDate.value.add(const Duration(days: 1));
//     clearAllData();
//     try {
//       await Future.wait([
//         // fetchtotalRuntime(daterange), // Fetch total runtime first
//         // fetchRuntime(daterange),
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//     } catch (e) {
//       // Handle error
//     }
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

//   // List<TimeSegment> calculateSegments(
//   //     List<RuntimeResponse> runTimes, List<OffLinePeriod> offlinePeriods) {
//   //   List<TimeSegment> result = [];

//   //   // First, add all OFFLINE segments (assuming offline periods don't overlap)
//   //   for (var offline in offlinePeriods) {
//   //     Duration duration = offline.end!.difference(offline.start!);
//   //     result
//   //         .add(TimeSegment(offline.start!, offline.end!, 'OFFLINE', duration));
//   //   }

//   //   // Then, for each run, split it by overlapping offlines and add ON segments
//   //   // Assumes offline periods don't overlap with each other
//   //   for (var run in runTimes) {
//   //     // Find overlapping offlines, sorted by start time
//   //     List<OffLinePeriod> overlappingOfflines = offlinePeriods
//   //         .where((offline) =>
//   //             run.startTime!.isBefore(offline.end!) &&
//   //             run.endTime!.isAfter(offline.start!))
//   //         .toList()
//   //       ..sort((a, b) => a.start!.compareTo(b.start!));

//   //     DateTime currentStart = run.startTime!;
//   //     for (var offline in overlappingOfflines) {
//   //       // Add ON segment before this offline, if any
//   //       if (currentStart.isBefore(offline.start!)) {
//   //         Duration diff = offline.start!.difference(currentStart);
//   //         result.add(TimeSegment(
//   //             currentStart, offline.start!, run.motorDescription!.name, diff));
//   //       }
//   //       // Move currentStart to after this offline
//   //       currentStart = offline.end!;
//   //       // If we've gone past the run end, break
//   //       if (currentStart.isAfter(run.endTime!)) {
//   //         break;
//   //       }
//   //     }
//   //     // Add remaining ON segment after the last offline, if any
//   //     if (currentStart.isBefore(run.endTime!)) {
//   //       Duration diff = run.endTime!.difference(currentStart);
//   //       result.add(TimeSegment(
//   //           currentStart, run.endTime!, run.motorDescription!.name, diff));
//   //     }
//   //   }

//   //   // Sort all segments by start time (to ensure proper order)
//   //   result.sort((a, b) => a.start.compareTo(b.start));

//   //   // Deduplicate: remove exact duplicates (if any edge cases create them)
//   //   // Assuming TimeSegment overrides == and hashCode appropriately for this
//   //   final uniqueResult = <TimeSegment>[];
//   //   final offlines = result.where((test) => test.type == 'OFFLINE').toList();

//   //   for (var segment in result) {
//   //     if (!uniqueResult.contains(segment)) {
//   //       uniqueResult.add(segment);
//   //       if (segment.type != 'OFFLINE') {
//   //         for (var i in offlines) {
//   //           uniqueResult.removeWhere((result) {
//   //             return result.start.isAfter(i.start) &&
//   //                 result.end.isBefore(i.end) &&
//   //                 result.type != "OFFLINE";
//   //           });
//   //         }
//   //       }
//   //     }
//   //   }

//   //   return uniqueResult;
//   // }

//   // Future<void> fetchRuntime(List<DateTime?> dateRange) async {
//   //   if (!isRefreshing.value) {
//   //     isLoadingruntime.value = true;
//   //   }

//   //   try {
//   //     final response = await AnalyticsRepositoryImpl().getMotorRunTime(
//   //         DateFormat('yyyy-MM-dd').format(dateRange.first!),
//   //         DateFormat('yyyy-MM-dd').format(dateRange.last!));
//   //     if (response != null) {
//   //       motorRuntimeData.value = response.data;
//   //       chartData.clear();
//   //     } else {
//   //       motorRuntimeData.clear();
//   //       chartData.clear();
//   //     }
//   //     // final response = await MotorRunTimeApi().call(
//   //     //     fromDate: DateFormat('yyyy-MM-dd').format(dateRange.first!),
//   //     //     toDate: DateFormat('yyyy-MM-dd').format(dateRange.last!));
//   //     // if (response.statusCode == 200) {
//   //     //   motorRuntimeData.value = response.data?.data?.runTimeData ?? [];
//   //     //   offLinePeriods.value = response.data?.data?.offLinePeriods ?? [];
//   //     //   chartData.clear();
//   //     //   chartData.value = calculateSegments(motorRuntimeData, offLinePeriods);
//   //     // } else {
//   //     //   motorRuntimeData.clear();
//   //     //   offLinePeriods.clear();
//   //     //   chartData.clear();
//   //     // }
//   //   } catch (e) {
//   //     motorRuntimeData.clear();
//   //     offLinePeriods.clear();

//   //     chartData.clear();
//   //   } finally {}
//   // }

//   // Future<void> fetchtotalRuntime(List<DateTime?> dateRange) async {
//   //   try {
//   //     final response = await MotorsRepositoryImpl().getMotorTotalRunTime(
//   //       DateFormat('yyyy-MM-dd').format(dateRange.first!),
//   //       DateFormat('yyyy-MM-dd').format(dateRange.last!)
//   //     );
//   //     if(response != null){
//   //       motortotalRuntimeData.value = response.data!;
//   //       isLoadingtotalruntime.value = false;
//   //     }else {
//   //       motortotalRuntimeData.value = null;
//   //     }
//   //     // final response = await MotorTotalRunTimeApi().call(
//   //     //     fromDate: DateFormat('yyyy-MM-dd').format(dateRange.first!),
//   //     //     toDate: DateFormat('yyyy-MM-dd').format(dateRange.last!));
//   //     // if (response.statusCode == 200) {
//   //     //   motortotalRuntimeData.value = response.data!.data;
//   //     //   isLoadingtotalruntime.value = false;
//   //     // } else {
//   //     //   motortotalRuntimeData.value = null;
//   //     // }
//   //   } catch (e) {
//   //     motortotalRuntimeData.value = null;
//   //     isLoadingtotalruntime.value = false;
//   //   } finally {
//   //     isLoadingtotalruntime.value = false;
//   //     isLoadingruntime.value = false;
//   //   }
//   // }

//   Future<void> fetchtotalkvar(List<DateTime?> dateRange) async {
//     if (!isRefreshing.value) {
//       isLoadingVoltage.value = true;
//     }
//     try {
//       final response = await AnalyticsRepositoryImpl().getVoltage(
//           DateFormat('yyyy-MM-dd').format(dateRange.first!),
//           DateFormat('yyyy-MM-dd').format(dateRange.last!));
//       if (response != null && response.data != null) {
//         voltage.value = response.data!;
//         isLoadingVoltage.value = false;
//       } else {
//         voltage.clear();
//       }
//     } catch (e) {
//       voltage.clear();
//       isLoadingVoltage.value = false;
//     } finally {
//       isLoadingVoltage.value = false;
//     }
//   }

//   Future<void> fetchavgcurrent(List<DateTime?> dateRange) async {
//     if (!isRefreshing.value) {
//       isLoadingCurrent.value = true;
//     }
//     try {
//       final response = await AnalyticsRepositoryImpl().getCurrent(
//           DateFormat('yyyy-MM-dd').format(dateRange.first!),
//           DateFormat('yyyy-MM-dd').format(dateRange.last!));
//       if (response != null && response.data != null) {
//         current.value = response.data!;
//         isLoadingCurrent.value = false;
//       } else {
//         current.clear();
//       }
//     } catch (e) {
//       current.clear();
//       isLoadingCurrent.value = false;
//     } finally {
//       isLoadingCurrent.value = false;
//     }
//   }
// }

// class TimeSegment {
//   final DateTime start;
//   final DateTime end;
//   final String type; //// "green" or "red"
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

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/models/graphs/current_model.dart';
// import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
// import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
// import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class AnalyticsController extends GetxController {
//   var voltage = <Voltage>[].obs;
//   var current = <Current>[].obs;
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

//   final sharedPointNotifier = ValueNotifier<dynamic>(null);
//   final sharedTimeNotifier = ValueNotifier<DateTime?>(null);
//   final ValueNotifier<dynamic> valueNotifier = ValueNotifier(null);
//   var voltageTrackball = Rxn<TrackballBehavior>();
//   var currentTrackball = Rxn<TrackballBehavior>();
//   var motorId = Rxn<int>();
//   var motorName = ''.obs;
//   var deviceId = ''.obs;
//   dynamic motorData;

//   @override
//   void onInit() {
//     super.onInit();

//     // Get motor data from navigation arguments
//     final args = Get.arguments as Map<String, dynamic>?;
//     if (args != null) {
//       motorData = args['motor'];
//       motorId.value = args['motorId'] as int?;
//       motorName.value = args['motorName'] as String? ?? 'Motor';
//       deviceId.value = args['deviceId'] as String? ?? 'N/A';
//       selectedTitle.value = motorName.value;

//       // Set selectedMotorId for API calls if needed
//       selectedMotorId.value = motorId.value;
//     }

//     // Fetch initial data
//     fetchallApis();
//   }

//   fetchallApis() async {
//     clearAllData();

//     selectedDate.value = DateTime.now();
//     selectedMotorId.value = null;

//     await Future.wait([
//       fetchRuntime(daterange),
//       fetchavgcurrent(daterange),
//       fetchtotalkvar(daterange),
//     ]);
//   }

//   Future<void> onrefresh() async {
//     isRefreshing.value = true;
//     voltageTrackball.value?.hide();
//     currentTrackball.value?.hide();
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchRuntime(daterange),
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//     } catch (e) {
//       isRefreshing.value = false;
//     } finally {
//       isRefreshing.value = false;
//     }
//   }

//   clearAllData() {
//     motorRuntimeData.clear();
//     chartData.clear();
//     voltage.clear();
//     current.clear();
//     sharedPointNotifier.value = null;
//     sharedTimeNotifier.value = null;
//     valueNotifier.value = null;
//   }

//   // Method to be called when calendar date is selected
//   Future<void> onDateRangeSelected() async {
//     clearAllData();

//     try {
//       await Future.wait([
//         fetchRuntime(daterange),
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//     } catch (e) {
//       // Handle error
//       print('Error fetching data: $e');
//     }
//   }

//   leftClick() async {
//     // Move the date range backward by one day
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
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//     } catch (e) {
//       // Handle error
//     }
//   }

//   // Right arrow click - move forward (only if not going into future)
//   rightClick() async {
//     // Normalize today's date to midnight for comparison
//     final today =
//         DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

//     // Calculate what the next end date would be
//     final nextEndDate = daterange.last!.add(const Duration(days: 1));
//     final nextEndDateNormalized =
//         DateTime(nextEndDate.year, nextEndDate.month, nextEndDate.day);

//     // Check if next date would be after today
//     if (nextEndDateNormalized.isAfter(today)) {
//       Get.snackbar(
//         'Invalid Date',
//         'Cannot select future dates',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red.withOpacity(0.7),
//         colorText: Colors.white,
//       );
//       return;
//     }

//     // Move the date range forward by one day
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
//         fetchavgcurrent(daterange),
//         fetchtotalkvar(daterange),
//       ]);
//     } catch (e) {
//       // Handle error
//     }
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

//   // Convert Runtime data to TimeSegment for chart display
//   List<TimeSegment> convertRuntimeToTimeSegments(List<Runtime> runtimes) {
//     List<TimeSegment> segments = [];

//     for (var runtime in runtimes) {
//       if (runtime.startTime != null && runtime.endTime != null) {
//         Duration duration = runtime.endTime!.difference(runtime.startTime!);

//         // Determine state based on motorState
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
//         motorRuntimeData.value = response.data!;
//         // Convert Runtime data to TimeSegment for chart
//         chartData.value = convertRuntimeToTimeSegments(response.data!);
//       } else {
//         motorRuntimeData.clear();
//         chartData.clear();
//       }
//     } catch (e) {
//       motorRuntimeData.clear();
//       chartData.clear();
//       print('Error fetching runtime: $e');
//     } finally {
//       isLoadingruntime.value = false;
//     }
//   }

//   Future<void> fetchtotalkvar(List<DateTime?> dateRange) async {
//     if (!isRefreshing.value) {
//       isLoadingVoltage.value = true;
//     }
//     try {
//       final response = await AnalyticsRepositoryImpl().getVoltage(
//           DateFormat('yyyy-MM-dd').format(dateRange.first!),
//           DateFormat('yyyy-MM-dd').format(dateRange.last!));
//       if (response != null && response.data != null) {
//         voltage.value = response.data!;
//         isLoadingVoltage.value = false;
//       } else {
//         voltage.clear();
//       }
//     } catch (e) {
//       voltage.clear();
//       isLoadingVoltage.value = false;
//     } finally {
//       isLoadingVoltage.value = false;
//     }
//   }

//   Future<void> fetchavgcurrent(List<DateTime?> dateRange) async {
//     if (!isRefreshing.value) {
//       isLoadingCurrent.value = true;
//     }
//     try {
//       final response = await AnalyticsRepositoryImpl().getCurrent(
//           DateFormat('yyyy-MM-dd').format(dateRange.first!),
//           DateFormat('yyyy-MM-dd').format(dateRange.last!));
//       if (response != null && response.data != null) {
//         current.value = response.data!;
//         isLoadingCurrent.value = false;
//       } else {
//         current.clear();
//       }
//     } catch (e) {
//       current.clear();
//       isLoadingCurrent.value = false;
//     } finally {
//       isLoadingCurrent.value = false;
//     }
//   }
// }

// class TimeSegment {
//   final DateTime start;
//   final DateTime end;
//   final String type; // "ON", "OFF", or "OFFLINE"
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
// }//main code
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

  @override
  void onInit() {
    super.onInit();

    // // Get motor data from navigation arguments
    // final args = Get.arguments as Map<String, dynamic>?;
    // if (args != null) {
    //   motorData = args['motor'];
    //   motorId.value = args['motorId'] as int?;
    //   motorName.value = args['motorName'] as String? ?? 'Motor';
    //   deviceId.value = args['deviceId'] as String? ?? 'N/A';
    //   selectedTitle.value = motorName.value;

    //   // Set selectedMotorId for API calls if needed
    //   selectedMotorId.value = motorId.value;
    // }
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

  clearAllData() {
    motorRuntimeData.clear();
    chartData.clear();
    voltage.clear();
    current.clear();
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
        motorRuntimeData.value = response.data!;
        // Convert Runtime data to TimeSegment for chart
        chartData.value = convertRuntimeToTimeSegments(response.data!);
      } else {
        motorRuntimeData.clear();
        chartData.clear();
      }
    } catch (e) {
      motorRuntimeData.clear();
      chartData.clear();
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

        motorName.value = response.data!.aliasName ?? 'Motor';
        deviceId.value = response.data!.starter?.macAddress ?? 'N/A';
        motorState.value = response.data!.state ?? 0;
        motorMode.value = response.data!.mode ?? 'N/A';
        locationName.value = response.data!.location?.name ?? 'N/A';
        faultMessage.value =
            response.data!.starter!.starterParameters!.first.faultDescription ??
                'N/A';
      }
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
