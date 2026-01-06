import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/utils/no_data_svg/no_data_svg.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
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

  DateTime? minTime;
  DateTime? maxTime;

  List<TimeSegment> _currentChartData = [];

  final AnalyticsController analyticsController =
      Get.find<AnalyticsController>();

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
      // shouldAlwaysShow: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
      builder: (BuildContext context, TrackballDetails details) {
        final cartPoint = details.point;
        DateTime? xTime;
        if (cartPoint?.x is DateTime) {
          xTime = cartPoint?.x as DateTime?;
        }

        final xLabel = xTime != null
            ? DateFormat('dd-MM-yyyy hh:mm:ss').format(xTime.toLocal())
            : '';

        String state = 'Unknown';
        String dur = '';

        String formatDuration(Duration d) {
          final h = d.inHours.toString().padLeft(2, '0');
          final m = (d.inMinutes % 60).toString().padLeft(2, '0');
          final s = (d.inSeconds % 60).toString().padLeft(2, '0');
          return '$h:$m:$s';
        }

        if (xTime != null && _currentChartData.isNotEmpty) {
          for (final e in _currentChartData) {
            if (xTime.isAfter(
                    e.start.subtract(const Duration(microseconds: 1))) &&
                xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
              state = e.type;
              dur = dur = formatDuration(e.duration);
              break;
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
            '$xLabel\nDuration :$dur',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      },
    );
  }

  /// Generate chart data with OFFLINE filling for missing intervals
  List<TimeSegment> buildChartData(List<TimeSegment> rawData) {
    final List<TimeSegment> result = [];

    if (rawData.isEmpty) return result;

    // Sort by start time
    rawData.sort((a, b) => a.start.compareTo(b.start));

    final dayStart = DateTime(rawData.first.start.year,
        rawData.first.start.month, rawData.first.start.day, 0, 0, 0);
    final dayEnd = DateTime(rawData.first.start.year, rawData.first.start.month,
        rawData.first.start.day, 23, 59, 59);

    for (int i = 0; i < rawData.length; i++) {
      final current = rawData[i];
      result.add(current);
    }

    return result;
  }

  void updateMinMax(List<TimeSegment> chartData) {
    if (chartData.isEmpty) return;
    minTime =
        chartData.map((e) => e.start).reduce((a, b) => a.isBefore(b) ? a : b);
    maxTime =
        chartData.map((e) => e.end).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final chartData = buildChartData(analyticsController.chartData);
      _currentChartData = chartData;
      updateMinMax(chartData);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 220,
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
                            'Motor Runtime',
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
                          final total =
                              analyticsController.motortotalRuntime.value;
                          if (total.isEmpty) return const SizedBox.shrink();

                          return Text(
                            total,
                            style: const TextStyle(
                              fontSize: 14,
                              // fontWeight: FontWeight.w400,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                analyticsController.isLoadingruntime.value
                    ? const Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : chartData.isEmpty
                        // || analyticsController.motorRuntimeData.length ==0
                        ? const Padding(
                            padding: EdgeInsets.only(top: 30),
                            child: NoGraphsFound(),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 5, top: 10, right: 0, bottom: 0),
                            child: Stack(
                              children: [
                                const Positioned(
                                    top: 40,
                                    bottom: 0,
                                    left: 1,
                                    child: Text(
                                      'M',
                                      style: TextStyle(color: Colors.black45),
                                    )),
                                Padding(
                                  padding: const EdgeInsets.only(left: 7),
                                  child: SizedBox(
                                    height: 160,
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
                                        labelRotation: -20,
                                        majorGridLines:
                                            const MajorGridLines(width: 0),
                                        intervalType: DateTimeIntervalType.auto,
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
                                            DateFormat('hh:mm a').format(date),
                                            const TextStyle(fontSize: 10),
                                          );
                                        },
                                      ),
                                      // primaryXAxis: DateTimeAxis(
                                      //   labelStyle:
                                      //       const TextStyle(fontSize: 10),
                                      //   dateFormat: DateFormat('hh:mm a'),
                                      //   minimum: minTime,
                                      //   maximum: maxTime,
                                      //   interval: 1,
                                      //   labelRotation: -20,
                                      //   majorGridLines:
                                      //       const MajorGridLines(width: 0),
                                      //   intervalType:
                                      //       DateTimeIntervalType.minutes,
                                      //   autoScrollingDeltaType:
                                      //       DateTimeIntervalType.minutes,
                                      //   axisLabelFormatter:
                                      //       (AxisLabelRenderDetails args) {
                                      //     final date = DateTime
                                      //         .fromMillisecondsSinceEpoch(
                                      //             args.value.toInt());

                                      //     return ChartAxisLabel(
                                      //       DateFormat('hh:mm a').format(date),
                                      //       const TextStyle(fontSize: 10),
                                      //     );
                                      //   },
                                      // ),
                                      primaryYAxis: const NumericAxis(
                                        isVisible: false,
                                        minimum: 0,
                                        maximum: 2,
                                      ),
                                      // legend: Legend(
                                      //   isVisible: true,
                                      //   position: LegendPosition.bottom,
                                      // ),
                                      series: _buildSeries(chartData),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
        ],
      );
    });
  }

  List<LineSeries<TimePoint, DateTime>> _buildSeries(List<TimeSegment> data) {
    final List<LineSeries<TimePoint, DateTime>> seriesList = [];

    for (final segment in data) {
      final points = <TimePoint>[
        TimePoint(
          segment.start,
          1,
          segment.duration.toString(),
          segment.type,
          segment.start,
          segment.end,
          true,
        ),
        TimePoint(
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
        LineSeries<TimePoint, DateTime>(
          dataSource: points,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: Colors.green,
          width: 3,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.circle,
          ),
          pointColorMapper: (TimePoint point, _) {
            return point.isStartPoint ? Colors.green : Colors.red;
          },
          isVisibleInLegend: false,
        ),
      );
    }

    return seriesList;
  }
}

class MotorTimeData {
  DateTime start;
  DateTime end;
  double value;
  final String duration;
  final String motorDescription;

  MotorTimeData(
    this.start,
    this.end,
    this.value,
    this.duration,
    this.motorDescription,
  );
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
