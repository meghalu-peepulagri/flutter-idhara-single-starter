import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/locations/location_model.dart';

void main() {
  group('LocationResponse', () {
    test('fromJson parses full response', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Locations fetched',
        'data': {
          'locations_count': 2,
          'records': [
            {
              'id': 1,
              'name': 'Farm A',
              'status': 'ACTIVE',
              'total_motors': 3,
              'on_state_count': 1,
              'auto_mode_count': 2,
              'manual_mode_count': 1,
              'motors': [
                {
                  'id': 10,
                  'name': 'Pump 1',
                  'hp': '5.0',
                  'state': 1,
                  'mode': 'AUTO',
                  'alias_name': 'Main Pump',
                  'starter': {'id': 20, 'power': 1},
                },
              ],
            },
          ],
        },
      };

      final response = LocationResponse.fromJson(json);

      expect(response.data!.locationsCount, 2);
      expect(response.data!.records!.length, 1);

      final location = response.data!.records![0];
      expect(location.id, 1);
      expect(location.name, 'Farm A');
      expect(location.totalMotors, 3);
      expect(location.onStateCount, 1);
      expect(location.autoModeCount, 2);
      expect(location.manualModeCount, 1);

      final motor = location.motors![0];
      expect(motor.id, 10);
      expect(motor.name, 'Pump 1');
      expect(motor.hp, '5.0');
      expect(motor.mode, 'AUTO');
      expect(motor.starter!.id, 20);
      expect(motor.starter!.power, 1);
    });

    test('Location handles null motors', () {
      final location = Location.fromJson({'motors': null});
      expect(location.motors, isEmpty);
    });

    test('Motor handles null starter', () {
      final motor = Motor.fromJson({'starter': null});
      expect(motor.starter, isNull);
    });

    test('toJson → fromJson round-trip', () {
      final original = LocationResponse(
        status: 200,
        data: Data(
          locationsCount: 1,
          records: [
            Location(
              id: 1,
              name: 'Test',
              totalMotors: 0,
              motors: [],
            ),
          ],
        ),
      );

      final json = original.toJson();
      final restored = LocationResponse.fromJson(json);

      expect(restored.data!.records![0].name, 'Test');
    });
  });
}
