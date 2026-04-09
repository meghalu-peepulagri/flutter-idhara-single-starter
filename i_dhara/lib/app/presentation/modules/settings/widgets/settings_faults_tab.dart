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

/// A single fault row definition: human label, bit value used in the bitwise
/// `pr_flt_en` payload, and a getter that pulls the current value from
/// [UserSettings2] so nothing is hardcoded.
class _FaultDef {
  final String label;
  final int bit;
  final int Function(UserSettings2 s) read;
  final bool isVisible;
  final int uiOrder;
  const _FaultDef(this.label, this.bit, this.read,
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
  static final List<_FaultDef> _defs = [
    _FaultDef('Under Voltage', 1, (s) => s.vfltUnderVoltage ?? 0, uiOrder: 2),
    _FaultDef('Over Voltage', 2, (s) => s.vfltOverVoltage ?? 0, uiOrder: 3),
    _FaultDef('Voltage Imbalance', 4, (s) => s.vfltVoltageImbalance ?? 0,
        isVisible: false, uiOrder: 99),
    _FaultDef('Phase Failure', 8, (s) => s.vfltPhaseFailure ?? 0, uiOrder: 1),
    _FaultDef('Dry Run', 16, (s) => s.cfltDryRun ?? 0, uiOrder: 4),
    _FaultDef('Over Current', 32, (s) => s.cfltOverCurrent ?? 0, uiOrder: 5),
    _FaultDef('Output Phase Failure', 64, (s) => s.cfltOutputPhaseFail ?? 0,
        uiOrder: 6),
    _FaultDef('Current Imbalance', 128, (s) => s.cfltCurrImbalance ?? 0,
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
    _initialValues = List<bool>.generate(
      _defs.length,
      (i) => s == null ? false : _defs[i].read(s) == 1,
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
    await showDeviceSettingConfirmDialog(
      context,
      title: 'Update Fault Settings',
      message: 'Are you sure you want to save the fault settings?',
      svgPath: 'assets/images/default_settings.svg',
      yesText: 'Confirm',
      onConfirm: _publishFaults,
    );
    _isDialogShowing = false;

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
                          _buildFaultsCard(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        AnimatedBuilder(
          animation: _mergedSwitches ?? Listenable.merge(_controllers),
          builder: (context, _) {
            return SettingsActionButtons(
              isActive: _hasChanges,
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

  Widget _buildFaultsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27AE60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          ..._buildRows(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F7EE),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.toggle_on_outlined,
            color: Color(0xFF27AE60),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Enable & Disable Faults',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF27AE60),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];

    final indices = List.generate(_defs.length, (i) => i);
    indices.sort((a, b) => _defs[a].uiOrder.compareTo(_defs[b].uiOrder));

    for (int i in indices) {
      if (_defs[i].isVisible) {
        rows.add(_buildRow(i));
      }
    }
    return rows;
  }

  Widget _buildRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _defs[index].label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _controllers[index],
            builder: (context, isOn, _) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controllers[index].value = !isOn;
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
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
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
    );
  }
}
