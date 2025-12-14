import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/models/devices/devices_model.dart';

class DevicesCard extends StatelessWidget {
  final Devices device;

  const DevicesCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final motor =
        device.motors?.isNotEmpty == true ? device.motors!.first : null;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    motor?.name ?? 'No Motor',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          color: const Color(0xFF13120D),
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
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
                                ],
                              ),
                              Text(
                                '#${device.pcbNumber ?? 'N/A'}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: const Color(0xFF2E393D),
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 4.0)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   motor?.name ?? 'No Motor',
                              //   style: FlutterFlowTheme.of(context)
                              //       .bodyMedium
                              //       .override(
                              //         font: GoogleFonts.dmSans(
                              //           fontWeight: FontWeight.w500,
                              //         ),
                              //         color: const Color(0xFF13120D),
                              //         fontSize: 16.0,
                              //         letterSpacing: 0.0,
                              //         fontWeight: FontWeight.w500,
                              //       ),
                              //   maxLines: 1,
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                              Text(
                                motor?.hp ?? 'N/A',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: const Color(0xFF2E393D),
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F80ED),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                6.0, 2.0, 6.0, 2.0),
                            child: Text(
                              motor?.mode?.substring(0, 1).toUpperCase() ?? 'M',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color: Colors.white,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        Text(
                          motor?.mode ?? 'Manual',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    color: Colors.black,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ].divide(const SizedBox(width: 8.0)),
                    ),
                  ].divide(const SizedBox(height: 12.0)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 6.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0.0),
                    child: SvgPicture.asset(
                      'assets/images/kdkr.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      motor?.location?.name ?? 'Unknown Location',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w500,
                            ),
                            color: const Color(0xFF5E5E5E),
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ].divide(const SizedBox(width: 8.0)),
              ),
            ),
          ].divide(const SizedBox(height: 8.0)),
        ),
      ),
    );
  }
}
