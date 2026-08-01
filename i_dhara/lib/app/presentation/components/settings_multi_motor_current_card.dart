import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/data/models/settings/user_setting_limits2_model.dart';
import 'package:i_dhara/app/presentation/components/settings_slider_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';

class SettingsMultiMotorCurrentCard extends StatefulWidget {
  final VoidCallback? onChanged;
  final int selectedIndex;

  const SettingsMultiMotorCurrentCard({
    super.key,
    this.onChanged,
    this.selectedIndex = 0,
  });

  @override
  State<SettingsMultiMotorCurrentCard> createState() =>
      SettingsMultiMotorCurrentCardState();
}

class SettingsMultiMotorCurrentCardState
    extends State<SettingsMultiMotorCurrentCard> {
  final SettingsController controller = Get.find<SettingsController>();
  final Map<String, GlobalKey<SettingsDualSliderState>> _sliderKeys = {};
  final Map<String, double> _low = {};
  final Map<String, double> _high = {};

  List<MotorSettingConfig> get _motors => controller.motorConfigsForUi();

  double _mapLow(num? drf) {
    final v = (drf ?? 0).toDouble();
    return v > 100 ? 100.0 : v;
  }

  double _mapHigh(num? olf) {
    final v = (olf ?? 0).toDouble();
    return v < 100 ? 101.0 : v;
  }

  // Per-motor drf/olf are stored as AMPS; the slider works in percent.
  double _pctFromAmps(num? amps, double flc) {
    final a = (amps ?? 0).toDouble();
    return flc > 0 ? a / flc * 100 : a;
  }

  String _motorLabel(MotorSettingConfig m, String ref) {
    final motors = controller.userSettings2.value?.starter?.motors ?? const [];
    String? alias;
    String? name;
    for (final sm in motors) {
      if (sm.id == m.motorId) {
        alias = sm.aliasName?.trim();
        name = sm.name?.trim();
        break;
      }
    }
    final display = (alias != null && alias.isNotEmpty)
        ? alias
        : (name != null && name.isNotEmpty)
            ? name
            : 'Motor ${m.motorIndex ?? ''}';
    return '$display (${ref.toUpperCase()})';
  }

  void resetValues() {
    setState(() {
      _low.clear();
      _high.clear();
    });
  }

  List<Map<String, dynamic>> getPerMotorValues() {
    final res = <Map<String, dynamic>>[];
    for (final m in _motors) {
      final ref = m.motorReference ?? '';
      if (ref.isEmpty) continue;
      final flcVal = controller.motorFlc[ref] ?? (m.flc ?? 0).toDouble();
      final origFlc = controller.originalMotorFlc(ref);
      final flcChanged = flcVal != origFlc;
      final origLow = _mapLow(_pctFromAmps(m.drf, origFlc));
      final origHigh = _mapHigh(_pctFromAmps(m.olf, origFlc));
      final curLow = _low[ref] ?? origLow;
      final curHigh = _high[ref] ?? origHigh;
      final lowChanged = curLow.round() != origLow.round();
      final highChanged = curHigh.round() != origHigh.round();
      res.add({
        'ref': ref,
        'motorId': m.motorId,
        'label': _motorLabel(m, ref),
        'changed': lowChanged || highChanged || flcChanged,
        'lowChanged': lowChanged,
        'highChanged': highChanged,
        'flcChanged': flcChanged,
        'low': curLow,
        'high': curHigh,
        'calcLow': curLow / 100 * flcVal,
        'calcHigh': curHigh / 100 * flcVal,
        'origCalcLow': (m.drf ?? 0).toDouble(),
        'origCalcHigh': (m.olf ?? 0).toDouble(),
        'flc': flcVal,
      });
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final motors = _motors;
    if (motors.isEmpty) return const SizedBox.shrink();

    final idx = widget.selectedIndex.clamp(0, motors.length - 1);
    final m = motors[idx];

    final lowMin = controller.data.value?.drfMin?.toDouble() ?? 0.0;
    final lowMax = controller.data.value?.drfMax?.toDouble() ?? 100.0;
    final highMin = controller.data.value?.olfMin?.toDouble() ?? 0.0;
    final highMax = controller.data.value?.olfMax?.toDouble() ?? 100.0;
    final globalMin = math.min(lowMin, highMin);
    final globalMax = math.max(lowMax, highMax);

    return _buildMotorSlider(
        m, lowMin, lowMax, highMin, highMax, globalMin, globalMax);
  }

  Widget _buildMotorSlider(
    MotorSettingConfig m,
    double lowMin,
    double lowMax,
    double highMin,
    double highMax,
    double globalMin,
    double globalMax,
  ) {
    final ref = m.motorReference ?? 'm${m.motorIndex ?? ''}';
    final key = _sliderKeys.putIfAbsent(ref, () => GlobalKey());

    final flcVal = controller.motorFlc[ref] ?? (m.flc ?? 0).toDouble();
    final origFlc = controller.originalMotorFlc(ref);
    double low =
        (_low[ref] ?? _mapLow(_pctFromAmps(m.drf, origFlc))).clamp(lowMin, lowMax);
    double high = (_high[ref] ?? _mapHigh(_pctFromAmps(m.olf, origFlc)))
        .clamp(highMin, highMax);
    if (high <= low) high = low + 1.0;

    return SettingsDualSlider(
      key: key,
      heading: 'Current Protection',
      initialLowValue: low,
      initialHighValue: high,
      minLimit: globalMin,
      maxLimit: globalMax,
      lowMinLimit: lowMin,
      lowMaxLimit: lowMax,
      highMinLimit: highMin,
      highMaxLimit: highMax,
      unit: ' A',
      lowColor: const Color(0XFF9F0712),
      highColor: const Color(0XFF9F0712),
      lowThumbColor: const Color(0XFF9F0712),
      highThumbColor: const Color(0XFF9F0712),
      safetyMargin: 2.0,
      cardType: 'current',
      flcOverride: flcVal,
      alignValuesRight: true,
      onChanged: (lowVal, highVal) {
        _low[ref] = lowVal;
        _high[ref] = highVal;
        widget.onChanged?.call();
      },
    );
  }
}
