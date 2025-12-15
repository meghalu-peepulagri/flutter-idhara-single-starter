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

        return ListView.separated(
          shrinkWrap: true,
          itemCount: controller.locations.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final loc = controller.locations[index];

            return ListTile(
              title: Text(loc.name ?? ''),
              trailing: controller.selectedLocationId.value == loc.id
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                controller.filterMotorsByLocation(loc.id);
                Get.back();
              },
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

  final controller = Get.find<DashboardController>();

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
              if (controller.locations.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.separated(
                itemCount: controller.locations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final loc = controller.locations[index];

                  final bool isSelected =
                      selectedLocationId == loc.id.toString();

                  return ListTile(
                    title: Text(
                      loc.name?.capitalizeFirst ?? '',
                      style: GoogleFonts.dmSans(fontSize: 16),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      onLocationSelected(
                        loc.name ?? '',
                        loc.id.toString(),
                      );
                    },
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
