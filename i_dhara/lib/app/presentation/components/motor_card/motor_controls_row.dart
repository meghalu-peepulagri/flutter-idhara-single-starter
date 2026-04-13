import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';

class MotorControlsRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: onNavigateToDetails,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: modeController,
                  builder: (context, modeIndex, _) {
                    final isAuto = modeIndex == 1;
                    final String modeText = isAuto ? 'Auto' : 'Manual';

                    return Container(
                      decoration: BoxDecoration(
                        color: isAuto
                            ? const Color(0xFFFFA500).withValues(alpha: 0.8)
                            : const Color(0xFF2F80ED).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4.0),
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
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusInfo(),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onScheduleTap ?? onNavigateToDetails,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                Icons.schedule,
                size: 18,
                color: Color(0xFF2F80ED),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ValueListenableBuilder(
            valueListenable: modeController,
            builder: (context, modeIndex, _) {
              return ValueListenableBuilder(
                valueListenable: switchController,
                builder: (context, isOn, child) {
                  return GestureDetector(
                    onTap:
                        !isSwitchDisabled ? () => onToggleSwitch(!isOn) : null,
                    behavior: HitTestBehavior.opaque,
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Opacity(
                        opacity: !isSwitchDisabled ? 1.0 : 0.4,
                        child: AdvancedSwitch(
                          key: ValueKey('switch_${motor.id}_$isOn'),
                          controller: switchController,
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
                          enabled: !isSwitchDisabled,
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
    // Priority 1: Fault description
    final starterParams = motor.starter?.starterParameters;
    final hasFault = starterParams != null &&
        starterParams.isNotEmpty &&
        (starterParams.first.fault ?? 0) != 0 &&
        starterParams.first.faultCleared != true;

    if (hasFault) {
      final faultDesc =
          starterParams.first.faultDescription ?? 'Fault detected';
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFDB3B2A), size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              faultDesc,
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

    // Priority 2: Runtime / last activity
    final runtime = motor.runtime;
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

  /// Parses duration like "1583 h 45 m 43 sec" and returns "1583h 45m" (no seconds)
  String _formatDuration(String raw) {
    final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(raw);
    final minMatch = RegExp(r'(\d+)\s*m(?!a)').firstMatch(raw);

    final hours = hourMatch?.group(1);
    final minutes = minMatch?.group(1);

    if (hours != null && minutes != null) {
      return '${hours}h ${minutes}m';
    } else if (hours != null) {
      return '${hours}h';
    } else if (minutes != null) {
      return '${minutes}m';
    }
    return raw.replaceAll(RegExp(r'\d+\s*sec.*'), '').trim();
  }
}
