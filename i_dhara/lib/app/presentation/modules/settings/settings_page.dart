import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';
import 'package:i_dhara/app/presentation/components/settings_current_card.dart';
import 'package:i_dhara/app/presentation/components/settings_voltage_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final SettingsController controller = Get.put(SettingsController());
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Keys to access card states
  // Keys to access card states
  final GlobalKey<SettingsVoltageCardState> voltageCardKey = GlobalKey();
  final GlobalKey<SettingsCurrentCardState> currentCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  void _handleCancel() {
    voltageCardKey.currentState?.resetValues();
    currentCardKey.currentState?.resetValues();
  }

  void _handleSave() {
    final voltageValues = voltageCardKey.currentState?.getValues();
    final currentValues = currentCardKey.currentState?.getValues();

    // Handle save logic here
    // Handle save logic here
    debugPrint(
        'Voltage - Low: ${voltageValues?['low']}, High: ${voltageValues?['high']}');
    debugPrint(
        'Current - Low: ${currentValues?['low']}, High: ${currentValues?['high']}');

    // You can call your controller methods here
    // controller.updateSettings(faultValues, alertValues);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFEBF3FE),
        endDrawer: Drawer(width: 250, elevation: 16, child: SidebarWidget()),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 0.0),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Settings',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: const Color(0xFF004E7E),
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                Get.offAllNamed(
                                  Routes.dashboard,
                                  arguments: {'refresh': true},
                                );
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF004E7E),
                                size: 20.0,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                onTapMenu();
                              },
                              child: Container(
                                decoration: const BoxDecoration(),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.menu_sharp,
                                    color: Color(0xFF121212),
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (controller.userSettings.value == null) {
                    return const Center(
                      child: Text('No settings available'),
                    );
                  }

                  final settings = controller.userSettings.value;
                  if (settings == null) {
                    return const Center(
                      child: Text('No settings available'),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                        child: Row(
                          children: [
                            Text(
                              settings.starter?.name?.toString() ?? 'Pump 1',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF004E7E),
                                    fontSize: 18.0,
                                  ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '3 HP',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 24.0),
                          child: Column(
                            children: [
                              // Voltages Section
                              // Voltages Section
                              SettingsVoltageCard(
                                key: voltageCardKey,
                                initialLowVoltage:
                                    settings.dvcFltLvf?.toDouble() ?? 180.0,
                                initialHighVoltage:
                                    settings.dvcFltHvf?.toDouble() ?? 280.0,
                                motorName: settings.starter?.name?.toString() ??
                                    'Pump 1',
                                motorHp: '3 HP',
                              ),
                              const SizedBox(height: 24),

                              // Currents Section
                              // Currents Section
                              SettingsCurrentCard(
                                key: currentCardKey,
                                initialLowCurrent:
                                    settings.dvcFltLvf?.toDouble() ??
                                        180.0, // NOTE: Check mapping
                                initialHighCurrent:
                                    settings.dvcFltHvf?.toDouble() ??
                                        280.0, // NOTE: Check mapping
                                motorName: settings.starter?.name?.toString() ??
                                    'Pump 1',
                                motorHp: '3 HP',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Single Action Buttons at Bottom
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: FFButtonWidget(
                                onPressed: _handleCancel,
                                text: 'Cancel',
                                options: FFButtonOptions(
                                  height: 45.0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Manrope',
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  elevation: 0.0,
                                  borderSide: const BorderSide(
                                      color: Color(0x38000000)),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24.0),
                            Expanded(
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF004E7E),
                                      Color(0xFF3686AF)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FFButtonWidget(
                                  onPressed: _handleSave,
                                  text: 'Save',
                                  options: FFButtonOptions(
                                    height: 45.0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0),
                                    color: Colors.transparent,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Manrope',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
