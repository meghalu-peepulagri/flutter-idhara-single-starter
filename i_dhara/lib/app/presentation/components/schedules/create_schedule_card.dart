import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_bottom_sheets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_utils.dart';

class ScheduleForm extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onBack;

  const ScheduleForm({
    super.key,
    required this.onSave,
    required this.onBack,
  });

  @override
  State<ScheduleForm> createState() => ScheduleFormState();
}

class ScheduleFormState extends State<ScheduleForm> {
  final Set<int> selectedDays = {};

  int startHour = 6;
  int startMinute = 0;
  bool startIsAm = true;

  int endHour = 8;
  int endMinute = 0;
  bool endIsAm = true;

  bool cyclicMode = false;
  bool powerLossRecovery = false;
  bool repeatWeekly = false;

  // ─── Switch controllers ───────────────────────────────────
  late final ValueNotifier<bool> _cyclicController;
  late final ValueNotifier<bool> _powerLossController;
  late final ValueNotifier<bool> _repeatController;

  @override
  void initState() {
    super.initState();
    _cyclicController = ValueNotifier(cyclicMode);
    _powerLossController = ValueNotifier(powerLossRecovery);
    _repeatController = ValueNotifier(repeatWeekly);
  }

  @override
  void dispose() {
    _cyclicController.dispose();
    _powerLossController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  // ─── Public derived getters (used by page via GlobalKey) ─
  int get start24Hour => startIsAm
      ? (startHour == 12 ? 0 : startHour)
      : (startHour == 12 ? 12 : startHour + 12);

  int get end24Hour => endIsAm
      ? (endHour == 12 ? 0 : endHour)
      : (endHour == 12 ? 12 : endHour + 12);

  TimeOfDay get startTime => TimeOfDay(hour: start24Hour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: end24Hour, minute: endMinute);

  int get durationMinutes {
    int s = start24Hour * 60 + startMinute;
    int e = end24Hour * 60 + endMinute;
    if (e <= s) e += 1440;
    return e - s;
  }

  String get durationText {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  // ─── Time picker callback ─────────────────────────────────
  void _onTimePicked(TimeOfDay t, bool isStart) {
    setState(() {
      final h = t.hour;
      final isAm = h < 12;
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      if (isStart) {
        startHour = h12;
        startMinute = t.minute;
        startIsAm = isAm;
      } else {
        endHour = h12;
        endMinute = t.minute;
        endIsAm = isAm;
      }
    });
  }

  void _openTimePicker(bool isStart) {
    showTimeBottomSheet(
      context,
      isStart ? startTime : endTime,
      (picked) => _onTimePicked(picked, isStart),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Select Days'),
                const SizedBox(height: 10),
                _buildDayChips(),
                const SizedBox(height: 24),
                _sectionLabel('Schedule Timing'),
                const SizedBox(height: 10),
                _buildTimingCard(),
                const SizedBox(height: 24),
                _buildToggle(
                  Icons.sync_rounded,
                  'Cyclic Mode',
                  'Motor alternates ON / OFF',
                  cyclicMode,
                  _cyclicController,
                  (v) => setState(() {
                    cyclicMode = v;
                    _cyclicController.value = v;
                  }),
                ),
                const SizedBox(height: 12),
                _buildToggle(
                  Icons.power_rounded,
                  'Power Loss Recovery',
                  'Auto-resume after power restored',
                  powerLossRecovery,
                  _powerLossController,
                  (v) => setState(() {
                    powerLossRecovery = v;
                    _powerLossController.value = v;
                  }),
                ),
                const SizedBox(height: 12),
                _buildToggle(
                  Icons.repeat_rounded,
                  'Repeat Weekly',
                  'Auto-repeat on selected days',
                  repeatWeekly,
                  _repeatController,
                  (v) => setState(() {
                    repeatWeekly = v;
                    _repeatController.value = v;
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildDayChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final sel = selectedDays.contains(i);
        return GestureDetector(
          onTap: () => setState(
              () => sel ? selectedDays.remove(i) : selectedDays.add(i)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 38,
            decoration: BoxDecoration(
              gradient: sel
                  ? const LinearGradient(
                      colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: sel ? null : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: sel ? Colors.transparent : const Color(0xFFDCDCDC)),
            ),
            child: Center(
              child: Text(
                dayLabels[i],
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF57636C),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildTimePicker(
                      'START', startHour, startMinute, startIsAm, true)),
              Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                  child: _buildTimePicker(
                      'END', endHour, endMinute, endIsAm, false)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF3FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: Color(0xFF004E7E)),
                const SizedBox(width: 6),
                Text(
                  'Duration: $durationText',
                  style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF004E7E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
      String label, int hour, int minute, bool isAm, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hour — tap to open picker
            GestureDetector(
              onTap: () => _openTimePicker(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hour.toString().padLeft(2, '0'),
                  style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004E7E)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(':',
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937))),
            ),
            // Minute — tap to open picker
            GestureDetector(
              onTap: () => _openTimePicker(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  minute.toString().padLeft(2, '0'),
                  style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF004E7E)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // AM/PM toggle
            GestureDetector(
              onTap: () => setState(
                  () => isStart ? startIsAm = !startIsAm : endIsAm = !endIsAm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isAm ? 'AM' : 'PM',
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggle(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueNotifier<bool> controller,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          AdvancedSwitch(
            controller: controller,
            activeColor: const Color(0xFF34C759),
            inactiveColor: const Color(0xFFE0E0E0),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            width: 46,
            height: 24,
            enabled: true,
            onChanged: (v) => onChanged(v as bool),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF004E7E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Cancel',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF004E7E))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF004E7E), Color(0xFF3686AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF004E7E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: widget.onSave,
                  child: Center(
                    child: Text('Save Schedule',
                        style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF14181B)),
      );
}
