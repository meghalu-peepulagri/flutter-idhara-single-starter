import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/services/connectivity_service.dart';
import 'package:i_dhara/app/core/utils/app_loading.dart';
import 'package:i_dhara/app/core/utils/snackbars/error_snackbar.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/presentation/components/flc_card.dart';
import 'package:i_dhara/app/presentation/components/popups/default_setting_popup.dart';
import 'package:i_dhara/app/presentation/components/settings_current_card.dart';
import 'package:i_dhara/app/presentation/components/settings_voltage_card.dart';
import 'package:i_dhara/app/presentation/modules/settings/settings_controller.dart';
import 'package:i_dhara/app/presentation/modules/sidebar/sidebar_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:i_dhara/app/presentation/widgets/no_internet_view.dart';

import 'widgets/settings_action_buttons.dart';
import 'widgets/settings_app_bar.dart';
import 'widgets/settings_confirm_dialog.dart';
import 'widgets/settings_content.dart';
import 'widgets/settings_device_info_bar.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final SettingsController controller =
      Get.put(SettingsController(), permanent: true);
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> updatedpayload = {};
  Map<String, dynamic> defaultupdatedpayload = {};

  late MqttService mqttService;
  MotorData? motorData;

  final GlobalKey<SettingsVoltageCardState> voltageCardKey = GlobalKey();
  final GlobalKey<SettingsCurrentCardState> currentCardKey = GlobalKey();
  final GlobalKey<FlcCardState> flcCardKey = GlobalKey();

  bool _ackInProgress = false;
  bool isVoltageRange = false;
  bool isCurrentRange = false;
  bool allowSnackbar = true;
  bool isSnackbarShown = false;
  bool isbuttonActive = false;
  bool _isFlcOutOfRange = false;
  bool _hasPendingSave = false;

  StreamSubscription? _mqttStreamSubscription;
  Timer? _settingsAckTimer;

  double? _currentVoltageLow;
  double? _currentVoltageHigh;
  double? _currentCurrentLow;
  double? _currentCurrentHigh;

  int? _originalVoltageLow;
  int? _originalVoltageHigh;
  int? _originalCurrentLow;
  int? _originalCurrentHigh;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    controller.fetchdata();
    controller.fetchdata();
    mqttService = MqttService();
    _mqttStreamSubscription = mqttService.settingstream.listen((data) async {
      final type = data["D"];
      final topic = data["topic"];
      final pcbNumber = controller.pcbNumber.value;

      if (topic != pcbNumber) return;

      if (type == 1 && !_ackInProgress && _hasPendingSave) {
        _settingsAckTimer?.cancel();
        _hasPendingSave = false;
        _ackInProgress = true;
        isSnackbarShown = true;
        getsuccessSnackBar("Settings updated successfully");
        controller.isLoading.value = true;
        controller.fetchupdateSettingsAck();
        controller.isLoading.value = false;
        _originalVoltageLow = null;
        _originalVoltageHigh = null;
        _originalCurrentLow = null;
        _originalCurrentHigh = null;
        setState(() {
          isbuttonActive = false;
        });
        await Future.delayed(const Duration(seconds: 5), () {
          _ackInProgress = false;
          isSnackbarShown = false;
        });
      } else if (type == 0 && !_ackInProgress && _hasPendingSave) {
        _settingsAckTimer?.cancel();
        _hasPendingSave = false;
        _ackInProgress = true;
        isSnackbarShown = true;
        geterrorSnackBar("Settings update failed");
        controller.isLoading.value = true;
        await controller.fetchUserSettings2();
        controller.isLoading.value = false;
        _currentVoltageLow = null;
        _currentVoltageHigh = null;
        _currentCurrentLow = null;
        _currentCurrentHigh = null;
        _originalVoltageLow = null;
        _originalVoltageHigh = null;
        _originalCurrentLow = null;
        _originalCurrentHigh = null;
        voltageCardKey.currentState?.resetValues();
        currentCardKey.currentState?.resetValues();
        setState(() {
          isbuttonActive = false;
        });
        await Future.delayed(const Duration(seconds: 5), () {
          _ackInProgress = false;
          isSnackbarShown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _settingsAckTimer?.cancel();
    _mqttStreamSubscription?.cancel();
    super.dispose();
  }

  // ─── Timer / ACK ──────────────────────────────────────────────────────────

  void _startAckTimer() {
    _settingsAckTimer?.cancel();
    _settingsAckTimer = Timer(const Duration(seconds: 11), _onAckTimeout);
  }

  void _onAckTimeout() {
    if (!mounted || !_hasPendingSave) return;
    _hasPendingSave = false;
    if (!isSnackbarShown) {
      isSnackbarShown = true;
      geterrorSnackBar('No acknowledgment received from device');
    }
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  void onTapMenu() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  Future<void> _handleCancel() async {
    _currentVoltageLow = null;
    _currentVoltageHigh = null;
    _currentCurrentLow = null;
    _currentCurrentHigh = null;
    _originalVoltageLow = null;
    _originalVoltageHigh = null;
    _originalCurrentLow = null;
    _originalCurrentHigh = null;

    await controller.fetchUserSettings2();
    await Future.delayed(const Duration(milliseconds: 100));

    voltageCardKey.currentState?.resetValues();
    currentCardKey.currentState?.resetValues();
    flcCardKey.currentState?.resetValue();
    controller.flc.value =
        controller.userSettings2.value?.flc?.toDouble() ?? 0.0;

    setState(() {
      isbuttonActive = false;
    });
  }

  Future<void> _handleRefresh() async {
    await _handleCancel();
    controller.isrefreshing.value = true;
    _currentVoltageLow = null;
    _currentVoltageHigh = null;
    _currentCurrentLow = null;
    _currentCurrentHigh = null;
    _originalVoltageLow = null;
    _originalVoltageHigh = null;
    _originalCurrentLow = null;
    _originalCurrentHigh = null;
    await controller.fetchUserSettings2();
    await controller.fetchUserSettingsLimits();
    await Future.delayed(const Duration(milliseconds: 100));
    voltageCardKey.currentState?.resetValues();
    currentCardKey.currentState?.resetValues();
    setState(() {
      isbuttonActive = false;
    });
    controller.isrefreshing.value = false;
  }

  void _checkForChanges() {
    final settings = controller.userSettings2.value;
    if (settings == null) return;

    final initialVoltageLow = settings.lvf?.toDouble() ?? 180.0;
    final initialVoltageHigh = settings.hvf?.toDouble() ?? 280.0;
    final initialCurrentLow = settings.drf?.toDouble() ?? 180.0;
    final initialCurrentHigh = settings.olf?.toDouble() ?? 280.0;
    final initialFlc = settings.flc?.toDouble() ?? 0.0;

    final currentVoltageLow = _currentVoltageLow ?? initialVoltageLow;
    final currentVoltageHigh = _currentVoltageHigh ?? initialVoltageHigh;
    final currentCurrentLow = _currentCurrentLow ?? initialCurrentLow;
    final currentCurrentHigh = _currentCurrentHigh ?? initialCurrentHigh;

    final hasChanges = (currentVoltageLow != initialVoltageLow) ||
        (currentVoltageHigh != initialVoltageHigh) ||
        (currentCurrentLow != initialCurrentLow) ||
        (currentCurrentHigh != initialCurrentHigh) ||
        (controller.flc.value != initialFlc);

    if (isbuttonActive != hasChanges) {
      setState(() {
        isbuttonActive = hasChanges;
      });
    }
  }

  Map<String, dynamic> diffNestedPayload({
    required Map<String, dynamic> newPayload,
    required Map<String, dynamic> oldPayload,
    required String key,
  }) {
    final newMap = Map<String, dynamic>.from(newPayload[key] ?? {});
    final oldMap = Map<String, dynamic>.from(oldPayload[key] ?? {});

    newMap.removeWhere((k, v) => oldMap.containsKey(k) && oldMap[k] == v);

    if (newMap.isEmpty) {
      newPayload.remove(key);
    } else {
      newPayload[key] = newMap;
    }
    return newPayload;
  }

  double safeToWholeDouble(num? value) {
    return (value ?? 0).toInt().toDouble();
  }

  // ─── Save Logic ───────────────────────────────────────────────────────────

  void _onSaveButtonPressed() {
    final voltageValues = voltageCardKey.currentState?.getValues();
    final currentValues = currentCardKey.currentState?.getValues();
    final calculatedCurrentValues =
        currentCardKey.currentState?.getCalculatedValues();

    controller.lvf.value =
        voltageValues?['low']?.toInt() ?? controller.userSettings2.value!.lvf!;
    controller.hvf.value =
        voltageValues?['high']?.toInt() ?? controller.userSettings2.value!.hvf!;
    controller.drf.value = currentValues?['low']?.toInt() ??
        controller.userSettings2.value!.drf!.toInt();
    controller.olf.value = currentValues?['high']?.toInt() ??
        controller.userSettings2.value!.olf!.toInt();

    final pcbNumber = controller.pcbNumber.value;

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

    if (updatedpayload["dvc_c"]?.containsKey("drf") == true) {
      updatedpayload["dvc_c"]['drf'] = controller.drf.value;
    }
    if (updatedpayload["dvc_c"]?.containsKey('olf') == true) {
      updatedpayload["dvc_c"]['olf'] = controller.olf.value;
    }

    final Map<String, dynamic> dvcMap = updatedpayload["dvc_c"] ?? {};

    setState(() {
      isVoltageRange = dvcMap.containsKey("lvf") || dvcMap.containsKey("hvf");
      isCurrentRange = dvcMap.containsKey("drf") || dvcMap.containsKey("olf");

      final bool vmin = dvcMap.containsKey("lvf");
      final bool vmax = dvcMap.containsKey("hvf");
      final bool cmin = dvcMap.containsKey("drf");
      final bool cmax = dvcMap.containsKey("olf");

      if (vmin) {
        try {
          if (dvcMap['lvf'] > controller.payload['dvc_c']['lvf'] ||
              dvcMap['lvf'] < controller.payload['dvc_c']['lvf']) {
            updatedpayload["dvc_c"]['lvr'] = dvcMap['lvf'] + 10;
            controller.lvr.value = dvcMap['lvf'] + 10;
          }
        } catch (e) {
          print("error line 818 $e");
        }
      }

      if (vmax) {
        try {
          if (dvcMap['hvf'] > controller.payload['dvc_c']['hvf']) {
            updatedpayload["dvc_c"]['hvr'] = dvcMap['hvf'] - 10;
            controller.hvr.value = dvcMap['hvf'] - 10;
          }
        } catch (e) {
          print("error line 844 $e");
        }
      }

      if (cmin) {
        final strVal =
            calculatedCurrentValues!['calculatedLow']?.toStringAsFixed(2);
        updatedpayload["dvc_c"]['drf'] = double.parse(strVal ?? "0.0");
      }

      if (cmax) {
        final strVal =
            calculatedCurrentValues!['calculatedHigh']?.toStringAsFixed(2);
        updatedpayload["dvc_c"]['olf'] = double.parse(strVal ?? "0.0");
      }

      final initialFlc = controller.userSettings2.value?.flc?.toDouble() ?? 0.0;
      final flcChanged = controller.flc.value != initialFlc;

      if (flcChanged) {
        updatedpayload['dvc_c'] ??= <String, dynamic>{};
        updatedpayload['dvc_c']['flc'] = controller.flc.value;
        final calculatedLrf = controller.calculatedFlc(
            controller.lrf.value, controller.flc.value);
        final calculatedOlr = controller.calculatedFlc(
            controller.olr.value, controller.flc.value);
        final calculatedLRR = controller.calculatedFlc(
            controller.lrr.value, controller.flc.value);
        final calculatedDrf = controller.calculatedFlc(
            controller.drf.value.toDouble(), controller.flc.value);
        final calculatedOlf = controller.calculatedFlc(
            controller.olf.value.toDouble(), controller.flc.value);
        updatedpayload["dvc_c"]['lrf'] = calculatedLrf;
        updatedpayload['dvc_c']['olr'] = calculatedOlr;
        updatedpayload['dvc_c']['lrr'] = calculatedLRR;
        updatedpayload['dvc_c']['drf'] = calculatedDrf;
        updatedpayload['dvc_c']['olf'] = calculatedOlf;
      }

      if (isVoltageRange || isCurrentRange || flcChanged) {
        _handleSave(vmin, vmax, cmin, cmax, pcbNumber, flcChanged: flcChanged);
      }
    });
  }

  void _handleSave(
    bool vmin,
    bool vmax,
    bool cmin,
    bool cmax,
    String pcbNumber, {
    bool flcChanged = false,
  }) {
    showSettingsConfirmDialog(
      context,
      isVoltageRange: isVoltageRange,
      isCurrentRange: isCurrentRange,
      flcChanged: flcChanged,
      vmin: vmin,
      vmax: vmax,
      cmin: cmin,
      cmax: cmax,
      originalVoltageLow: _originalVoltageLow?.toString(),
      currentLvf: controller.lvf.value.toString(),
      originalVoltageHigh: _originalVoltageHigh?.toString(),
      currentHvf: controller.hvf.value.toString(),
      originalCurrentLow: _originalCurrentLow?.toString(),
      currentDrf: controller.drf.value.toInt().toString(),
      originalCurrentHigh: _originalCurrentHigh?.toString(),
      currentOlf: controller.olf.value.toString(),
      originalFlc:
          controller.userSettings2.value?.flc?.toStringAsFixed(2) ?? '0.00',
      currentFlc: controller.flc.value.toStringAsFixed(2),
      onConfirm: () async {
        isSnackbarShown = false;
        _hasPendingSave = true;
        await mqttService.publishUpdateSettings(pcbNumber, updatedpayload);
        await controller.fetchupdateSettings();
        _startAckTimer();
      },
    );
  }

  // ─── Default Settings ─────────────────────────────────────────────────────

  void _defaultSettingsPopUp(BuildContext context) {
    showDeviceSettingConfirmDialog(
      context,
      title: 'Restore Default Settings',
      message:
          'Restore Voltage and Current faults to default settings? Custom changes will be lost',
      svgPath: 'assets/images/default_settings.svg',
      onConfirm: () async {
        _originalVoltageLow = controller.userSettings2.value?.lvf?.toInt();
        _originalVoltageHigh = controller.userSettings2.value?.hvf?.toInt();
        _originalCurrentLow = controller.userSettings2.value?.drf?.toInt();
        _originalCurrentHigh = controller.userSettings2.value?.olf?.toInt();
        updatedpayload = {};
        controller.payload = {};
        await controller.fetchdefaultSettings();
        _currentVoltageLow = null;
        _currentVoltageHigh = null;
        _currentCurrentLow = null;
        _currentCurrentHigh = null;
        voltageCardKey.currentState?.resetValues();
        currentCardKey.currentState?.resetValues();
        try {
          setState(() {
            final pcbNumber = controller.pcbNumber.value;
            onUpdatedSettings2(pcbNumber);
          });
        } catch (e) {}
        setState(() {
          isbuttonActive = true;
        });
      },
    );
  }

  void onUpdatedSettings2(String pcbNumber) async {
    isSnackbarShown = false;
    _hasPendingSave = true;
    await mqttService.publishUpdateSettings(
        pcbNumber, controller.defaultSettingspayload);
    await controller.fetchDefaultupdateSettings();
    _startAckTimer();
    setState(() {
      isbuttonActive = false;
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAllNamed(Routes.devices, arguments: {"refresh": true});
        return false;
      },
      child: GestureDetector(
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
                SettingsAppBar(onMenuTap: onTapMenu),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 50),
                        child: Center(child: AppLottieLoading()),
                      );
                    }
                    if (!ConnectivityService.to.isConnected) {
                      return const Center(child: NoInternetWidget());
                    }

                    final settings = controller.userSettings2.value;
                    final motorName =
                        settings?.starter?.name?.toString() ?? 'Pump 1';
                    final drf = settings?.drf ?? 100;
                    final olf = settings?.olf ?? 101;

                    return Column(
                      children: [
                        SettingsDeviceInfoBar(
                          pumpName: controller.pumpName.value,
                          pumpHP: controller.pumpHP.value,
                          onDefaultPressed: () =>
                              _defaultSettingsPopUp(context),
                        ),
                        Expanded(
                          child: SettingsContent(
                            voltageCardKey: voltageCardKey,
                            currentCardKey: currentCardKey,
                            flcCardKey: flcCardKey,
                            isRefreshing: controller.isrefreshing.value,
                            flcInitialValue: controller.userSettings2.value?.flc
                                    ?.toDouble() ??
                                0.0,
                            flcMinValue:
                                controller.data.value?.flcMin?.toDouble() ??
                                    0.0,
                            flcMaxValue:
                                controller.data.value?.flcMax?.toDouble() ??
                                    0.0,
                            voltageInitialLow: controller
                                    .userSettings2.value?.lvf
                                    ?.toDouble() ??
                                180.0,
                            voltageInitialHigh: controller
                                    .userSettings2.value?.hvf
                                    ?.toDouble() ??
                                280.0,
                            currentInitialLow:
                                drf > 100 ? 100.0 : drf.toDouble(),
                            currentInitialHigh:
                                olf < 100 ? 101.0 : olf.toDouble(),
                            motorName: motorName,
                            onRefresh: _handleRefresh,
                            onFlcChanged: (newValue) {
                              controller.flc.value = newValue;
                              _checkForChanges();
                            },
                            onFlcOutOfRange: (isOutOfRange) {
                              setState(() {
                                _isFlcOutOfRange = isOutOfRange;
                              });
                            },
                            onVoltageChanged: (low, high) {
                              _currentVoltageLow = safeToWholeDouble(low);
                              _currentVoltageHigh = safeToWholeDouble(high);
                              _checkForChanges();
                            },
                            onCurrentChanged: (low, high) {
                              _currentCurrentLow =
                                  (low ?? 0).toInt().toDouble();
                              _currentCurrentHigh =
                                  (high ?? 0).toInt().toDouble();
                              _checkForChanges();
                            },
                          ),
                        ),
                        if (isbuttonActive)
                          SettingsActionButtons(
                            isActive: isbuttonActive,
                            isFlcOutOfRange: _isFlcOutOfRange,
                            hasStarter: settings?.starter != null,
                            onCancel: _handleCancel,
                            onSave: _onSaveButtonPressed,
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
