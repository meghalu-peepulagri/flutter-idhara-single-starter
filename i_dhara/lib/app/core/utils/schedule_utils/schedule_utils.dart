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

/// True when the phone's system time setting is 24-hour.
bool deviceUses24h(BuildContext context) =>
    MediaQuery.of(context).alwaysUse24HourFormat;

/// Formats an hour (0-23) + minute in the device's clock format — 12h shows
/// AM/PM ("6:05 PM"), 24h shows "18:05" — following the phone's setting.
String formatScheduleClock(BuildContext context, int hour24, int minute) {
  final m = minute.toString().padLeft(2, '0');
  if (deviceUses24h(context)) {
    return '${hour24.toString().padLeft(2, '0')}:$m';
  }
  final period = hour24 >= 12 ? 'PM' : 'AM';
  var h = hour24 % 12;
  if (h == 0) h = 12;
  return '$h:$m $period';
}

/// Parses a raw "HHMM" / "HH:MM" time string and formats it in the device's
/// clock format. Returns the raw value unchanged when it can't be parsed.
String formatScheduleClockRaw(BuildContext context, String raw) {
  int hh;
  int mm;
  if (raw.contains(':')) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    hh = int.tryParse(parts[0]) ?? -1;
    final mp = parts[1].length >= 2 ? parts[1].substring(0, 2) : parts[1];
    mm = int.tryParse(mp) ?? -1;
  } else if (raw.length >= 3) {
    mm = int.tryParse(raw.substring(raw.length - 2)) ?? -1;
    hh = int.tryParse(raw.substring(0, raw.length - 2)) ?? -1;
  } else {
    return raw;
  }
  if (hh < 0 || mm < 0) return raw;
  return formatScheduleClock(context, hh, mm);
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
