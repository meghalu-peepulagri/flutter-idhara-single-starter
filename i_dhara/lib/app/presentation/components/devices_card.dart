import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/core/utils/bottomsheets/location_bottomsheet.dart';
import 'package:i_dhara/app/core/utils/dialogs/device_bottomsheet.dart';
import 'package:i_dhara/app/core/utils/dialogs/popup_dialog.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart'
    as motor_model;
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/testrun_verification_card.dart';
import 'package:i_dhara/app/presentation/modules/devices/devices_controller.dart';
import 'package:i_dhara/app/presentation/modules/devices/edit_device/edit_device_page.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

import '../../core/utils/mqtt_utils.dart';

class DevicesCard extends StatelessWidget {
  final Devices device;
  final MqttService mqttService;

  DevicesCard({super.key, required this.device, required this.mqttService});

  final DevicesController controller = Get.find<DevicesController>();

  void _showDeleteDialog(BuildContext context) {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) {
        return PopupDialog(
          title: "Delete Device",
          description:
              "This device will be deleted permanently. Do you wish to go ahead?",
          iconAssetPath: 'assets/images/Device Icon.svg',
          buttonlable: 'Delete',
          onDelete: () async {
            if (device.id != null) {
              await controller.deleteDevice(device.id!);
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  void _showDeviceOptionsBottomSheet(BuildContext context, Motor? motor) {
    final bool hasMotor = device.motors?.isNotEmpty == true;
    final bool hasLocation = motor?.location?.name != null &&
        motor!.location!.name!
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DeviceOptionsBottomSheet(
          hasMotor: hasMotor,
          hasLocation: hasLocation,
          onRename: () {
            Navigator.pop(context);
            _showRenameBottomSheet(context, motor);
          },
          onReplace: () {
            Navigator.pop(context);
            _showReplaceLocationBottomSheet(context, motor);
          },
          onDelete: () {
            Navigator.pop(context);
            _showDeleteDialog(context);
          },
          onTestRun: () {
            Navigator.pop(context);
            _navigateToTestRun(motor);
          },
        );
      },
    );
  }

  void _showRenameBottomSheet(BuildContext context, Motor? motor) {
    if (motor == null) return;

    // Get the motor name and replace multiple spaces with single space
    final motorName = (motor.aliasName?.trim().isNotEmpty ?? false)
        ? motor.aliasName!
        : motor.name ?? '';
    final cleanedMotorName = motorName.replaceAll(RegExp(r'\s+'), ' ').trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditDevicePage(
            motorId: motor.id!,
            motorName: cleanedMotorName,
            hp: double.tryParse(motor.hp?.toString() ?? '0') ?? 0.0,
            onLocationAdded: (updatedName) {},
          ),
        );
      },
    );
  }

  void _showReplaceLocationBottomSheet(BuildContext context, Motor? motor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSelectionBottomSheet(
        selectedLocationId: motor?.location?.id?.toString(),
        onLocationSelected: (locationName, locationId) async {
          Get.back();
          if (motor == null || device.id == null) return;
          {
            await controller.locationreplace(
              starterId: device.id!,
              motorId: motor.id!,
              locationId: int.parse(locationId),
            );
          }
        },
      ),
    );
  }

  void _showAddLocationBottomSheet(BuildContext context, Motor? motor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSelectionBottomSheet(
        selectedLocationId: null,
        onLocationSelected: (locationName, locationId) async {
          Navigator.pop(context);
          if (motor != null) {
            await controller.locationreplace(
              starterId: device.id!,
              motorId: motor.id!,
              locationId: int.parse(locationId),
            );
          }
        },
      ),
    );
  }

  void _navigateToTestRun(Motor? motor) {
    if (motor == null || motor.id == null) return;

    final motorModelMotor = motor_model.Motor(
      id: motor.id,
      name: motor.name,
      hp: motor.hp,
      mode: motor.mode,
      state: motor.state,
      aliasName: motor.aliasName,
      testrunStatus: motor.testrunStatus,
      location: motor.location != null
          ? motor_model.Location(
              id: motor.location!.id,
              name: motor.location!.name,
            )
          : null,
      starter: motor_model.Starter(
        deviceAllocation: device.deviceAllocation,
        id: device.id,
        name: device.name,
        macAddress: device.macAddress,
        pcbNumber: device.pcbNumber,
        signalQuality: device.signalQuality,
        power: device.power,
        networkType: device.networkType,
      ),
    );

    SharedPreference.setMotorId(motor.id ?? 0);
    SharedPreference.setStarterId(device.id ?? 0);

    _showConfirmTestRunDialog(Get.context!, motorModelMotor);
  }

  void _showConfirmTestRunDialog(
      BuildContext ctx, motor_model.Motor motorModelMotor) async {
    final cloudConnectionVerified = ValueNotifier<bool>(false);
    final inputPowerVerified = ValueNotifier<bool>(false);
    final avgflc = ValueNotifier<double>(0.0);

    // Publish verification command (type 5)

    final deviceallow = motorModelMotor.starter!.deviceAllocation.toString();
    final pcb = motorModelMotor.starter?.pcbNumber.toString();
    final mac = motorModelMotor.starter?.macAddress.toString();

    print("line 8 $pcb $mac $deviceallow");

    try {
      final identifier = getMotorIdentifier(
          deviceallow.toString(), pcb.toString(), mac.toString());
      if (identifier.isNotEmpty) {
        final groupId = _getMotorGroupId(mqttService, identifier);
        final mqttMotorId = '$identifier-$groupId';

        await mqttService.publishTestRunCommand(mqttMotorId, 1,
            data: 1, type: 5);
      }
    } catch (e) {
      print("Error publishing verification command: $e");
    }

    if (!ctx.mounted) return;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder(
          valueListenable: mqttService.dataUpdateNotifier,
          builder: (context, _, __) {
            final motorData = _getMotorData(mqttService, motorModelMotor);
            return ConfirmTestRunScreen(
              motorData: motorData,
              motor: motorModelMotor,
              mqttService: mqttService,
              cloudConnectionVerified: cloudConnectionVerified,
              inputPowerVerified: inputPowerVerified,
              avgflc: avgflc,
              route: '/devices',
            );
          }),
    );
  }

  String _getMotorGroupId(MqttService mqttService, String identifier) {
    const allowedGroups = ['G01', 'G02'];
    for (final groupId in allowedGroups) {
      final motorData = mqttService.motorDataMap['$identifier-$groupId'];
      if (motorData != null) return groupId;
    }
    return 'G01';
  }

  MotorData? _getMotorData(MqttService mqttService, motor_model.Motor motor) {
    if (motor.starter == null) return null;
    final mac = motor.starter!.macAddress;
    final pcb = motor.starter!.pcbNumber;

    MotorData? bestData;
    DateTime? bestTime;

    for (var entry in mqttService.motorDataMap.entries) {
      final data = entry.value;
      if (data.hasReceivedData != true) continue;

      final key = entry.key;
      final matchesByKey =
          (mac != null && mac.isNotEmpty && key.startsWith('$mac-')) ||
              (pcb != null && pcb.isNotEmpty && key.startsWith('$pcb-'));
      final matchesByData = (mac != null &&
              mac.isNotEmpty &&
              (data.macAddress == mac || data.pcbNumber == mac)) ||
          (pcb != null &&
              pcb.isNotEmpty &&
              (data.macAddress == pcb || data.pcbNumber == pcb));

      if (matchesByKey || matchesByData) {
        final ackTime = mqttService.getLastAckTime(key);
        if (bestData == null ||
            (ackTime != null &&
                (bestTime == null || ackTime.isAfter(bestTime)))) {
          bestData = data;
          bestTime = ackTime;
        }
      }
    }

    return bestData;
  }

  @override
  Widget build(BuildContext context) {
    final motor =
        device.motors?.isNotEmpty == true ? device.motors!.first : null;

    return GestureDetector(
      // onTap: () => _navigateToTestRun(motor),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildHeader(context, motor),
                      _buildPcbAndPowerStatus(context, motor),
                    ].divide(const SizedBox(height: 12.0)),
                  ),
                ),
              ),
              _buildLocationRow(context, motor),
            ].divide(const SizedBox(height: 8.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Motor? motor) {
    final displayName = _getMotorDisplayName(motor);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      Text(
                        displayName.length > 10
                            ? '${displayName.substring(0, 10)}...'
                            : displayName,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                              ),
                              color: const Color(0xFF13120D),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${motor?.hp ?? 'N/A'} HP',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                              ),
                              color: const Color(0xFF2E393D),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      _buildMotorMode(context, motor),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    spacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () {
                          SharedPreference.setStarterId(device.id ?? 0);
                          Get.offNamed(Routes.usersettings);
                        },
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0.0),
                        child: SvgPicture.asset(
                          device.power == 1
                              ? 'assets/images/power.svg'
                              : 'assets/images/Power_red.svg',
                          width: 17,
                          height: 17,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _showDeviceOptionsBottomSheet(context, motor),
                        child: const Icon(
                          Icons.more_vert,
                          color: Color(0XFF464646),
                          size: 20.0,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ].divide(const SizedBox(height: 4.0)),
          ),
        ),
      ],
    );
  }

  String _getMotorDisplayName(Motor? motor) {
    final alias = motor?.aliasName;
    final name = (alias != null && alias.trim().isNotEmpty)
        ? alias
        : (motor?.name ?? 'No Motor');
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildPcbAndPowerStatus(BuildContext context, Motor? motor) {
    String starterText = device.starterNumber ?? 'N/A';
    String displayText = starterText.length > 12
        ? '${starterText.substring(0, 12)}...'
        : starterText;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Starter No :',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                          ),
                          color: const Color(0xFF62697D),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#$displayText',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                          ),
                          color: const Color(0xFF2E393D),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ].divide(const SizedBox(height: 4.0)),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(0.0),
          child: SvgPicture.asset(
            (motor?.state == 1)
                ? 'assets/images/pump.svg'
                : 'assets/images/pump_off.svg',
            width: 34,
            height: 34,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildMotorMode(BuildContext context, Motor? motor) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          decoration: BoxDecoration(
            color: (motor?.mode?.toUpperCase() == 'AUTO')
                ? const Color(0xFFF59E0B)
                : const Color(0xFF2F80ED),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6.0, 2.0, 6.0, 2.0),
            child: Text(
              ((motor?.mode ?? 'MANUAL').toLowerCase()).replaceFirstMapped(
                RegExp(r'^[a-z]'),
                (m) => m.group(0)!.toUpperCase(),
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                    ),
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        )
      ].divide(const SizedBox(width: 8.0)),
    );
  }

  Widget _buildLocationRow(BuildContext context, Motor? motor) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 6.0, 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0.0),
            child: SvgPicture.asset(
              (motor?.location?.name == null ||
                      motor!.location!.name!
                          .replaceAll(RegExp(r'\s+'), ' ')
                          .trim()
                          .isEmpty)
                  ? 'assets/images/Add.svg'
                  : 'assets/images/kdkr.svg',
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: _buildLocationNameOrAddButton(context, motor),
          ),
        ].divide(const SizedBox(width: 8.0)),
      ),
    );
  }

  Widget _buildLocationNameOrAddButton(BuildContext context, Motor? motor) {
    final locationName = motor?.location?.name;
    final cleanedLocationName =
        locationName?.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (locationName == null || cleanedLocationName?.isEmpty == true) {
      return GestureDetector(
        onTap: () => _showAddLocationBottomSheet(context, motor),
        child: Row(
          children: [
            Text(
              'Add Location',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                    ),
                    color: const Color(0xFF6A7282),
                    fontSize: 14.0,
                  ),
            ),
          ],
        ),
      );
    }

    return Text(
      cleanedLocationName!,
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.dmSans(
              fontWeight: FontWeight.w500,
            ),
            color: const Color(0xFF5E5E5E),
            fontSize: 14.0,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
