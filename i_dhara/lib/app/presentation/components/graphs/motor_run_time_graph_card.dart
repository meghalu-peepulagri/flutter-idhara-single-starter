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
  bool _showOff = true;

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
    }

    final xLabel = xTime != null
        ? DateFormat('dd-MM-yyyy hh:mm:ss').format(xTime.toLocal())
        : '';

    String formatDuration(Duration d) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }

    final yValue = cartPoint?.y as double?;
    final isMotorLine = yValue != null && yValue > 2;
    final isPowerLine = yValue != null && yValue < 2;

    String tooltipText = xLabel;

    if (xTime != null) {
      if (isMotorLine) {
        // Check motor ON segments first
        bool found = false;
        for (final e in analyticsController.chartData) {
          if (xTime
                  .isAfter(e.start.subtract(const Duration(microseconds: 1))) &&
              xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
            final startLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.start.toLocal());
            final endLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.end.toLocal());
            tooltipText =
                'Motor ON\nStart: $startLabel\nEnd:   $endLabel\nDuration: ${formatDuration(e.duration)}';
            found = true;
            break;
          }
        }
        // Fall back to motor OFF segments
        if (!found) {
          for (final e in analyticsController.motorOffChartData) {
            if (xTime.isAfter(
                    e.start.subtract(const Duration(microseconds: 1))) &&
                xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
              final startLabel =
                  DateFormat('dd-MM-yyyy hh:mm:ss').format(e.start.toLocal());
              final endLabel =
                  DateFormat('dd-MM-yyyy hh:mm:ss').format(e.end.toLocal());
              tooltipText =
                  'Motor OFF\nStart: $startLabel\nEnd:   $endLabel\nDuration: ${formatDuration(e.duration)}';
              break;
            }
          }
        }
      } else if (isPowerLine) {
        // Check power ON segments first
        bool found = false;
        for (final e in analyticsController.powerChartData) {
          if (xTime
                  .isAfter(e.start.subtract(const Duration(microseconds: 1))) &&
              xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
            final startLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.start.toLocal());
            final endLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.end.toLocal());
            tooltipText =
                'Power ON\nStart: $startLabel\nEnd:   $endLabel\nDuration: ${formatDuration(e.duration)}';
            found = true;
            break;
          }
        }
        // Fall back to power OFF segments
        if (!found) {
          for (final e in analyticsController.powerOffChartData) {
            if (xTime.isAfter(
                    e.start.subtract(const Duration(microseconds: 1))) &&
                xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
              final startLabel =
                  DateFormat('dd-MM-yyyy hh:mm:ss').format(e.start.toLocal());
              final endLabel =
                  DateFormat('dd-MM-yyyy hh:mm:ss').format(e.end.toLocal());
              tooltipText =
                  'Power OFF\nStart: $startLabel\nEnd:   $endLabel\nDuration: ${formatDuration(e.duration)}';
              break;
            }
          }
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tooltipText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  List<TimeSegment> buildChartData(List<TimeSegment> rawData) {
    if (rawData.isEmpty) return [];
    final sorted = List<TimeSegment>.from(rawData);
    sorted.sort((a, b) => a.start.compareTo(b.start));
    return sorted;
  }

  DateTime? getMinTime(
      List<TimeSegment> motorData,
      List<TimeSegment> motorOffData,
      List<TimeSegment> powerData,
      List<TimeSegment> powerOffData) {
    final allData = [
      ...motorData,
      ...motorOffData,
      ...powerData,
      ...powerOffData
    ];
    if (allData.isEmpty) return null;
    return allData.map((e) => e.start).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? getMaxTime(
      List<TimeSegment> motorData,
      List<TimeSegment> motorOffData,
      List<TimeSegment> powerData,
      List<TimeSegment> powerOffData) {
    final allData = [
      ...motorData,
      ...motorOffData,
      ...powerData,
      ...powerOffData
    ];
    if (allData.isEmpty) return null;
    return allData.map((e) => e.end).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final motorChartData = buildChartData(analyticsController.chartData);
      final motorOffChartData =
          buildChartData(analyticsController.motorOffChartData);
      final powerChartData = buildChartData(analyticsController.powerChartData);
      final powerOffChartData =
          buildChartData(analyticsController.powerOffChartData);

      final minTime = getMinTime(
          motorChartData, motorOffChartData, powerChartData, powerOffChartData);
      final maxTime = getMaxTime(
          motorChartData, motorOffChartData, powerChartData, powerOffChartData);

      final hasData = motorChartData.isNotEmpty ||
          motorOffChartData.isNotEmpty ||
          powerChartData.isNotEmpty ||
          powerOffChartData.isNotEmpty;

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
                                          if (_showMotorOn)
                                            ..._buildMotorSeries(
                                                motorChartData),
                                          if (_showOff)
                                            ..._buildMotorOffSeries(
                                                motorOffChartData),
                                          if (_showPowerOn)
                                            ..._buildPowerSeries(
                                                powerChartData),
                                          if (_showOff)
                                            ..._buildPowerOffSeries(
                                                powerOffChartData),
                                        ],
                                        legend: const Legend(
                                          isVisible: false,
                                        ),
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
          // Container(
          //   padding: const EdgeInsets.all(9),
          //   decoration: BoxDecoration(
          //     color: const Color(0xFF45A845).withValues(alpha: 0.12),
          //     borderRadius: BorderRadius.circular(10),
          //     border: Border.all(
          //       color: const Color(0xFF45A845).withValues(alpha: 0.2),
          //       width: 0.8,
          //     ),
          //   ),
          //   child: Image.asset(
          //     'assets/images/motorruntime.png',
          //     height: 20,
          //   ),
          // ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Motor",
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
            final parts = motorTotal.split(':');
            final display = parts.length >= 3
                ? '${parts[0]}:${parts[1]}'
                : motorTotal
                    .replaceAll(
                        RegExp(r'\s*\d+\s*sec', caseSensitive: false), '')
                    .trim();
            return _runtimeBadge(display, Colors.green, Icons.timer_outlined);
          }),
        ],
      ),
    );
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
        _legendChip(Colors.green, 'Motor On', Icons.power_rounded, _showMotorOn,
            () => setState(() => _showMotorOn = !_showMotorOn)),
        const SizedBox(width: 8),
        _legendChip(Colors.blue, 'Power On', Icons.bolt_rounded, _showPowerOn,
            () => setState(() => _showPowerOn = !_showPowerOn)),
        const SizedBox(width: 8),
        _legendChip(Colors.red, 'Off', Icons.stop_circle_outlined, _showOff,
            () => setState(() => _showOff = !_showOff)),
      ],
    );
  }

  Widget _legendChip(Color color, String label, IconData icon, bool isActive,
      VoidCallback onTap) {
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

List<LineSeries<TimePoint, DateTime>> _buildMotorSeries(
    List<TimeSegment> data) {
  final List<LineSeries<TimePoint, DateTime>> seriesList = [];
  final DateTime now = DateTime.now();

  for (final segment in data) {
    // Check if this motor segment is still running
    // A segment is "still running" if end time is very close to now (within 5 seconds)
    final isStillRunning = segment.end.difference(now).abs().inSeconds < 5;

    // Choose color based on whether it's still running
    final lineColor = isStillRunning ? Colors.green : Colors.green;
    final endPointColor = isStillRunning ? Colors.green : Colors.red;

    final points = [
      TimePoint(
        segment.start,
        3, // Y-position for motor line (top)
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        true,
      ),
      TimePoint(
        segment.end,
        3, // Y-position for motor line (top)
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        false,
      ),
    ];

    seriesList.add(
      LineSeries(
        dataSource: points,
        xValueMapper: (p, _) => p.time,
        yValueMapper: (p, _) => p.value,
        color: lineColor, // Orange if still running, green if completed
        width: 3,
        name: isStillRunning ? 'Still Running' : null,
        legendIconType:
            isStillRunning ? LegendIconType.circle : LegendIconType.circle,
        isVisibleInLegend: isStillRunning,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
          shape: DataMarkerType.circle,
        ),
        pointColorMapper: (TimePoint point, _) {
          if (isStillRunning) {
            // Both points orange if still running
            return Colors.green;
          } else {
            // Green start, red end if completed
            return point.isStartPoint ? Colors.green : Colors.red;
          }
        },
      ),
    );
  }

  return seriesList;
}

List<LineSeries<TimePoint, DateTime>> _buildMotorOffSeries(
    List<TimeSegment> data) {
  final List<LineSeries<TimePoint, DateTime>> seriesList = [];

  for (final segment in data) {
    final points = [
      TimePoint(
        segment.start,
        3, // same Y-position as motor ON line
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        true,
      ),
      TimePoint(
        segment.end,
        3,
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        false,
      ),
    ];

    seriesList.add(
      LineSeries(
        dataSource: points,
        xValueMapper: (p, _) => p.time,
        yValueMapper: (p, _) => p.value,
        color: Colors.red,
        width: 3,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
          shape: DataMarkerType.circle,
        ),
        pointColorMapper: (TimePoint point, _) => Colors.red,
        isVisibleInLegend: false,
      ),
    );
  }

  return seriesList;
}

List<LineSeries<PowerTimePoint, DateTime>> _buildPowerSeries(
    List<TimeSegment> data) {
  final List<LineSeries<PowerTimePoint, DateTime>> seriesList = [];
  final DateTime now = DateTime.now();

  for (final segment in data) {
    // Check if this segment is still running
    // A segment is "still running" if end time is very close to now (within 5 seconds)
    final isStillRunning = segment.end.difference(now).abs().inSeconds < 5;

    // Choose color based on whether it's still running
    final lineColor = isStillRunning ? Colors.blue : Colors.blue;
    final endPointColor = isStillRunning ? Colors.blue : Colors.red;

    final points = [
      PowerTimePoint(
        segment.start,
        1, // Y-position for power line (bottom)
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        true,
      ),
      PowerTimePoint(
        segment.end,
        1, // Y-position for power line (bottom)
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        false,
      ),
    ];

    seriesList.add(
      LineSeries(
        dataSource: points,
        xValueMapper: (p, _) => p.time,
        yValueMapper: (p, _) => p.value,
        color: lineColor, // Orange if still running, blue if completed
        width: 3,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
          shape: DataMarkerType.circle,
        ),
        pointColorMapper: (PowerTimePoint point, _) {
          if (isStillRunning) {
            // Both points orange if still running
            return Colors.blue;
          } else {
            // Blue start, orange end if completed
            return point.isStartPoint ? Colors.blue : Colors.red;
          }
        },
        isVisibleInLegend: false,
      ),
    );
  }

  return seriesList;
}

List<LineSeries<PowerTimePoint, DateTime>> _buildPowerOffSeries(
    List<TimeSegment> data) {
  final List<LineSeries<PowerTimePoint, DateTime>> seriesList = [];

  for (final segment in data) {
    final points = [
      PowerTimePoint(
        segment.start,
        1, // same Y-position as power line
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        true,
      ),
      PowerTimePoint(
        segment.end,
        1,
        segment.duration.toString(),
        segment.type,
        segment.start,
        segment.end,
        false,
      ),
    ];

    seriesList.add(
      LineSeries(
        dataSource: points,
        xValueMapper: (p, _) => p.time,
        yValueMapper: (p, _) => p.value,
        color: Colors.red,
        width: 3,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 6,
          width: 6,
          shape: DataMarkerType.circle,
        ),
        pointColorMapper: (PowerTimePoint point, _) => Colors.red,
        isVisibleInLegend: false,
      ),
    );
  }

  return seriesList;
}

class TimePoint {
  final DateTime time;
  final double value;
  final String duration;
  final String motorDescription;
  DateTime start;
  DateTime end;
  final bool isStartPoint;

  TimePoint(
    this.time,
    this.value,
    this.duration,
    this.motorDescription,
    this.start,
    this.end,
    this.isStartPoint,
  );
}

class PowerTimePoint {
  final DateTime time;
  final double value;
  final String duration;
  final String powerDescription;
  DateTime start;
  DateTime end;
  final bool isStartPoint;

  PowerTimePoint(
    this.time,
    this.value,
    this.duration,
    this.powerDescription,
    this.start,
    this.end,
    this.isStartPoint,
  );
}
