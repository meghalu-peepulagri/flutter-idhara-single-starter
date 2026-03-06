import 'dart:async';

import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart' as motor_model;
import 'package:i_dhara/app/data/models/motors/motor_details_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_list_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class MotorScheduleController extends GetxController {
  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final MqttService _mqttService = MqttService();
  StreamSubscription<Map<String, dynamic>>? _scheduleAckSubscription;

  var schedules = <Record>[].obs;
  var isLoading = true.obs;

  MotorDetails? motorDetails;

  @override
  void onInit() {
    super.onInit();
    fetchSchedules();
  }

  @override
  void onClose() {
    _scheduleAckSubscription?.cancel();
    super.onClose();
  }

  void setMotorDetails(MotorDetails? details) {
    motorDetails = details;
    _listenScheduleAck();
  }

  Future<void> fetchSchedules() async {
    isLoading.value = true;
    try {
      final response = await _scheduleRepo.getScheduleList(1, 50);
      schedules.value = response?.data?.records ?? [];
    } catch (_) {
      // silently fail
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToCreateSchedule() {
    final details = motorDetails;
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
    final starter = motorDetails?.starter;
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
      } else {
        geterrorSnackBar('Schedule creation failed');
      }
    });
  }
}
