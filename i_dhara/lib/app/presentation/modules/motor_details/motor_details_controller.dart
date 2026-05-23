import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/mixins/connectivity_mixin.dart';
import 'package:i_dhara/app/core/services/connectivity_service.dart';
import 'package:i_dhara/app/core/utils/api_retry.dart';
import 'package:i_dhara/app/core/utils/mqtt_utils.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';
import 'package:i_dhara/app/data/models/graphs/device_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_run_time_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/motor_total_runtime_model.dart';
import 'package:i_dhara/app/data/models/graphs/power_status_history_model.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/repository/analytics/analytics_repo_impl.dart';
import 'package:i_dhara/app/data/repository/motors/motor_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/tabs/motor_logs_controller.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_schedule_controller.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

part 'motor_details_controller.api.dart';
part 'motor_details_controller.mqtt.dart';

class AnalyticsController extends GetxController with ConnectivityMixin {
  static const int modeTabIndex = 0;
  static const int scheduleTabIndex = 1;
  static const int analyticsTabIndex = 2;
  static const int logsTabIndex = 3;
  // --- Data Variables ---
  var motorDetails = Rxn<MotorDetails>();
  var daterange = <DateTime?>[DateTime.now(), DateTime.now()].obs;

  // Graphs Data
  var voltage = <Voltage>[].obs;
  var current = <Current>[].obs;
  var motorRuntimeData = <Runtime>[].obs;
  var chartData = <TimeSegment>[].obs;
  var motorOffChartData = <TimeSegment>[].obs;
  var powerChartData = <TimeSegment>[].obs;
  var powerOffChartData = <TimeSegment>[].obs;
  var deviceOfflineChartData = <TimeSegment>[].obs;

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
  var logFilter = Rxn<String>();
  // Removed local connectivity logic, handled by ConnectivityMixin and ConnectivityService

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
  // Removed local connectivity logic

  // --- Internal Logic Variables ---
  var selectedMotorId = Rxn<int?>();
  var selectedDate = DateTime.now().obs;
  var motorId = Rxn<int>();

  // --- MQTT Protocol Variables ---
  late MqttService mqttService;
  bool mqttInitialized = false;
  var localModeIndex = 1.obs; // 0 = Manual, 1 = Auto, 2 = Schedule
  bool _hasPendingModeCommand = false;
  int? _pendingModeValue;
  Timer? _modeAckTimer;
  StreamSubscription? _modeAckErrorSubscription;
  static const Duration _ackTimeout = Duration(seconds: 23);
  // After a local mode change we briefly ignore stale `mode` values reported
  // in live data (T:35/T:41) — the device sometimes keeps sending the old
  // mode for a few packets before its reporting catches up to the T:32 ACK,
  // which would otherwise flip the UI back to the old mode.
  DateTime? _modeGuardUntil;
  static const Duration _modeGuardDuration = Duration(seconds: 10);
  var isWaitingForModeAck = false.obs;
  var canChangeMode = false.obs;
  var signalQuality = 0.obs;

  final bool _isUsingExistingMqttInstance = false;

  StreamSubscription? _mqttUpdateSubscription;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      motorId.value = args['motorId'];
      if (args['tabIndex'] != null) {
        selectedTabIndex.value = args['tabIndex'];
      }
      if (args['logFilter'] != null) {
        logFilter.value = args['logFilter'];
      }
    }

    if (motorId.value != null) {
      _initializeSequentially();
    }
    resetDateToToday();
    fetchallApis();
  }

  Future<void> _initializeSequentially() async {
    await fetchMotorDetails(enableRetry: true);
    await _initializeMqtt();
    _updateCanChangeMode();
  }

  @override
  Future<void> onRetry() async {
    Get.log('AnalyticsController: Retrying API calls after reconnection');
    await fetchallApis();
  }

  void onTabChanged(int newIndex) async {
    final previousIndex = selectedTabIndex.value;
    if (newIndex == modeTabIndex) {
      await fetchMotorDetails(enableRetry: false);
    }

    if (previousIndex == analyticsTabIndex && newIndex != analyticsTabIndex) {
      _clearAnalyticsData();
    }

    if (newIndex == analyticsTabIndex && previousIndex != analyticsTabIndex) {
      resetDateToToday();
      clearAllData();
      fetchRuntime(daterange);
    }

    selectedTabIndex.value = newIndex;
  }

  void _clearAnalyticsData() {
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

  @override
  void onClose() {
    _modeAckTimer?.cancel();
    _modeAckErrorSubscription?.cancel();
    _mqttUpdateSubscription?.cancel();
    if (mqttInitialized) {
      mqttService.dataUpdateNotifier.removeListener(_onMqttDataUpdate);
      // Do NOT call mqttService.dispose() — MQTT is a global singleton shared
      // across Dashboard and Motor Details. Disposing here disconnects the
      // broker connection for everyone. Cleanup happens only on logout via
      // MqttService().disconnectOnly().
    }
    monthScrollController.dispose();
    controller.dispose();
    super.onClose();
  }
}
