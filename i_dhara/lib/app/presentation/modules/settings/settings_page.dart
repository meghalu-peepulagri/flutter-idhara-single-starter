import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_widgets.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/settings_current_card.dart';
import 'package:i_dhara/app/presentation/components/settings_voltage_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/popups/default_setting_popup.dart';
import '../../components/popups/setting_update.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final SettingsController controller = Get.put(SettingsController());
  final scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _subscription;
  Map<String, dynamic> updatedpayload = {};

  late MqttService mqttService;
  MotorData? motorData;
  final GlobalKey<SettingsVoltageCardState> voltageCardKey = GlobalKey();
  final GlobalKey<SettingsCurrentCardState> currentCardKey = GlobalKey();
  bool _ackInProgress = false;
  bool isVoltageRange = false;
  bool isCurrentRange = false;
  bool allowSnackbar = true;
  bool isSnackbarShown = false;
  bool isbuttonActive = false;

  // New: Track current values to compare with initial
  double? _currentVoltageLow;
  double? _currentVoltageHigh;
  double? _currentCurrentLow;
  double? _currentCurrentHigh;
  @override
  void initState() {
    super.initState();
    mqttService = MqttService();
    mqttConnection();
    mqttService.settingstream.listen((data) async {
      final type = data["D"];
      final topic = data["topic"];
      print("line 599--------> $topic t====> ${controller.pcbNumber.value}");
      if (type == 1 && !_ackInProgress && topic == controller.pcbNumber.value) {
        isSnackbarShown = true;
        _ackInProgress = true;
        getsuccessSnackBar("Settings updated successfully");
        controller.isLoading.value = true;
        await controller.fetchUserSettings2();
        controller.isLoading.value = false;
        await Future.delayed(const Duration(seconds: 5), () {
          _ackInProgress = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  mqttConnection() async {
    await mqttService.initializeMqttClient();
  }

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  void _handleCancel() {
    voltageCardKey.currentState?.resetValues();
    currentCardKey.currentState?.resetValues();
    setState(() {
      isbuttonActive = false;
    });
  }

  Map<String, dynamic> diffNestedPayload({
    required Map<String, dynamic> newPayload,
    required Map<String, dynamic> oldPayload,
    required String key,
  }) {
    final newMap = Map<String, dynamic>.from(newPayload[key] ?? {});
    final oldMap = Map<String, dynamic>.from(oldPayload[key] ?? {});

    newMap.removeWhere((k, v) {
      return oldMap.containsKey(k) && oldMap[k] == v;
    });

    if (newMap.isEmpty) {
      newPayload.remove(key);
    } else {
      newPayload[key] = newMap;
    }
    return newPayload;
  }

  void _checkForChanges() {
    final settings = controller.userSettings2.value;
    if (settings == null) return;

    final initialVoltageLow = settings.lvf?.toDouble() ?? 180.0;
    final initialVoltageHigh = settings.hvf?.toDouble() ?? 280.0;
    final initialCurrentLow = settings.drf?.toDouble() ?? 180.0;
    final initialCurrentHigh = settings.olf?.toDouble() ?? 280.0;

    final currentVoltageLow = _currentVoltageLow ?? initialVoltageLow;
    final currentVoltageHigh = _currentVoltageHigh ?? initialVoltageHigh;
    final currentCurrentLow = _currentCurrentLow ?? initialCurrentLow;
    final currentCurrentHigh = _currentCurrentHigh ?? initialCurrentHigh;

    final hasChanges = (currentVoltageLow != initialVoltageLow) ||
        (currentVoltageHigh != initialVoltageHigh) ||
        (currentCurrentLow != initialCurrentLow) ||
        (currentCurrentHigh != initialCurrentHigh);

    if (isbuttonActive != hasChanges) {
      setState(() {
        isbuttonActive = hasChanges;
      });
    }
  }

  void _handleSave(
      bool vmin, bool vmax, bool cmin, bool cmax, String pcbNumber) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm Setting Updates',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w500, // Medium
                    height: 1.0, // 100% line height
                    letterSpacing: 0,
                  ),
                ),

                const SizedBox(height: 20),

                /// Voltage Range Card
                if (isVoltageRange)
                  infoCard(
                      bgColor: const Color(0xFFEAF3FF),
                      iconBg: const Color(0xFF3B82F6),
                      svg: 'assets/images/voltage_range.svg',
                      title: "Voltage Range",
                      lowOld:
                          "${controller.userSettings2.value!.lvf.toString()}A",
                      lowNew: "${controller.lvf.value.toString()}A",
                      highOld:
                          "${controller.userSettings2.value!.hvf.toString()}A",
                      highNew: "${controller.hvf.value.toString()}A",
                      valueColor: const Color(0xFF2563EB),
                      vmin: vmin,
                      vmax: vmax,
                      cmin: false,
                      cmax: false),
                const SizedBox(height: 12),
                if (isCurrentRange)
                  infoCard(
                      bgColor: const Color(0xFFFFF3E8),
                      iconBg: const Color(0xFFFF7A00),
                      svg: 'assets/images/current_range.svg',
                      title: "Current Range",
                      lowOld:
                          "${controller.userSettings2.value?.drf?.toInt()}A",
                      lowNew: "${controller.drf.value.toInt()}A",
                      highOld:
                          "${controller.userSettings2.value?.olf?.toInt()}A",
                      highNew: "${controller.olf.value.toString()}A",
                      valueColor: const Color(0xFFF97316),
                      vmin: false,
                      vmax: false,
                      cmin: cmin,
                      cmax: cmax),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleCancel();
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FFButtonWidget(
                            showLoadingIndicator: true,
                            text: 'Confirm & Save',
                            onPressed: () async {
                              isSnackbarShown = false;
                              Navigator.of(context).pop();
                              await mqttService.publishUpdateSettings(
                                  controller.lvf.value,
                                  controller.hvf.value,
                                  pcbNumber,
                                  controller.drf.value,
                                  controller.olf.value,
                                  updatedpayload);
                              await controller.fetchupdateSettings();
                              Future.delayed(const Duration(seconds: 8), () {
                                if (!isSnackbarShown)
                                  geterrorSnackBar(
                                      "No response from the device");
                                _handleCancel();
                              });
                            },
                            options: const FFButtonOptions(
                              color: Color(0xff00A63E),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _defaultSettingsPopUp(BuildContext context) async {
    showDeviceSettingConfirmDialog(
      context,
      title: 'Confirm Default Settings',
      message: 'Are you sure you want to fetch the default settings?',
      onConfirm: () async {
        await controller.fetchdefaultSettings();
      },
    );
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
                                  Routes.devices,
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
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: AppLottieLoading(),
                    );
                  }
                  final settings = controller.userSettings2.value;
                  return Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 25.0, 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                Text(
                                  controller.pumpName.value ?? 'N/A',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF004E7E),
                                        fontSize: 18.0,
                                      ),
                                ),
                                Text(
                                  "${controller.pumpHP.value} HP" ?? '0 HP',
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
                            Container(
                              height: 25,
                              width: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FFButtonWidget(
                                onPressed: () {
                                  _defaultSettingsPopUp(context);
                                },
                                text: 'Default',
                                options: FFButtonOptions(
                                  height: 40.0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  color: Colors.transparent,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Manrope',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  elevation: 0.0,
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            controller.isrefreshing.value = true;
                            _handleCancel();
                            await controller.fetchdata();
                            controller.isrefreshing.value = false;
                          },
                          child: Skeletonizer(
                            enabled: controller.isrefreshing.value,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 24.0),
                              child: Column(
                                children: [
                                  SettingsVoltageCard(
                                    key: voltageCardKey,
                                    initialLowVoltage: controller
                                            .userSettings2.value?.lvf
                                            ?.toDouble() ??
                                        180.0,
                                    initialHighVoltage: controller
                                            .userSettings2.value?.hvf
                                            ?.toDouble() ??
                                        280.0,
                                    motorName:
                                        settings?.starter?.name?.toString() ??
                                            'Pump 1',
                                    motorHp: '3 HP',
                                    onChanged: (low, high) {
                                      _currentVoltageLow = low;
                                      _currentVoltageHigh = high;
                                      _checkForChanges();
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SettingsCurrentCard(
                                    key: currentCardKey,
                                    initialLowCurrent:
                                        settings?.drf?.toDouble() ??
                                            180.0, // NOTE: Check mapping
                                    initialHighCurrent:
                                        settings?.olf?.toDouble() ??
                                            280.0, // NOTE: Check mapping
                                    motorName:
                                        settings?.starter?.name?.toString() ??
                                            'Pump 1',
                                    motorHp: '3 HP',
                                    onChanged: (low, high) {
                                      _currentCurrentLow = low;
                                      _currentCurrentHigh = high;
                                      _checkForChanges();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
                                  color: settings?.starter != null
                                      ? FlutterFlowTheme.of(context)
                                          .secondaryBackground
                                      : Colors.white38,
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
                                  onPressed: !isbuttonActive
                                      ? null
                                      : () {
                                          final voltageValues = voltageCardKey
                                              .currentState
                                              ?.getValues();
                                          final currentValues = currentCardKey
                                              .currentState
                                              ?.getValues();
                                          controller.lvf.value =
                                              voltageValues?['low']?.toInt() ??
                                                  controller.userSettings2
                                                      .value!.lvf!;
                                          controller.hvf.value =
                                              voltageValues?['high']?.toInt() ??
                                                  controller.userSettings2
                                                      .value!.hvf!;
                                          controller.drf.value =
                                              currentValues?['low']?.toInt() ??
                                                  controller
                                                      .userSettings2.value!.drf!
                                                      .toInt();
                                          controller.olf.value =
                                              currentValues?['high']?.toInt() ??
                                                  controller
                                                      .userSettings2.value!.olf!
                                                      .toInt();
                                          var pcbNumber =
                                              controller.pcbNumber.value;
                                          updatedpayload = {
                                            "dvc_c": {
                                              "lvf": controller.lvf.value,
                                              "hvf": controller.hvf.value,
                                              "drf": controller.drf.value,
                                              "olf": controller.olf.value,
                                            },
                                          };
                                          updatedpayload = diffNestedPayload(
                                            newPayload: updatedpayload,
                                            oldPayload: controller.payload,
                                            key: "dvc_c",
                                          );
                                          final Map<String, dynamic> dvcMap =
                                              updatedpayload["dvc_c"] ?? {};
                                          setState(() {
                                            isVoltageRange =
                                                dvcMap.containsKey("lvf") ||
                                                    dvcMap.containsKey("hvf");
                                            isCurrentRange =
                                                dvcMap.containsKey("drf") ||
                                                    dvcMap.containsKey("olf");
                                            bool vmin =
                                                dvcMap.containsKey("lvf");
                                            bool vmax =
                                                dvcMap.containsKey("hvf");
                                            bool cmin =
                                                dvcMap.containsKey("drf");
                                            bool cmax =
                                                dvcMap.containsKey("olf");
                                            if (isVoltageRange ||
                                                isCurrentRange) {
                                              _handleSave(vmin, vmax, cmin,
                                                  cmax, pcbNumber);
                                              isbuttonActive = false;
                                            } else {}
                                          });
                                        },
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
                                    disabledColor: const Color(0xFFB0B0B0),
                                    disabledTextColor: Colors.white,
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
