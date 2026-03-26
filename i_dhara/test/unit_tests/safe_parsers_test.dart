import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/dto/device_setting_dto.dart';

void main() {
  // ── parseDouble ────────────────────────────────────────────
  group('parseDouble', () {
    test('returns null for null input', () {
      expect(parseDouble(null), isNull);
    });

    test('returns double from double', () {
      expect(parseDouble(3.14), 3.14);
    });

    test('returns double from int', () {
      expect(parseDouble(42), 42.0);
    });

    test('returns double from valid string', () {
      expect(parseDouble('2.5'), 2.5);
    });

    test('returns null from invalid string', () {
      expect(parseDouble('abc'), isNull);
    });

    test('returns null from unsupported type (List)', () {
      expect(parseDouble([1, 2]), isNull);
    });

    test('handles zero values', () {
      expect(parseDouble(0), 0.0);
      expect(parseDouble(0.0), 0.0);
      expect(parseDouble('0'), 0.0);
    });

    test('handles negative values', () {
      expect(parseDouble(-5), -5.0);
      expect(parseDouble('-3.14'), -3.14);
    });
  });

  // ── parseInt ──────────────────────────────────────────────
  group('parseInt', () {
    test('returns null for null input', () {
      expect(parseInt(null), isNull);
    });

    test('returns int from int', () {
      expect(parseInt(42), 42);
    });

    test('returns int from double (truncates)', () {
      expect(parseInt(3.9), 3);
    });

    test('returns int from valid string', () {
      expect(parseInt('100'), 100);
    });

    test('returns null from invalid string', () {
      expect(parseInt('abc'), isNull);
    });

    test('returns null from unsupported type (bool)', () {
      expect(parseInt(true), isNull);
    });

    test('handles zero values', () {
      expect(parseInt(0), 0);
      expect(parseInt(0.0), 0);
      expect(parseInt('0'), 0);
    });

    test('handles negative values', () {
      expect(parseInt(-5), -5);
      expect(parseInt('-10'), -10);
    });
  });
}
