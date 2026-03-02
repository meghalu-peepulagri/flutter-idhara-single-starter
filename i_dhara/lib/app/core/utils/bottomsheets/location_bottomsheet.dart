import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';
import 'package:i_dhara/app/presentation/widgets/no_data_view.dart';

String _normalizeLocationName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return '';
  }
  return name.trim().replaceAll(RegExp(r'\s+'), ' ');
}

class LocationBottomSheet extends StatefulWidget {
  final DashboardController controller;

  const LocationBottomSheet({super.key, required this.controller});

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  late final DashboardController controller = widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchLocationDropDown();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.45,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        if (controller.isLoadingLocations.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Filter out "All" option to check if there are real locations
        final realLocations =
            controller.locations.where((loc) => loc.id != null).toList();

        if (realLocations.isEmpty) {
          return const Center(
            child: Padding(
                padding: EdgeInsets.all(32.0), child: NoLocationsFound()),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: controller.locations.length > 3
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: controller.locations.length,
          itemBuilder: (context, index) {
            final loc = controller.locations[index];
            final isSelected = controller.selectedLocationId.value == loc.id;

            return InkWell(
              onTap: () async {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 200));
                controller.filterMotorsByLocation(loc.id);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      () {
                        final normalizedName = _normalizeLocationName(loc.name);
                        return normalizedName.length > 20
                            ? '${normalizedName.substring(0, 20)}…'
                            : normalizedName;
                      }(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.blue, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class LocationSelectionBottomSheet extends StatefulWidget {
  final Function(String name, String id) onLocationSelected;
  final String? selectedLocationId;

  const LocationSelectionBottomSheet({
    super.key,
    required this.onLocationSelected,
    required this.selectedLocationId,
  });

  @override
  State<LocationSelectionBottomSheet> createState() =>
      _LocationSelectionBottomSheetState();
}

class _LocationSelectionBottomSheetState
    extends State<LocationSelectionBottomSheet> {
  final controller = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchLocationDropDown();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Location',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingLocations.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Filter out 'All' option
              final locations = controller.locations
                  .where((e) => e.name?.toLowerCase() != 'all')
                  .toList();

              if (locations.isEmpty) {
                return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0), child: NoLocationsFound()),
                );
              }

              return ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  final bool isSelected =
                      widget.selectedLocationId == loc.id.toString();

                  return InkWell(
                    onTap: () {
                      widget.onLocationSelected(
                        _normalizeLocationName(loc.name),
                        loc.id.toString(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            () {
                              final normalizedName =
                                  _normalizeLocationName(loc.name);
                              return normalizedName.length > 20
                                  ? '${normalizedName.substring(0, 20)}…'
                                  : normalizedName;
                            }(),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Colors.blue,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
