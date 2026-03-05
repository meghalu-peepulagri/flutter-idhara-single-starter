import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/models/devices/motor_model.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Motor? motor;
  bool _isScheduleEnabled = false;

  // OneTime state
  final Set<int> _oneTimeSelectedDays = {};
  TimeOfDay _oneTimeStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _oneTimeEndTime = const TimeOfDay(hour: 0, minute: 0);
  int _oneTimeDurationHours = 0;
  int _oneTimeDurationMinutes = 0;

  // Cyclic state
  final Set<int> _cyclicSelectedDays = {};
  TimeOfDay _cyclicStartTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _cyclicEndTime = const TimeOfDay(hour: 0, minute: 0);
  int _cyclicDurationHours = 0;
  int _cyclicDurationMinutes = 0;

  static const List<String> _dayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  static const List<String> _dayFullLabels = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      motor = args['motor'] as Motor?;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime24h(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _calcEndTime(TimeOfDay start, int durH, int durM) {
    int totalMin = (start.hour * 60 + start.minute) + (durH * 60 + durM);
    totalMin = totalMin % (24 * 60);
    return TimeOfDay(hour: totalMin ~/ 60, minute: totalMin % 60);
  }

  String _formatDurationHM(int h, int m) {
    return '${h.toString().padLeft(2, '0')}h : ${m.toString().padLeft(2, '0')}m';
  }

  // ─── OneTime setters with auto-calc ─────────────────────
  void _setOneTimeStartTime(TimeOfDay t) {
    setState(() {
      _oneTimeStartTime = t;
      // Recalculate end time from start + duration
      _oneTimeEndTime =
          _calcEndTime(t, _oneTimeDurationHours, _oneTimeDurationMinutes);
    });
  }

  void _setOneTimeEndTime(TimeOfDay t) {
    setState(() {
      _oneTimeEndTime = t;
      // Recalculate duration from start → end
      int startMin = _oneTimeStartTime.hour * 60 + _oneTimeStartTime.minute;
      int endMin = t.hour * 60 + t.minute;
      if (endMin <= startMin) endMin += 24 * 60;
      final diff = endMin - startMin;
      _oneTimeDurationHours = diff ~/ 60;
      _oneTimeDurationMinutes = diff % 60;
    });
  }

  void _setOneTimeDuration(int h, int m) {
    setState(() {
      _oneTimeDurationHours = h;
      _oneTimeDurationMinutes = m;
      _oneTimeEndTime = _calcEndTime(_oneTimeStartTime, h, m);
    });
  }

  // ─── Cyclic setters with auto-calc ──────────────────────
  void _setCyclicStartTime(TimeOfDay t) {
    setState(() {
      _cyclicStartTime = t;
      _cyclicEndTime =
          _calcEndTime(t, _cyclicDurationHours, _cyclicDurationMinutes);
    });
  }

  void _setCyclicEndTime(TimeOfDay t) {
    setState(() {
      _cyclicEndTime = t;
      int startMin = _cyclicStartTime.hour * 60 + _cyclicStartTime.minute;
      int endMin = t.hour * 60 + t.minute;
      if (endMin <= startMin) endMin += 24 * 60;
      final diff = endMin - startMin;
      _cyclicDurationHours = diff ~/ 60;
      _cyclicDurationMinutes = diff % 60;
    });
  }

  void _setCyclicDuration(int h, int m) {
    setState(() {
      _cyclicDurationHours = h;
      _cyclicDurationMinutes = m;
      _cyclicEndTime = _calcEndTime(_cyclicStartTime, h, m);
    });
  }

  // ─── Duration Bottom Sheet ──────────────────────────────
  void _showDurationBottomSheet(
    BuildContext context,
    int curH,
    int curM,
    Function(int, int) onPicked,
  ) {
    int selH = curH;
    int selM = curM;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCDCDC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set Duration',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text('Hours',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF57636C),
                              )),
                          const SizedBox(height: 4),
                          _buildScrollWheel(
                            values: List.generate(24, (i) => i),
                            selected: selH,
                            onChanged: (v) => setSheetState(() => selH = v),
                            padZero: true,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(' : ',
                            style: GoogleFonts.dmSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF004E7E),
                            )),
                      ),
                      Column(
                        children: [
                          Text('Minutes',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF57636C),
                              )),
                          const SizedBox(height: 4),
                          _buildScrollWheel(
                            values: List.generate(60, (i) => i),
                            selected: selM,
                            onChanged: (v) => setSheetState(() => selM = v),
                            padZero: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFDCDCDC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onPicked(selH, selM);
                                Navigator.of(ctx).pop();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text('Confirm',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Bottom Sheet Time Picker (24h) ──────────────────────
  void _showTimeBottomSheet(
    BuildContext context,
    TimeOfDay current,
    Function(TimeOfDay) onPicked,
  ) {
    int selectedHour = current.hour;
    int selectedMinute = current.minute;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCDCDC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Time',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF004E7E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Hour : Minute row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hour wheel
                      _buildScrollWheel(
                        values: List.generate(24, (i) => i),
                        selected: selectedHour,
                        onChanged: (v) => setSheetState(() => selectedHour = v),
                        padZero: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: GoogleFonts.dmSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF004E7E),
                          ),
                        ),
                      ),
                      // Minute wheel
                      _buildScrollWheel(
                        values: List.generate(60, (i) => i),
                        selected: selectedMinute,
                        onChanged: (v) =>
                            setSheetState(() => selectedMinute = v),
                        padZero: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFDCDCDC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onPicked(TimeOfDay(
                                    hour: selectedHour,
                                    minute: selectedMinute));
                                Navigator.of(ctx).pop();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'Confirm',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScrollWheel({
    required List<int> values,
    required int selected,
    required Function(int) onChanged,
    bool padZero = false,
  }) {
    final controller = FixedExtentScrollController(
      initialItem: values.indexOf(selected),
    );
    return Container(
      width: 64,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => onChanged(values[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: values.length,
          builder: (context, index) {
            final isSelected = values[index] == selected;
            final display = padZero
                ? values[index].toString().padLeft(2, '0')
                : values[index].toString();
            return Center(
              child: Text(
                display,
                style: GoogleFonts.dmSans(
                  fontSize: isSelected ? 24 : 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF004E7E)
                      : const Color(0xFF828282),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motorName = motor?.aliasName ?? motor?.name ?? 'Motor';

    return Scaffold(
      backgroundColor: const Color(0xFFEBF3FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, motorName),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildOneTimeTab(context),
                  _buildCyclicTab(context),
                ],
              ),
            ),
            // Fixed bottom: Power toggle + Create button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPowerToggleRow(),
                  const SizedBox(height: 12),
                  _buildCreateButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String motorName) {
    String displayName = motorName;
    if (displayName.length > 16) {
      displayName = '${displayName.substring(0, 16)}...';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF004E7E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004E7E),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF57636C),
          labelStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'One Time'),
            Tab(text: 'Cyclic'),
          ],
        ),
      ),
    );
  }

  // ─── OneTime Tab ─────────────────────────────────────────
  Widget _buildOneTimeTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildSectionLabel('Select Days'),
          const SizedBox(height: 8),
          _buildDaySelector(_oneTimeSelectedDays, (days) {
            setState(() => _oneTimeSelectedDays
              ..clear()
              ..addAll(days));
          }),
          const SizedBox(height: 16),
          _buildSectionLabel('Set Time'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  context,
                  label: 'Start Time',
                  time: _oneTimeStartTime,
                  icon: Icons.play_circle_outline_rounded,
                  onTap: () => _showTimeBottomSheet(
                      context, _oneTimeStartTime, _setOneTimeStartTime),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimeCard(
                  context,
                  label: 'End Time',
                  time: _oneTimeEndTime,
                  icon: Icons.stop_circle_outlined,
                  onTap: () => _showTimeBottomSheet(
                      context, _oneTimeEndTime, _setOneTimeEndTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDurationCard(
            _oneTimeDurationHours,
            _oneTimeDurationMinutes,
            onTap: () => _showDurationBottomSheet(
                context,
                _oneTimeDurationHours,
                _oneTimeDurationMinutes,
                _setOneTimeDuration),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Cyclic Tab ──────────────────────────────────────────
  Widget _buildCyclicTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildSectionLabel('Select Days'),
          const SizedBox(height: 8),
          _buildDaySelector(_cyclicSelectedDays, (days) {
            setState(() => _cyclicSelectedDays
              ..clear()
              ..addAll(days));
          }),
          const SizedBox(height: 16),
          _buildSectionLabel('Set Time'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  context,
                  label: 'Start Time',
                  time: _cyclicStartTime,
                  icon: Icons.play_circle_outline_rounded,
                  onTap: () => _showTimeBottomSheet(
                      context, _cyclicStartTime, _setCyclicStartTime),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTimeCard(
                  context,
                  label: 'End Time',
                  time: _cyclicEndTime,
                  icon: Icons.stop_circle_outlined,
                  onTap: () => _showTimeBottomSheet(
                      context, _cyclicEndTime, _setCyclicEndTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDurationCard(
            _cyclicDurationHours,
            _cyclicDurationMinutes,
            onTap: () => _showDurationBottomSheet(context, _cyclicDurationHours,
                _cyclicDurationMinutes, _setCyclicDuration),
          ),
          const SizedBox(height: 12),
          _buildRepeatInfoCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Section Label ───────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF14181B),
      ),
    );
  }

  // ─── Day Selector ────────────────────────────────────────
  Widget _buildDaySelector(
      Set<int> selectedDays, Function(Set<int>) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                4,
                (i) => _buildDayChip(
                      i,
                      selectedDays.contains(i),
                      () {
                        final newDays = Set<int>.from(selectedDays);
                        newDays.contains(i)
                            ? newDays.remove(i)
                            : newDays.add(i);
                        onChanged(newDays);
                      },
                    )),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...List.generate(3, (idx) {
                final i = idx + 4;
                return _buildDayChip(
                  i,
                  selectedDays.contains(i),
                  () {
                    final newDays = Set<int>.from(selectedDays);
                    newDays.contains(i) ? newDays.remove(i) : newDays.add(i);
                    onChanged(newDays);
                  },
                );
              }),
              const SizedBox(width: 52),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(int dayIndex, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFEBF3FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFDCDCDC),
          ),
        ),
        child: Center(
          child: Text(
            _dayLabels[dayIndex],
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF57636C),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Time Card (compact) ─────────────────────────────────
  Widget _buildTimeCard(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF004E7E)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime24h(time),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14181B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Duration Card (compact, tappable) ───────────────────
  Widget _buildDurationCard(int durationH, int durationM,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF004E7E)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDurationHM(durationH, durationM),
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004E7E),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 14, color: Color(0xFF004E7E)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Repeat Info Card (Cyclic only) ──────────────────────
  Widget _buildRepeatInfoCard() {
    final selectedDayNames = _cyclicSelectedDays.toList()..sort();
    String repeatText;
    if (selectedDayNames.isEmpty) {
      repeatText = 'No days selected';
    } else if (selectedDayNames.length == 7) {
      repeatText = 'Repeats every day';
    } else {
      repeatText =
          'Every ${selectedDayNames.map((d) => _dayFullLabels[d]).join(', ')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFA500).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA500).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.repeat_rounded,
                size: 16, color: Color(0xFFFFA500)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repeat Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repeatText,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF57636C),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Power Toggle Row ─────────────────────────────────────
  Widget _buildPowerToggleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isScheduleEnabled
                    ? Colors.green.withValues(alpha: 0.12)
                    : const Color(0xFFEBF3FE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                size: 18,
                color:
                    _isScheduleEnabled ? Colors.green : const Color(0xFF004E7E),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Schedule Power',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF14181B),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _isScheduleEnabled = !_isScheduleEnabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 50,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _isScheduleEnabled ? Colors.green : Colors.red.shade400,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: _isScheduleEnabled
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Create Schedule Button ──────────────────────────────
  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // TODO: Implement schedule creation logic
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_send_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Create Schedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
