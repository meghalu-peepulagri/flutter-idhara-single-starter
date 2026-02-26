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

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
      maximumZoomLevel: 0.1,
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
        for (final e in analyticsController.chartData) {
          if (xTime
                  .isAfter(e.start.subtract(const Duration(microseconds: 1))) &&
              xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
            final motorDur = formatDuration(e.duration);
            final startLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.start.toLocal());
            final endLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.end.toLocal());
            tooltipText =
                'Start: $startLabel\nEnd:   $endLabel\nDuration: $motorDur';
            break;
          }
        }
      } else if (isPowerLine) {
        for (final e in analyticsController.powerChartData) {
          if (xTime
                  .isAfter(e.start.subtract(const Duration(microseconds: 1))) &&
              xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
            final powerDur = formatDuration(e.duration);
            final startLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.start.toLocal());
            final endLabel =
                DateFormat('dd-MM-yyyy hh:mm:ss').format(e.end.toLocal());
            tooltipText =
                'Start: $startLabel\nEnd:   $endLabel\nDuration: $powerDur';
            break;
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
      List<TimeSegment> motorData, List<TimeSegment> powerData) {
    final allData = [...motorData, ...powerData];
    if (allData.isEmpty) return null;
    return allData.map((e) => e.start).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? getMaxTime(
      List<TimeSegment> motorData, List<TimeSegment> powerData) {
    final allData = [...motorData, ...powerData];
    if (allData.isEmpty) return null;
    return allData.map((e) => e.end).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final motorChartData = buildChartData(analyticsController.chartData);
      final powerChartData = buildChartData(analyticsController.powerChartData);

      final minTime = getMinTime(motorChartData, powerChartData);
      final maxTime = getMaxTime(motorChartData, powerChartData);

      final hasData = motorChartData.isNotEmpty || powerChartData.isNotEmpty;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 323,
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
                                          ..._buildMotorSeries(motorChartData),
                                          ..._buildPowerSeries(powerChartData),
                                        ],
                                        legend: const Legend(isVisible: false),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendChip(Colors.green, 'Motor On', Icons.power_rounded),
        const SizedBox(width: 8),
        _legendChip(Colors.blue, 'Power On', Icons.bolt_rounded),
        const SizedBox(width: 8),
        _legendChip(Colors.red, 'Off', Icons.stop_circle_outlined),
      ],
    );
  }

  Widget _legendChip(Color color, String label, IconData icon) {
    return Container(
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
            ),
          ),
        ],
      ),
    );
  }

  List<LineSeries<TimePoint, DateTime>> _buildMotorSeries(
      List<TimeSegment> data) {
    final List<LineSeries<TimePoint, DateTime>> seriesList = [];

    for (final segment in data) {
      final points = [
        TimePoint(
          segment.start,
          3,
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
          color: Colors.green,
          width: 3,
          isVisibleInLegend: false,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 7,
            width: 7,
            shape: DataMarkerType.circle,
          ),
          pointColorMapper: (TimePoint point, _) {
            return point.isStartPoint ? Colors.green : Colors.red;
          },
        ),
      );
    }

    return seriesList;
  }

  List<LineSeries<PowerTimePoint, DateTime>> _buildPowerSeries(
      List<TimeSegment> data) {
    final List<LineSeries<PowerTimePoint, DateTime>> seriesList = [];

    for (final segment in data) {
      final points = [
        PowerTimePoint(
          segment.start,
          1,
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
          color: Colors.blue,
          width: 3,
          isVisibleInLegend: false,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 7,
            width: 7,
            shape: DataMarkerType.circle,
          ),
          pointColorMapper: (PowerTimePoint point, _) {
            return point.isStartPoint ? Colors.blue : Colors.red;
          },
        ),
      );
    }

    return seriesList;
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
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF45A845).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF45A845).withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Image.asset(
              'assets/images/motorruntime.png',
              height: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Motor & Power",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "overview",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final motorTotal = analyticsController.motortotalRuntime.value;
            if (motorTotal.isEmpty) return const SizedBox.shrink();
            return _runtimeBadge(
                motorTotal, Colors.green, Icons.timer_outlined);
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
