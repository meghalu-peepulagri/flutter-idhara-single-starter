import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/auth/otp_model.dart';

void main() {
  group('OtpResponse', () {
    test('fromJson parses full success response', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Login successful',
        'data': {
          'user_details': {
            'id': 1,
            'full_name': 'Pavan Kumar',
            'email': 'pavan@test.com',
            'phone': '9876543210',
            'user_type': 'ADMIN',
            'address': 'Hyderabad',
            'status': 'ACTIVE',
            'created_by': null,
            'user_verified': true,
            'created_at': '2025-01-15T10:30:00.000Z',
            'updated_at': '2025-06-20T14:00:00.000Z',
          },
          'access_token': 'eyJhbGciOiJIUzI1NiJ9.test',
          'refresh_token': 'refresh_token_value',
        },
        'errors': null,
      };

      final response = OtpResponse.fromJson(json);

      expect(response.status, 200);
      expect(response.success, true);
      expect(response.data, isNotNull);
      expect(response.data!.accessToken, 'eyJhbGciOiJIUzI1NiJ9.test');
      expect(response.data!.refreshToken, 'refresh_token_value');
    });

    test('UserDetails parses DateTime fields', () {
      final json = {
        'id': 1,
        'full_name': 'Test User',
        'created_at': '2025-01-15T10:30:00.000Z',
        'updated_at': '2025-06-20T14:00:00.000Z',
      };

      final user = UserDetails.fromJson(json);

      expect(user.createdAt, isNotNull);
      expect(user.createdAt!.year, 2025);
      expect(user.createdAt!.month, 1);
      expect(user.createdAt!.day, 15);
      expect(user.updatedAt, isNotNull);
      expect(user.updatedAt!.year, 2025);
    });

    test('UserDetails handles null DateTime fields', () {
      final json = {
        'id': 1,
        'created_at': null,
        'updated_at': null,
      };

      final user = UserDetails.fromJson(json);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('UserDetails toJson serializes DateTime to ISO8601', () {
      final user = UserDetails(
        id: 1,
        fullName: 'Test',
        createdAt: DateTime.utc(2025, 3, 15, 10, 0),
      );

      final json = user.toJson();
      expect(json['created_at'], '2025-03-15T10:00:00.000Z');
    });

    test('fromJson parses error response', () {
      final json = {
        'status': 401,
        'success': false,
        'message': 'Invalid OTP',
        'errors': {
          'otp': 'OTP has expired',
        },
      };

      final response = OtpResponse.fromJson(json);

      expect(response.success, false);
      expect(response.errors, isNotNull);
      expect(response.errors!.otp, 'OTP has expired');
    });

    test('fromJson → toJson round-trip preserves data', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'OK',
        'data': {
          'user_details': {
            'id': 5,
            'full_name': 'Round Trip User',
            'phone': '1234567890',
            'user_verified': true,
          },
          'access_token': 'token123',
          'refresh_token': 'refresh456',
        },
      };

      final response = OtpResponse.fromJson(json);
      final output = response.toJson();

      expect(output['status'], 200);
      expect(output['data']['access_token'], 'token123');
      expect(output['data']['user_details']['full_name'], 'Round Trip User');
    });
  });
}
