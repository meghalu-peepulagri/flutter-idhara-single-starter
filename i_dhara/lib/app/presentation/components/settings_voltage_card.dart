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
  });

  @override
  State<SettingsVoltageCard> createState() => SettingsVoltageCardState();
}

class SettingsVoltageCardState extends State<SettingsVoltageCard> {
  final SettingsController controller = Get.find<SettingsController>();
  late double lowVoltageValue;
  late double highVoltageValue;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    final lowMin = controller.data?.dvcFltLvfMin?.toDouble() ?? 150.0;
    final lowMax = controller.data?.dvcFltLvfMax?.toDouble() ?? 300.0;
    final highMin = controller.data?.dvcFltHvfMin?.toDouble() ?? 240.0;
    final highMax = controller.data?.dvcFltHvfMax?.toDouble() ?? 550.0;

    lowVoltageValue = widget.initialLowVoltage.clamp(lowMin, lowMax);
    highVoltageValue = widget.initialHighVoltage.clamp(highMin, highMax);
  }

  void resetValues() {
    setState(() {
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
    final lowMin = controller.data?.dvcFltLvfMin?.toDouble() ?? 150.0;
    final lowMax = controller.data?.dvcFltLvfMax?.toDouble() ?? 300.0;
    final highMin = controller.data?.dvcFltHvfMin?.toDouble() ?? 240.0;
    final highMax = controller.data?.dvcFltHvfMax?.toDouble() ?? 550.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        SettingsDualSlider(
          heading: 'Voltage',
          initialLowValue: lowVoltageValue,
          initialHighValue: highVoltageValue,
          minLimit: lowMin, // Default min (when no thumb is active)
          maxLimit: highMax, // Default max (when no thumb is active)
          lowMinLimit: lowMin, // Min for low voltage thumb
          lowMaxLimit: lowMax, // Max for low voltage thumb
          highMinLimit: highMin, // Min for high voltage thumb
          highMaxLimit: highMax, // Max for high voltage thumb
          unit: 'V',
          lowColor: const Color(0xFFE53935),
          highColor: const Color(0xFFFF6F00),
          lowThumbColor: const Color(0xFFE53935),
          highThumbColor: const Color(0xFFFF6F00),
          onChanged: (low, high) {
            lowVoltageValue = low;
            highVoltageValue = high;
          },
        ),
      ],
    );
  }
}
