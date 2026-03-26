import 'package:flutter_test/flutter_test.dart';
import 'package:i_dhara/app/data/dto/device_setting_dto.dart';

void main() {
  group('UserUpdateSettingsDto', () {
    test('fromJson parses basic fields correctly', () {
      final json = {
        'starter_id': 1,
        'allflt_en': 1,
        'flc': 5.5,
        'as_dly': 10,
        'v_en': 1,
        'c_en': 0,
        'port': 1883,
      };

      final dto = UserUpdateSettingsDto.fromJson(json);

      expect(dto.starterId, 1);
      expect(dto.allfltEn, 1);
      expect(dto.flc, 5.5);
      expect(dto.asDly, 10);
      expect(dto.vEn, 1);
      expect(dto.cEn, 0);
      expect(dto.port, 1883);
    });

    test('fromJson handles int-to-double conversion for flc', () {
      final json = {'flc': 5};
      final dto = UserUpdateSettingsDto.fromJson(json);
      expect(dto.flc, 5.0);
    });

    test('fromJson handles string-to-int conversion', () {
      final json = {'starter_id': '42'};
      final dto = UserUpdateSettingsDto.fromJson(json);
      expect(dto.starterId, 42);
    });

    test('fromJson handles string-to-double conversion', () {
      final json = {'flc': '3.14'};
      final dto = UserUpdateSettingsDto.fromJson(json);
      expect(dto.flc, 3.14);
    });

    test('fromJson handles null values gracefully', () {
      final json = <String, dynamic>{};
      final dto = UserUpdateSettingsDto.fromJson(json);

      expect(dto.starterId, isNull);
      expect(dto.flc, isNull);
      expect(dto.asDly, isNull);
    });

    test('fromJson parses authNum list', () {
      final json = {
        'auth_num': ['9876543210', '1234567890'],
      };
      final dto = UserUpdateSettingsDto.fromJson(json);

      expect(dto.authNum, ['9876543210', '1234567890']);
    });

    test('fromJson handles null authNum as empty list', () {
      final json = {'auth_num': null};
      final dto = UserUpdateSettingsDto.fromJson(json);
      expect(dto.authNum, isEmpty);
    });

    test('fromJson parses string fields', () {
      final json = {
        'ca_fn': 'cert.pem',
        'bkr_adrs': 'broker.mqtt.io',
        'sn': 12345,
        'usrn': 'admin',
        'pswd': 'secret',
        'prd_url': 'https://api.example.com',
      };
      final dto = UserUpdateSettingsDto.fromJson(json);

      expect(dto.caFn, 'cert.pem');
      expect(dto.bkrAdrs, 'broker.mqtt.io');
      expect(dto.sn, '12345'); // sn converts via .toString()
      expect(dto.usrn, 'admin');
      expect(dto.pswd, 'secret');
      expect(dto.prdUrl, 'https://api.example.com');
    });

    test('toJson serializes all fields', () {
      final dto = UserUpdateSettingsDto(
        starterId: 1,
        allfltEn: 1,
        flc: 5.5,
        asDly: 10,
        vEn: 1,
        port: 1883,
        authNum: ['123', '456'],
      );

      final json = dto.toJson();

      expect(json['starter_id'], 1);
      expect(json['allflt_en'], 1);
      expect(json['flc'], 5.5);
      expect(json['as_dly'], 10);
      expect(json['v_en'], 1);
      expect(json['port'], 1883);
      expect(json['auth_num'], ['123', '456']);
    });

    test('toJson handles null authNum as empty list', () {
      final dto = UserUpdateSettingsDto();
      final json = dto.toJson();
      expect(json['auth_num'], isEmpty);
    });

    test('fromJson → toJson round-trip preserves data', () {
      final original = {
        'starter_id': 5,
        'allflt_en': 1,
        'flc': 4.2,
        'as_dly': 15,
        'v_en': 1,
        'c_en': 0,
        'lvf': 180,
        'hvf': 260,
        'port': 1883,
        'auth_num': ['111', '222'],
      };

      final dto = UserUpdateSettingsDto.fromJson(original);
      final roundTripped = dto.toJson();

      expect(roundTripped['starter_id'], original['starter_id']);
      expect(roundTripped['allflt_en'], original['allflt_en']);
      expect(roundTripped['flc'], original['flc']);
      expect(roundTripped['as_dly'], original['as_dly']);
      expect(roundTripped['lvf'], original['lvf']);
      expect(roundTripped['hvf'], original['hvf']);
      expect(roundTripped['port'], original['port']);
    });

    test('fromJson parses voltage/current fault flags', () {
      final json = {
        'vflt_under_voltage': 1,
        'vflt_over_voltage': 0,
        'cflt_dry_run': 1,
        'cflt_over_current': 0,
      };
      final dto = UserUpdateSettingsDto.fromJson(json);

      expect(dto.vfltUnderVoltage, 1);
      expect(dto.vfltOverVoltage, 0);
      expect(dto.cfltDryRun, 1);
      expect(dto.cfltOverCurrent, 0);
    });

    test('fromJson parses gain/offset calibration fields', () {
      final json = {
        'ug_r': 100,
        'ug_y': 101,
        'ug_b': 102,
        'vo_r': 5,
        'vo_y': 6,
        'vo_b': 7,
      };
      final dto = UserUpdateSettingsDto.fromJson(json);

      expect(dto.ugR, 100);
      expect(dto.ugY, 101);
      expect(dto.ugB, 102);
      expect(dto.voR, 5);
      expect(dto.voY, 6);
      expect(dto.voB, 7);
    });
  });
}
