import 'package:flutter/material.dart';
import 'package:i_dhara/app/presentation/components/flc_card.dart';
import 'package:i_dhara/app/presentation/components/settings_current_card.dart';
import 'package:i_dhara/app/presentation/components/settings_voltage_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsContent extends StatelessWidget {
  final GlobalKey<SettingsVoltageCardState> voltageCardKey;
  final GlobalKey<SettingsCurrentCardState> currentCardKey;
  final GlobalKey<FlcCardState> flcCardKey;

  final bool isRefreshing;

  // Card initial values
  final double flcInitialValue;
  final double flcMinValue;
  final double flcMaxValue;
  final double voltageInitialLow;
  final double voltageInitialHigh;
  final double currentInitialLow;
  final double currentInitialHigh;
  final String motorName;

  // Callbacks
  final Future<void> Function() onRefresh;
  final ValueChanged<double> onFlcChanged;
  final ValueChanged<bool> onFlcOutOfRange;
  final void Function(double low, double high) onVoltageChanged;
  final void Function(double low, double high) onCurrentChanged;

  const SettingsContent({
    super.key,
    required this.voltageCardKey,
    required this.currentCardKey,
    required this.flcCardKey,
    required this.isRefreshing,
    required this.flcInitialValue,
    required this.flcMinValue,
    required this.flcMaxValue,
    required this.voltageInitialLow,
    required this.voltageInitialHigh,
    required this.currentInitialLow,
    required this.currentInitialHigh,
    required this.motorName,
    required this.onRefresh,
    required this.onFlcChanged,
    required this.onFlcOutOfRange,
    required this.onVoltageChanged,
    required this.onCurrentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Skeletonizer(
        enabled: isRefreshing,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              FlcCard(
                key: flcCardKey,
                initialValue: flcInitialValue,
                minValue: flcMinValue,
                maxValue: flcMaxValue,
                decimalPlaces: 2,
                step: 0.01,
                onValueChanged: onFlcChanged,
                onOutOfRange: onFlcOutOfRange,
              ),
              const SizedBox(height: 7),
              SettingsVoltageCard(
                key: voltageCardKey,
                initialLowVoltage: voltageInitialLow,
                initialHighVoltage: voltageInitialHigh,
                motorName: motorName,
                motorHp: '3 HP',
                onChanged: onVoltageChanged,
              ),
              const SizedBox(height: 8),
              SettingsCurrentCard(
                key: currentCardKey,
                initialLowCurrent: currentInitialLow,
                initialHighCurrent: currentInitialHigh,
                motorName: motorName,
                motorHp: '3 HP',
                onChanged: onCurrentChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
