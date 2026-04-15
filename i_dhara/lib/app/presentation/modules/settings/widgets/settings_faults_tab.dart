import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/models/settings/user_setting_limits2_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/popups/default_setting_popup.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';
import 'package:i_dhara/app/presentation/modules/settings/widgets/settings_action_buttons.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A single fault row definition: human label and the bit value used in the
/// bitwise `pr_flt_en` payload. The ON/OFF state of each toggle is derived
/// entirely from `pr_flt_en` via bitwise AND with [bit].
class _FaultDef {
  final String label;
  final String description;
  final String offDescription;
  final int bit;
  final bool isVisible;
  final int uiOrder;
  const _FaultDef(
      this.label, this.description, this.offDescription, this.bit,
      {this.isVisible = true, this.uiOrder = 99});
}

class SettingsFaultsTab extends StatefulWidget {
  final UserSettings2? settings;
  final String motorName;
  final String motorHp;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final MqttService mqttService;
  final String pcbNumber;

  const SettingsFaultsTab({
    super.key,
    required this.settings,
    required this.motorName,
    required this.motorHp,
    required this.isRefreshing,
    required this.onRefresh,
    required this.mqttService,
    required this.pcbNumber,
  });

  @override
  State<SettingsFaultsTab> createState() => _SettingsFaultsTabState();
}

class _SettingsFaultsTabState extends State<SettingsFaultsTab> {
  // Order here is the order shown on screen.
  // Bit values match the device contract for `pr_flt_en`.
  static const List<_FaultDef> _defs = [
    _FaultDef(
        'Under Voltage',
        'Stops the motor when the voltage drops below safe limits.',
        'Motor will run even if voltage drops below safe limits, which may cause damage.',
        1,
        uiOrder: 2),
    _FaultDef(
        'Over Voltage',
        'Stops the motor when the voltage spikes above safe limits.',
        'Motor will run even if voltage spikes above safe limits, which may cause damage.',
        2,
        uiOrder: 3),
    _FaultDef('Voltage Imbalance', '', '', 4,
        isVisible: false, uiOrder: 99),
    _FaultDef(
        'Phase Failure',
        'Stops the motor if the incoming power supply loses a phase.',
        'Motor won\'t stop if a phase is lost, which can lead to overheating and damage.',
        8,
        uiOrder: 1),
    _FaultDef(
        'Dry Run',
        'Stops the pump if there is no water to prevent damage.',
        'Pump will keep running even without water, which could result in severe damage.',
        16,
        uiOrder: 4),
    _FaultDef(
        'Over Current',
        'Stops the motor if it draws excessive load current.',
        'Motor will not be protected against drawing excessive current, risking failure.',
        32,
        uiOrder: 5),
    _FaultDef(
        'Output Phase Failure',
        'Stops the motor if the connection to the motor is lost.',
        'Motor will not stop if the connection to the motor is lost, which may cause issue.',
        64,
        uiOrder: 6),
    _FaultDef('Current Imbalance', '', '', 128,
        isVisible: false, uiOrder: 99),
  ];

  late List<ValueNotifier<bool>> _controllers;
  late List<bool> _initialValues;

  Listenable? _mergedSwitches;

  StreamSubscription<Map<String, dynamic>>? _mqttStreamSubscription;
  Timer? _settingsAckTimer;
  bool _hasPendingSave = false;
  bool _isSnackbarShown = false;
  bool _isReloading = false;

  Completer<bool>? _ackCompleter;

  bool _isDialogShowing = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _controllers = const [];
    _hydrate();

    _mqttStreamSubscription =
        widget.mqttService.settingstream.listen(_onSettingsAck);
    widget.mqttService.commandStatusNotifier
        .addListener(_onCommandStatusChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsFaultsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _hydrate();
    }
  }

  @override
  void dispose() {
    // Resolve any in-flight ack future so awaiters unwind cleanly.
    final completer = _ackCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
    _ackCompleter = null;
    _settingsAckTimer?.cancel();
    _mqttStreamSubscription?.cancel();
    widget.mqttService.commandStatusNotifier
        .removeListener(_onCommandStatusChanged);
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate() {
    // Tear down any previous controllers before re-creating them.
    for (final c in _controllers) {
      c.dispose();
    }

    final s = widget.settings;
    final prFltEn = s?.prFltEn ?? 0;
    _initialValues = List<bool>.generate(
      _defs.length,
      (i) => s == null ? false : (prFltEn & _defs[i].bit) != 0,
    );
    _controllers = List<ValueNotifier<bool>>.generate(
      _defs.length,
      (i) => ValueNotifier<bool>(_initialValues[i]),
    );
    _mergedSwitches = Listenable.merge(_controllers);
  }

  bool get _hasChanges {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].value != _initialValues[i]) return true;
    }
    return false;
  }

  /// Compute the bitwise `pr_flt_en` value from the current toggle states.
  int _computePrFltEn() {
    int value = 0;
    for (int i = 0; i < _defs.length; i++) {
      if (_controllers[i].value) value |= _defs[i].bit;
    }
    return value;
  }

  void _handleCancel() {
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].value = _initialValues[i];
    }
  }

  void _handleSave() async {
    _isDialogShowing = true;
    _isCancelled = false;
    bool isConfirmed = false;

    await showDeviceSettingConfirmDialog(
      context,
      title: 'Update Fault Settings',
      message: 'Are you sure you want to save the fault settings?',
      svgPath: 'assets/images/default_settings.svg',
      yesText: 'Confirm',
      onConfirm: () async {
        isConfirmed = true;
        await _publishFaults();
      },
    );
    _isDialogShowing = false;

    if (!isConfirmed) {
      if (mounted) _handleCancel();
    }

    if (_hasPendingSave || _ackCompleter != null) {
      _isCancelled = true;
      _resolveAck(false);
      widget.mqttService.cancelPendingSettingsCommand();
    }
  }

  Future<void> _publishFaults() async {
    final pcb = widget.pcbNumber;
    if (pcb.isEmpty) {
      _popDialog();
      geterrorSnackBar('Device not available');
      return;
    }

    final controller = Get.find<SettingsController>();
    final prFltEn = _computePrFltEn();

    controller.updateSettingDto['vflt_under_voltage'] =
        _controllers[0].value ? 1 : 0;
    controller.updateSettingDto['vflt_over_voltage'] =
        _controllers[1].value ? 1 : 0;
    controller.updateSettingDto['vflt_voltage_imbalance'] =
        _controllers[2].value ? 1 : 0;
    controller.updateSettingDto['vflt_phase_failure'] =
        _controllers[3].value ? 1 : 0;
    controller.updateSettingDto['cflt_dry_run'] = _controllers[4].value ? 1 : 0;
    controller.updateSettingDto['cflt_over_current'] =
        _controllers[5].value ? 1 : 0;
    controller.updateSettingDto['cflt_output_phase_fail'] =
        _controllers[6].value ? 1 : 0;
    controller.updateSettingDto['cflt_curr_imbalance'] =
        _controllers[7].value ? 1 : 0;
    controller.updateSettingDto['pr_flt_en'] = prFltEn;

    // ── Step 1: POST API (reuses existing controller method) ─────────────
    _isSnackbarShown = false;
    final priorErrorMessage = controller.errorMessage.value;
    try {
      await controller.fetchupdateSettings();
    } catch (_) {
      _popDialog();
      if (!_isSnackbarShown) {
        _isSnackbarShown = true;
        geterrorSnackBar('Failed to update fault settings');
      }
      return;
    }
    final postFailed = controller.errorMessage.value != priorErrorMessage &&
        controller.errorMessage.value.isNotEmpty;
    if (postFailed) {
      _popDialog();
      if (!_isSnackbarShown) {
        _isSnackbarShown = true;
        geterrorSnackBar('Failed to update fault settings');
      }
      return;
    }

    // ── Step 2: MQTT publish + wait for ack ───────────────────────────────
    final payload = {
      "dvc_c": {"pr_flt_en": prFltEn},
    };

    final completer = Completer<bool>();
    _ackCompleter = completer;
    _hasPendingSave = true;

    try {
      await widget.mqttService.publishUpdateSettings(pcb, payload);
    } catch (_) {
      _resolveAck(false);
      _popDialog();
      _hasPendingSave = false;
      _ackCompleter = null;
      if (!_isSnackbarShown) {
        _isSnackbarShown = true;
        geterrorSnackBar('Failed to send to device');
      }
      return;
    }

    _startAckTimer();
    final success = await completer.future;

    _settingsAckTimer?.cancel();
    _hasPendingSave = false;
    _ackCompleter = null;

    if (_isCancelled) {
      if (mounted) _handleCancel();
      return;
    }

    _popDialog();

    // ── Step 3: Hit PATCH ack + Reload only the faults tab body via GET ───────
    if (success) {
      if (!_isSnackbarShown) {
        _isSnackbarShown = true;
        getsuccessSnackBar('Fault settings updated successfully');
      }
      if (mounted) {
        setState(() => _isReloading = true);
      }
      try {
        await controller.fetchupdateSettingsAck();
      } finally {
        if (mounted) {
          setState(() => _isReloading = false);
        }
      }
    } else {
      if (!_isSnackbarShown) {
        _isSnackbarShown = true;
        geterrorSnackBar('Device not responding');
      }
      if (mounted) _handleCancel();
    }
  }

  /// Pop the confirm dialog if it is still on top.
  void _popDialog() {
    if (!mounted) return;
    if (_isDialogShowing) {
      _isDialogShowing = false;
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
    }
  }

  /// Complete the pending ack future once and only once.
  void _resolveAck(bool success) {
    final completer = _ackCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  // ─── ACK / Timer ──────────────────────────────────────────────────────────

  void _startAckTimer() {
    _settingsAckTimer?.cancel();
    _settingsAckTimer = Timer(const Duration(seconds: 15), _onAckTimeout);
  }

  void _onAckTimeout() {
    if (!mounted || !_hasPendingSave) return;
    _resolveAck(false);
  }

  void _onSettingsAck(Map<String, dynamic> data) {
    if (!mounted) return;
    final type = data["D"];
    final topic = data["topic"];
    if (topic != widget.pcbNumber) return;
    if (!_hasPendingSave) return;

    if (type == 1) {
      _resolveAck(true);
    } else if (type == 0) {
      _resolveAck(false);
    }
  }

  void _onCommandStatusChanged() {
    if (!mounted || !_hasPendingSave) return;
    final message = widget.mqttService.commandStatusNotifier.value;
    if (message == null) return;
    // Only react to messages relating to device settings retry exhaustion.
    if (!message.toLowerCase().contains('device settings')) return;

    _resolveAck(false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isReloading
              ? const Padding(
                  padding: EdgeInsets.only(right: 50),
                  child: Center(child: AppLottieLoading()),
                )
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: Skeletonizer(
                    enabled: widget.isRefreshing,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._buildFaultCards(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        AnimatedBuilder(
          animation: _mergedSwitches ?? Listenable.merge(_controllers),
          builder: (context, _) {
            if (_isReloading || !_hasChanges) {
              return const SizedBox.shrink();
            }
            return SettingsActionButtons(
              isActive: true,
              isFlcOutOfRange: false,
              hasStarter: widget.settings?.starter != null,
              onCancel: _handleCancel,
              onSave: _handleSave,
            );
          },
        ),
      ],
    );
  }

  Widget _buildMotorHeader() {
    return Row(
      children: [
        Text(
          widget.motorName,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF000000),
            fontSize: 16.0,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${widget.motorHp} HP',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w400,
            color: const Color(0xFF000000),
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  // ─── Per-fault card icons ──────────────────────────────────────────────────

  IconData _faultIcon(String label) {
    switch (label) {
      case 'Phase Failure':
        return Icons.bolt_outlined;
      case 'Under Voltage':
        return Icons.battery_alert_outlined;
      case 'Over Voltage':
        return Icons.flash_on_outlined;
      case 'Dry Run':
        return Icons.water_drop_outlined;
      case 'Over Current':
        return Icons.electric_meter_outlined;
      case 'Output Phase Failure':
        return Icons.electrical_services_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  // ─── Build one card per fault ──────────────────────────────────────────────

  List<Widget> _buildFaultCards() {
    final cards = <Widget>[];

    final indices = List.generate(_defs.length, (i) => i);
    indices.sort((a, b) => _defs[a].uiOrder.compareTo(_defs[b].uiOrder));

    for (int i in indices) {
      if (_defs[i].isVisible) {
        cards.add(_buildFaultCard(i));
        cards.add(const SizedBox(height: 10));
      }
    }
    return cards;
  }

  Widget _buildFaultCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left icon ──────────────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _faultIcon(_defs[index].label),
              size: 26,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 12),
          // ── Right content ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row + toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _defs[index].label,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: _controllers[index],
                      builder: (context, isOn, _) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            if (!isOn && _defs[index].description.isNotEmpty) {
                              final bool? result =
                                  await showDeviceSettingConfirmDialog(
                                context,
                                title: 'Enable ${_defs[index].label}',
                                message: _defs[index].description,
                                yesText: 'Enable',
                                showIcon: false,
                                onConfirm: () {
                                  Navigator.pop(context, true);
                                },
                              );
                              if (result == true) {
                                _controllers[index].value = true;
                              }
                            } else if (isOn &&
                                _defs[index].offDescription.isNotEmpty) {
                              final bool? result =
                                  await showDeviceSettingConfirmDialog(
                                context,
                                title: 'Disable ${_defs[index].label}',
                                message: _defs[index].offDescription,
                                yesText: 'Disable',
                                showIcon: false,
                                onConfirm: () {
                                  Navigator.pop(context, true);
                                },
                              );
                              if (result == true) {
                                _controllers[index].value = false;
                              }
                            } else {
                              _controllers[index].value = !isOn;
                            }
                          },
                          child: AbsorbPointer(
                            absorbing: true,
                            child: AdvancedSwitch(
                              key: ValueKey('fault_switch_${index}_$isOn'),
                              controller: _controllers[index],
                              initialValue: isOn,
                              activeColor: const Color(0xFF27AE60),
                              inactiveColor: const Color(0xFFBDBDBD),
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
                              height: 26,
                              enabled: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // ON description chip
                if (_defs[index].description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ON:',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: ' ${_defs[index].description}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // OFF description chip
                if (_defs[index].offDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OFF:',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9F1239),
                              ),
                            ),
                          ),
                        ),
                        TextSpan(
                          text: ' ${_defs[index].offDescription}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
