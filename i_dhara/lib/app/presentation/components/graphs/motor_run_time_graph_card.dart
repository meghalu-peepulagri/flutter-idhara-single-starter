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

    // Determine if clicked point is motor or power based on y-value
    final yValue = cartPoint?.y as double?;
    final isMotorLine = yValue != null && yValue > 2; // Motor line is at y=3
    final isPowerLine = yValue != null && yValue < 2; // Power line is at y=1

    String tooltipText = xLabel;

    if (xTime != null) {
      if (isMotorLine) {
        // Show only motor info
        for (final e in analyticsController.chartData) {
          if (xTime
                  .isAfter(e.start.subtract(const Duration(microseconds: 1))) &&
              xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
            final motorDur = formatDuration(e.duration);
            tooltipText += '\nDuration: $motorDur';
            break;
          }
        }
      } else if (isPowerLine) {
        // Show only power info
        for (final e in analyticsController.powerChartData) {
          if (xTime
                  .isAfter(e.start.subtract(const Duration(microseconds: 1))) &&
              xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
            final powerDur = formatDuration(e.duration);
            tooltipText += '\nDuration: $powerDur';
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

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
            height: 300,
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
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF9ED),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Image.asset(
                            'assets/images/motorruntime.png',
                            height: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Motor & Power',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Lato',
                                  color: const Color(0xFF45A845),
                                  letterSpacing: 0,
                                ),
                          ),
                        ]),
                        Obx(() {
                          final motorTotal =
                              analyticsController.motortotalRuntime.value;
                          final powerTotal =
                              analyticsController.powerTotalRuntime.value;
                          if (motorTotal.isEmpty && powerTotal.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (motorTotal.isNotEmpty)
                                Text(
                                  ' $motorTotal',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
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
                                        legend: const Legend(
                                          isVisible: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _legendDot(Colors.green),
                                          const SizedBox(width: 4),
                                          const Text('Motor On',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54)),
                                          const SizedBox(width: 10),
                                          const SizedBox(width: 10),
                                          _legendDot(Colors.blue),
                                          const SizedBox(width: 4),
                                          const Text('Power On',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54)),
                                          const SizedBox(width: 10),
                                          _legendDot(Colors.red),
                                          const SizedBox(width: 4),
                                          const Text('Off',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54)),
                                        ],
                                      ),
                                    ),
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

  // List<LineSeries<TimePoint, DateTime>> _buildMotorSeries(
  //     List<TimeSegment> data) {
  //   final List<LineSeries<TimePoint, DateTime>> seriesList = [];

  //   for (final segment in data) {
  //     final points = [
  //       TimePoint(
  //         segment.start,
  //         3, // Y-position for motor line (top)
  //         segment.duration.toString(),
  //         segment.type,
  //         segment.start,
  //         segment.end,
  //         true,
  //       ),
  //       TimePoint(
  //         segment.end,
  //         3, // Y-position for motor line (top)
  //         segment.duration.toString(),
  //         segment.type,
  //         segment.start,
  //         segment.end,
  //         false,
  //       ),
  //     ];

  //     seriesList.add(
  //       LineSeries(
  //         dataSource: points,
  //         xValueMapper: (p, _) => p.time,
  //         yValueMapper: (p, _) => p.value,
  //         color: Colors.green,
  //         width: 3,
  //         markerSettings: const MarkerSettings(
  //           isVisible: true,
  //           height: 6,
  //           width: 6,
  //           shape: DataMarkerType.circle,
  //         ),
  //         pointColorMapper: (TimePoint point, _) {
  //           return point.isStartPoint ? Colors.green : Colors.red;
  //         },
  //         isVisibleInLegend: false,
  //       ),
  //     );
  //   }

  //   return seriesList;
  // }
  List<LineSeries<TimePoint, DateTime>> _buildMotorSeries(
      List<TimeSegment> data) {
    final List<LineSeries<TimePoint, DateTime>> seriesList = [];

    for (final segment in data) {
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
          color: Colors.green,
          width: 3,
          isVisibleInLegend: false,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
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
          color: Colors.blue,
          width: 3,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.circle,
          ),
          pointColorMapper: (PowerTimePoint point, _) {
            return point.isStartPoint ? Colors.blue : Colors.red;
          },
          isVisibleInLegend: false,
        ),
      );
    }

    return seriesList;
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
