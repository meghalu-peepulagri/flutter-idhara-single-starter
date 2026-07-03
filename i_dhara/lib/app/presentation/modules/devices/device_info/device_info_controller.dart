import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/dto/image_upload_dto.dart';
import 'package:i_dhara/app/data/repository/devices/devices_repo_impl.dart';
import 'package:image_picker/image_picker.dart';

class DeviceInfoController extends GetxController {
  final photoUrl = RxnString();
  final deviceLocation = RxnString();

  // Shown on first open while fetching fresh data
  final isInitialLoading = true.obs;

  // Full-page loading — shown during upload and location save
  final isPageLoading = false.obs;

  // Skeleton loading — shown during pull-to-refresh
  final isRefreshing = false.obs;

  int? starterId;
  String? deviceName;
  String? starterNumber;

  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map<String, dynamic>?) ?? {};
    starterId = args['starterId'];
    deviceName = args['deviceName'];
    starterNumber = args['starterNumber'];
    photoUrl.value = args['photoUrl'];
    deviceLocation.value = args['deviceLocation'];
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    if (starterId != null) {
      try {
        final device = await DevicesRepositoryImpl()
            .getDeviceFromList(starterId!, search: starterNumber);
        if (device != null) {
          photoUrl.value = device.installationPhotoUrl;
          deviceLocation.value = device.deviceInstalledLocation;
        }
      } catch (_) {}
    }
    isInitialLoading.value = false;
  }

  // ── Pull-to-refresh ────────────────────────────────────────────────────────

  Future<void> refreshData() async {
    if (starterId == null) return;
    isRefreshing.value = true;
    try {
      final device = await DevicesRepositoryImpl()
          .getDeviceFromList(starterId!, search: starterNumber);
      if (device != null) {
        photoUrl.value = device.installationPhotoUrl;
        deviceLocation.value = device.deviceInstalledLocation;
      }
    } catch (_) {}
    isRefreshing.value = false;
  }

  // ── Photo upload ───────────────────────────────────────────────────────────

  Future<void> pickAndUploadPhoto(BuildContext context) async {
    final source = await _showSourcePicker(context);
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    await _uploadPhoto(context, File(picked.path));
  }

  Future<ImageSource?> _showSourcePicker(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF004E7E)),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF004E7E)),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(BuildContext context, File file) async {
    if (starterId == null) return;
    isPageLoading.value = true;
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      final dto = ImageUploadDto(
        fileName: file.path.split('/').last,
        fileType: mime,
        fileBase64: '',
      );

      final key = await DevicesRepositoryImpl()
          .fetchUploadImage(dto, bytes, starterIdOverride: starterId);

      if (key != null) {
        await _refreshFromList();
        if (context.mounted) {
          successSnackBar(context, 'Installation photo updated');
        }
      } else {
        if (context.mounted) {
          errorSnackBar(context, 'Failed to upload photo. Please try again.');
        }
      }
    } catch (_) {
      if (context.mounted) {
        errorSnackBar(context, 'Something went wrong. Please try again.');
      }
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> _refreshFromList() async {
    if (starterId == null) return;
    final device = await DevicesRepositoryImpl()
        .getDeviceFromList(starterId!, search: starterNumber);
    if (device != null) {
      photoUrl.value = device.installationPhotoUrl;
      deviceLocation.value = device.deviceInstalledLocation;
    }
  }

  // ── Location edit ──────────────────────────────────────────────────────────

  Future<void> showEditLocationSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _LocationEditSheet(
          initialValue: deviceLocation.value,
          // null return = success (sheet closes); non-null = field error (sheet stays)
          onSave: (value) => _updateLocation(context, value),
        ),
      ),
    );
  }

  /// Returns the field-level error string to show inside the sheet,
  /// or null on success (sheet should close).
  Future<String?> _updateLocation(BuildContext context, String location) async {
    if (starterId == null) return null;
    try {
      final res = await DevicesRepositoryImpl()
          .updateDeviceLocation(starterId!, location);
      if (res?.success == true) {
        deviceLocation.value = location;
        if (context.mounted) {
          successSnackBar(context, 'Device location updated');
        }
        // Fire page reload — sheet will close first, then AppLottieLoading shows
        isPageLoading.value = true;
        _refreshAndStopLoading();
        return null; // success → sheet closes
      }
      // Field-level validation error from 422
      final fieldError = res?.errors?.deviceInstalledLocation;
      if (fieldError != null) return fieldError;
      // General failure — show snackbar and close sheet
      if (context.mounted) {
        errorSnackBar(
            context, res?.message ?? 'Failed to update location. Please try again.');
      }
      return null;
    } catch (_) {
      if (context.mounted) {
        errorSnackBar(context, 'Something went wrong. Please try again.');
      }
      return null;
    }
  }

  Future<void> _refreshAndStopLoading() async {
    await _refreshFromList();
    isPageLoading.value = false;
  }
}

// ── Location edit bottom sheet ─────────────────────────────────────────────

class _LocationEditSheet extends StatefulWidget {
  final String? initialValue;
  final Future<String?> Function(String) onSave;

  const _LocationEditSheet({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_LocationEditSheet> createState() => _LocationEditSheetState();
}

class _LocationEditSheetState extends State<_LocationEditSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _fieldError = null;
    });
    final error = await widget.onSave(_controller.text.trim());
    if (!mounted) return;
    if (error != null) {
      // Field validation error — stay open, show error below text field
      setState(() {
        _isSaving = false;
        _fieldError = error;
      });
    } else {
      // Success or general error (snackbar shown) — close sheet
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title row ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Device Location',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      color: const Color(0xFFE9E9E9),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: Colors.black, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── Label + field ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(text: 'Device Location '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_fieldError != null) {
                        setState(() => _fieldError = null);
                      }
                    },
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      hintText: 'Enter device location',
                      hintStyle: const TextStyle(
                        color: Color(0xFFC5C5C5),
                        fontSize: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: _fieldError != null
                                ? Colors.red
                                : const Color(0xFFB4C1D6),
                            width: 1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: _fieldError != null
                                ? Colors.red
                                : const Color(0xFF004E7E),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.red, width: 1.5),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      errorText: _fieldError,
                      errorStyle: const TextStyle(
                          color: Colors.red, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Buttons ──────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.zero,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  Get.back();
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                                color: Color(0x38000000), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Save
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isSaving
                                ? [
                                    const Color(0xFF004E7E).withValues(alpha: 0.6),
                                    const Color(0xFF3686AF).withValues(alpha: 0.6),
                                  ]
                                : const [
                                    Color(0xFF004E7E),
                                    Color(0xFF3686AF),
                                  ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
