import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:i_dhara/app/presentation/widgets/no_data_view.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MotorRuntimeGraphWidget extends StatefulWidget {
  final List<DateTime?> selectedDateRange;

  const MotorRuntimeGraphWidget({
    super.key,
    required this.selectedDateRange,
  });

  @override
  State<MotorRuntimeGraphWidget> createState() =>
      _MotorRuntimeGraphWidgetState();
}

class _MotorRuntimeGraphWidgetState extends State<MotorRuntimeGraphWidget> {
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;

  final AnalyticsController analyticsController = Get.find();

  bool _showMotorOn = true;
  bool _showPowerOn = true;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
      maximumZoomLevel: 0.05,
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
      builder: (BuildContext context, TrackballDetails details) {
        return _buildTooltip(context, details);
      },
    );
  }

  Widget _buildTooltip(BuildContext context, TrackballDetails details) {
    final cartPoint = details.point;
    DateTime? xTime;
    if (cartPoint?.x is DateTime) {
      xTime = cartPoint?.x as DateTime?;
    } else if (cartPoint?.x is num) {
      // ScatterSeries (and some other series) pass the internal axis value
      // (milliseconds since epoch) rather than a DateTime object.
      xTime =
          DateTime.fromMillisecondsSinceEpoch((cartPoint!.x as num).toInt());
    }
    if (xTime == null) return const SizedBox.shrink();

    String fmtDur(Duration d) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }

    String fmt(DateTime dt) =>
        DateFormat('dd-MM-yyyy hh:mm:ss a').format(dt.toLocal());

    bool ptMatch(DateTime t, TimeSegment seg) =>
        (t.difference(seg.start).inMilliseconds.abs() < 500) ||
        (t.difference(seg.end).inMilliseconds.abs() < 500);

    // Y value tells us which row was tapped:
    //   Y ≥ 2.0  →  motor row  (series plotted at Y = 3.0)
    //   Y < 2.0  →  power row  (series plotted at Y = 1.0)
    // Using Y prevents motor and power segments that share the same start
    // time from incorrectly matching each other's tooltip.
    final double yValue = cartPoint?.y is num
        ? (cartPoint!.y as num).toDouble()
        : 3.0; // default to motor row if unavailable

    // ── Device offline — shown on both rows; check before motor/power
    for (final seg in analyticsController.deviceOfflineChartData) {
      if (ptMatch(xTime, seg)) {
        if (seg.isOngoing) {
          return _tooltip(
            'Device Offline\nStart:  ${fmt(seg.start)}\nStatus: Offline',
            Colors.grey.shade600,
          );
        }
        return _tooltip(
          'Device Offline\nStart:    ${fmt(seg.start)}\nEnd:      ${fmt(seg.end)}\nDuration: ${fmtDur(seg.duration)}',
          Colors.grey.shade600,
        );
      }
    }

    if (yValue >= 2.0) {
      // ── Motor row
      for (final seg in analyticsController.chartData) {
        if (ptMatch(xTime, seg)) {
          if (seg.isOngoing) {
            return _tooltip(
              'Motor ON\nStart:  ${fmt(seg.start)}\nStatus: Running',
              Colors.green.shade700,
            );
          }
          return _tooltip(
            'Motor ON\nStart:  ${fmt(seg.start)}\nEnd:    ${fmt(seg.end)}\nDuration: ${fmtDur(seg.duration)}',
            Colors.green.shade700,
          );
        }
      }
    } else {
      // ── Power row
      for (final seg in analyticsController.powerChartData) {
        if (ptMatch(xTime, seg)) {
          if (seg.isOngoing) {
            return _tooltip(
              'Power ON\nStart:  ${fmt(seg.start)}\nStatus:  Running',
              Colors.blue.shade700,
            );
          }
          return _tooltip(
            'Power ON\nStart:    ${fmt(seg.start)}\nEnd:      ${fmt(seg.end)}\nDuration: ${fmtDur(seg.duration)}',
            Colors.blue.shade700,
          );
        }
      }
    }

    return _tooltip(fmt(xTime), Colors.black87);
  }

  Widget _tooltip(String text, Color headerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: headerColor, width: 3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
      ),
    );
  }

  List<TimeSegment> _sorted(List<TimeSegment> data) {
    final copy = List<TimeSegment>.from(data);
    copy.sort((a, b) => a.start.compareTo(b.start));
    return copy;
  }

  DateTime? _minTime(List<List<TimeSegment>> allLists) {
    DateTime? min;
    for (final list in allLists) {
      for (final seg in list) {
        if (min == null || seg.start.isBefore(min)) min = seg.start;
      }
    }
    return min;
  }

  DateTime? _maxTime(List<List<TimeSegment>> allLists) {
    DateTime? max;
    for (final list in allLists) {
      for (final seg in list) {
        if (max == null || seg.end.isAfter(max)) max = seg.end;
      }
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final motorData = _sorted(analyticsController.chartData);
      final powerData = _sorted(analyticsController.powerChartData);
      final offlineData = _sorted(analyticsController.deviceOfflineChartData);

      final minTime = _minTime([motorData, powerData, offlineData]);
      final maxTime = _maxTime([motorData, powerData, offlineData]);

      final hasData = motorData.isNotEmpty ||
          powerData.isNotEmpty ||
          offlineData.isNotEmpty;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 330,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                )
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildHeader(context),
                analyticsController.isLoadingruntime.value
                    ? const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: GraphLottieLoading()),
                      )
                    : !hasData
                        ? const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: NoGraphsFound(),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 5, top: 0, right: 0, bottom: 0),
                            child: SizedBox(
                              height: 255,
                              child: Stack(
                                children: [
                                  const Positioned(
                                    top: 50,
                                    bottom: 60,
                                    left: 1,
                                    child: Text(
                                      'M',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 12),
                                    ),
                                  ),
                                  const Positioned(
                                    top: 130,
                                    bottom: 0,
                                    left: 1,
                                    child: Text(
                                      'P',
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, top: 10, right: 8),
                                    child: SizedBox(
                                      height: 220,
                                      child: SfCartesianChart(
                                        zoomPanBehavior: _zoomPanBehavior,
                                        trackballBehavior: _trackballBehavior,
                                        primaryXAxis: DateTimeAxis(
                                          labelStyle:
                                              const TextStyle(fontSize: 10),
                                          dateFormat: DateFormat('hh:mm a'),
                                          minimum: minTime,
                                          maximum: maxTime,
                                          interval: 1,
                                          labelRotation: -45,
                                          majorGridLines:
                                              const MajorGridLines(width: 0),
                                          intervalType:
                                              DateTimeIntervalType.auto,
                                          autoScrollingDeltaType:
                                              DateTimeIntervalType.minutes,
                                          labelIntersectAction:
                                              AxisLabelIntersectAction.hide,
                                          maximumLabels: 10,
                                          labelAlignment: LabelAlignment.center,
                                          axisLabelFormatter:
                                              (AxisLabelRenderDetails args) {
                                            final date = DateTime
                                                .fromMillisecondsSinceEpoch(
                                              args.value.toInt(),
                                            );
                                            return ChartAxisLabel(
                                              DateFormat('hh:mm a')
                                                  .format(date),
                                              const TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                        primaryYAxis: const NumericAxis(
                                          isVisible: false,
                                          minimum: 0,
                                          maximum: 4,
                                        ),
                                        series: [
                                          ..._offlineSeries(
                                              offlineData, 3.0), // motor row
                                          ..._offlineSeries(
                                              offlineData, 1.0), // power row
                                          if (_showMotorOn)
                                            ..._motorOnSeries(motorData),
                                          if (_showPowerOn)
                                            ..._powerOnSeries(powerData),
                                        ],
                                        legend: const Legend(isVisible: false),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: _buildLegend(),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFF4FAF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Motor Runtime",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final motorTotal = analyticsController.motortotalRuntime.value;
            if (motorTotal.isEmpty) return const SizedBox.shrink();
            return _runtimeBadge(
              _fmtHhMm(motorTotal),
              Colors.green,
              Icons.timer_outlined,
            );
          }),
        ],
      ),
    );
  }

  // Parses runtime strings from the API and returns "Xh Ym" (no seconds).
  // Handles both "HH:MM:SS" / "HH:MM" and pre-formatted "Xh Ym Zs" / "Xh Ym".
  String _fmtHhMm(String raw) {
    final s = raw.trim();

    // Format: "Xh Ym Zs" or "Xh Ym" — strip seconds portion if present.
    if (s.contains('h') || s.contains('m')) {
      final noSec = s.replaceAll(RegExp(r'\s*\d+\s*s\b'), '').trim();
      return noSec.isEmpty ? '0m' : noSec;
    }

    // Format: "HH:MM:SS" or "HH:MM" — take only hours and minutes.
    final parts = s.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0].trim()) ?? 0;
      final m = int.tryParse(parts[1].trim()) ?? 0;
      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      if (m > 0) return '${m}m';
      return '0m';
    }

    return s;
  }

  Widget _runtimeBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendChip(Colors.green, 'Motor On', Icons.power_rounded, false,
            _showMotorOn, () => setState(() => _showMotorOn = !_showMotorOn)),
        const SizedBox(width: 8),
        _legendChip(Colors.blue, 'Power On', Icons.bolt_rounded, false,
            _showPowerOn, () => setState(() => _showPowerOn = !_showPowerOn)),
      ],
    );
  }

  Widget _legendChip(Color color, String label, IconData icon, bool isDashed,
      bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                  decoration: isActive ? null : TextDecoration.lineThrough,
                  decorationColor: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Series builders
// ---------------------------------------------------------------------------

/// Motor ON → solid green line (start→end) with a dot only at the ON start.
/// Skips the start dot for continuation segments (motor was already running
/// before this date range — no fresh start occurred).
List<LineSeries<_Pt, DateTime>> _motorOnSeries(List<TimeSegment> data) {
  final result = <LineSeries<_Pt, DateTime>>[];
  for (final seg in data) {
    result.add(LineSeries<_Pt, DateTime>(
      dataSource: [_Pt(seg.start, 3.0, seg), _Pt(seg.end, 3.0, seg)],
      xValueMapper: (p, _) => p.time,
      yValueMapper: (p, _) => p.value,
      color: Colors.green,
      width: 3,
      markerSettings: const MarkerSettings(isVisible: false),
      isVisibleInLegend: false,
    ));
    result.add(LineSeries<_Pt, DateTime>(
      dataSource: [
        _Pt(seg.start, 3.0, seg),
        _Pt(seg.start.add(const Duration(milliseconds: 1)), 3.0, seg),
      ],
      xValueMapper: (p, _) => p.time,
      yValueMapper: (p, _) => p.value,
      color: Colors.transparent,
      width: 0,
      markerSettings: const MarkerSettings(
        isVisible: true,
        height: 8,
        width: 8,
        shape: DataMarkerType.circle,
        color: Colors.green,
        borderColor: Colors.green,
      ),
      isVisibleInLegend: false,
    ));
  }
  return result;
}

/// Power ON → solid blue line (start→end) with a dot only at the ON start.
/// Skips the start dot for continuation segments.
List<LineSeries<_Pt, DateTime>> _powerOnSeries(List<TimeSegment> data) {
  final result = <LineSeries<_Pt, DateTime>>[];
  for (final seg in data) {
    result.add(LineSeries<_Pt, DateTime>(
      dataSource: [_Pt(seg.start, 1.0, seg), _Pt(seg.end, 1.0, seg)],
      xValueMapper: (p, _) => p.time,
      yValueMapper: (p, _) => p.value,
      color: Colors.blue,
      width: 3,
      markerSettings: const MarkerSettings(isVisible: false),
      isVisibleInLegend: false,
    ));
    result.add(LineSeries<_Pt, DateTime>(
      dataSource: [
        _Pt(seg.start, 1.0, seg),
        _Pt(seg.start.add(const Duration(milliseconds: 1)), 1.0, seg),
      ],
      xValueMapper: (p, _) => p.time,
      yValueMapper: (p, _) => p.value,
      color: Colors.transparent,
      width: 0,
      markerSettings: const MarkerSettings(
        isVisible: true,
        height: 8,
        width: 8,
        shape: DataMarkerType.circle,
        color: Colors.blue,
        borderColor: Colors.blue,
      ),
      isVisibleInLegend: false,
    ));
  }
  return result;
}

/// Device offline → two-pass rendering per segment so coloured lines below
/// cannot bleed through the gaps in the dashes:
///   1. Wide white masking line (covers the coloured series beneath).
///   2. Grey dashed line on top.
List<LineSeries<_Pt, DateTime>> _offlineSeries(
    List<TimeSegment> data, double yValue) {
  final result = <LineSeries<_Pt, DateTime>>[];
  for (final seg in data) {
    final pts = [
      _Pt(seg.start, yValue, seg),
      _Pt(seg.end, yValue, seg),
    ];
    // Pass 1 — white mask to erase the coloured line underneath
    result.add(LineSeries<_Pt, DateTime>(
      dataSource: pts,
      xValueMapper: (p, _) => p.time,
      yValueMapper: (p, _) => p.value,
      color: Colors.white,
      width: 6,
      markerSettings: const MarkerSettings(isVisible: false),
      isVisibleInLegend: false,
    ));
    // Pass 2 — grey dashes
    result.add(LineSeries<_Pt, DateTime>(
      dataSource: pts,
      xValueMapper: (p, _) => p.time,
      yValueMapper: (p, _) => p.value,
      color: Colors.grey.shade400,
      width: 3,
      dashArray: const [6, 4],
      markerSettings: const MarkerSettings(isVisible: false),
      isVisibleInLegend: false,
    ));
  }
  return result;
}

class _Pt {
  final DateTime time;
  final double value;
  final TimeSegment segment;
  _Pt(this.time, this.value, this.segment);
}
