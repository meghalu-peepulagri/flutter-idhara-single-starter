import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/motors/faults_model.dart';

void main() {
  group('FaultsResponse', () {
    test('fromJson parses full response with faults', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Faults fetched',
        'data': {
          'pagination': {
            'total_records': 25,
            'total_pages': 3,
            'page_size': 10,
            'current_page': 1,
            'next_page': 2,
            'prev_page': null,
          },
          'records': [
            {
              'id': 1,
              'starter_id': 5,
              'motor_id': 10,
              'code': 101,
              'description': 'Over voltage detected',
              'timestamp': '2026-03-26T14:30:00.000Z',
            },
            {
              'id': 2,
              'starter_id': 5,
              'motor_id': 10,
              'code': 202,
              'description': 'Dry run detected',
              'timestamp': '2026-03-26T15:00:00.000Z',
            },
          ],
        },
      };

      final response = FaultsResponse.fromJson(json);

      expect(response.status, 200);
      expect(response.data!.pagination!.totalRecords, 25);
      expect(response.data!.pagination!.totalPages, 3);
      expect(response.data!.records!.length, 2);

      final fault = response.data!.records![0];
      expect(fault.id, 1);
      expect(fault.starterId, 5);
      expect(fault.motorId, 10);
      expect(fault.code, 101);
      expect(fault.description, 'Over voltage detected');
      expect(fault.timestamp!.year, 2026);
      expect(fault.timestamp!.hour, 14);
    });

    test('MotorFaults handles null timestamp', () {
      final fault = MotorFaults.fromJson({
        'id': 1,
        'code': 100,
        'timestamp': null,
      });
      expect(fault.timestamp, isNull);
    });

    test('handles null records', () {
      final data = Data.fromJson({'records': null});
      expect(data.records, isEmpty);
    });

    test('handles null pagination', () {
      final data = Data.fromJson({'pagination': null});
      expect(data.pagination, isNull);
    });

    test('Pagination handles last page (no next)', () {
      final pagination = Pagination.fromJson({
        'total_records': 10,
        'total_pages': 1,
        'page_size': 10,
        'current_page': 1,
        'next_page': null,
        'prev_page': null,
      });

      expect(pagination.nextPage, isNull);
      expect(pagination.prevPage, isNull);
    });

    test('MotorFaults toJson → fromJson round-trip', () {
      final original = MotorFaults(
        id: 1,
        starterId: 5,
        motorId: 10,
        code: 301,
        description: 'Test fault',
        timestamp: DateTime.utc(2026, 3, 26, 12, 0),
      );

      final json = original.toJson();
      final restored = MotorFaults.fromJson(json);

      expect(restored.id, 1);
      expect(restored.code, 301);
      expect(restored.description, 'Test fault');
      expect(restored.timestamp!.hour, 12);
    });
  });
}
