import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final bool isExpanded;
  final VoidCallback onToggle;

  const LocationCard({
    super.key,
    required this.location,
    required this.isExpanded,
    required this.onToggle,
  });

  Color _getMotorStatusColor(int? state) {
    return state == 1 ? const Color(0xFF1D7433) : const Color(0xFFDC2626);
  }

  Color _getMotorBackgroundColor(int? state) {
    return state == 1 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
  }

  Color _getMotorBorderColor(int? state) {
    return state == 1 ? const Color(0xFFB9F8CF) : const Color(0xFFFECACA);
  }

  @override
  Widget build(BuildContext context) {
    final motors = location.motors ?? [];
    final onCount = location.onStateCount ?? 0;
    final totalMotors = location.totalMotors ?? 0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Make entire row clickable
          InkWell(
            onTap: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 20.0,
                    ),
                    Text(
                      location.name ?? 'Unknown Location',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.dmSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: const Color(0xFF1A1A1A),
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ].divide(const SizedBox(width: 4.0)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: onCount > 0
                            ? const Color(0xFFE8F9ED)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: const Color(0xFFEFEFEF),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            8.0, 6.0, 8.0, 6.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: onCount > 0
                                    ? const Color(0xFF1D7433)
                                    : const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                            ),
                            Text(
                              '$onCount / $totalMotors ON',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: onCount > 0
                                        ? const Color(0xFF087D40)
                                        : const Color(0xFFDC2626),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(const SizedBox(width: 6.0)),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 20.0,
                    ),
                  ].divide(const SizedBox(width: 12.0)),
                ),
              ],
            ),
          ),
          // Expandable motors section with GridView
          if (isExpanded && motors.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: motors.length,
                  itemBuilder: (context, index) {
                    final motor = motors[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: _getMotorBackgroundColor(motor.state),
                        border: Border.all(
                          color: _getMotorBorderColor(motor.state),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: _getMotorStatusColor(motor.state),
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                motor.name ?? 'Pump ${index + 1}',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ].divide(const SizedBox(width: 8.0)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ].divide(const SizedBox(height: 12.0)),
      ),
    );
  }
}

// Extension to add divide method to List<Widget>
extension ListExtension on List<Widget> {
  List<Widget> divide(Widget divider) {
    if (isEmpty) return this;

    final result = <Widget>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(divider);
      }
    }
    return result;
  }
}
