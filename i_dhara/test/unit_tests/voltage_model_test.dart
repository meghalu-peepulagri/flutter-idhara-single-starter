import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/graphs/voltage_model.dart';

void main() {
  group('VoltageResponse', () {
    test('fromJson parses response with voltage data', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Voltage data fetched',
        'data': [
          {
            'id': 1,
            'time_stamp': '2026-03-26T10:00:00.000Z',
            'line_voltage_r': 230.5,
            'line_voltage_y': 228.3,
            'line_voltage_b': 231.1,
          },
          {
            'id': 2,
            'time_stamp': '2026-03-26T10:05:00.000Z',
            'line_voltage_r': 229.8,
            'line_voltage_y': 227.9,
            'line_voltage_b': 230.4,
          },
        ],
      };

      final response = VoltageResponse.fromJson(json);

      expect(response.status, 200);
      expect(response.data, isNotNull);
      expect(response.data!.length, 2);
      expect(response.data![0].lineVoltageR, 230.5);
      expect(response.data![0].lineVoltageY, 228.3);
      expect(response.data![0].lineVoltageB, 231.1);
    });

    test('Voltage parses DateTime', () {
      final json = {
        'id': 1,
        'time_stamp': '2026-03-26T10:30:00.000Z',
        'line_voltage_r': 220.0,
      };

      final voltage = Voltage.fromJson(json);

      expect(voltage.timeStamp, isNotNull);
      expect(voltage.timeStamp!.year, 2026);
      expect(voltage.timeStamp!.month, 3);
      expect(voltage.timeStamp!.hour, 10);
    });

    test('Voltage handles null fields', () {
      final voltage = Voltage.fromJson(<String, dynamic>{});
      expect(voltage.id, isNull);
      expect(voltage.timeStamp, isNull);
      expect(voltage.lineVoltageR, isNull);
    });

    test('Voltage handles int voltage values via toDouble', () {
      final json = {
        'line_voltage_r': 230,
        'line_voltage_y': 228,
        'line_voltage_b': 231,
      };

      final voltage = Voltage.fromJson(json);
      expect(voltage.lineVoltageR, 230.0);
      expect(voltage.lineVoltageY, 228.0);
      expect(voltage.lineVoltageB, 231.0);
    });

    test('handles empty data list', () {
      final json = {
        'status': 200,
        'success': true,
        'data': [],
      };

      final response = VoltageResponse.fromJson(json);
      expect(response.data, isEmpty);
    });

    test('handles null data', () {
      final json = {
        'status': 200,
        'data': null,
      };

      final response = VoltageResponse.fromJson(json);
      expect(response.data, isEmpty);
    });

    test('toJson → fromJson round-trip', () {
      final original = VoltageResponse(
        status: 200,
        success: true,
        data: [
          Voltage(
            id: 1,
            timeStamp: DateTime.utc(2026, 3, 26),
            lineVoltageR: 230.0,
            lineVoltageY: 228.0,
            lineVoltageB: 231.0,
          ),
        ],
      );

      final json = original.toJson();
      final restored = VoltageResponse.fromJson(json);

      expect(restored.data!.length, 1);
      expect(restored.data![0].lineVoltageR, 230.0);
    });
  });
}
