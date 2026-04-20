import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_widgets.dart';

void showSimInfoPopup({
  required BuildContext context,
  required String simNumber,
  required String expiryDate,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'SimInfoPopup',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: animation,
          child: _SimInfoDialog(
            simNumber: simNumber,
            expiryDate: expiryDate,
          ),
        ),
      );
    },
  );
}

class _SimInfoDialog extends StatelessWidget {
  final String simNumber;
  final String expiryDate;

  const _SimInfoDialog({
    required this.simNumber,
    required this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final expiryColor = _getExpiryColor(expiryDate);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Device Info',
                        style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF9090A0),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info rows
                  _InfoRow(
                    icon: Icons.sim_card,
                    label: 'SIM Number',
                    value: simNumber,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: simNumber));
                    },
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Recharge Expiry',
                    value: expiryDate,
                    accentColor: expiryColor,
                  ),

                  const SizedBox(height: 20),

                  // OK Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF004E7E),
                                Color(0xFF3686AF),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FFButtonWidget(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            text: 'Got it',
                            options: FFButtonOptions(
                              height: 45.0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              color: Colors.transparent,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Manrope',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    fontWeight: FontWeight.w500,
                                  ),
                              elevation: 0.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSimNumber(String sim) {
    final clean = sim.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  Color _getExpiryColor(String date) {
    try {
      final parts = date.split('/');
      if (parts.length >= 2) {
        final month = int.tryParse(parts[0]) ?? 12;
        final year = int.tryParse(parts[1]) ?? 2099;
        final expiry = DateTime(year, month);
        final now = DateTime.now();
        final diff = expiry.difference(now).inDays;
        if (diff < 7) return const Color(0xFFE53935);
        if (diff < 30) return const Color(0xFFF59E0B);
        return const Color(0xFF10B981);
      }
    } catch (_) {}
    return const Color(0xFF10B981);
  }
}

class _InfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor = const Color(0xFF6C63FF),
    this.onCopy,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 15, color: widget.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFF9090A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.value,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onCopy != null)
            GestureDetector(
              onTap: _handleCopy,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _copied
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('check'),
                        size: 18,
                        color: Color(0xFF10B981),
                      )
                    : const Icon(
                        Icons.copy_rounded,
                        key: ValueKey('copy'),
                        size: 15,
                        color: Color(0xFFB0B0C0),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade700.withOpacity(0.35)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
