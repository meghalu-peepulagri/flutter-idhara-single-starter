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
            ? DateFormat('dd-MM-yyyy HH:mm:ss').format(xTime.toLocal())
            : '';

        String state = 'Unknown';
        String dur = '';

        if (xTime != null && _currentChartData.isNotEmpty) {
          for (final e in _currentChartData) {
            if (xTime.isAfter(
                    e.start.subtract(const Duration(microseconds: 1))) &&
                xTime.isBefore(e.end.add(const Duration(microseconds: 1)))) {
              state = e.type;
              dur = e.duration.toString().split('.').first;
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

    // Fill gap before first record
    // if (rawData.first.start.isAfter(dayStart)) {
    //   result.add(MotorTimeData(
    //     dayStart,
    //     rawData.first.start,
    //     1,
    //     _durationStr(dayStart, rawData.first.start),
    //     "OFFLINE",
    //   ));
    // }

    // Add records + fill gaps between
    for (int i = 0; i < rawData.length; i++) {
      final current = rawData[i];
      result.add(current);

      // if (i < rawData.length - 1) {
      //   final next = rawData[i + 1];
      //   if (next.start.isAfter(current.end)) {
      //     result.add(MotorTimeData(
      //       current.end,
      //       next.start,
      //       1,
      //       _durationStr(current.end, next.start),
      //       "OFFLINE",
      //     ));
      //   }
      // }
    }

    // Fill gap after last record
    // if (rawData.last.end.isBefore(dayEnd)) {
    //   result.add(MotorTimeData(
    //     rawData.last.end,
    //     dayEnd,
    //     1,
    //     _durationStr(rawData.last.end, dayEnd),
    //     "OFFLINE",
    //   ));
    // }

    return result;
  }

  String _durationStr(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    return '${h}h ${m}m ${s}s';
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
                        // if (analyticsController.motortotalRuntimeData.value
                        //         ?.totalRuntimeHours !=
                        //     null)
                        //   Text(
                        //     analyticsController.motortotalRuntimeData.value
                        //             ?.totalRuntimeHours ??
                        //         '',
                        //     style: const TextStyle(fontSize: 14),
                        //   ),
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
                        ? const NoGraphsFound()
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
                                        intervalType:
                                            DateTimeIntervalType.minutes,
                                        // interval: 1,
                                        labelRotation: -20,
                                        majorGridLines:
                                            const MajorGridLines(width: 0),
                                      ),
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

  Color _colorForDescription(String? desc) {
    final d = (desc ?? '').trim().toUpperCase();
    if (d == 'ON') return Colors.green;
    if (d == 'OFF') return Colors.red;
    if (d == 'OFFLINE') return Colors.grey;
    return Colors.red; // fallback
  }

  /// Build one short series per segment to allow exact per-segment coloring.
  /// This prevents connecting segments of the same description across gaps.
  List<LineSeries<TimePoint, DateTime>> _buildSeries(List<TimeSegment> data) {
    final List<LineSeries<TimePoint, DateTime>> seriesList = [];

    for (final segment in data) {
      final color = _colorForDescription(segment.type);

      // Two points: start and end of the segment
      final points = <TimePoint>[
        TimePoint(segment.start, 1, segment.duration.toString(), segment.type,
            segment.start, segment.end, true),
        TimePoint(segment.end, 1, segment.duration.toString(), segment.type,
            segment.start, segment.end, false),
      ];

      seriesList.add(LineSeries<TimePoint, DateTime>(
        dataSource: points,
        xValueMapper: (p, _) => p.time,
        yValueMapper: (p, _) => p.value,
        color: color,
        width: 4,
        // Hide markers (set true if you want visible markers)
        markerSettings: MarkerSettings(
            isVisible: true,
            height: 5,
            width: 5,
            shape: DataMarkerType.circle,
            color: color
            // optionally set shape/border:
            // height: 4, width: 4, shape: DataMarkerType.circle,
            ),
        // don't show the lots-of-segment series in the legend
        isVisibleInLegend: false,
        // if you want small segment visual smoothing off:
        // enableTooltip: true,
      ));
    }

    return seriesList;
  }

//   List<LineSeries<TimePoint, DateTime>> _buildSeries(List<MotorTimeData> data) {
//     final grouped = <String, List<MotorTimeData>>{};
//     for (final e in data) {
//       grouped.putIfAbsent(e.motorDescription, () => []).add(e);
//     }

//     final List<LineSeries<TimePoint, DateTime>> seriesList = [];
//     grouped.forEach((desc, list) {
//       Color color;
//       switch (desc) {
//         case "ON":
//           color = Colors.green;
//           break;
//         case "OFF":
//           color = Colors.red;
//           break;
//         case "OFFLINE":
//           color = Colors.grey;
//           break;
//         default:
//           color = Colors.grey;
//       }

//       final points = <TimePoint>[];
//       for (var e in list) {
//         points.add(TimePoint(e.start, e.value, e.duration, e.motorDescription,
//             e.start, e.end, true));
//         points.add(TimePoint(e.end, e.value, e.duration, e.motorDescription,
//             e.start, e.end, false));
//       }

//       seriesList.add(LineSeries<TimePoint, DateTime>(
//         name: desc,
//         color: color,
//         dataSource: points,
//         xValueMapper: (p, _) => p.time,
//         yValueMapper: (p, _) => p.value,
//         width: 4,
//         markerSettings: MarkerSettings(
//           isVisible: true,
//           height: 5,
//           width: 5,
//           shape: DataMarkerType.circle,
//           color: color,
//         ),
//       ));
//     });

//     return seriesList;
//   }
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
