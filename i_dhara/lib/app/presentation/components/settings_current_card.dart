import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/presentation/components/settings_slider_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';

class SettingsCurrentCard extends StatefulWidget {
  final double initialLowCurrent;
  final double initialHighCurrent;
  final String motorName;
  final String motorHp;

  const SettingsCurrentCard({
    super.key,
    this.initialLowCurrent = 180.0,
    this.initialHighCurrent = 280.0,
    this.motorName = 'Pump 1',
    this.motorHp = '3 HP',
  });

  @override
  State<SettingsCurrentCard> createState() => SettingsCurrentCardState();
}

class SettingsCurrentCardState extends State<SettingsCurrentCard> {
  final SettingsController controller = Get.find<SettingsController>();
  late double lowCurrentValue;
  late double highCurrentValue;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    final lowMin = controller.data.value?.drfMin?.toDouble() ?? 0.0;
    final lowMax = controller.data.value?.drfMax?.toDouble() ?? 100.0;
    final highMin = controller.data.value?.olfMin?.toDouble() ?? 0.0;
    final highMax = controller.data.value?.olfMax?.toDouble() ?? 100.0;
    print(
        "line  40 ----------------------> $lowMin $lowMax  $highMin $highMax");

    lowCurrentValue = widget.initialLowCurrent.clamp(lowMin, lowMax);
    highCurrentValue = widget.initialHighCurrent.clamp(highMin, highMax);

    print("line 46 --------------> $lowCurrentValue  $highCurrentValue");
  }

  void resetValues() {
    setState(() {
      _initializeValues();
    });
  }

  Map<String, double> getValues() {
    return {
      'low': lowCurrentValue,
      'high': highCurrentValue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final lowMin = controller.data.value?.drfMin?.toDouble() ?? 0.0;
    final lowMax = controller.data.value?.drfMax?.toDouble() ?? 100.0;
    final highMin = controller.data.value?.olfMin?.toDouble() ?? 0.0;
    final highMax = controller.data.value?.olfMax?.toDouble() ?? 100.0;

    print(
        "line  68 ----------------------> $lowMin $lowMax  $highMin $highMax");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        SettingsDualSlider(
          heading: 'Current Faults',
          leadingSvg: 'assets/images/Current.svg',
          // leadingSvgBgColor: const Color(0xFFFFF3E0),
          // leadingSvgColor: const Color(0xFFFF6F00),
          initialLowValue: lowCurrentValue,
          initialHighValue: highCurrentValue,
          minLimit: lowMin,
          maxLimit: highMax,
          lowMinLimit: lowMin,
          lowMaxLimit: lowMax,
          highMinLimit: highMin,
          highMaxLimit: highMax,
          unit: 'A',
          lowColor: const Color(0xFFE53935),
          highColor: const Color(0xFFFF6F00),
          lowThumbColor: const Color(0xFFE53935),
          highThumbColor: const Color(0xFFFF6F00),
          onChanged: (low, high) {
            lowCurrentValue = low;
            highCurrentValue = high;
          },
        ),
      ],
    );
  }
}
