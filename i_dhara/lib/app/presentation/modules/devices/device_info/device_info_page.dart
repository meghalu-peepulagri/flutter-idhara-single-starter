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
    final controller = Get.find<DeviceInfoController>();
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Obx(() {
          // Initial load on first open
          if (controller.isInitialLoading.value) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 50, right: 50),
              child: Center(child: AppLottieLoading()),
            );
          }

          // Full-page loading during upload / location save
          if (controller.isPageLoading.value) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 50, right: 50),
              child: Center(child: AppLottieLoading()),
            );
          }

          // Normal content with pull-to-refresh + skeletonizer
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
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: _buildInfoCard(context, controller),
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

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context, DeviceInfoController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    size: 18,
                    color: Color(0xFF004E7E),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Device Info',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004E7E),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F4FA)),
          const SizedBox(height: 4),

          // Info rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Starter Number',
                  value: starterNumber,
                  accentColor: const Color(0xFF6C63FF),
                  onCopy: starterNumber != null
                      ? () =>
                          Clipboard.setData(ClipboardData(text: starterNumber!))
                      : null,
                ),
                _InfoRow(
                  icon: Icons.developer_board_outlined,
                  label: 'PCB Number',
                  value: pcbNumber,
                  accentColor: const Color(0xFF0288D1),
                  onCopy: pcbNumber != null
                      ? () => Clipboard.setData(ClipboardData(text: pcbNumber!))
                      : null,
                ),
                _InfoRow(
                  icon: Icons.sim_card_outlined,
                  label: 'SIM Number',
                  value: simNumber,
                  accentColor: const Color(0xFF6C63FF),
                  onCopy: simNumber != null
                      ? () => Clipboard.setData(ClipboardData(text: simNumber!))
                      : null,
                ),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Recharge Expiry',
                  value: simRechargeExpiry,
                  accentColor: _expiryColor(simRechargeExpiry),
                  valueColor: _expiryColor(simRechargeExpiry),
                ),
                // Device location — reactive + editable
                Obx(() => _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Device Location',
                      value: controller.deviceLocation.value,
                      accentColor: const Color(0xFFEF4444),
                      onEdit: starterId != null
                          ? () => controller.showEditLocationSheet(context)
                          : null,
                    )),
                _InfoRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Test Run Completed Date',
                  value: _formatDate(testRunDate),
                  accentColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          // Installation photo — reactive + editable
          Obx(() {
            final url = controller.photoUrl.value;
            final hasPhoto = url != null && url.isNotEmpty;
            if (!hasPhoto && starterId == null) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF0F4FA)),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
          const SizedBox(height: 8),
          if (hasPhoto)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _FullScreenImageViewer(imageUrl: url),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _photoPlaceholder(withHint: false),
                  errorWidget: (_, __, ___) => _photoPlaceholder(),
                ),
              ),
            )
          else
            _photoPlaceholder(),
        ],
      ),
    );
  }

  Widget _photoPlaceholder({bool withHint = true}) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFCFDFF5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined,
              size: 32, color: Color(0xFF94A3B8)),
          if (withHint) ...[
            const SizedBox(height: 6),
            const Text(
              'Tap Edit to add a photo',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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

// ── _InfoRow ───────────────────────────────────────────────────────────────

class _InfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color accentColor;
  final Color? valueColor;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.accentColor = const Color(0xFF6C63FF),
    this.valueColor,
    this.onCopy,
    this.onEdit,
  });

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 16, color: widget.accentColor),
          ),
          const SizedBox(width: 12),
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
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
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
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined,
                    size: 16, color: Color(0xFF004E7E)),
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

// ── Full-screen image viewer ───────────────────────────────────────────────

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
