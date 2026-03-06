import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/schedules/create_schedule_model.dart';
import 'package:i_dhara/app/data/repository/schedules/schedule_repo_impl.dart';

class ScheduleController extends GetxController {
  final ScheduleRepositoryImpl _scheduleRepo = ScheduleRepositoryImpl();
  final controller1 = TextEditingController();

  var isLoading = false.obs;
  var isRefreshing = false.obs;

  var page = 1.obs;
  var limit = 10.obs;

  dynamic errorInstance = {};
  String? message = '';

  @override
  void onClose() {
    controller1.dispose();
    super.onClose();
  }

  Future<CreateScheduleResponse?> createSchedule({
    required CreateScheduleDto dto,
  }) async {
    isLoading.value = true;
    try {
      final response = await _scheduleRepo.createschedule(dto);
      isLoading.value = false;

      if (response != null && response.success == true) {
        message = response.message;
        return response;
      } else {
        message = response?.errors?.daysOfWeek ?? 'Failed to create schedule';
        errorInstance = response?.toJson() ?? {};
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      message = 'Error: $e';
      return null;
    }
  }
}
