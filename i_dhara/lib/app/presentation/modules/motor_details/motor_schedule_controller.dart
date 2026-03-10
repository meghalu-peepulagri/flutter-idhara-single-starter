import 'dart:async';

import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart'
    as motor_model;
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class MotorScheduleController extends GetxController {
  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;

  var schedules = <Record>[].obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSchedules();
    _listenScheduleAck();
    ever(Get.find<AnalyticsController>().selectedTabIndex, (int index) {
      if (index == 1) fetchSchedules();
    });
  }

  @override
  void onClose() {
    _scheduleAckSubscription?.cancel();
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
    isLoading.value = true;
    try {
      await _scheduleRepo.scheduleAcknowledgement();
    } catch (_) {
      // silently fail
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDeleteSchedule() async {
    isLoading.value = true;
    try {
      final response = await _scheduleRepo.scheduleDelete();
      if (response != null && response.success == true) {
        fetchSchedules();
        getsuccessSnackBar(response.message ?? 'Schedule deleted successfully');
      }
    } catch (_) {
      // silently fail
    } finally {
      isLoading.value = false;
    }
  }

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
    final starter = Get.find<AnalyticsController>().motorDetails.value?.starter;
    final mac = starter?.macAddress?.trim() ?? '';
    if (mac.isNotEmpty) return mac;
    return starter?.pcbNumber?.trim() ?? '';
  }

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
