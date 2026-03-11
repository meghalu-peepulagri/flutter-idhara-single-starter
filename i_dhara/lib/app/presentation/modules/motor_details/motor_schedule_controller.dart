import 'dart:async';

import 'package:flutter/widgets.dart';
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
  var page = 1.obs;
  var limit = 10.obs;
  var totalPages = 1.obs;
  var currentPage = 0.obs;
  var isHasMoreLoading = false.obs;
  var isInitialLoading = true.obs;
  var totalRecords = 0.obs;

  final scrollController = ScrollController();

  // Track pending actions: scheduleId -> cmd (1=stop, 2=restart, 3=delete)
  final _pendingActions = <int, int>{};

  // Completers for delete (cmd=3): resolved when ACK arrives
  final _deleteCompleters = <int, Completer<bool>>{};

  // Completers for stop/restart (cmd=1/2): resolved after ACK + post API
  final _toggleCompleters = <int, Completer<bool>>{};

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    fetchSchedules();
    _listenScheduleAck();
    _listenScheduleActionAck();
    ever(Get.find<AnalyticsController>().selectedTabIndex, (int index) {
      if (index == 1) fetchSchedules();
    });
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMoreSchedules();
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _scheduleAckSubscription?.cancel();
    _scheduleActionAckSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchSchedules({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
      page.value = 1;
    } else {
      isLoading.value = true;
      page.value = 1;
    }
    try {
      final response =
          await _scheduleRepo.getScheduleList(page.value, limit.value);
      schedules.value = response?.data?.records ?? [];

      final pagination = response?.data?.paginationInfo;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? 1;
      totalRecords.value = pagination?.totalRecords ?? schedules.length;
    } catch (_) {
      // silently fail
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isInitialLoading.value = false;
      isHasMoreLoading.value = false;
    }
  }

  Future<void> loadMoreSchedules() async {
    if (isHasMoreLoading.value) return;
    if (currentPage.value >= totalPages.value) return;

    isHasMoreLoading.value = true;
    page.value = currentPage.value + 1;
    try {
      final response =
          await _scheduleRepo.getScheduleList(page.value, limit.value);
      final newRecords = response?.data?.records ?? [];
      schedules.addAll(newRecords);

      final pagination = response?.data?.paginationInfo;
      currentPage.value = pagination?.currentPage ?? page.value;
      totalPages.value = pagination?.totalPages ?? totalPages.value;
      totalRecords.value = pagination?.totalRecords ?? totalRecords.value;
    } catch (_) {
      // silently fail
    } finally {
      isHasMoreLoading.value = false;
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
      _deleteCompleters.remove(scheduleId)?.complete(false);
      _toggleCompleters.remove(scheduleId)?.complete(false);
      geterrorSnackBar('Failed to send command: $e');
    }
  }

  /// Delete: publish MQTT cmd:3, wait for ACK, then call delete API.
  /// Returns true on success, false on failure.
  Future<bool> deleteSchedule(Record record) async {
    final scheduleId = record.scheduleId ?? 0;
    final completer = Completer<bool>();
    _deleteCompleters[scheduleId] = completer;
    await publishScheduleAction(record, 3);
    return completer.future;
  }

  /// Stop/Restart: publish MQTT cmd:1 (stop) or cmd:2 (restart),
  /// wait for ACK, then call stop/restart API.
  /// Returns true on success, false on failure.
  Future<bool> toggleSchedule(Record record, bool enabled) async {
    final scheduleId = record.scheduleId ?? 0;
    final completer = Completer<bool>();
    _toggleCompleters[scheduleId] = completer;
    await publishScheduleAction(record, enabled ? 2 : 1);
    return completer.future;
  }

  void _listenScheduleActionAck() {
    _scheduleActionAckSubscription?.cancel();
    _scheduleActionAckSubscription =
        _mqttService.scheduleActionAckStream.listen((ack) async {
      int scheduleId = 0;
      try {
        final currentId = _resolveIdentifier();
        final ackId = (ack['topic'] ?? '').toString();
        if (currentId.isNotEmpty && ackId != currentId) return;

        final status = ack['status'] as int? ?? 0;
        scheduleId = ack['id'] as int? ?? 0;
        final cmd = _pendingActions.remove(scheduleId);

        if (status == 1) {
          if (cmd == 3) {
            // ── DELETE: set id, call delete API, complete completer ──
            await _deleteScheduleAfterAck(scheduleId);
            _deleteCompleters.remove(scheduleId)?.complete(true);
          } else if (cmd == 1 || cmd == 2) {
            // ── STOP / RESTART: set id, call post API, complete completer ──
            final record =
                schedules.firstWhereOrNull((r) => r.scheduleId == scheduleId);
            if (record != null) {
              await SharedPreference.setscheduleid(record.id ?? 0);
            }
            try {
              final response = await _scheduleRepo.scheduleStopAndRestart(cmd!);
              if (response != null) {
                getsuccessSnackBar(
                    cmd == 1 ? 'Schedule stopped' : 'Schedule restarted');
                _toggleCompleters.remove(scheduleId)?.complete(true);
              } else {
                geterrorSnackBar('Failed to update schedule status');
                _toggleCompleters.remove(scheduleId)?.complete(false);
              }
            } catch (_) {
              geterrorSnackBar('Failed to update schedule status');
              _toggleCompleters.remove(scheduleId)?.complete(false);
            }
            fetchSchedules();
          } else {
            fetchSchedules();
          }
        } else {
          // ── ACK FAILURE / TIMEOUT ──
          geterrorSnackBar(cmd == null
              ? 'Schedule action: No response from device'
              : 'Schedule action failed');
          _deleteCompleters.remove(scheduleId)?.complete(false);
          _toggleCompleters.remove(scheduleId)?.complete(false);
          fetchSchedules();
        }
      } catch (e) {
        // Safety net: always resolve completers so dialogs never get stuck
        _deleteCompleters.remove(scheduleId)?.complete(false);
        _toggleCompleters.remove(scheduleId)?.complete(false);
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

  motor_model.Motor _buildMotorFromDetails() {
    final details = Get.find<AnalyticsController>().motorDetails.value;
    return motor_model.Motor(
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
  }

  void navigateToCreateSchedule() {
    Get.toNamed(
      Routes.schedule,
      arguments: {'motor': _buildMotorFromDetails()},
    )?.then((_) {
      fetchSchedules();
    });
  }

  void navigateToEditSchedule(Record record) {
    Get.toNamed(
      Routes.schedule,
      arguments: {
        'motor': _buildMotorFromDetails(),
        'record': record,
      },
    )?.then((_) {
      fetchSchedules();
    });
  }

  String _resolveIdentifier() {
    final starter = Get.find<AnalyticsController>().motorDetails.value?.starter;
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
