import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
