import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/utils/schedule_utils/schedule_utils.dart';
import 'package:i_dhara/app/presentation/components/schedules/create_schedule_form_widgets.dart';
import 'package:i_dhara/app/presentation/modules/schedule/schedule_bottom_sheets.dart';

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

  int startHour = 0;
  int startMinute = 0;
  int endHour = 0;
  int endMinute = 0;

  bool cyclicMode = false;
  int cyclicOnMinutes = 20;
  int cyclicOffMinutes = 15;
  bool powerLossRecovery = false;
  bool repeatWeekly = false;

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

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  int get durationMinutes {
    int s = startHour * 60 + startMinute;
    int e = endHour * 60 + endMinute;
    if (e <= s) e += 1440;
    return e - s;
  }

  String get durationText {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  //  Time picker
  void _onTimePicked(TimeOfDay t, bool isStart) => setState(() {
        if (isStart) {
          startHour = t.hour;
          startMinute = t.minute;
        } else {
          endHour = t.hour;
          endMinute = t.minute;
        }
      });

  void _openTimePicker(bool isStart) => showTimeBottomSheet(
        context,
        isStart ? startTime : endTime,
        (picked) => _onTimePicked(picked, isStart),
        minTime: isStart ? null : startTime,
      );

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
                scheduleSectionLabel('Select Days'),
                const SizedBox(height: 10),
                _buildDayChips(),
                const SizedBox(height: 24),
                scheduleSectionLabel('Schedule Timing'),
                const SizedBox(height: 10),
                _buildTimingCard(),
                const SizedBox(height: 24),
                ScheduleCyclicCard(
                  cyclicMode: cyclicMode,
                  cyclicOnMinutes: cyclicOnMinutes,
                  cyclicOffMinutes: cyclicOffMinutes,
                  cyclicController: _cyclicController,
                  onCyclicChanged: (v) => setState(() {
                    cyclicMode = v;
                    _cyclicController.value = v;
                  }),
                  onOnDecrement: () => setState(() {
                    if (cyclicOnMinutes > 5) cyclicOnMinutes -= 5;
                  }),
                  onOnIncrement: () => setState(() {
                    if (cyclicOnMinutes < 120) cyclicOnMinutes += 5;
                  }),
                  onOffDecrement: () => setState(() {
                    if (cyclicOffMinutes > 5) cyclicOffMinutes -= 5;
                  }),
                  onOffIncrement: () => setState(() {
                    if (cyclicOffMinutes < 120) cyclicOffMinutes += 5;
                  }),
                ),
                const SizedBox(height: 12),
                buildScheduleToggle(
                  icon: Icons.power_rounded,
                  title: 'Power Loss Recovery',
                  subtitle: 'Auto-resume after power restored',
                  controller: _powerLossController,
                  onChanged: (v) => setState(() {
                    powerLossRecovery = v;
                    _powerLossController.value = v;
                  }),
                ),
                const SizedBox(height: 12),
                buildScheduleToggle(
                  icon: Icons.repeat_rounded,
                  title: 'Repeat Weekly',
                  subtitle: 'Auto-repeat on selected days',
                  controller: _repeatController,
                  onChanged: (v) => setState(() {
                    repeatWeekly = v;
                    _repeatController.value = v;
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        ScheduleFormBottomBar(onBack: widget.onBack, onSave: widget.onSave),
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
              child: Text(dayLabels[i],
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF57636C))),
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
                  child:
                      _buildTimePicker('START', startHour, startMinute, true)),
              Container(
                  width: 1,
                  height: 60,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                  child: _buildTimePicker('END', endHour, endMinute, false)),
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
                Text('Duration: $durationText',
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, int hour, int minute, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _openTimePicker(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(hour.toString().padLeft(2, '0'),
                    style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(':',
                  style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A))),
            ),
            GestureDetector(
              onTap: () => _openTimePicker(isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FE),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(minute.toString().padLeft(2, '0'),
                    style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
