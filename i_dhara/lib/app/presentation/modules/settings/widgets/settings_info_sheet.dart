import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows the info bottom sheet for the Settings page.
/// [selectedTab] 0 → Limits tab, 1 → Fault Settings tab.
void showSettingsInfoSheet(BuildContext context, {required int selectedTab}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _SettingsInfoSheet(selectedTab: selectedTab),
  );
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
  });
}

// Limits tab items
const _limitsItems = [
  _InfoItem(
    icon: Icons.electrical_services_outlined,
    iconColor: Color(0xFF004E7E),
    iconBg: Color(0xFFE3F2FD),
    title: 'Full Load Current (FLC)',
    description:
        'The rated maximum current your motor draws under a full load. '
        'Setting this correctly lets the device calculate overload and dry-run '
        'thresholds automatically. Enter the value from the motor nameplate.',
  ),
  _InfoItem(
    icon: Icons.bolt_outlined,
    iconColor: Color(0xFFF59E0B),
    iconBg: Color(0xFFFFFBEB),
    title: 'Voltage Protection',
    description: 'Defines the safe operating voltage range (Low – High). '
        'If the supply voltage falls below the low limit or rises above the '
        'high limit, the motor is stopped to prevent winding damage.',
  ),
  _InfoItem(
    icon: Icons.electric_meter_outlined,
    iconColor: Color(0xFFEF4444),
    iconBg: Color(0xFFFFF0F0),
    title: 'Overload',
    description:
        'Sets the current threshold above which the device considers the motor '
        'to be overloaded. When the motor draws more current than this value, '
        'it is tripped to protect the windings from heat damage.',
  ),
  _InfoItem(
    icon: Icons.water_drop_outlined,
    iconColor: Color(0xFF10B981),
    iconBg: Color(0xFFECFDF5),
    title: 'Dry Run',
    description:
        'Sets the minimum current the pump must draw. If the current falls '
        'below this limit, the pump is assumed to be running without water '
        '(dry run) and is stopped to protect the pump and motor.',
  ),
];

// Fault Settings tab items
const _faultItems = [
  _InfoItem(
    icon: Icons.warning_amber_rounded,
    iconColor: Color(0xFFEF4444),
    iconBg: Color(0xFFFFF0F0),
    title: 'Faults',
    description:
        'Enable or disable individual fault protections for your motor. '
        'When a fault is enabled, the motor will stop automatically if that '
        'fault condition is detected, protecting the motor from damage.',
  ),
];

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _SettingsInfoSheet extends StatelessWidget {
  final int selectedTab;

  const _SettingsInfoSheet({required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final isLimitsTab = selectedTab == 0;
    final items = isLimitsTab ? _limitsItems : _faultItems;
    final sheetTitle =
        isLimitsTab ? 'About Limits Settings' : 'About Fault Settings';
    const limitsSubtitle =
        'Understand each protection limit before adjusting values.';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: isLimitsTab ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sheetTitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                        if (isLimitsTab) ...[
                          const SizedBox(height: 4),
                          Text(
                            limitsSubtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFFEF4444),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            // Items list — scrollable for Limits, content-height for Fault
            if (isLimitsTab)
              Expanded(
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _InfoCard(item: items[index]),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _InfoCard(item: items[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final _InfoItem item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 24, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
