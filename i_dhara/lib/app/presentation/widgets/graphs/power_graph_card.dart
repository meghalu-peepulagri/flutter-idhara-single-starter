import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/utils/no_data_svg/no_data_svg.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PowerGraphWidget extends StatefulWidget {
  final List<DateTime?> selectedDateRange;

  const PowerGraphWidget({
    super.key,
    required this.selectedDateRange,
  });

  @override
  State<PowerGraphWidget> createState() => _PowerGraphWidgetState();
}

class _PowerGraphWidgetState extends State<PowerGraphWidget> {
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
            '$xLabel\nDuration: $dur',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      },
    );
  }

  List<TimeSegment> buildChartData(List<TimeSegment> rawData) {
    final List<TimeSegment> result = [];

    if (rawData.isEmpty) return result;

    // Sort by start time
    rawData.sort((a, b) => a.start.compareTo(b.start));

    // Add records
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
      final chartData = buildChartData(analyticsController.powerChartData);
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
                    color: Color(0xFFEDF5FF),
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
                          const Icon(
                            Icons.power,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Power Runtime',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Lato',
                                  color: const Color(0xFF2196F3),
                                  letterSpacing: 0,
                                ),
                          ),
                        ]),
                        Obx(() {
                          final total =
                              analyticsController.powerTotalRuntime.value;
                          if (total.isEmpty) return const SizedBox.shrink();

                          return Text(
                            total,
                            style: const TextStyle(
                              fontSize: 14,
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
                                      'P',
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
                                        labelRotation: -20,
                                        majorGridLines:
                                            const MajorGridLines(width: 0),
                                      ),
                                      primaryYAxis: const NumericAxis(
                                        isVisible: false,
                                        minimum: 0,
                                        maximum: 2,
                                      ),
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
    if (d == 'POWER_ON') return Colors.blue;
    if (d == 'POWER_OFF') return Colors.orange;
    if (d == 'POWER_OFFLINE') return Colors.grey;
    return Colors.grey;
  }

  List<LineSeries<PowerTimePoint, DateTime>> _buildSeries(
      List<TimeSegment> data) {
    final List<LineSeries<PowerTimePoint, DateTime>> seriesList = [];

    for (final segment in data) {
      final color = _colorForDescription(segment.type);

      final points = <PowerTimePoint>[
        PowerTimePoint(segment.start, 1, segment.duration.toString(),
            segment.type, segment.start, segment.end, true),
        PowerTimePoint(segment.end, 1, segment.duration.toString(),
            segment.type, segment.start, segment.end, false),
      ];

      seriesList.add(LineSeries<PowerTimePoint, DateTime>(
        dataSource: points,
        xValueMapper: (p, _) => p.time,
        yValueMapper: (p, _) => p.value,
        color: color,
        width: 4,
        markerSettings: MarkerSettings(
          isVisible: true,
          height: 5,
          width: 5,
          shape: DataMarkerType.circle,
          color: color,
        ),
        isVisibleInLegend: false,
      ));
    }

    return seriesList;
  }
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
