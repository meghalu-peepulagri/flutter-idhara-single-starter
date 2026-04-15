import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/dto/device_assign_dto.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';
import 'package:i_dhara/app/data/repository/locations/location_repo_impl.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/flutter_flow/flutter_flow_util.dart';
import '../../../../data/dto/image_upload_dto.dart';
import 'add_devices_page.dart' show AddDevicesWidget;

class AddDevicesModel extends FlutterFlowModel<AddDevicesWidget> {
  // dynamic errorInstance;
  dynamic errorInstance1;
  String message = '';
  Map<String, dynamic> errorInstance = {};
  List<Location>? locations;
  String locationId = '';
  File? imageFile;

  File? selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked != null) {
      selectedImage = File(picked.path);
      return selectedImage;
    }
    return null;
  }

  void removeImage() {
    selectedImage = null;
  }

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;

  FocusNode? textFieldFocusNode5;
  TextEditingController? textController5;
  String? Function(BuildContext, String?)? textController5Validator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    textFieldFocusNode5?.dispose();
    textController5?.dispose();
  }

  Future<void> fetchLocationDropDown() async {
    final response = await LocationRepoImpl().getLocations();
    if (response != null) {
      response.data ?? [];
    }
  }

  String convertToBase64(File file) {
    final bytes = file.readAsBytesSync();
    return base64Encode(bytes);
  }

  Future<void> fetchupload() async {
    if (imageFile == null) {
      return;
    }
    String base64Image = convertToBase64(imageFile!);

    final Uint8List imageBytes = await imageFile!.readAsBytes();
    final fileName = imageFile!.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    String mimeType;
    switch (extension) {
      case 'png':
        mimeType = 'image/png';
        break;
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      default:
        mimeType = 'image/jpeg';
        break;
    }
    final dto = ImageUploadDto(
      fileName: fileName,
      fileType: mimeType,
      fileBase64: base64Image,
    );
    try {
      final response =
          await DevicesRepositoryImpl().fetchUploadImage(dto, imageBytes);
      if (response != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (Get.isRegistered<DashboardController>()) {
          Get.delete<DashboardController>();
        }
        Get.offAllNamed(Routes.devices, arguments: {'refresh': true});
      }
    } catch (e) {}
  }

  Future<void> assignDevice({
    required String pcbNumber,
    required String deviceLoc,
    required String pumpName,
    required double hp,
    required int locationId,
  }) async {
    final dto = StarterCreateDto(
      deviceInstalledLoc: deviceLoc,
      pcbNumber: pcbNumber,
      motorName: pumpName,
      hp: hp,
      locationId: locationId,
    );

    final response = await DevicesRepositoryImpl().deviceassign(dto);

    if (response != null && response.errors == null) {
      if (response.data?.starterId != null) {
        SharedPreference.setStarterId(response.data?.starterId ?? 0);
      }
      if (imageFile != null) {
        await fetchupload();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (Get.isRegistered<DashboardController>()) {
          Get.delete<DashboardController>();
        }
        Get.offAllNamed(Routes.devices, arguments: {'refresh': true});
      }
    } else if (response?.errors != null) {
      errorInstance.clear();
      errorInstance.addAll(response!.errors!.toJson());
    }
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return {'error': 'Location services are disabled. Please enable them.'};
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return {'error': 'Location permission denied.'};
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return {'error': 'Location permissions are permanently denied.'};
    }

    try {
      // iOS needs explicit LocationSettings with a timeout,
      // otherwise getCurrentPosition() hangs silently on iOS.
      final LocationSettings locationSettings = Platform.isIOS
          ? AppleSettings(
              accuracy: LocationAccuracy.high,
              activityType: ActivityType.other,
              timeLimit: const Duration(seconds: 15),
              pauseLocationUpdatesAutomatically: false,
              allowBackgroundLocationUpdates: false,
            )
          : AndroidSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 15),
            );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build address using only one field to avoid duplicates and commas.
        // API only allows characters (no commas or special chars).
        String locality = place.locality ?? '';
        String subArea = place.subAdministrativeArea ?? '';

        String address;
        if (locality.isNotEmpty) {
          address = locality;
        } else if (subArea.isNotEmpty) {
          address = subArea;
        } else if ((place.name ?? '').isNotEmpty) {
          address = place.name!;
        } else {
          address = 'New Location';
        }

        // Remove any characters not allowed by the API (commas, digits, specials)
        address = address.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();

        // Check if location already exists
        final existingResponse = await LocationRepoImpl().getLocations();
        if (existingResponse != null && existingResponse.data != null) {
          for (var element in existingResponse.data!) {
            if (element.name == address) {
              return {
                'id': element.id.toString(),
                'name': element.name ?? address,
              };
            }
          }
        }

        // Try to add location if not found
        await LocationRepoImpl().addLocation(address);

        // Fetch all locations to find the ID of the newly added location
        final response = await LocationRepoImpl().getLocations();
        if (response != null && response.data != null) {
          for (var element in response.data!) {
            if (element.name == address) {
              return {
                'id': element.id.toString(),
                'name': element.name ?? address,
              };
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
}
