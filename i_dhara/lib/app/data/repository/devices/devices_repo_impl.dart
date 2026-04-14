import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:i_dhara/app/core/config/app_config.dart';
import 'package:i_dhara/app/data/dto/device_assign_dto.dart';
import 'package:i_dhara/app/data/dto/image_upload_dto.dart';
import 'package:i_dhara/app/data/models/devices/device_assign_model.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/models/devices/location_replace_model.dart';
import 'package:i_dhara/app/data/models/devices/rename_devices_model.dart';
import 'package:i_dhara/app/data/models/motors/delete_motor_model.dart';
import 'package:i_dhara/app/data/models/test_run/test_run_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repository.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';

class DevicesRepositoryImpl extends DevicesRepository {
  @override
  Future<DevicesResponse?> getDevices(
      int? page, String? search, int? limit) async {
    Map<String, dynamic> params = {
      'page': page,
      'limit': limit,
    };

    if (search != null && search.isNotEmpty) {
      params['search_string'] = search;
    }

    final response =
        await NetworkManager().get('/starters/mobile', queryParameters: params);
    if (response.statusCode == 200) {
      final res = DevicesResponse.fromJson(response.data);
      return res;
    }
    return null;
  }

  @override
  Future<DeviceAssignResponse?> deviceassign(
    StarterCreateDto dto,
  ) async {
    final body = dto.toJson();
    final response =
        await NetworkManager().patch('/starters/assign', data: body);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422) {
      final data = DeviceAssignResponse.fromJson(response.data);
      return data;
    } else {
      return null;
    }
  }

  @override
  Future<DeleteStarterResponse?> deletestarter(int starterId) async {
    final response = await NetworkManager().patch('/starters/$starterId');
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 422) {
      return DeleteStarterResponse.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<RenameDeviceResponse?> renameDevice(
      int motorId, String name, double? hp) async {
    final body = {"name": name, "hp": hp};
    final response =
        await NetworkManager().patch('/motors/$motorId', data: body);
    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = RenameDeviceResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<LocationReplaceResponse?> locationreplace(
      int starterId, int locationId, int motorId) async {
    final body = {
      "starter_id": starterId,
      "motor_id": motorId,
      "location_id": locationId
    };
    final response =
        await NetworkManager().patch('/starters/replace', data: body);
    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = LocationReplaceResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  @override
  Future<TestRunResponse?> testRun(int motorId, TestRunStatus status) async {
    final body = {"test_run_status": status.value};
    final response = await NetworkManager().patch(
      '/motors/$motorId/test-run-status',
      data: body,
    );
    if (response.statusCode == 200 ||
        response.statusCode == 422 ||
        response.statusCode == 201) {
      final res = TestRunResponse.fromJson(response.data);
      return res;
    } else {
      return null;
    }
  }

  Future<String?> fetchUploadImage(
      ImageUploadDto dto, Uint8List? screenshotBytes) async {
    final deviceID = SharedPreference.getStarterId();
    final dio = Dio();
    final response = await NetworkManager().get(
      '/starters/$deviceID/installation-photo/upload-url',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;

      try {
        if (data['success'] == true && data['data'] != null) {
          final targetUrl = data['data']['upload_url'];
          final fileKey = data['data']['key'];
          final putResponse = await dio.put(
            targetUrl,
            data: screenshotBytes,
            options: Options(
              headers: {
                'Content-Type': 'image/png',
              },
            ),
          );
          debugPrint("line 151 ----> ${putResponse.statusCode}");

          if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
            return fileKey;
          } else {
            return null;
          }
        }
      } catch (e) {
        debugPrint("line 151 error ----> $e");
      }
    }
    return null;
  }
}
