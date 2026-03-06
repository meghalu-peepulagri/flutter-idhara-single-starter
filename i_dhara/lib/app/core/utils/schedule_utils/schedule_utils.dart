import 'package:flutter/material.dart';

const List<String> dayLabels = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat'
];

const List<String> dayFullLabels = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday'
];

String formatTime24h(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay calcEndTime(TimeOfDay start, int durH, int durM) {
  int totalMin = (start.hour * 60 + start.minute) + (durH * 60 + durM);
  totalMin = totalMin % (24 * 60);
  return TimeOfDay(hour: totalMin ~/ 60, minute: totalMin % 60);
}

String formatDurationHM(int h, int m) {
  return '${h.toString().padLeft(2, '0')}h : ${m.toString().padLeft(2, '0')}m';
}

int buildDaysBitmask(Set<int> selectedDays) {
  int mask = 0;
  for (final dayIndex in selectedDays) {
    if (dayIndex >= 0 && dayIndex <= 6) {
      mask |= (1 << dayIndex);
    }
  }
  return mask;
}

int durationToMinutes(int hours, int minutes) {
  return (hours * 60) + minutes;
}
