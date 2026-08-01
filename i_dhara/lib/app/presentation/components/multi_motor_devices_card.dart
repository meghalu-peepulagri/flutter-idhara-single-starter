import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';
import 'package:i_dhara/app/data/services/mqtt_manager/mqtt_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/components/devices_card.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';

class MultiMotorDevicesCard extends StatelessWidget {
  final Devices device;
  final MqttService mqttService;

  const MultiMotorDevicesCard({
    super.key,
    required this.device,
    required this.mqttService,
  });

  List<Motor?> _orderedMotors() {
    final motors = List<Motor>.from(device.motors ?? const []);
    motors.sort((a, b) => (a.motorIndex ?? 99).compareTo(b.motorIndex ?? 99));
    final left = motors.isNotEmpty ? motors[0] : null;
    final right = motors.length > 1 ? motors[1] : null;
    return [left, right];
  }

  String _locationName() {
    for (final m in device.motors ?? const <Motor>[]) {
      final name = m.location?.name?.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return device.deviceInstalledLocation
            ?.replaceAll(RegExp(r'\s+'), ' ')
            .trim() ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final motors = _orderedMotors();
    final left = motors[0];
    final right = motors[1];
    final locationName = _locationName();

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStarterHeader(context),
            const SizedBox(height: 8.0),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildMotorSlot(left)),
                  const SizedBox(width: 8.0),
                  Expanded(child: _buildMotorSlot(right)),
                ],
              ),
            ),
            if (locationName.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              _buildLocationRow(context, locationName),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMotorSlot(Motor? motor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: const Color(0xFFDADADA)),
      ),
      child: motor == null
          ? const SizedBox.shrink()
          : DevicesCard(
              device: device,
              motor: motor,
              mqttService: mqttService,
              compact: true,
            ),
    );
  }

  Widget _buildStarterHeader(BuildContext context) {
    final starterText = device.starterNumber ?? 'N/A';
    final displayText = starterText.length > 12
        ? '${starterText.substring(0, 12)}...'
        : starterText;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6.0, 4.0, 0.0, 0.0),
      child: Row(
        children: [
          Text(
            'Starter No :',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                  color: const Color(0xFF62697D),
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '#$displayText',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    color: const Color(0xFF13120D),
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              SharedPreference.setStarterId(device.id ?? 0);
              SharedPreference.setStarterNumber(device.starterNumber ?? '');
              SharedPreference.setIsMultiMotor(true);
              Get.offNamed(Routes.usersettings,
                  arguments: {'from': Routes.devices});
            },
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, String locationName) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 6.0, 0.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0.0),
            child: SvgPicture.asset(
              'assets/images/kdkr.svg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              locationName,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                    color: const Color(0xFF5E5E5E),
                    fontSize: 14.0,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
