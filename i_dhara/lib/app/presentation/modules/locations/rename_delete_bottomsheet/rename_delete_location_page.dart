import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/utils/dialogs/popup_dialog.dart';
import 'package:i_dhara/app/core/utils/snackbars/success_snackbar.dart';
import 'package:i_dhara/app/presentation/modules/locations/locations_controller.dart';
import 'package:i_dhara/app/presentation/modules/locations/rename_delete_bottomsheet/rename_delete_location_controller.dart';
import 'package:i_dhara/app/presentation/modules/locations/rename_delete_bottomsheet/rename_location_page.dart';

import '../../../../core/flutter_flow/flutter_flow_theme.dart';
import '../../../../core/flutter_flow/flutter_flow_util.dart';

class EditDeleteLocationPage extends StatelessWidget {
  final int locationId;
  final String locationName;

  EditDeleteLocationPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  final EditDeleteLocationController controller =
      Get.put(EditDeleteLocationController());
  final LocationsController locationsController =
      Get.find<LocationsController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Match motor bottom sheet height
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
            16, 16, 16, 16), // Match motor padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Left-align content
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Options',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Lexend', // Match motor font
                        color: const Color(0xFF6A7185),
                        fontSize: 18, // Match motor font size
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    Get.back();
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9E9E9),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start, // Left-align items
              children: [
                InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                    showModalBottomSheet(
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                      ),
                      context: context,
                      builder: (BuildContext context) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: EditLocationWidget(
                            locationId: locationId,
                            locationName: locationName,
                            onLocationAdded: (String newLocation) {},
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8), // Match motor padding
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit, // Match motor icon
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 20, // Match motor icon size
                        ),
                        const SizedBox(width: 8), // Match motor spacing
                        Text(
                          'Rename Location', // Consistent naming
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Lexend', // Match motor font
                                    color: Colors.black,
                                    fontSize: 16, // Match motor font size
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  thickness: 1,
                  color: FlutterFlowTheme.of(context).alternate,
                ),
                InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return PopupDialog(
                          description:
                              "This  will be deleted permanently. Do you wish to go ahead?",
                          title: "Delete Location",
                          iconAssetPath: 'assets/images/location.svg',
                          onDelete: () async {
                            await locationsController
                                .deleteLocation(locationId);
                            Navigator.pop(context);
                            Get.back();
                            getsuccessSnackBar('Location Deleted successfully');
                          },
                          buttonlable: 'Delete',
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8), // Match motor padding
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline, // Match motor icon
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 20, // Match motor icon size
                        ),
                        const SizedBox(width: 8), // Match motor spacing
                        Text(
                          'Delete Location', // Consistent naming
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Lexend', // Match motor font
                                    color: Colors.black,
                                    fontSize: 16, // Match motor font size
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ].divide(const SizedBox(height: 4)), // Match motor divider height
            ),
          ].divide(const SizedBox(height: 16)), // Match motor divider height
        ),
      ),
    );
  }
}
