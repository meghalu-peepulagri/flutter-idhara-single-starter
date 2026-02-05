import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_logs_controller.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

part 'motor_details_controller.api.dart';
part 'motor_details_controller.mqtt.dart';

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

  final bool _isUsingExistingMqttInstance = false;

  StreamSubscription? _mqttUpdateSubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      motorId.value = args['motorId'];
      if (args['tabIndex'] != null) {
        selectedTabIndex.value = args['tabIndex'];
      }
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
        _updateCanChangeMode();
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
