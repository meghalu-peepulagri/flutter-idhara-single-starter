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

  // StreamSubscription to properly manage the MQTT stream listener
  StreamSubscription? _mqttStreamSubscription;

  // New: Track current values to compare with initial
  double? _currentVoltageLow;
  double? _currentVoltageHigh;
  double? _currentCurrentLow;
  double? _currentCurrentHigh;

  // Store original user settings before loading defaults
  int? _originalVoltageLow;
  int? _originalVoltageHigh;
  int? _originalCurrentLow;
  int? _originalCurrentHigh;

  @override
  void initState() {
    super.initState();
    mqttService = MqttService();
    mqttConnection();

    // Assign the stream listener to the subscription variable
    _mqttStreamSubscription = mqttService.settingstream.listen((data) async {
      final type = data["D"];
      final topic = data["topic"];
      final pcbNumber = controller.pcbNumber.value;
      final macAddress = controller.macAddress.value;

      if (type == 1 &&
          !_ackInProgress &&
          (topic == pcbNumber || topic == macAddress)) {
        // Set flag BEFORE showing snackbar to prevent duplicates
        _ackInProgress = true;
        isSnackbarShown = true;

        // Show success snackbar only once
        getsuccessSnackBar("Settings updated successfully");

        controller.isLoading.value = true;
        await controller.fetchUserSettings2();
        controller.isLoading.value = false;

        // Reset original values after successful save
        _originalVoltageLow = null;
        _originalVoltageHigh = null;
        _originalCurrentLow = null;
        _originalCurrentHigh = null;

        // Reset flag after 5 seconds
        await Future.delayed(const Duration(seconds: 5), () {
          _ackInProgress = false;
          isSnackbarShown = false;
        });
      }
    });
  }

  num calculatedFlc(int value) {
    final flc = controller.userSettings2.value?.flc?.toInt() ?? 0;
    final percantage = value / 100;
    final result = flc * percantage;
    final roundedResult = double.parse(result.toStringAsFixed(2));

    print("line 77 --------> $flc $percantage  $result");
    return roundedResult;
  }

  @override
  void dispose() {
    // Cancel the MQTT stream subscription to prevent memory leaks
    _mqttStreamSubscription?.cancel();
    super.dispose();
  }

  mqttConnection() async {
    await mqttService.initializeMqttClient();
  }

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  Future<void> _handleCancel() async {
    // Reset local form values
    _currentVoltageLow = null;
    _currentVoltageHigh = null;
    _currentCurrentLow = null;
    _currentCurrentHigh = null;

    // Reset original values (used for default settings comparison)
    _originalVoltageLow = null;
    _originalVoltageHigh = null;
    _originalCurrentLow = null;
    _originalCurrentHigh = null;

    // Reload actual user settings (not default settings)
    await controller.fetchUserSettings2();

    // Small delay to ensure controller state is updated
    await Future.delayed(const Duration(milliseconds: 100));

    // Reset cards to show actual user values after data is loaded
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
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Dynamic dialog width: 85% of screen width, with min 280 and max 400
        final dialogWidth = (screenWidth * 0.85).clamp(280.0, 400.0);

        // Dynamic padding based on screen size
        final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
        final verticalPadding = screenHeight < 600 ? 16.0 : 20.0;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: (screenWidth - dialogWidth) / 2,
            vertical: 24.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            0,
          ),
          actionsPadding: EdgeInsets.all(horizontalPadding),
          content: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Setting Updates',
                  style: GoogleFonts.dmSans(
                    fontSize: screenWidth < 360 ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004E7E),
                  ),
                ),
                SizedBox(height: verticalPadding),

                /// Voltage Range Card
                if (isVoltageRange)
                  infoCard(
                      bgColor: const Color(0xFFEAF3FF),
                      iconBg: const Color(0xFF3B82F6),
                      svg: 'assets/images/Voltage.svg',
                      title: "Voltage Fault",
                      lowOld:
                          "${(_originalVoltageLow ?? controller.userSettings2.value!.lvf?.toInt()).toString()}V",
                      lowNew: "${controller.lvf.value.toString()}V",
                      highOld:
                          "${(_originalVoltageHigh ?? controller.userSettings2.value!.hvf?.toInt()).toString()}V",
                      highNew: "${controller.hvf.value.toString()}V",
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
                      svg: 'assets/images/Current.svg',
                      title: "Current Fault",
                      lowOld:
                          "${(_originalCurrentLow ?? controller.userSettings2.value?.drf?.toInt()).toString()}A",
                      lowNew: "${controller.drf.value.toInt()}A",
                      highOld:
                          "${(_originalCurrentHigh ?? controller.userSettings2.value?.olf?.toInt()).toString()}A",
                      highNew: "${controller.olf.value.toString()}A",
                      valueColor: const Color(0xFFF97316),
                      vmin: false,
                      vmax: false,
                      cmin: cmin,
                      cmax: cmax),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleCancel();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: dialogWidth * 0.35,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF004E7E),
                    Color(0xFF3686AF),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  isSnackbarShown = false;
                  Navigator.of(context).pop();
                  await mqttService.publishUpdateSettings(
                      pcbNumber, updatedpayload);
                  await controller.fetchupdateSettings();

                  // Wait for MQTT service to complete all retries
                  Future.delayed(const Duration(seconds: 15), () {
                    final errorMessage =
                        mqttService.commandStatusNotifier.value;
                    if (errorMessage != null && !isSnackbarShown) {
                      isSnackbarShown = true;
                      geterrorSnackBar(errorMessage);
                      _handleCancel();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  _defaultSettingsPopUp(BuildContext context) async {
    showDeviceSettingConfirmDialog(
      context,
      title: 'Restore Default Settings',
      message:
          'Restore Voltage and Current faults to default settings? Custom changes will be lost',
      svgPath: 'assets/images/default_settings.svg',
      onConfirm: () async {
        // Store original user settings BEFORE loading defaults
        _originalVoltageLow = controller.userSettings2.value?.lvf?.toInt();
        _originalVoltageHigh = controller.userSettings2.value?.hvf?.toInt();
        _originalCurrentLow = controller.userSettings2.value?.drf?.toInt();
        _originalCurrentHigh = controller.userSettings2.value?.olf?.toInt();

        updatedpayload = {};
        controller.payload = {};
        await controller.fetchdefaultSettings();

        // Reset form values
        _currentVoltageLow = null;
        _currentVoltageHigh = null;
        _currentCurrentLow = null;
        _currentCurrentHigh = null;

        // Reset cards to show default values
        voltageCardKey.currentState?.resetValues();
        currentCardKey.currentState?.resetValues();

        // Enable Save button
        setState(() {
          isbuttonActive = true;
        });
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
                    return const Padding(
                      padding: EdgeInsets.only(right: 50),
                      child: Center(
                        child: AppLottieLoading(),
                      ),
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
                                  (() {
                                    final name =
                                        (controller.pumpName.value ?? 'N/A')
                                            .replaceAll(RegExp(r'\s+'), ' ');
                                    return name.length > 16
                                        ? '${name.substring(0, 16)}...'
                                        : name;
                                  })(),
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF000000),
                                        fontSize: 16.0,
                                      ),
                                ),
                                Text(
                                  "${controller.pumpHP.value} HP" ?? '0 HP',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF000000),
                                        fontSize: 12.0,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              height: 38,
                              width: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2994A),
                                borderRadius: BorderRadius.circular(8),
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
                                          color: const Color(0XFFFFFFFF),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14),
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

                            // Reset local form values
                            _currentVoltageLow = null;
                            _currentVoltageHigh = null;
                            _currentCurrentLow = null;
                            _currentCurrentHigh = null;

                            // Reset original values (used for default settings comparison)
                            _originalVoltageLow = null;
                            _originalVoltageHigh = null;
                            _originalCurrentLow = null;
                            _originalCurrentHigh = null;

                            // Fetch actual user settings (not default)
                            await controller.fetchUserSettings2();

                            // Small delay to ensure controller state is updated
                            await Future.delayed(
                                const Duration(milliseconds: 100));

                            // Reset cards to actual user values after data is loaded
                            voltageCardKey.currentState?.resetValues();
                            currentCardKey.currentState?.resetValues();

                            setState(() {
                              isbuttonActive = false;
                            });

                            controller.isrefreshing.value = false;
                          },
                          child: Skeletonizer(
                            enabled: controller.isrefreshing.value,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
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
                                  const SizedBox(height: 8),
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
                                          print(
                                              "line 610 ---> $updatedpayload ${controller.payload}");
                                          updatedpayload = diffNestedPayload(
                                            newPayload: updatedpayload,
                                            oldPayload: controller.payload,
                                            key: "dvc_c",
                                          );

                                          print("line 610 $updatedpayload");

                                          if (updatedpayload["dvc_c"]
                                              .containsKey("drf")) {
                                            final calculatedDrf = calculatedFlc(
                                                controller.drf.value);
                                            updatedpayload["dvc_c"]['drf'] =
                                                calculatedDrf;
                                          }
                                          if (updatedpayload["dvc_c"]
                                              .containsKey('olf')) {
                                            final calculatedOlf = calculatedFlc(
                                                controller.olf.value);
                                            updatedpayload["dvc_c"]['olf'] =
                                                calculatedOlf;
                                          }
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
