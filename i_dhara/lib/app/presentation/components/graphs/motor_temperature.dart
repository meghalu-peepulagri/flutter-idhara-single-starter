import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/modules/motor_details/motor_details_controller.dart';
import 'package:i_dhara/app/presentation/widgets/no_data_view.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../popups/temperature_popup.dart';

class MotorTemperatureWidget extends StatefulWidget {
  final List<DateTime?> selectedDateRange;

  const MotorTemperatureWidget({
    super.key,
    required this.selectedDateRange,
  });

  @override
  State<MotorTemperatureWidget> createState() => _MotorTemperatureWidgetState();
}

class _MotorTemperatureWidgetState extends State<MotorTemperatureWidget> {
  late TooltipBehavior _tooltipBehavior;

  final AnalyticsController analyticsController = Get.find();

  double _thresholdValue = 45.0;
  static const double _yAxisMin = 0;
  static const double _yAxisMax = 150;
  final GlobalKey _chartStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      header: '',
      format: 'point.x : point.y°C',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                // Header section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
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
                        Row(spacing: 8, children: [
                          SvgPicture.asset(
                            'assets/images/temperature_icon.svg',
                            width: 28,
                            height: 28,
                          ),
                          Text(
                            'Temperature',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                    fontFamily: 'Lato',
                                    color: const Color(0xFF0A0A0A),
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/Ellipse.svg',
                                height: 40,
                              ),
                              const Text(
                                '45',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(width: 6),
                        Row(
                          spacing: 10,
                          children: [
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffF2994A),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        height: 1.0,
                                        letterSpacing: 0),
                                  )),
                            ),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const TemperaturePopup();
                                  },
                                );
                              },
                              child: SizedBox(
                                child: SvgPicture.asset(
                                    width: 28,
                                    height: 28,
                                    'assets/images/edit_button2.svg'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                // Chart section
                analyticsController.isLoadingtemperature.value
                    ? const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: GraphLottieLoading()),
                      )
                    : analyticsController.temperaturePoints.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: NoGraphsFound(),
                          )
                        : Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, top: 4, right: 12, bottom: 8),
                              child: LayoutBuilder(
                                builder: (_, constraints) {
                                  const plotLeft = 45.0;
                                  const plotTop = 5.0;
                                  final plotBottom =
                                      constraints.maxHeight - 50.0;
                                  const plotRight = 5.0;
                                  final plotHeight = plotBottom - plotTop;
                                  final fraction =
                                      (_thresholdValue - _yAxisMin) /
                                          (_yAxisMax - _yAxisMin);
                                  final lineY =
                                      plotBottom - (fraction * plotHeight);
                                  return Stack(
                                    key: _chartStackKey,
                                    clipBehavior: Clip.none,
                                    children: [
                                      SfCartesianChart(
                                        tooltipBehavior: _tooltipBehavior,
                                        primaryXAxis: const CategoryAxis(
                                          labelStyle: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF57636C),
                                          ),
                                          labelRotation: -45,
                                          majorGridLines:
                                              MajorGridLines(width: 0),
                                          majorTickLines:
                                              MajorTickLines(size: 0),
                                          axisLine: AxisLine(
                                            color: Color(0xFFE0E0E0),
                                          ),
                                          title: AxisTitle(
                                            text: 'Time',
                                            textStyle: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Lato',
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF57636C),
                                            ),
                                          ),
                                        ),
                                        primaryYAxis: NumericAxis(
                                          labelStyle: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF57636C),
                                          ),
                                          majorGridLines: const MajorGridLines(
                                            width: 0.5,
                                            color: Color(0xFFE0E0E0),
                                            dashArray: <double>[4, 4],
                                          ),
                                          majorTickLines:
                                              const MajorTickLines(size: 0),
                                          axisLine: const AxisLine(
                                            color: Color(0xFFE0E0E0),
                                          ),
                                          title: const AxisTitle(
                                            text: 'Temperature (°C)',
                                            textStyle: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Lato',
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF57636C),
                                            ),
                                          ),
                                          minimum: _yAxisMin,
                                          maximum: _yAxisMax,
                                          plotBands: <PlotBand>[
                                            PlotBand(
                                              start: _thresholdValue,
                                              end: _thresholdValue,
                                              borderColor:
                                                  const Color(0xFFEB5757),
                                              borderWidth: 2,
                                              dashArray: const <double>[6, 3],
                                            ),
                                          ],
                                        ),
                                        series: <CartesianSeries>[
                                          ColumnSeries<TemperatureDataPoint,
                                              String>(
                                            dataSource: analyticsController
                                                .temperaturePoints,
                                            xValueMapper: (data, _) =>
                                                data.hour,
                                            yValueMapper: (data, _) =>
                                                data.temperature,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                            width: 0.6,
                                            gradient: const LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Color(0xFFF2994A),
                                                Color(0xFFEB5757),
                                              ],
                                            ),
                                            dataLabelSettings:
                                                const DataLabelSettings(
                                              isVisible: false,
                                            ),
                                          ),
                                        ],
                                        legend: const Legend(isVisible: false),
                                      ),
                                      // Draggable threshold line handle
                                      Positioned(
                                        left: plotLeft,
                                        right: plotRight,
                                        top: lineY.clamp(plotTop, plotBottom) -
                                            12,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onVerticalDragUpdate: (details) {
                                            final box = _chartStackKey
                                                    .currentContext
                                                    ?.findRenderObject()
                                                as RenderBox?;
                                            if (box == null) return;
                                            final localPos = box.globalToLocal(
                                                details.globalPosition);
                                            final clampedY = localPos.dy
                                                .clamp(plotTop, plotBottom);
                                            final newValue = _yAxisMin +
                                                ((plotBottom - clampedY) /
                                                        plotHeight) *
                                                    (_yAxisMax - _yAxisMin);
                                            setState(() {
                                              _thresholdValue = newValue.clamp(
                                                  _yAxisMin, _yAxisMax);
                                            });
                                          },
                                          child: SizedBox(
                                            height: 24,
                                            child: Row(
                                              children: [
                                                // Left drag indicator
                                                Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFFEB5757),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Value label on right
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEB5757),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    '${_thresholdValue.toInt()}°C',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
}

/// Data model for a temperature reading at a given hour.
class TemperatureDataPoint {
  final String hour;
  final double temperature;

  TemperatureDataPoint(this.hour, this.temperature);
}
