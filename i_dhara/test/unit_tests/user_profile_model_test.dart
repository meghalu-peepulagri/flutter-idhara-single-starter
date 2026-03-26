import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/models/user_profile/user_profile_model.dart';

void main() {
  group('UserProfileResponse', () {
    test('fromJson parses full profile', () {
      final json = {
        'status': 200,
        'success': true,
        'message': 'Profile fetched',
        'data': {
          'id': 1,
          'full_name': 'Pavan Kumar',
          'email': 'pavan@example.com',
          'phone': '9876543210',
          'user_type': 'ADMIN',
          'address': 'Hyderabad, India',
          'status': 'ACTIVE',
          'created_by': null,
          'referred_by': null,
          'notifications_enabled': ['SMS', 'PUSH'],
          'user_verified': true,
          'created_at': '2025-01-15T10:00:00.000Z',
          'updated_at': '2026-03-26T08:00:00.000Z',
        },
      };

      final response = UserProfileResponse.fromJson(json);

      expect(response.status, 200);
      expect(response.data, isNotNull);
      expect(response.data!.id, 1);
      expect(response.data!.fullName, 'Pavan Kumar');
      expect(response.data!.email, 'pavan@example.com');
      expect(response.data!.phone, '9876543210');
      expect(response.data!.userType, 'ADMIN');
      expect(response.data!.address, 'Hyderabad, India');
      expect(response.data!.status, 'ACTIVE');
      expect(response.data!.userVerified, true);
      expect(response.data!.notificationsEnabled, ['SMS', 'PUSH']);
    });

    test('UserProfile parses DateTime fields', () {
      final profile = UserProfile.fromJson({
        'created_at': '2025-01-15T10:00:00.000Z',
        'updated_at': '2026-03-26T08:00:00.000Z',
      });

      expect(profile.createdAt!.year, 2025);
      expect(profile.updatedAt!.year, 2026);
    });

    test('UserProfile handles null DateTime', () {
      final profile = UserProfile.fromJson({
        'created_at': null,
        'updated_at': null,
      });

      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
    });

    test('UserProfile handles null notifications_enabled', () {
      final profile = UserProfile.fromJson({
        'notifications_enabled': null,
      });
      expect(profile.notificationsEnabled, isEmpty);
    });

    test('UserProfile handles empty notifications_enabled', () {
      final profile = UserProfile.fromJson({
        'notifications_enabled': [],
      });
      expect(profile.notificationsEnabled, isEmpty);
    });

    test('handles null data', () {
      final response = UserProfileResponse.fromJson({
        'status': 404,
        'data': null,
      });
      expect(response.data, isNull);
    });

    test('toJson → fromJson round-trip', () {
      final original = UserProfileResponse(
        status: 200,
        success: true,
        data: UserProfile(
          id: 1,
          fullName: 'Test User',
          phone: '1234567890',
          userVerified: true,
          notificationsEnabled: ['PUSH'],
          createdAt: DateTime.utc(2025, 6, 1),
        ),
      );

      final json = original.toJson();
      final restored = UserProfileResponse.fromJson(json);

      expect(restored.data!.fullName, 'Test User');
      expect(restored.data!.userVerified, true);
      expect(restored.data!.notificationsEnabled, ['PUSH']);
    });
  });
}
