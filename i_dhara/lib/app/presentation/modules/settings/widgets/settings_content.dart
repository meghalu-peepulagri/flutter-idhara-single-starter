import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/settings/user_setting_limits2_model.dart';
import 'package:i_dhara/app/presentation/components/flc_card.dart';
import 'package:i_dhara/app/presentation/components/settings_current_card.dart';
import 'package:i_dhara/app/presentation/components/settings_multi_motor_current_card.dart';
import 'package:i_dhara/app/presentation/components/settings_voltage_card.dart';
import 'package:i_dhara/app/presentation/components/timing_config_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsContent extends StatefulWidget {
  final GlobalKey<SettingsVoltageCardState> voltageCardKey;
  final GlobalKey<SettingsCurrentCardState> currentCardKey;
  final GlobalKey<FlcCardState> flcCardKey;
  final GlobalKey<TimingConfigCardState>? timingCardKey;
  final GlobalKey<SettingsMultiMotorCurrentCardState>? multiCurrentCardKey;
  final bool isMultiMotor;

  final bool isRefreshing;

  // Card initial values
  final double flcInitialValue;
  final double flcMinValue;
  final double flcMaxValue;
  final double voltageInitialLow;
  final double voltageInitialHigh;
  final double currentInitialLow;
  final double currentInitialHigh;
  final int asDlyInitialValue;
  final int asDlyMinValue;
  final int asDlyMaxValue;
  final String motorName;

  // Callbacks
  final Future<void> Function() onRefresh;
  final ValueChanged<double> onFlcChanged;
  final ValueChanged<bool> onFlcOutOfRange;
  final void Function(double low, double high) onVoltageChanged;
  final void Function(double low, double high) onCurrentChanged;
  final ValueChanged<int>? onAsDlyChanged;
  final ValueChanged<bool>? onAsDlyOutOfRange;
  final ValueChanged<int>? onStartTimeChanged;
  final VoidCallback? onMultiCurrentChanged;

  const SettingsContent({
    super.key,
    required this.voltageCardKey,
    required this.currentCardKey,
    required this.flcCardKey,
    this.timingCardKey,
    this.multiCurrentCardKey,
    this.isMultiMotor = false,
    required this.isRefreshing,
    required this.flcInitialValue,
    required this.flcMinValue,
    required this.flcMaxValue,
    required this.voltageInitialLow,
    required this.voltageInitialHigh,
    required this.currentInitialLow,
    required this.currentInitialHigh,
    this.asDlyInitialValue = 0,
    this.asDlyMinValue = 100,
    this.asDlyMaxValue = 100,
    required this.motorName,
    required this.onRefresh,
    required this.onFlcChanged,
    required this.onFlcOutOfRange,
    required this.onVoltageChanged,
    required this.onCurrentChanged,
    this.onAsDlyChanged,
    this.onAsDlyOutOfRange,
    this.onStartTimeChanged,
    this.onMultiCurrentChanged,
  });

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  int _selectedMotorIdx = 0;
  List<MotorSettingConfig> _multiMotors = const [];

  String _refOfMotor(MotorSettingConfig m, int i) =>
      m.motorReference ?? 'm${m.motorIndex ?? (i + 1)}';

  void _onSelectMotor(int index) {
    final controller = Get.find<SettingsController>();
    if (index < _multiMotors.length) {
      final ref = _refOfMotor(_multiMotors[index], index);
      controller.flc.value =
          controller.motorFlc[ref] ?? (_multiMotors[index].flc ?? 0).toDouble();
    }
    setState(() => _selectedMotorIdx = index);
  }

  Widget _multiFlcCard() {
    final controller = Get.find<SettingsController>();
    final m = _multiMotors[_selectedMotorIdx];
    final ref = _refOfMotor(m, _selectedMotorIdx);
    final flcVal = controller.motorFlc[ref] ?? (m.flc ?? 0).toDouble();
    return FlcCard(
      key: ValueKey('multi_flc_$_selectedMotorIdx'),
      initialValue: flcVal,
      minValue: widget.flcMinValue,
      maxValue: widget.flcMaxValue,
      decimalPlaces: 2,
      step: 0.01,
      onValueChanged: (v) {
        controller.motorFlc[ref] = v;
        controller.flc.value = v;
        widget.onFlcChanged(v);
        widget.onMultiCurrentChanged?.call();
        setState(() {});
      },
      onOutOfRange: widget.onFlcOutOfRange,
    );
  }

  Widget _flcCard() => FlcCard(
        key: widget.flcCardKey,
        initialValue: widget.flcInitialValue,
        minValue: widget.flcMinValue,
        maxValue: widget.flcMaxValue,
        decimalPlaces: 2,
        step: 0.01,
        onValueChanged: widget.onFlcChanged,
        onOutOfRange: widget.onFlcOutOfRange,
      );

  /// Star-delta changeover time. Multi-motor starters only, and only when the
  /// starter reports motor_starter_type STAR_DELTA. Hidden everywhere else.
  Widget _startTimeCard() {
    final controller = Get.find<SettingsController>();
    if (!controller.isMultiMotorDevice || !controller.isStarDelta) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: TimingConfigCard(
        label: 'Star Time',
        initialValue: controller.sdTime.value,
        minValue: controller.sdTimeMin,
        maxValue: controller.sdTimeMax,
        onChanged: (v) {
          controller.sdTime.value = v;
          widget.onStartTimeChanged?.call(v);
        },
        onOutOfRange: widget.onAsDlyOutOfRange,
        hideHeading: true,
      ),
    );
  }

  Widget _voltageCard() => SettingsVoltageCard(
        key: widget.voltageCardKey,
        initialLowVoltage: widget.voltageInitialLow,
        initialHighVoltage: widget.voltageInitialHigh,
        motorName: widget.motorName,
        motorHp: '3 HP',
        onChanged: widget.onVoltageChanged,
      );

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Skeletonizer(
        enabled: widget.isRefreshing,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: widget.isMultiMotor ? _buildMulti() : _buildSingle(),
        ),
      ),
    );
  }

  Widget _buildSingle() {
    return Column(
      children: [
        const SizedBox(height: 10),
        TimingConfigCard(
          key: widget.timingCardKey,
          initialValue: widget.asDlyInitialValue,
          minValue: widget.asDlyMinValue,
          maxValue: widget.asDlyMaxValue,
          onChanged: widget.onAsDlyChanged,
          onOutOfRange: widget.onAsDlyOutOfRange,
          hideHeading: true,
        ),
        const SizedBox(height: 7),
        _voltageCard(),
        const SizedBox(height: 8),
        // FLC sits directly above Current Protection, mirroring _buildMulti.
        _flcCard(),
        const SizedBox(height: 8),
        SettingsCurrentCard(
          key: widget.currentCardKey,
          initialLowCurrent: widget.currentInitialLow,
          initialHighCurrent: widget.currentInitialHigh,
          motorName: widget.motorName,
          motorHp: '3 HP',
          onChanged: widget.onCurrentChanged,
        ),
      ],
    );
  }

  Widget _buildMulti() {
    final motors = Get.find<SettingsController>().motorConfigsForUi();
    _multiMotors = motors;
    if (motors.isNotEmpty && _selectedMotorIdx >= motors.length) {
      _selectedMotorIdx = 0;
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        TimingConfigCard(
          key: widget.timingCardKey,
          initialValue: widget.asDlyInitialValue,
          minValue: widget.asDlyMinValue,
          maxValue: widget.asDlyMaxValue,
          onChanged: widget.onAsDlyChanged,
          onOutOfRange: widget.onAsDlyOutOfRange,
          hideHeading: true,
        ),
        _startTimeCard(),
        const SizedBox(height: 8),
        _voltageCard(),
        const SizedBox(height: 8),
        if (motors.length > 1) ...[
          _buildSelectMotorCard(motors),
          const SizedBox(height: 8),
        ],
        if (motors.isNotEmpty) ...[
          _buildMotorLabel(motors[_selectedMotorIdx]),
          const SizedBox(height: 8),
          _multiFlcCard(),
          const SizedBox(height: 8),
          SettingsMultiMotorCurrentCard(
            key: widget.multiCurrentCardKey,
            onChanged: widget.onMultiCurrentChanged,
            selectedIndex: _selectedMotorIdx,
          ),
        ],
      ],
    );
  }

  String _refOf(MotorSettingConfig m, int i) =>
      (m.motorReference ?? 'm${m.motorIndex ?? (i + 1)}').toUpperCase();

  Widget _buildSelectMotorCard(List<MotorSettingConfig> motors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Motor',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < motors.length; i++)
                _motorRadio(_refOf(motors[i], i), i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _motorRadio(String ref, int index) {
    final selected = index == _selectedMotorIdx;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onSelectMotor(index),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? const Color(0xFF2F80ED) : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              ref,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String name, String hp}) _motorNameHp(MotorSettingConfig m, int i) {
    final motors =
        Get.find<SettingsController>().userSettings2.value?.starter?.motors ??
            const [];
    String? alias;
    String? name;
    String? hp;
    for (final sm in motors) {
      if (sm.id == m.motorId) {
        alias = sm.aliasName?.trim();
        name = sm.name?.trim();
        hp = sm.hp?.toString().trim();
        break;
      }
    }
    final display = (alias != null && alias.isNotEmpty)
        ? alias
        : (name != null && name.isNotEmpty)
            ? name
            : 'Motor ${_refOf(m, i)}';
    return (name: display, hp: hp ?? '');
  }

  Widget _buildMotorLabel(MotorSettingConfig m) {
    final info = _motorNameHp(m, _selectedMotorIdx);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              info.name,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A0A0A),
              ),
            ),
            if (info.hp.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${info.hp} HP',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF62697D),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
