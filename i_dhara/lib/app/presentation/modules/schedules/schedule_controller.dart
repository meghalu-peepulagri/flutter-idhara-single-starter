import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/dto/create_schedule_dto.dart';
import 'package:i_dhara/app/data/models/schedules/create_schedule_model.dart';
import 'package:i_dhara/app/data/models/schedules/schedule_update_model.dart';
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

  /// [dtos] — pass a single-item list for single schedule,
  ///          pass multiple items for bulk creation.
  /// Body is always sent as a JSON array to the server.
  Future<CreateScheduleResponse?> createSchedule({
    required List<CreateScheduleDto> dtos,
  }) async {
    isLoading.value = true;
    try {
      final response = await _scheduleRepo.createschedule(dtos);
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

  Future<ScheduleUpdateResponse?> updateSchedule({
    required CreateScheduleDto dto,
  }) async {
    isLoading.value = true;
    try {
      final response = await _scheduleRepo.scheduleupdate(dto);
      isLoading.value = false;

      if (response != null && response.success == true) {
        message = response.message;
        return response;
      } else {
        message = response?.message ?? 'Failed to update schedule';
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      message = 'Error: $e';
      return null;
    }
  }

  Future<void> refreshCreateSchedulePage() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      // Keeps skeleton visible briefly so pull-to-refresh has clear UI feedback.
      await Future<void>.delayed(const Duration(milliseconds: 800));
    } finally {
      isRefreshing.value = false;
    }
  }
}
