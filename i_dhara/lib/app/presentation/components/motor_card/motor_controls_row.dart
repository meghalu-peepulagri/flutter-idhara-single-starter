import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

class MotorControlsRow extends StatefulWidget {
  final Motor motor;
  final MotorData? motorData;
  final ValueNotifier<bool> switchController;
  final ValueNotifier<int> modeController;
  final Function(bool) onToggleSwitch;
  final Function(int) onModeChange;
  final bool isSwitchDisabled;
  final bool isModeDisabled;
  final VoidCallback? onNavigateToDetails;
  final VoidCallback? onScheduleTap;

  const MotorControlsRow({
    super.key,
    required this.motor,
    required this.motorData,
    required this.switchController,
    required this.modeController,
    required this.onToggleSwitch,
    required this.onModeChange,
    required this.isSwitchDisabled,
    required this.isModeDisabled,
    this.onNavigateToDetails,
    this.onScheduleTap,
  });

  @override
  State<MotorControlsRow> createState() => _MotorControlsRowState();
}

class _MotorControlsRowState extends State<MotorControlsRow> {
  Timer? _runtimeTimer;

  @override
  void initState() {
    super.initState();
    _startRuntimeTimer();
  }

  @override
  void dispose() {
    _runtimeTimer?.cancel();
    super.dispose();
  }

  /// Periodic timer to refresh the elapsed runtime display every 60 seconds
  void _startRuntimeTimer() {
    _runtimeTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: widget.onNavigateToDetails,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: widget.modeController,
                  builder: (context, modeIndex, _) {
                    final isAuto = modeIndex == 1;
                    final isSchedule = modeIndex == 2;
                    final String modeText =
                        isSchedule ? 'Schedule' : (isAuto ? 'Auto' : 'Manual');
                    final Color chipColor = isSchedule
                        ? const Color(0xFF8B5CF6)
                        : (isAuto
                            ? const Color(0xFFFFA500)
                            : const Color(0xFF2F80ED));

                    return Container(
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          8.0, 4.0, 8.0, 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            modeText,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  color: Colors.white,
                                  fontSize: 14.0,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // const Expanded(child: SizedBox(height: 25)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusInfo(),
          ),
          const SizedBox(width: 8),
          // GestureDetector(
          //   onTap: widget.onScheduleTap ?? widget.onNavigateToDetails,
          //   behavior: HitTestBehavior.opaque,
          //   child: Container(
          //     width: 30,
          //     height: 30,
          //     decoration: BoxDecoration(
          //       color: const Color(0xFF2F80ED).withValues(alpha: 0.12),
          //       borderRadius: BorderRadius.circular(8.0),
          //     ),
          //     child: const Icon(
          //       Icons.schedule,
          //       size: 18,
          //       color: Color(0xFF2F80ED),
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 12),
          ValueListenableBuilder(
            valueListenable: widget.modeController,
            builder: (context, modeIndex, _) {
              return ValueListenableBuilder(
                valueListenable: widget.switchController,
                builder: (context, isOn, child) {
                  return GestureDetector(
                    onTap: !widget.isSwitchDisabled
                        ? () => widget.onToggleSwitch(!isOn)
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Opacity(
                        opacity: !widget.isSwitchDisabled ? 1.0 : 0.4,
                        child: AdvancedSwitch(
                          key: ValueKey('switch_${widget.motor.id}_$isOn'),
                          controller: widget.switchController,
                          initialValue: isOn,
                          activeColor: Colors.green,
                          inactiveColor: Colors.red.shade500,
                          activeChild: const Text(
                            'ON',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          inactiveChild: const Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(15)),
                          width: 55,
                          height: 25,
                          enabled: !widget.isSwitchDisabled,
                          disabledOpacity: 0.9,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    // Priority 1: Fault description (live data takes precedence over API)
    final int liveFault = widget.motorData?.fault ?? 0;
    final starterParams = widget.motor.starter?.starterParameters;
    final int apiFault = (starterParams != null && starterParams.isNotEmpty)
        ? (starterParams.first.fault ?? 0)
        : 0;
    final bool isFaultCleared =
        starterParams?.firstOrNull?.faultCleared == true;

    // Use live fault if live data has been received, otherwise API fault
    final int effectiveFault =
        (widget.motorData?.hasReceivedLiveData == true) ? liveFault : apiFault;

    if (effectiveFault != 0 && !isFaultCleared) {
      final faultDescriptions =
          MotorData.decodeFaultDescriptions(effectiveFault);
      final faultText = faultDescriptions.isNotEmpty
          ? faultDescriptions.join(', ')
          : 'Fault detected';

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFDB3B2A), size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              faultText,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDB3B2A),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Priority 2: Runtime from live data state tracking
    if (widget.motorData != null &&
        widget.motorData!.hasReceivedData &&
        widget.motorData!.stateChangedAt != null) {
      final isOn = widget.motorData!.state == 1;
      final stateLabel = isOn ? 'ON' : 'OFF';
      final elapsed =
          DateTime.now().difference(widget.motorData!.stateChangedAt!);
      final duration = _formatElapsedDuration(elapsed);

      return Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Last activity: $stateLabel',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'since $duration',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Priority 3: Runtime from API
    final runtime = widget.motor.runtime;
    if (runtime != null &&
        runtime.lastState != null &&
        runtime.stateDuration != null) {
      final isOn = runtime.lastState?.toUpperCase() == 'ON';
      final stateLabel = isOn ? 'ON' : 'OFF';
      final duration = _formatDuration(runtime.stateDuration!);

      return Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Last activity: $stateLabel',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'since $duration',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Nothing to show
    return const SizedBox.shrink();
  }

  /// Format elapsed Duration into human-readable string (e.g., "0h 1 min")
  String _formatElapsedDuration(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    return '${hours}h $minutes min';
  }

  /// Parses duration like "1583 h 45 m 43 sec" and returns "1583h 45 min"
  String _formatDuration(String raw) {
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(raw);
    final minMatch = RegExp(r'(\d+)\s*m(?!a)').firstMatch(raw);

    final hours = hourMatch?.group(1) ?? '0';
    final minutes = minMatch?.group(1) ?? '0';
    return '${hours}h $minutes min';
  }
}
