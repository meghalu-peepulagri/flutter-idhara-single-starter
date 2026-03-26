import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/locations/location_drop_down_model.dart';

void main() {
  group('LocationDropDownResponse', () {
    test('fromJson parses list of locations', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'OK',
        'data': [
          {'id': 1, 'name': 'Farm A'},
          {'id': 2, 'name': 'Farm B'},
          {'id': 3, 'name': 'Farm C'},
        ],
      };

      final response = LocationDropDownResponse.fromJson(json);

      expect(response.data!.length, 3);
      expect(response.data![0].id, 1);
      expect(response.data![0].name, 'Farm A');
      expect(response.data![2].name, 'Farm C');
    });

    test('handles null data', () {
      final response = LocationDropDownResponse.fromJson({'data': null});
      expect(response.data, isEmpty);
    });

    test('handles empty list', () {
      final response = LocationDropDownResponse.fromJson({'data': []});
      expect(response.data, isEmpty);
    });

    test('LocationDropDown toJson round-trip', () {
      final item = LocationDropDown(id: 5, name: 'Test Location');
      final json = item.toJson();
      final restored = LocationDropDown.fromJson(json);

      expect(restored.id, 5);
      expect(restored.name, 'Test Location');
    });
  });
}
