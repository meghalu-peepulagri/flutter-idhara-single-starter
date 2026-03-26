import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/graphs/current_model.dart';

void main() {
  group('CurrentResponse', () {
    test('fromJson parses response with current data', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Current data fetched',
        'data': [
          {
            'id': 1,
            'time_stamp': '2026-03-26T10:00:00.000Z',
            'current_r': 4.5,
            'current_y': 4.3,
            'current_b': 4.6,
          },
        ],
      };

      final response = CurrentResponse.fromJson(json);

      expect(response.data!.length, 1);
      expect(response.data![0].currentR, 4.5);
      expect(response.data![0].currentY, 4.3);
      expect(response.data![0].currentB, 4.6);
    });

    test('Current handles int values via toDouble', () {
      final json = {
        'current_r': 5,
        'current_y': 4,
        'current_b': 6,
      };

      final current = Current.fromJson(json);
      expect(current.currentR, 5.0);
      expect(current.currentY, 4.0);
      expect(current.currentB, 6.0);
    });

    test('Current handles null fields', () {
      final current = Current.fromJson(<String, dynamic>{});
      expect(current.id, isNull);
      expect(current.timeStamp, isNull);
      expect(current.currentR, isNull);
    });

    test('handles null data list', () {
      final response = CurrentResponse.fromJson({'data': null});
      expect(response.data, isEmpty);
    });

    test('toJson → fromJson round-trip', () {
      final original = CurrentResponse(
        status: 200,
        data: [
          Current(
            id: 1,
            timeStamp: DateTime.utc(2026, 3, 26),
            currentR: 3.5,
            currentY: 3.2,
            currentB: 3.8,
          ),
        ],
      );

      final json = original.toJson();
      final restored = CurrentResponse.fromJson(json);

      expect(restored.data![0].currentR, 3.5);
      expect(restored.data![0].currentY, 3.2);
    });
  });
}
