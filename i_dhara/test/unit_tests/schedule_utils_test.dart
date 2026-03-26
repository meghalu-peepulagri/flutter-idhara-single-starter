import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/core/utils/schedule_utils/schedule_utils.dart';

void main() {
  // ── formatTime24h ──────────────────────────────────────────
  group('formatTime24h', () {
    test('pads single-digit hour and minute', () {
      expect(formatTime24h(const TimeOfDay(hour: 5, minute: 3)), '05:03');
    });

    test('formats midnight as 00:00', () {
      expect(formatTime24h(const TimeOfDay(hour: 0, minute: 0)), '00:00');
    });

    test('formats 23:59 correctly', () {
      expect(formatTime24h(const TimeOfDay(hour: 23, minute: 59)), '23:59');
    });

    test('formats double-digit hour and minute without extra padding', () {
      expect(formatTime24h(const TimeOfDay(hour: 14, minute: 30)), '14:30');
    });

    test('formats noon as 12:00', () {
      expect(formatTime24h(const TimeOfDay(hour: 12, minute: 0)), '12:00');
    });
  });

  // ── calcEndTime ────────────────────────────────────────────
  group('calcEndTime', () {
    test('adds duration within same day', () {
      final result =
          calcEndTime(const TimeOfDay(hour: 10, minute: 0), 2, 30);
      expect(result.hour, 12);
      expect(result.minute, 30);
    });

    test('wraps past midnight', () {
      final result =
          calcEndTime(const TimeOfDay(hour: 23, minute: 0), 2, 0);
      expect(result.hour, 1);
      expect(result.minute, 0);
    });

    test('wraps past midnight with minutes', () {
      final result =
          calcEndTime(const TimeOfDay(hour: 23, minute: 45), 0, 30);
      expect(result.hour, 0);
      expect(result.minute, 15);
    });

    test('zero duration returns same time', () {
      final result =
          calcEndTime(const TimeOfDay(hour: 8, minute: 15), 0, 0);
      expect(result.hour, 8);
      expect(result.minute, 15);
    });

    test('exactly 24 hours wraps to same time', () {
      final result =
          calcEndTime(const TimeOfDay(hour: 6, minute: 0), 24, 0);
      expect(result.hour, 6);
      expect(result.minute, 0);
    });

    test('large duration wraps correctly', () {
      final result =
          calcEndTime(const TimeOfDay(hour: 0, minute: 0), 25, 30);
      expect(result.hour, 1);
      expect(result.minute, 30);
    });
  });

  // ── formatDurationHM ──────────────────────────────────────
  group('formatDurationHM', () {
    test('formats single-digit values with padding', () {
      expect(formatDurationHM(1, 5), '01h : 05m');
    });

    test('formats zero duration', () {
      expect(formatDurationHM(0, 0), '00h : 00m');
    });

    test('formats double-digit values', () {
      expect(formatDurationHM(12, 45), '12h : 45m');
    });
  });

  // ── buildDaysBitmask ──────────────────────────────────────
  group('buildDaysBitmask', () {
    test('empty set returns 0', () {
      expect(buildDaysBitmask({}), 0);
    });

    test('single day Sunday (0) returns 1', () {
      expect(buildDaysBitmask({0}), 1);
    });

    test('single day Monday (1) returns 2', () {
      expect(buildDaysBitmask({1}), 2);
    });

    test('single day Saturday (6) returns 64', () {
      expect(buildDaysBitmask({6}), 64);
    });

    test('all days returns 127', () {
      expect(buildDaysBitmask({0, 1, 2, 3, 4, 5, 6}), 127);
    });

    test('weekdays Mon-Fri (1-5) returns correct mask', () {
      expect(buildDaysBitmask({1, 2, 3, 4, 5}), 2 + 4 + 8 + 16 + 32);
    });

    test('ignores out-of-range days', () {
      expect(buildDaysBitmask({0, 7, 10}), 1);
    });

    test('weekend (0, 6) returns correct mask', () {
      expect(buildDaysBitmask({0, 6}), 1 + 64);
    });
  });

  // ── durationToMinutes ──────────────────────────────────────
  group('durationToMinutes', () {
    test('converts hours and minutes', () {
      expect(durationToMinutes(2, 30), 150);
    });

    test('zero duration', () {
      expect(durationToMinutes(0, 0), 0);
    });

    test('only hours', () {
      expect(durationToMinutes(3, 0), 180);
    });

    test('only minutes', () {
      expect(durationToMinutes(0, 45), 45);
    });
  });

  // ── Constants ─────────────────────────────────────────────
  group('Constants', () {
    test('dayLabels has 7 entries', () {
      expect(dayLabels.length, 7);
      expect(dayLabels.first, 'Sun');
      expect(dayLabels.last, 'Sat');
    });

    test('dayFullLabels has 7 entries', () {
      expect(dayFullLabels.length, 7);
      expect(dayFullLabels.first, 'Sunday');
      expect(dayFullLabels.last, 'Saturday');
    });
  });
}
