import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/motor_card/motor_controls_row.dart';
import 'package:i_dhara/app/presentation/components/motor_card/voltage_current_values_card.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';
import 'package:lottie/lottie.dart';

import 'test_run_logic_mixin.dart';

class TestRunPage extends StatefulWidget {
  const TestRunPage({super.key});

  @override
  State<TestRunPage> createState() => _TestRunPageState();
}

class _TestRunPageState extends State<TestRunPage> with TestRunLogicMixin {
  @override
  void initState() {
    super.initState();
    initLogic();
  }

  @override
  void dispose() {
    disposeLogic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF3FE),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isWaitingForAck
                  ? const Color(0xFFB0B0B0)
                  : const Color(0xFF1E1E1E)),
          onPressed: isWaitingForAck ? null : goBack,
        ),
        title: Text(
          'Test Run',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF004E7E),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: hasInternet,
          builder: (context, hasInternetValue, child) {
            if (testRunController.isLoadingApiData && fromDevices) {
              return const Padding(
                padding: EdgeInsets.only(right: 50),
                child: Center(
                  child: AppLottieLoading(),
                ),
              );
            } else if (!hasInternetValue) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 70),
                child: Center(child: NoInternetWidget()),
              );
            }

            return ValueListenableBuilder(
              valueListenable: mqttService.dataUpdateNotifier,
              builder: (context, _, __) {
                final motorData = getMotorData();

                // CRITICAL: Validate motor data is from allowed groups only
                final isValidData = motorData == null ||
                    motorData.groupId == null ||
                    ['G01', 'G02'].contains(motorData.groupId);

                if (!isValidData) {
                  // If data is from G03/G04, ignore it completely
                  debugPrint(
                      '⚠️ Test Run Page: Blocking data from group ${motorData.groupId}');
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildMotorCard(null),
                      ),
                      const Spacer(),
                      _buildBottomButtons(),
                    ],
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMotorCard(motorData),
                    ),
                    const Spacer(),
                    // if (isFailed) _buildFailureMessage(),
                    _buildBottomButtons(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMotorCard(MotorData? motorData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildMotorHeader(motorData),
            const Divider(height: 0, thickness: 1.0, color: Color(0xFFECECEC)),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
              child: VoltageCurrentValuesCard(
                motor: motor,
                mqttService: mqttService,
                isTestRunRequired: isTestRunRequired,
              ),
            ),
            const Divider(height: 2, thickness: 1.0, color: Color(0xFFECECEC)),
            MotorControlsRow(
              motor: motor,
              motorData: motorData,
              switchController: localSwitchController,
              modeController: localModeController,
              onToggleSwitch: (_) {},
              onModeChange: (_) {},
              isSwitchDisabled: true,
              isModeDisabled: true,
              onNavigateToDetails: () {},
              showTestRun: false,
              isTestRunRequired: isTestRunRequired,
            ),
          ].divide(const SizedBox(height: 4.0)),
        ),
      ),
    );
  }

  Widget _buildMotorHeader(MotorData? motorData) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(0.0),
                  child: SvgPicture.asset(
                    'assets/images/motor.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    _getDisplayName(),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                          ),
                          color: const Color(0xFF1E1E1E),
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPowerIcon(),
              const SizedBox(width: 8.0),
              _buildSignalIcon(motorData),
              if (faultValue > 0 && !isTestRunRequired) ...[
                const SizedBox(width: 8.0),
                _buildFaultIndicator(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    final aliasName = normalizeMotorName(motor.aliasName);
    final motorName = normalizeMotorName(motor.name);
    final displayName = aliasName.isNotEmpty ? aliasName : motorName;
    return displayName.length > 12
        ? '${displayName.substring(0, 12)}...'
        : displayName;
  }

  Widget _buildPowerIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0.0),
      child: SvgPicture.asset(
        isTestRunRequired
            ? 'assets/images/Power_red.svg'
            : (isPowerOn
                ? 'assets/images/power.svg'
                : 'assets/images/Power_red.svg'),
        width: 17,
        height: 17,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSignalIcon(MotorData? motorData) {
    // Block signal display if test run is required
    int bars = isTestRunRequired ? 0 : getSignalBars(motorData);
    String assetPath;
    double iconWidth = 16;
    double iconHeight = 16;

    switch (bars) {
      case 1:
        assetPath = 'assets/images/first_signal.svg';
        break;
      case 2:
        assetPath = 'assets/images/second_signal.svg';
        break;
      case 3:
        assetPath = 'assets/images/third_signal.svg';
        break;
      case 4:
        assetPath = 'assets/images/network.svg';
        break;
      case 0:
      default:
        assetPath = 'assets/images/no_network.svg';
        iconWidth = 20;
        iconHeight = 20;
        break;
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: iconWidth,
          height: iconHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFaultIndicator() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8.0, 2.0, 8.0, 2.0),
        child: Lottie.asset(
          'assets/lottie_animations/warning 1.json',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          repeat: true,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final bool buttonsDisabled = isWaitingForAck;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWaitingForAck)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF004E7E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for ack...',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Cancel button (left)
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton(
                    onPressed: buttonsDisabled ? null : goBack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: buttonsDisabled
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: buttonsDisabled
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    gradient:
                        (testRunController.isdisabled.value || buttonsDisabled)
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                    color: buttonsDisabled ? const Color(0xFFD1D5DB) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (testRunController.isdisabled.value ||
                              buttonsDisabled)
                          ? null
                          : showTestRunConfirmDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          isFailed ? 'Retry Test' : 'Test Run',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
