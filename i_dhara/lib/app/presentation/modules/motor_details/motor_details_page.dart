import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';
import 'package:i_dhara/app/presentation/components/graphs/motor_run_time_graph_card.dart';
import 'package:i_dhara/app/presentation/components/graphs/power_graph_card.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../core/flutter_flow/flutter_flow_util.dart';
import 'motor_details_controller.dart';

export 'motor_details_controller.dart';

class MotorControlWidget extends StatelessWidget {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AnalyticsController controller = Get.put(AnalyticsController());
  final RxInt selectedTabIndex = 0.obs;

  MotorControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Get.back();
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: const Color(0xFFEBF3FE),
          body: SafeArea(
            child: Obx(() {
              if (controller.isMotorDetailsLoading.value) {
                return const Padding(
                  padding: EdgeInsets.only(right: 50),
                  child: Center(child: AppLottieLoading()),
                );
              } else if (!controller.hasInternet.value) {
                return const Center(
                  child: NoInternetWidget(),
                );
              }
              return Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(1.0, 8.0, 0.0, 0.0),
                child: Column(mainAxisSize: MainAxisSize.max, children: [
                  _buildHeader(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.onrefresh,
                      child: Skeletonizer(
                        enabled: controller.isRefreshing.value,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              _buildMotorDetailsCard(context),
                              const SizedBox(height: 12),
                              _buildTabBar(context),
                              Expanded(
                                child: Obx(() => _buildTabContent(context)),
                              ),
                            ].addToStart(const SizedBox(height: 10.0)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              controller.motorName.value,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: const Color(0xFF004E7E),
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: const BoxDecoration(),
              child: InkWell(
                onTap: () {
                  Get.back();
                },
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF004E7E),
                    size: 20.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorDetailsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMotorName(context),
                      const SizedBox(height: 2),
                      _buildTimeStamp(context),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMotorHP(context),
                    const SizedBox(height: 6),
                    _buildMotorState(context),
                  ],
                ),
              ],
            ),
            _buildFaultBanner(context),
          ].divide(const SizedBox(height: 12.0)),
        ),
      ),
    );
  }

  Widget _buildMotorName(BuildContext context) {
    return Obx(() {
      return Text(
        controller.motorName.value,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              font: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
              color: const Color(0xFF0A0A0A),
              fontSize: 20.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
            ),
      );
    });
  }

  Widget _buildTimeStamp(BuildContext context) {
    return Obx(() {
      final dateText = controller.timeStamp.value.trim();
      return Row(
        children: [
          const Icon(
            Icons.sync,
            color: Color(0xFF166491),
            size: 16,
          ),
          Text(
            ' ${dateText.isEmpty || dateText == 'N/A' ? ' N/A' : dateText}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: const Color(0xFF166491),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
          ),
        ],
      );
    });
  }

  Widget _buildMotorHP(BuildContext context) {
    return Obx(() {
      return Row(
        children: [
          Text(
            '${controller.hp.value} HP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: const Color(0xFF6A7282),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
          ),
        ],
      );
    });
  }

  Widget _buildMotorState(BuildContext context) {
    return Obx(() {
      final state = controller.motorState.value;
      final isOn = state == 1;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'State :  ',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(
                    fontWeight: FontWeight.normal,
                  ),
                  color: const Color(0xFF000000),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFDCDCDC),
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle_rounded,
                  size: 10,
                  color:
                      isOn ? const Color(0xFF45A845) : const Color(0xFFF90707),
                ),
                const SizedBox(width: 6),
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w400,
                        ),
                        color: isOn
                            ? const Color(0xFF45A845)
                            : const Color(0xFFF90707),
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFaultBanner(BuildContext context) {
    return Obx(() {
      final fault = controller.faultMessage.value.trim();

      if (fault.isEmpty ||
          fault == '0' ||
          fault == 'N/A' ||
          fault.toLowerCase() == 'no fault') {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF4D9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Lottie.asset(
              'assets/lottie_animations/warning 1.json',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fault,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.dmSans(fontWeight: FontWeight.w300),
                      fontSize: 12,
                      color: const Color(0xFFFF8A00),
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            _buildTab(context, 'Mode', 0, Icons.settings),
            _buildTab(context, 'Analytics', 1, Icons.timer),
            _buildTab(context, 'Logs', 2, Icons.history),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
      BuildContext context, String title, int index, IconData icon) {
    return Expanded(
      child: Obx(() {
        final isSelected = selectedTabIndex.value == index;
        return GestureDetector(
          onTap: () => selectedTabIndex.value = index,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.black : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: isSelected
                        ? Color(0XFF000000)
                        : const Color(0XFF000000),
                    fontSize: 14.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (selectedTabIndex.value) {
      case 0:
        return _buildModeTab(context);
      case 1:
        return _buildRuntimeTab(context);
      case 2:
        return _buildLogsTab(context);
      default:
        return _buildRuntimeTab(context);
    }
  }

  Widget _buildModeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Icon(
                //   Icons.settings_suggest,
                //   size: 48,
                //   color: const Color(0xFF004E7E).withOpacity(0.7),
                // ),
                // const SizedBox(height: 16),
                Text(
                  'Motor Mode',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF004E7E),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch between Auto and Manual modes',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                /// 🔁 Your existing ToggleSwitch code stays SAME
                Obx(() {
                  final currentModeIndex = controller.localModeIndex.value;
                  final isAuto = currentModeIndex == 1;
                  final int uiIndex = isAuto ? 0 : 1;
                  final isDisabled = controller.isWaitingForModeAck.value;

                  return ToggleSwitch(
                    key: ValueKey('mode_$currentModeIndex'),
                    changeOnTap: false,
                    customWidths: const [90, 90],
                    radiusStyle: true,
                    minWidth: 80.0,
                    minHeight: 30.0,
                    initialLabelIndex: uiIndex,
                    cornerRadius: 8.0,
                    activeBgColors: !isDisabled
                        ? [
                            [const Color(0xFFFFA500)],
                            [const Color(0xFF2F80ED)]
                          ]
                        : [
                            [const Color(0xFFFFA500).withOpacity(0.3)],
                            [const Color(0xFF2F80ED).withOpacity(0.3)],
                          ],
                    activeFgColor: !isDisabled ? Colors.white : Colors.black,
                    inactiveBgColor: Colors.white,
                    inactiveFgColor: Colors.black,
                    fontSize: 12,
                    totalSwitches: 2,
                    labels: const ['Auto', 'Manual'],
                    borderWidth: 1,
                    borderColor: [Colors.grey.shade300],
                    onToggle: !isDisabled
                        ? (index) {
                            if (index == null) return;
                            final newModeIndex = index == 0 ? 1 : 0;
                            if (newModeIndex != currentModeIndex) {
                              _showModeChangeDialog(context, newModeIndex);
                            }
                          }
                        : null,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showModeChangeDialog(BuildContext context, int newModeIndex) {
    final modeName = newModeIndex == 1 ? 'Auto' : 'Manual';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: const Color(0xFF004E7E),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Change Motor Mode',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004E7E),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to change the motor mode?',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "Motor: ",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            controller.motorName.value,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF0A0A0A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'New Mode: ',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: newModeIndex == 1
                                ? const Color(0xFFFFA500).withOpacity(0.2)
                                : const Color(0xFF2F80ED).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            modeName,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: newModeIndex == 1
                                  ? const Color(0xFFFFA500)
                                  : const Color(0xFF2F80ED),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.handleModeChange(newModeIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E7E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRuntimeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      shrinkWrap: true,
      children: [
        _buildDateCard(context, controller),
        const SizedBox(height: 12),
        MotorRuntimeGraphWidget(
          selectedDateRange: controller.daterange,
        ),
        // const SizedBox(height: 16),
        // PowerGraphWidget(
        //   selectedDateRange: controller.daterange,
        // ),
      ],
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: const Color(0xFF6B7280).withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Logs Available',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF1F2937),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(BuildContext context, AnalyticsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => controller.leftClick(),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF004E7E),
                  size: 18.0,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final selectedDate =
                    controller.daterange.first ?? DateTime.now();
                return Column(
                  children: [
                    Text(
                      DateFormat('EEEE').format(selectedDate),
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF6B7280),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF004E7E),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }),
            ),
            Obx(() {
              final selectedDate = controller.daterange.first ?? DateTime.now();
              final today = DateTime.now();
              final isToday = selectedDate.year == today.year &&
                  selectedDate.month == today.month &&
                  selectedDate.day == today.day;

              return GestureDetector(
                onTap: isToday ? null : () => controller.rightClick(),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: isToday
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF004E7E),
                    size: 18.0,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
