import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/dto/device_assign_dto.dart';

void main() {
  group('StarterCreateDto', () {
    test('toJson includes required fields', () {
      final dto = StarterCreateDto(
        pcbNumber: 'PCB001',
        motorName: 'Pump Motor 1',
        hp: 5.0,
        locationId: 10,
      );

      final json = dto.toJson();

      expect(json['pcb_number'], 'PCB001');
      expect(json['motor_name'], 'Pump Motor 1');
      expect(json['hp'], 5.0);
      expect(json['location_id'], 10);
    });

    test('toJson excludes null optional fields', () {
      final dto = StarterCreateDto(
        pcbNumber: 'PCB001',
        motorName: 'Motor',
        hp: 3.0,
        locationId: 1,
      );

      final json = dto.toJson();

      expect(json.containsKey('name'), false);
      expect(json.containsKey('serial_number'), false);
      expect(json.containsKey('starter_number'), false);
      expect(json.containsKey('mac_address'), false);
      expect(json.containsKey('gateway_id'), false);
    });

    test('toJson includes optional fields when provided', () {
      final dto = StarterCreateDto(
        pcbNumber: 'PCB002',
        motorName: 'Motor 2',
        hp: 7.5,
        locationId: 5,
        name: 'Starter A',
        serialNumber: 'SN12345',
        starterNumber: 'ST001',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        gatewayId: 99,
      );

      final json = dto.toJson();

      expect(json['name'], 'Starter A');
      expect(json['serial_number'], 'SN12345');
      expect(json['starter_number'], 'ST001');
      expect(json['mac_address'], 'AA:BB:CC:DD:EE:FF');
      expect(json['gateway_id'], 99);
    });

    test('hp field supports decimal values', () {
      final dto = StarterCreateDto(
        pcbNumber: 'PCB003',
        motorName: 'Motor 3',
        hp: 2.5,
        locationId: 1,
      );

      expect(dto.toJson()['hp'], 2.5);
    });
  });
}
