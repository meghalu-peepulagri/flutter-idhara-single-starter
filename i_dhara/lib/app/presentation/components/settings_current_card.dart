import 'dart:math' as math; // Add for min/max

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
    this.onChanged,
  });

  final Function(double, double)? onChanged;

  @override
  State<SettingsCurrentCard> createState() => SettingsCurrentCardState();
}

class SettingsCurrentCardState extends State<SettingsCurrentCard> {
  final SettingsController controller = Get.find<SettingsController>();
  late double lowCurrentValue;
  late double highCurrentValue;
  int _resetVersion = 0;
  final GlobalKey<SettingsDualSliderState> _sliderKey = GlobalKey();

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

    lowCurrentValue = widget.initialLowCurrent.clamp(lowMin, lowMax);
    highCurrentValue = widget.initialHighCurrent.clamp(highMin, highMax);
  }

  void resetValues() {
    setState(() {
      _resetVersion++;
      _initializeValues();
      // Need to recreate the GlobalKey when resetting
      // _sliderKey = GlobalKey();
    });
  }

  Map<String, double> getValues() {
    return {
      'low': lowCurrentValue,
      'high': highCurrentValue,
    };
  }

  Map<String, double>? getCalculatedValues() {
    return _sliderKey.currentState?.getCalculatedValues();
  }

  @override
  Widget build(BuildContext context) {
    final lowMin = controller.data.value?.drfMin?.toDouble() ?? 0.0;
    final lowMax = controller.data.value?.drfMax?.toDouble() ?? 100.0;
    final highMin = controller.data.value?.olfMin?.toDouble() ?? 0.0;
    final highMax = controller.data.value?.olfMax?.toDouble() ?? 100.0;

    // Compute global min/max for the track (union of both ranges)
    final globalMin = math.min(lowMin, highMin);
    final globalMax = math.max(lowMax, highMax);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        SettingsDualSlider(
          key: _sliderKey,
          heading: 'Current Faults',
          leadingSvg: 'assets/images/Current.svg',
          // leadingSvgBgColor: const Color(0xFFFFF3E0),
          // leadingSvgColor: const Color(0xFFFF6F00),
          initialLowValue: lowCurrentValue,
          initialHighValue: highCurrentValue,
          minLimit: globalMin, // Updated: global min
          maxLimit: globalMax, // Updated: global max
          lowMinLimit: lowMin,
          lowMaxLimit: lowMax,
          highMinLimit: highMin,
          highMaxLimit: highMax,
          unit: ' A',
          lowColor: const Color(0XFF9F0712),
          highColor: const Color(0XFF9F0712),
          lowThumbColor: const Color(0XFF9F0712),
          highThumbColor: const Color(0XFF9F0712),
          safetyMargin: 2.0, // Current: 2A margin for red zone
          cardType: 'current',
          onChanged: (low, high) {
            lowCurrentValue = low;
            highCurrentValue = high;
            widget.onChanged?.call(low, high);
          },
        ),
      ],
    );
  }
}
