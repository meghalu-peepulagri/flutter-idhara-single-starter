import 'dart:async';

import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart'
    as motor_model;
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class MotorScheduleController extends GetxController {
  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;
  StreamSubscription<Map<String, dynamic>>? _scheduleActionAckSubscription;

  var schedules = <Record>[].obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;

  // Track pending actions: scheduleId -> cmd (1=stop, 2=restart, 3=delete)
  final _pendingActions = <int, int>{};

  // Completers for delete: resolved when T:55 ACK arrives for cmd=3
  final _deleteCompleters = <int, Completer<bool>>{};

  @override
  void onInit() {
    super.onInit();
    fetchSchedules();
    _listenScheduleAck();
    _listenScheduleActionAck();
    ever(Get.find<AnalyticsController>().selectedTabIndex, (int index) {
      if (index == 1) fetchSchedules();
    });
  }

  @override
  void onClose() {
    _scheduleAckSubscription?.cancel();
    _scheduleActionAckSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchSchedules({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    try {
      final response = await _scheduleRepo.getScheduleList(1, 10);
      schedules.value = response?.data?.records ?? [];
    } catch (_) {
      // silently fail
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> fetchacknowledgement() async {
    try {
      await _scheduleRepo.scheduleAcknowledgement();
    } catch (_) {
      // silently fail
    }
  }

  // --- Schedule Actions (T:24): stop/restart/delete ---

  int _getScheduleType(Record record) {
    return record.scheduleType?.toLowerCase() == 'cyclic' ? 2 : 1;
  }

  /// Publish schedule action: cmd 1=stop, 2=restart, 3=delete
  Future<void> publishScheduleAction(Record record, int cmd) async {
    final id = _resolveIdentifier();
    if (id.isEmpty) return;
    final scheduleId = record.scheduleId ?? 0;
    final scheduleType = _getScheduleType(record);
    _pendingActions[scheduleId] = cmd;
    try {
      await _mqttService.publishScheduleActionCommand(
        identifier: id,
        scheduleType: scheduleType,
        scheduleId: scheduleId,
        cmd: cmd,
      );
    } catch (e) {
      _pendingActions.remove(scheduleId);
      geterrorSnackBar('Failed to send command: $e');
    }
  }

  /// Delete: publish MQTT cmd:3, wait for ACK, returns true=success false=failed
  Future<bool> deleteSchedule(Record record) async {
    final scheduleId = record.scheduleId ?? 0;
    final completer = Completer<bool>();
    _deleteCompleters[scheduleId] = completer;
    await publishScheduleAction(record, 3);
    return completer.future;
  }

  /// Toggle: publish MQTT cmd:2 (restart/on) or cmd:1 (stop/off)
  Future<void> toggleSchedule(Record record, bool enabled) async {
    await publishScheduleAction(record, enabled ? 2 : 1);
  }

  void _listenScheduleActionAck() {
    _scheduleActionAckSubscription?.cancel();
    _scheduleActionAckSubscription =
        _mqttService.scheduleActionAckStream.listen((ack) async {
      final currentId = _resolveIdentifier();
      final ackId = (ack['topic'] ?? '').toString();
      if (currentId.isNotEmpty && ackId != currentId) return;

      final status = ack['status'] as int? ?? 0;
      final scheduleId = ack['id'] as int? ?? 0;
      final cmd = _pendingActions.remove(scheduleId);

      if (status == 1) {
        if (cmd == 3) {
          await _deleteScheduleAfterAck(scheduleId);
          _deleteCompleters.remove(scheduleId)?.complete(true);
        } else {
          getsuccessSnackBar(
              cmd == 1 ? 'Schedule stopped' : 'Schedule restarted');
          fetchSchedules();
        }
      } else {
        if (cmd == 3) {
          _deleteCompleters.remove(scheduleId)?.complete(false);
        }
        geterrorSnackBar(
            cmd == null ? 'Schedule action: No response from device'
                : 'Schedule action failed');
        // Refresh to revert any optimistic UI changes (e.g. toggle switch)
        fetchSchedules();
      }
    });
  }

  Future<void> _deleteScheduleAfterAck(int scheduleId) async {
    final record =
        schedules.firstWhereOrNull((r) => r.scheduleId == scheduleId);
    if (record != null) {
      SharedPreference.setscheduleid(record.id ?? 0);
      schedules.remove(record);
    }
    getsuccessSnackBar('Schedule deleted successfully');
    try {
      await _scheduleRepo.scheduleDelete();
    } catch (_) {
      // silently fail
    }
  }

  // --- Navigation ---

  void navigateToCreateSchedule() {
    final details = Get.find<AnalyticsController>().motorDetails.value;
    final motor = motor_model.Motor(
      id: details?.id,
      name: details?.name,
      aliasName: details?.aliasName,
      starter: details?.starter != null
          ? motor_model.Starter(
              id: details!.starter!.id,
              name: details.starter!.name,
              macAddress: details.starter!.macAddress,
              pcbNumber: details.starter!.pcbNumber,
              starterNumber: details.starter!.starterNumber,
            )
          : null,
    );
    Get.toNamed(
      Routes.schedule,
      arguments: {'motor': motor},
    )?.then((_) {
      fetchSchedules();
    });
  }

  String _resolveIdentifier() {
    final starter =
        Get.find<AnalyticsController>().motorDetails.value?.starter;
    final mac = starter?.macAddress?.trim() ?? '';
    if (mac.isNotEmpty) return mac;
    return starter?.pcbNumber?.trim() ?? '';
  }

  // --- Schedule Create ACK (T:54) ---

  void _listenScheduleAck() {
    _scheduleAckSubscription?.cancel();
    _scheduleAckSubscription = _mqttService.scheduleAckStream.listen((ack) {
      final currentId = _resolveIdentifier();
      final ackId = (ack['topic'] ?? '').toString();
      if (currentId.isNotEmpty && ackId != currentId) return;

      final status = ack['status'] as int? ?? 0;
      if (status == 1) {
        getsuccessSnackBar('Schedule created successfully');
        fetchSchedules();
        fetchacknowledgement();
      } else {
        geterrorSnackBar('Schedule creation failed');
      }
    });
  }
}
