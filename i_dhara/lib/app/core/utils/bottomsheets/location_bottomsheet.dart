import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/modules/dashboard/dashboard_controller.dart';

class LocationBottomSheet extends StatelessWidget {
  LocationBottomSheet({super.key});
  final controller = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        if (controller.locations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: controller.locations.length,
          itemBuilder: (context, index) {
            final loc = controller.locations[index];
            final isSelected = controller.selectedLocationId.value == loc.id;

            return InkWell(
              onTap: () async {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 200));
                controller.filterMotorsByLocation(loc.id);
                // Get.back();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                decoration: const BoxDecoration(
                    // border: Border(
                    //   bottom: BorderSide(
                    //     color: Colors.grey.shade300,
                    //     width: 0.5,
                    //   ),
                    // ),
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.name?.capitalizeFirst ?? '',
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

class LocationSelectionBottomSheet extends StatelessWidget {
  final Function(String name, String id) onLocationSelected;
  final String? selectedLocationId;

  LocationSelectionBottomSheet({
    super.key,
    required this.onLocationSelected,
    required this.selectedLocationId,
  });

  final controller = Get.put(DashboardController());

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
          // const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.locations.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final locations = controller.locations
                  .where((e) => e.name?.toLowerCase() != 'all')
                  .toList();

              return ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  final bool isSelected =
                      selectedLocationId == loc.id.toString();

                  return InkWell(
                    onTap: () {
                      onLocationSelected(
                        loc.name ?? '',
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
                            loc.name?.capitalizeFirst ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
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
