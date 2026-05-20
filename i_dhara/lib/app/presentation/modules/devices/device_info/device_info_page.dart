import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/modules/devices/device_info/device_info_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DeviceInfoPage extends StatelessWidget {
  final String? deviceName;
  final int? starterId;
  final String? starterNumber;
  final String? pcbNumber;
  final String? simNumber;
  final String? simRechargeExpiry;
  final String? testRunDate;

  const DeviceInfoPage({
    super.key,
    this.deviceName,
    this.starterId,
    this.starterNumber,
    this.pcbNumber,
    this.simNumber,
    this.simRechargeExpiry,
    this.testRunDate,
  });

  factory DeviceInfoPage.fromArgs(Map<String, dynamic> args) {
    return DeviceInfoPage(
      deviceName: args['deviceName'],
      starterId: args['starterId'],
      starterNumber: args['starterNumber'],
      pcbNumber: args['pcbNumber'],
      simNumber: args['simNumber'],
      simRechargeExpiry: args['simRechargeExpiry'],
      testRunDate: args['testRunDate'],
    );
  }

  @override
  Widget build(BuildContext context) {
    // iOS only: block the left-edge swipe-back gesture. The header back
    // arrow still works — Get.back() pops unconditionally, unaffected by
    // canPop. Android keeps its normal system back behaviour.
    return PopScope(
      canPop: !Platform.isIOS,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final controller = Get.find<DeviceInfoController>();
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Obx(() {
          if (controller.isInitialLoading.value ||
              controller.isPageLoading.value) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 50, right: 50),
              child: Center(child: AppLottieLoading()),
            );
          }

          return Column(
            children: [
              _buildHeader(context, controller),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshData,
                  color: const Color(0xFF004E7E),
                  child: Obx(
                    () => Skeletonizer(
                      enabled: controller.isRefreshing.value,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Device Info :-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF004E7E),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCard(context, controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, DeviceInfoController controller) {
    final title =
        controller.deviceName ?? deviceName ?? starterNumber ?? 'Device Info';

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF004E7E),
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004E7E),
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main card ──────────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, DeviceInfoController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              children: [
                _FieldRow(
                  label: 'Starter Number',
                  value: starterNumber,
                  onCopy: starterNumber != null
                      ? () =>
                          Clipboard.setData(ClipboardData(text: starterNumber!))
                      : null,
                ),
                const _RowDivider(),
                _FieldRow(
                  label: 'PCB Number',
                  value: pcbNumber,
                  onCopy: pcbNumber != null
                      ? () => Clipboard.setData(ClipboardData(text: pcbNumber!))
                      : null,
                ),
                const _RowDivider(),
                _FieldRow(
                  label: 'SIM Number',
                  value: simNumber,
                  onCopy: simNumber != null
                      ? () => Clipboard.setData(ClipboardData(text: simNumber!))
                      : null,
                ),
                const _RowDivider(),
                _FieldRow(
                  label: 'Recharge Expiry',
                  value: simRechargeExpiry,
                  valueColor: _expiryColor(simRechargeExpiry),
                ),
                const _RowDivider(),
                Obx(() => _FieldRow(
                      label: 'Device Location',
                      value: controller.deviceLocation.value,
                      onEdit: starterId != null
                          ? () => controller.showEditLocationSheet(context)
                          : null,
                    )),
                const _RowDivider(),
                _FieldRow(
                  label: 'Test Run Completed',
                  value: _formatDate(testRunDate),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // Photo section
          Obx(() {
            final url = controller.photoUrl.value;
            final hasPhoto = url != null && url.isNotEmpty;
            if (!hasPhoto && starterId == null) return const SizedBox.shrink();
            return Column(
              children: [
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF0F4FA)),
                _buildPhotoSection(context, controller, url),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Photo section ──────────────────────────────────────────────────────────

  Widget _buildPhotoSection(
      BuildContext context, DeviceInfoController controller, String? url) {
    final hasPhoto = url != null && url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Installation Photo',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9090A8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (starterId != null)
                InkWell(
                  onTap: () => controller.pickAndUploadPhoto(context),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 16, color: Color(0xFF004E7E)),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF004E7E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasPhoto)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _FullScreenImageViewer(imageUrl: url),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _photoPlaceholder(withHint: false),
                      errorWidget: (_, __, ___) => _photoPlaceholder(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (starterId != null)
            GestureDetector(
              onTap: () => controller.pickAndUploadPhoto(context),
              child: _photoPlaceholder(tappable: true),
            )
          else
            _photoPlaceholder(),
        ],
      ),
    );
  }

  Widget _photoPlaceholder({bool withHint = true, bool tappable = false}) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: tappable ? const Color(0xFFEAF3FF) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tappable
              ? const Color(0xFF004E7E).withValues(alpha: 0.35)
              : const Color(0xFFCFDFF5),
          width: tappable ? 1.5 : 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tappable ? Icons.add_a_photo_rounded : Icons.add_a_photo_outlined,
            size: 34,
            color: tappable
                ? const Color(0xFF004E7E).withValues(alpha: 0.6)
                : const Color(0xFF94A3B8),
          ),
          if (withHint) ...[
            const SizedBox(height: 6),
            Text(
              tappable ? 'Tap to add a photo' : 'Tap Edit to add a photo',
              style: TextStyle(
                fontSize: 12,
                color: tappable
                    ? const Color(0xFF004E7E).withValues(alpha: 0.6)
                    : const Color(0xFF94A3B8),
                fontWeight: tappable ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _expiryColor(String? date) {
    if (date == null || date.isEmpty) return const Color(0xFF94A3B8);
    try {
      final parts = date.split('/');
      if (parts.length >= 2) {
        final month = int.tryParse(parts[0]) ?? 12;
        final year = int.tryParse(parts[1]) ?? 2099;
        final diff = DateTime(year, month).difference(DateTime.now()).inDays;
        if (diff < 7) return const Color(0xFFE53935);
        if (diff < 30) return const Color(0xFFF59E0B);
      }
    } catch (_) {}
    return const Color(0xFF10B981);
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year  $hour:$min';
    } catch (_) {
      return iso;
    }
  }
}

// ── _FieldRow ──────────────────────────────────────────────────────────────

class _FieldRow extends StatefulWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;

  const _FieldRow({
    required this.label,
    this.value,
    this.valueColor,
    this.onCopy,
    this.onEdit,
  });

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  bool _copied = false;

  void _handleCopy() {
    if (widget.onCopy == null) return;
    setState(() => _copied = true);
    widget.onCopy!();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayValue =
        widget.value?.isNotEmpty == true ? widget.value! : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9090A8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.valueColor ?? const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onEdit != null)
            GestureDetector(
              onTap: widget.onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 15, color: Color(0xFF004E7E)),
              ),
            )
          else if (widget.onCopy != null && widget.value?.isNotEmpty == true)
            GestureDetector(
              onTap: _handleCopy,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _copied
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('check'),
                        size: 18,
                        color: Color(0xFF10B981))
                    : const Icon(Icons.copy_rounded,
                        key: ValueKey('copy'),
                        size: 15,
                        color: Color(0xFFB0B0C0)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Divider between rows ───────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.8, color: Color(0xFFF0F4FA));
  }
}

// ── Full-screen image viewer ───────────────────────────────────────────────

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // iOS only: block the left-edge swipe-back so it doesn't conflict
    // with the InteractiveViewer pan/zoom. The close button still works
    // — Navigator.pop is unconditional, unaffected by canPop. Android
    // keeps its normal system back behaviour.
    return PopScope(
      canPop: !Platform.isIOS,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
