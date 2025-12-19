import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DeviceMenuAction { rename, replace, delete }

class DeviceOptionsMenu extends StatelessWidget {
  final Function(DeviceMenuAction action) onSelected;
  final bool hasMotor;

  const DeviceOptionsMenu({
    super.key,
    required this.onSelected,
    required this.hasMotor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _menuItem(
            icon: Icons.edit,
            text: 'Rename',
            enabled: hasMotor,
            onTap: () => onSelected(DeviceMenuAction.rename),
          ),
          _menuItem(
            icon: Icons.swap_horiz,
            text: 'Replace',
            onTap: () => onSelected(DeviceMenuAction.replace),
          ),

          // if (!hasMotor)
          //   _menuItem(
          //     icon: Icons.add,
          //     text: 'Add Motor',
          //     onTap: () => onSelected(DeviceMenuAction.addMotor),
          //   ),
          _menuItem(
            icon: Icons.delete_outline,
            text: 'Delete',
            color: Colors.red,
            onTap: () => onSelected(DeviceMenuAction.delete),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool enabled = true,
    Color color = Colors.black,
  }) {
    final effectiveColor = enabled ? color : Colors.grey.shade400;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
