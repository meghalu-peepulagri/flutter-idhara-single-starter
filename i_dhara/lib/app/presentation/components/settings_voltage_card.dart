import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/components/settings_slider_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';

class SettingsVoltageCard extends StatefulWidget {
  final double initialLowVoltage;
  final double initialHighVoltage;
  final String motorName;
  final String motorHp;

  const SettingsVoltageCard({
    super.key,
    this.initialLowVoltage = 180.0,
    this.initialHighVoltage = 280.0,
    this.motorName = 'Pump 1',
    this.motorHp = '3 HP',
    this.onChanged,
  });

  final Function(double, double)? onChanged;

  @override
  State<SettingsVoltageCard> createState() => SettingsVoltageCardState();
}

class SettingsVoltageCardState extends State<SettingsVoltageCard> {
  final SettingsController controller = Get.find<SettingsController>();
  late double lowVoltageValue;
  late double highVoltageValue;
  int _resetVersion = 0;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    final lowMin = controller.data.value?.lvfMin?.toDouble() ?? 150.0;
    final lowMax = controller.data.value?.lvfMax?.toDouble() ?? 300.0;
    final highMin = controller.data.value?.hvfMin?.toDouble() ?? 240.0;
    final highMax = controller.data.value?.hvfMax?.toDouble() ?? 550.0;

    // Read directly from controller for most up-to-date values
    final initialLow = controller.userSettings2.value?.lvf?.toDouble() ??
        widget.initialLowVoltage;
    final initialHigh = controller.userSettings2.value?.hvf?.toDouble() ??
        widget.initialHighVoltage;

    lowVoltageValue = initialLow.clamp(lowMin, lowMax);
    highVoltageValue = initialHigh.clamp(highMin, highMax);
  }

  void resetValues() {
    setState(() {
      _resetVersion++;
      _initializeValues();
    });
  }

  Map<String, double> getValues() {
    return {
      'low': lowVoltageValue,
      'high': highVoltageValue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lowMin = controller.data.value?.lvfMin?.toDouble() ?? 150.0;
    final lowMax = controller.data.value?.lvfMax?.toDouble() ?? 300.0;
    final highMin = controller.data.value?.hvfMin?.toDouble() ?? 240.0;
    final highMax = controller.data.value?.hvfMax?.toDouble() ?? 550.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        SettingsDualSlider(
          key: ValueKey("voltage_slider_$_resetVersion"),
          heading: 'Voltage Faults',
          leadingSvg: 'assets/images/Voltage.svg',
          // leadingSvgBgColor: const Color(0xFFFFF3E0),
          // leadingSvgColor: const Color(0xFFFF6F00),
          initialLowValue: lowVoltageValue,
          initialHighValue: highVoltageValue,
          minLimit: lowMin,
          maxLimit: highMax,
          lowMinLimit: lowMin,
          lowMaxLimit: lowMax,
          highMinLimit: highMin,
          highMaxLimit: highMax,
          unit: ' V',
          lowColor: const Color(0XFF9F0712),
          highColor: const Color(0XFF9F0712),
          lowThumbColor: const Color(0XFF9F0712),
          highThumbColor: const Color(0XFF9F0712),
          safetyMargin: 10.0,
          cardType: 'voltage',
          onChanged: (low, high) {
            lowVoltageValue = low;
            highVoltageValue = high;
            widget.onChanged?.call(low, high);
          },
        ),
      ],
    );
  }
}
