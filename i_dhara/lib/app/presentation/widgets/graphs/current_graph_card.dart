import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/utils/app_text/app_text.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CurrentGraphWidget extends StatefulWidget {
  final List<DateTime?> selectedDateRange;
  final String motorName;
  final ValueNotifier<dynamic> sharedPointNotifier;
  final ValueNotifier<DateTime?> sharedTimeNotifier;

  const CurrentGraphWidget({
    super.key,
    required this.selectedDateRange,
    required this.motorName,
    required this.sharedPointNotifier,
    required this.sharedTimeNotifier,
  });

  @override
  State<CurrentGraphWidget> createState() => _CurrentGraphWidgetState();
}

class _CurrentGraphWidgetState extends State<CurrentGraphWidget> {
  late ZoomPanBehavior _zoomPanBehavior;
  late Future<void> _dataFuture;
  late VoidCallback? _timeListener;
  late StreamSubscription<bool> _refreshSub;
  late StreamSubscription<bool> _loadingSub;
  late StreamSubscription<bool> _modalSub;
  bool _previousEnable = true;
  final AnalyticsController controller = Get.find<AnalyticsController>();

  @override
  void initState() {
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.xy,
      enableDoubleTapZooming: true,
    );

    _createTrackballBehavior();

    _timeListener = () {
      if (widget.sharedTimeNotifier.value != null &&
          controller.currentTrackball.value!.enable) {
        final sharedIndex = controller.current.indexWhere(
          (data) => data.timeStamp == widget.sharedTimeNotifier.value,
        );
        if (sharedIndex != -1) {
          final data = controller.current[sharedIndex];
          widget.sharedPointNotifier.value = {
            "C1": data.currentY,
            "C2": data.currentB,
            "C3": data.currentR,
          };
          _showTrackballAtIndex(sharedIndex);
        }
      }
    };
    widget.sharedTimeNotifier.addListener(_timeListener!);

    _refreshSub = controller.isRefreshing.listen((bool val) {
      if (mounted) _updateTrackballIfNeeded();
    });
    _loadingSub = controller.isLoadingCurrent.listen((bool val) {
      if (mounted) _updateTrackballIfNeeded();
    });
    _modalSub = controller.isModalOpen.listen((bool val) {
      if (mounted) _updateTrackballIfNeeded();
    });

    _dataFuture = fetchdata();
    super.initState();
  }

  void _updateTrackballIfNeeded() {
    final isDisabled = controller.isRefreshing.value ||
        controller.isLoadingCurrent.value ||
        controller.isModalOpen.value;
    final newEnable = !isDisabled;
    if (newEnable != _previousEnable) {
      setState(() {
        _createTrackballBehavior();
        _previousEnable = newEnable;
      });
    }
  }

  void _createTrackballBehavior() {
    final isDisabled = controller.isRefreshing.value ||
        controller.isLoadingCurrent.value ||
        controller.isModalOpen.value;
    final enable = !isDisabled;
    controller.currentTrackball.value = TrackballBehavior(
      enable: enable,
      lineType: TrackballLineType.vertical,
      shouldAlwaysShow: enable,
      activationMode: enable ? ActivationMode.singleTap : ActivationMode.none,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: const InteractiveTooltip(
        enable: false,
        format: 'point.x : point.y',
      ),
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
      ),
      builder: (context, trackballDetails) {
        final groupInfo = trackballDetails.groupingModeInfo;
        if (groupInfo != null && groupInfo.points.isNotEmpty) {
          final point = groupInfo.points.first;
          widget.sharedTimeNotifier.value = point.x as DateTime?;
        }
        return Container();
      },
    );
    if (!enable) {
      controller.currentTrackball.value?.hide();
    }
  }

  void _showTrackballAtIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.currentTrackball.value!.enable) {
        controller.currentTrackball.value?.showByIndex(index);
      }
    });
  }

  @override
  void dispose() {
    widget.sharedTimeNotifier.removeListener(_timeListener!);
    _refreshSub.cancel();
    _loadingSub.cancel();
    _modalSub.cancel();
    super.dispose();
  }

  Future<void> fetchdata() async {
    await controller.fetchavgcurrent(widget.selectedDateRange);
    if (controller.current.isNotEmpty) {
      int lastNonZeroIndex = controller.current.length - 1;
      for (int i = controller.current.length - 1; i >= 0; i--) {
        final point = controller.current[i];
        if ((point.currentY ?? 0) > 0 ||
            (point.currentB ?? 0) > 0 ||
            (point.currentR ?? 0) > 0) {
          lastNonZeroIndex = i;
          break;
        }
      }
      final lastPoint = controller.current[lastNonZeroIndex];
      widget.sharedPointNotifier.value = {
        "C1": lastPoint.currentY,
        "C2": lastPoint.currentB,
        "C3": lastPoint.currentR,
      };
      widget.sharedTimeNotifier.value = lastPoint.timeStamp;

      await Future.delayed(const Duration(milliseconds: 300));
      if (controller.currentTrackball.value!.enable) {
        _showTrackballAtIndex(lastNonZeroIndex);
      }
    }
  }

  num _getMaxYValue() {
    if (controller.current.isEmpty) return 40;
    num maxValue = 0;
    for (var e in controller.current) {
      maxValue = [maxValue, e.currentY ?? 0, e.currentB ?? 0, e.currentR ?? 0]
          .reduce((a, b) => a > b ? a : b);
    }
    return maxValue > 0 ? maxValue + 40 : 40;
  }

  num _getMinYValue() {
    if (controller.current.isEmpty) return 0;
    num minValue = 0;
    for (var e in controller.current) {
      minValue = [minValue, e.currentY ?? 0, e.currentB ?? 0, e.currentR ?? 0]
          .reduce((a, b) => a < b ? a : b);
    }
    return minValue < 0 ? minValue - 10 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          height: 295,
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
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: SvgPicture.asset(
                          'assets/images/Current_(1).svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(
                        'Total Current',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Lato',
                              color: const Color(0xFF45A845),
                              letterSpacing: 0,
                            ),
                      ),
                    ].divide(const SizedBox(width: 8)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 8, 0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: widget.sharedTimeNotifier,
                        builder: (context, currentTime, _) {
                          return Text(
                            currentTime != null
                                ? DateFormat('dd/MM HH:mm').format(currentTime)
                                : '--',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Lato',
                                  color: const Color(0xFF6A7185),
                                  fontSize: 12,
                                ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      ValueListenableBuilder(
                        valueListenable: widget.sharedPointNotifier,
                        builder: (context, currentPoint, _) {
                          if (currentPoint == null) {
                            return const Text(
                              "Current: --",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6A7185),
                              ),
                            );
                          }
                          return Row(
                            children: [
                              Text(
                                "I1: ${currentPoint['C1']?.toStringAsFixed(2) ?? '--'}A",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6A7185),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "I2: ${currentPoint['C2']?.toStringAsFixed(2) ?? '--'}A",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6A7185),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "I3: ${currentPoint['C3']?.toStringAsFixed(2) ?? '--'}A",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6A7185),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 220,
                child: Obx(
                  () {
                    if (controller.isLoadingCurrent.value) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      return controller.current.isNotEmpty &&
                              controller.current.isNotEmpty
                          ? SfCartesianChart(
                              zoomPanBehavior: _zoomPanBehavior,
                              trackballBehavior:
                                  controller.currentTrackball.value,
                              primaryXAxis: DateTimeAxis(
                                minimum: controller.current.length == 1
                                    ? controller.current.first.timeStamp
                                        ?.subtract(const Duration(minutes: 10))
                                    : null,
                                maximum: controller.current.length == 1
                                    ? controller.current.first.timeStamp
                                        ?.add(const Duration(minutes: 10))
                                    : null,
                                desiredIntervals:
                                    controller.current.length == 1 ? 1 : null,
                                enableAutoIntervalOnZooming: true,
                                intervalType: DateTimeIntervalType.minutes,
                                dateFormat: DateFormat('dd:MM:yyyy HH:mm'),
                                majorGridLines: const MajorGridLines(width: 0),
                                axisLabelFormatter:
                                    (AxisLabelRenderDetails args) {
                                  final DateTime date =
                                      DateTime.fromMillisecondsSinceEpoch(
                                    args.value.toInt(),
                                    isUtc: true,
                                  );
                                  final String formattedLabel =
                                      DateFormat('HH:mm').format(date);
                                  return ChartAxisLabel(formattedLabel,
                                      const TextStyle(fontSize: 12));
                                },
                              ),
                              primaryYAxis: NumericAxis(
                                numberFormat: NumberFormat('#.#'),
                                minimum: _getMinYValue().toDouble(),
                                maximum: _getMaxYValue().toDouble(),
                                interval: 10,
                              ),
                              series: _getSeries(['C1', 'C2', 'C3']),
                              legend: const Legend(
                                isVisible: true,
                                position: LegendPosition.bottom,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/No graph.svg',
                                    height: 70,
                                    width: 70,
                                  ),
                                  AppText(
                                    text: 'No-Graph',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ],
                              ),
                            );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ].divide(const SizedBox(height: 6)),
    );
  }

  List<LineSeries<dynamic, DateTime>> _getSeries(List<String> selectedOptions) {
    List<LineSeries<dynamic, DateTime>> series = [];
    if (selectedOptions.contains('C1')) {
      series.add(LineSeries<dynamic, DateTime>(
        name: 'C1',
        dataSource: controller.current,
        xValueMapper: (data, _) => data.timeStamp,
        yValueMapper: (data, _) => data.currentY ?? 0,
        color: Colors.red,
        width: 2,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 4,
          width: 4,
          shape: DataMarkerType.circle,
          color: Colors.red,
          borderWidth: 2,
          borderColor: Colors.red,
        ),
      ));
    }
    if (selectedOptions.contains('C2')) {
      series.add(LineSeries<dynamic, DateTime>(
        name: 'C2',
        dataSource: controller.current,
        xValueMapper: (data, _) => data.timeStamp,
        yValueMapper: (data, _) => data.currentB ?? 0,
        color: Colors.yellow,
        width: 2,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 4,
          width: 4,
          shape: DataMarkerType.circle,
          color: Colors.yellow,
          borderWidth: 2,
          borderColor: Colors.yellow,
        ),
      ));
    }
    if (selectedOptions.contains('C3')) {
      series.add(LineSeries<dynamic, DateTime>(
        name: 'C3',
        dataSource: controller.current,
        xValueMapper: (data, _) => data.timeStamp,
        yValueMapper: (data, _) => data.currentR ?? 0,
        color: Colors.blue,
        width: 2,
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 4,
          width: 4,
          shape: DataMarkerType.circle,
          color: Colors.blue,
          borderWidth: 2,
          borderColor: Colors.blue,
        ),
      ));
    }
    return series;
  }
}
