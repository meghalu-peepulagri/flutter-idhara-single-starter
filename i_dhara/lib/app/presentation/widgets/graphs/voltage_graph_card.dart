import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/utils/app_text/app_text.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:i_dhara/app/presentation/widgets/location_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class VoltageGraphWidget extends StatefulWidget {
  final List<DateTime?> selectedDateRange;
  final String motorName;
  final ValueNotifier<dynamic> sharedPointNotifier;
  final ValueNotifier<DateTime?> sharedTimeNotifier;

  const VoltageGraphWidget({
    super.key,
    required this.selectedDateRange,
    required this.motorName,
    required this.sharedPointNotifier,
    required this.sharedTimeNotifier,
  });

  @override
  State<VoltageGraphWidget> createState() => _VoltageGraphWidgetState();
}

class _VoltageGraphWidgetState extends State<VoltageGraphWidget> {
  late ZoomPanBehavior _zoomPanBehavior;
  late Future<void> _dataFuture;
  late VoidCallback? _timeListener;
  late StreamSubscription<bool> _refreshSub;
  late StreamSubscription<bool> _loadingSub;
  late StreamSubscription<bool> _modalSub;
  bool _previousEnable = true; // Track to avoid unnecessary recreation

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

    // Listener for shared time changes
    _timeListener = () {
      if (widget.sharedTimeNotifier.value != null &&
          controller.voltageTrackball.value!.enable) {
        final sharedIndex = controller.voltage.indexWhere(
          (data) => data.timeStamp == widget.sharedTimeNotifier.value,
        );
        if (sharedIndex != -1) {
          final data = controller.voltage[sharedIndex];
          widget.sharedPointNotifier.value = {
            'vry': data.lineVoltageY,
            'vyb': data.lineVoltageB,
            'vbr': data.lineVoltageR,
          };
          // Show only if enabled
          _showTrackballAtIndex(sharedIndex);
        }
      }
    };
    widget.sharedTimeNotifier.addListener(_timeListener!);

    // Optimized listeners: recreate only if enable changes
    _refreshSub = controller.isRefreshing.listen((bool val) {
      if (mounted) _updateTrackballIfNeeded();
    });
    _loadingSub = controller.isLoadingVoltage.listen((bool val) {
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
        controller.isLoadingVoltage.value ||
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
        controller.isLoadingVoltage.value ||
        controller.isModalOpen.value;
    final enable = !isDisabled;
    controller.voltageTrackball.value = TrackballBehavior(
      enable: enable,
      lineType: TrackballLineType.vertical,
      shouldAlwaysShow: enable,
      activationMode: enable ? ActivationMode.singleTap : ActivationMode.none,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      tooltipSettings: const InteractiveTooltip(enable: false),
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
      controller.voltageTrackball.value?.hide(); // Explicit hide on disable
    }
  }

  void _showTrackballAtIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.voltageTrackball.value!.enable) {
        controller.voltageTrackball.value?.showByIndex(index);
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
    await controller.fetchtotalkvar(widget.selectedDateRange);
    if (controller.voltage.isNotEmpty) {
      int lastNonZeroIndex = controller.voltage.length - 1;
      for (int i = controller.voltage.length - 1; i >= 0; i--) {
        final point = controller.voltage[i];
        if ((point.lineVoltageY ?? 0) > 0 ||
            (point.lineVoltageB ?? 0) > 0 ||
            (point.lineVoltageR ?? 0) > 0) {
          lastNonZeroIndex = i;
          break;
        }
      }
      final lastPoint = controller.voltage[lastNonZeroIndex];
      widget.sharedPointNotifier.value = {
        'vry': lastPoint.lineVoltageY,
        'vyb': lastPoint.lineVoltageB,
        'vbr': lastPoint.lineVoltageR,
      };
      widget.sharedTimeNotifier.value = lastPoint.timeStamp;

      // Delay for stability post-load/rebuild
      await Future.delayed(const Duration(milliseconds: 300));
      if (controller.voltageTrackball.value!.enable) {
        _showTrackballAtIndex(lastNonZeroIndex);
      }
    }
  }

  num _getMaxYValue() {
    if (controller.voltage.isEmpty) return 100;
    num maxValue = 0;
    for (var e in controller.voltage) {
      maxValue = [
        maxValue,
        e.lineVoltageY ?? 0,
        e.lineVoltageB ?? 0,
        e.lineVoltageR ?? 0
      ].reduce((a, b) => a > b ? a : b);
    }
    maxValue += 40;
    return ((maxValue / 100).ceil()) * 100;
  }

  num _getMinYValue() {
    if (controller.voltage.isEmpty) return 0;
    num minValue = 0;
    for (var e in controller.voltage) {
      minValue = [
        minValue,
        e.lineVoltageY ?? 0,
        e.lineVoltageB ?? 0,
        e.lineVoltageR ?? 0
      ].reduce((a, b) => a < b ? a : b);
    }
    return minValue < 0 ? minValue - 10 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: SvgPicture.asset(
                            'assets/images/high-voltage_1_(1).svg',
                            fit: BoxFit.cover),
                      ),
                      Text(
                        'Total Voltage',
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
              Flexible(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 8, 0),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: widget.sharedTimeNotifier,
                            builder: (context, currentTime, _) {
                              return Row(children: [
                                Text(
                                  currentTime != null
                                      ? DateFormat('dd/MM HH:mm')
                                          .format(currentTime)
                                      : '--',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Lato',
                                        color: const Color(0xFF6A7185),
                                        fontSize: 12,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ]);
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: widget.sharedPointNotifier,
                            builder: (context, currentPoints, child) {
                              if (currentPoints == null) {
                                return const Text(
                                  "voltage: --",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A7185),
                                  ),
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "V1: ${currentPoints['vry']?.toStringAsFixed(2) ?? '--'}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6A7185),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "V2: ${currentPoints['vyb']?.toStringAsFixed(2) ?? '--'}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6A7185),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "V3: ${currentPoints['vbr']?.toStringAsFixed(2) ?? '--'}",
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
                ),
              ),
              Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Obx(
                  () {
                    if (controller.isLoadingVoltage.value) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      return controller.voltage.isNotEmpty
                          ? SfCartesianChart(
                              zoomPanBehavior: _zoomPanBehavior,
                              trackballBehavior:
                                  controller.voltageTrackball.value,
                              primaryXAxis: DateTimeAxis(
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
                                minimum: controller.voltage.length == 1
                                    ? controller.voltage.first.timeStamp
                                        ?.subtract(const Duration(minutes: 10))
                                    : null,
                                maximum: controller.voltage.length == 1
                                    ? controller.voltage.first.timeStamp
                                        ?.add(const Duration(minutes: 10))
                                    : null,
                                desiredIntervals:
                                    controller.voltage.length == 1 ? 1 : null,
                              ),
                              primaryYAxis: NumericAxis(
                                numberFormat: NumberFormat('#.#'),
                                minimum: 0,
                                maximum: _getMaxYValue().toDouble(),
                                interval: 100,
                              ),
                              series: _getSeries(['V1', 'V2', 'V3']),
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
      ],
    );
  }

  List<LineSeries<dynamic, DateTime>> _getSeries(List<String> selectedOptions) {
    List<LineSeries<dynamic, DateTime>> series = [];
    if (selectedOptions.contains('V1')) {
      series.add(
        LineSeries<dynamic, DateTime>(
          name: 'V1',
          dataSource: controller.voltage,
          xValueMapper: (data, _) => data.timeStamp,
          yValueMapper: (data, _) => data.lineVoltageY,
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
        ),
      );
    }
    if (selectedOptions.contains('V2')) {
      series.add(
        LineSeries<dynamic, DateTime>(
          name: 'V2',
          dataSource: controller.voltage,
          xValueMapper: (data, _) => data.timeStamp,
          yValueMapper: (data, _) => data.lineVoltageB,
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
        ),
      );
    }
    if (selectedOptions.contains('V3')) {
      series.add(
        LineSeries<dynamic, DateTime>(
          name: 'V3',
          dataSource: controller.voltage,
          xValueMapper: (data, _) => data.timeStamp,
          yValueMapper: (data, _) => data.lineVoltageR,
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
        ),
      );
    }
    return series;
  }
}
