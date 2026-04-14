import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/motor_details/motor_details_controller.dart';

class MotorDetailsTabBar extends StatefulWidget {
  final AnalyticsController controller;

  const MotorDetailsTabBar({
    super.key,
    required this.controller,
  });

  @override
  State<MotorDetailsTabBar> createState() => _MotorDetailsTabBarState();
}

class _MotorDetailsTabBarState extends State<MotorDetailsTabBar>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _arrowAnimController;
  late Animation<double> _arrowAnim;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _arrowAnim = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _arrowAnimController, curve: Curves.easeInOut),
    );
    _scrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateScrollIndicators());
  }

  @override
  void dispose() {
    _arrowAnimController.dispose();
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final newLeft = pos.pixels > 0;
    final newRight = pos.pixels < pos.maxScrollExtent - 1;
    if (newLeft != _canScrollLeft || newRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = newLeft;
        _canScrollRight = newRight;
      });
    }
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 80)
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + 80)
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            // Left arrow
            if (_canScrollLeft)
              GestureDetector(
                onTap: _scrollLeft,
                child: AnimatedBuilder(
                  animation: _arrowAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(-_arrowAnim.value, 0),
                    child: child,
                  ),
                  child: Text(
                    '«',
                    style: GoogleFonts.dmSans(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                ),
              ),
            // Scrollable tabs
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildSvgTab(context, 'Mode', 0, 'assets/images/Mode.svg'),
                    _buildSvgTab(
                        context, 'Schedule', 1, 'assets/images/schedule.svg'),
                    _buildSvgTab(
                        context, 'Analytics', 2, 'assets/images/Graph.svg'),
                    _buildSvgTab(context, 'Logs', 3, 'assets/images/Logs.svg'),
                  ],
                ),
              ),
            ),
            // Right arrow
            if (_canScrollRight)
              GestureDetector(
                onTap: _scrollRight,
                child: AnimatedBuilder(
                  animation: _arrowAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_arrowAnim.value, 0),
                    child: child,
                  ),
                  child: Text(
                    '»',
                    style: GoogleFonts.dmSans(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSvgTab(
      BuildContext context, String label, int index, String svgPath) {
    return InkWell(
      onTap: () => widget.controller.onTabChanged(index),
      borderRadius: BorderRadius.circular(8.0),
      child: Obx(() {
        final isSelected = widget.controller.selectedTabIndex.value == index;
        return _tabContainer(isSelected, [
          SvgPicture.asset(
            svgPath,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              isSelected ? const Color(0xFF004E7E) : const Color(0xFF6B7280),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          _tabLabel(label, isSelected),
        ]);
      }),
    );
  }

  Widget _tabContainer(bool isSelected, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _tabLabel(String label, bool isSelected) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: isSelected ? const Color(0xFF004E7E) : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12.0,
      ),
    );
  }
}
