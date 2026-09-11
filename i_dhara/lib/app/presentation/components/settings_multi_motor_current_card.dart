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
  // The percent the slider showed the FIRST time it rendered for this motor
  // in this Settings visit — i.e. exactly what the "DRY RUN LIMIT" /
  // "OVERLOAD LIMIT" chip showed before any dragging. Set once via
  // putIfAbsent and never overwritten, so the confirm dialog's "old" value
  // stays pinned to what the user actually saw, even when the raw drf/olf
  // field is itself stale/inconsistent with the motor's current FLC.
  final Map<String, double> _sessionOrigLow = {};
  final Map<String, double> _sessionOrigHigh = {};
  // The raw drf/olf amp value the chip actually showed the FIRST time it
  // rendered this visit (see SettingsDualSlider.initialLowAmount /
  // initialHighAmount) — pinned the same way as the percent snapshots above
  // so the confirm dialog's "old" amount matches what was on screen, instead
  // of being recomputed from the truncated whole-percent slider position
  // (which can differ from the raw stored value, e.g. "1.05 A" on screen vs
  // a recomputed "1.03 A" in the dialog).
  final Map<String, double> _sessionOrigLowAmount = {};
  final Map<String, double> _sessionOrigHighAmount = {};

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
    return display;
  }

  void resetValues() {
    setState(() {
      _low.clear();
      _high.clear();
      // _revertLocal() also resets controller.flc right after calling this,
      // which fires the slider's own FLC-change listener — that redraws
      // using whatever percent it still has cached from the user's drag,
      // racing the initialLowValue/initialHighValue prop-diff reset below.
      // Forcing a fresh GlobalKey remounts the slider from scratch (a new
      // initState reading the just-cleared _low/_high above) instead of
      // relying on that ordering to land correctly.
      _sliderKeys.clear();
      _sessionOrigLow.clear();
      _sessionOrigHigh.clear();
      _sessionOrigLowAmount.clear();
      _sessionOrigHighAmount.clear();
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
      // Fall back to a fresh computation only if this motor's slider was
      // never actually built this visit (e.g. the other motor was selected
      // the whole time) — otherwise reuse the pinned session snapshot.
      final origLow = _sessionOrigLow[ref] ?? _mapLow(_pctFromAmps(m.drf, origFlc));
      final origHigh =
          _sessionOrigHigh[ref] ?? _mapHigh(_pctFromAmps(m.olf, origFlc));
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
        // Truncate to the whole percent the slider chip actually displays
        // (e.g. "37%") before converting to amps — curLow/curHigh are the
        // raw, un-truncated drag position, so using them directly here
        // published a slightly different amp value than what was shown on
        // screen (e.g. 1.87 A published for a chip that read "1.85 A").
        'calcLow': curLow.toInt() / 100 * flcVal,
        'calcHigh': curHigh.toInt() / 100 * flcVal,
        // The confirm dialog's "old" amount must match what the slider chip
        // actually showed as the current value — the pinned session percent
        // converted through origFlc — not the raw drf/olf field. Raw
        // drf/olf can be stale/inconsistent with the motor's current FLC
        // (e.g. left over from before FLC was last changed), which made the
        // old amp-based display show numbers with no relation to the screen
        // (e.g. "49.00 A" for a motor the screen showed as "2.00 A").
        'origCalcLow':
            _sessionOrigLowAmount[ref] ?? (m.drf ?? 0).toDouble(),
        'origCalcHigh':
            _sessionOrigHighAmount[ref] ?? (m.olf ?? 0).toDouble(),
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
    final rawOrigLow = _mapLow(_pctFromAmps(m.drf, origFlc));
    final rawOrigHigh = _mapHigh(_pctFromAmps(m.olf, origFlc));
    double low = (_low[ref] ?? rawOrigLow).clamp(lowMin, lowMax);
    double high = (_high[ref] ?? rawOrigHigh).clamp(highMin, highMax);
    if (high <= low) high = low + 1.0;
    // Snapshot AFTER the lowMin/lowMax (resp. highMin/highMax) clamp above —
    // _mapHigh only enforces a floor (never below 101%), it has no ceiling,
    // so an extreme raw olf (e.g. 3025% from a stale/inconsistent stored
    // value) sails through _mapHigh unclamped and only gets capped here,
    // against the backend's olf_max. Snapshotting the pre-clamp value left
    // the dialog's "old" amount reconstructing that same extreme raw number
    // instead of the capped percent the slider actually starts at.
    _sessionOrigLow.putIfAbsent(ref, () => low);
    _sessionOrigHigh.putIfAbsent(ref, () => high);
    _sessionOrigLowAmount.putIfAbsent(ref, () => (m.drf ?? 0).toDouble());
    _sessionOrigHighAmount.putIfAbsent(ref, () => (m.olf ?? 0).toDouble());

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
      initialLowAmount: (m.drf ?? 0).toDouble(),
      initialHighAmount: (m.olf ?? 0).toDouble(),
      onChanged: (lowVal, highVal) {
        _low[ref] = lowVal;
        _high[ref] = highVal;
        widget.onChanged?.call();
      },
    );
  }
}
