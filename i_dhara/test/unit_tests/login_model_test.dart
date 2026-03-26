import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/auth/login_model.dart';

void main() {
  group('PhoneResponse', () {
    test('fromJson parses success response', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'OTP sent successfully',
        'data': null,
        'errors': null,
      };

      final response = PhoneResponse.fromJson(json);

      expect(response.status, 200);
      expect(response.success, true);
      expect(response.message, 'OTP sent successfully');
      expect(response.data, isNull);
      expect(response.errors, isNull);
    });

    test('fromJson parses error response with errors', () {
      final json = {
        'status': 422,
        'success': false,
        'message': 'Validation failed',
        'data': null,
        'errors': {'phone': 'Phone number is required'},
      };

      final response = PhoneResponse.fromJson(json);

      expect(response.status, 422);
      expect(response.success, false);
      expect(response.errors, isNotNull);
      expect(response.errors!.phone, 'Phone number is required');
    });

    test('toJson serializes correctly', () {
      final response = PhoneResponse(
        status: 200,
        success: true,
        message: 'Success',
      );

      final json = response.toJson();

      expect(json['status'], 200);
      expect(json['success'], true);
      expect(json['message'], 'Success');
    });

    test('fromJson → toJson round-trip via JSON string', () {
      const jsonStr =
          '{"status":200,"success":true,"message":"OTP sent","data":null,"errors":null}';

      final parsed = phoneResponseFromJson(jsonStr);
      final serialized = phoneResponseToJson(parsed);
      final reparsed = phoneResponseFromJson(serialized);

      expect(reparsed.status, 200);
      expect(reparsed.success, true);
      expect(reparsed.message, 'OTP sent');
    });

    test('handles all-null fields', () {
      final json = <String, dynamic>{};
      final response = PhoneResponse.fromJson(json);

      expect(response.status, isNull);
      expect(response.success, isNull);
      expect(response.message, isNull);
      expect(response.errors, isNull);
    });
  });

  group('Errors', () {
    test('fromJson and toJson round-trip', () {
      final json = {'phone': 'Invalid phone number'};
      final errors = Errors.fromJson(json);
      expect(errors.phone, 'Invalid phone number');

      final output = errors.toJson();
      expect(output['phone'], 'Invalid phone number');
    });
  });
}
