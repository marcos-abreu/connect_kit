// test/unit/src/utils/mapper/response_mappers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/utils/mapper/response_mappers.dart';

void main() {
  group('RawPigeonResponseMapping extension', () {
    group('normalizeAsDataAccess', () {
      test('converts valid Pigeon response to normalized map', () {
        final input = <Object?, Object?>{
          'steps': <Object?, Object?>{
            'read': 'granted',
            'write': 'denied',
          },
          'height': <Object?, Object?>{
            'read': 'granted',
          },
        };

        final result = input.normalizeAsDataAccess();

        expect(result, isA<Map<String, Map<String, String>>>());
        expect(result?['steps']?['read'], 'granted');
        expect(result?['steps']?['write'], 'denied');
        expect(result?['height']?['read'], 'granted');
      });

      test('filters out entries with non-String outer keys', () {
        final input = <Object?, Object?>{
          'valid': <Object?, Object?>{'read': 'granted'},
          123: <Object?, Object?>{'read': 'granted'}, // Invalid key
          null: <Object?, Object?>{'read': 'granted'}, // Invalid key
        };

        final result = input.normalizeAsDataAccess();

        expect(result?.length, 1);
        expect(result?['valid'], isNotNull);
        expect(result?[123], isNull);
      });

      test('filters out entries with non-Map values', () {
        final input = <Object?, Object?>{
          'valid': <Object?, Object?>{'read': 'granted'},
          'invalid': 'not a map', // Invalid value
          'alsoInvalid': null, // Invalid value
        };

        final result = input.normalizeAsDataAccess();

        expect(result?.length, 1);
        expect(result?['valid'], isNotNull);
        expect(result?['invalid'], isNull);
        expect(result?['alsoInvalid'], isNull);
      });

      test('converts inner map keys and values to String', () {
        final input = <Object?, Object?>{
          'steps': <Object?, Object?>{
            123: 456, // Numbers should convert to strings
            'read': 'granted',
          },
        };

        final result = input.normalizeAsDataAccess();

        expect(result?['steps']?['123'], '456');
        expect(result?['steps']?['read'], 'granted');
      });

      test('handles null input', () {
        const Map<Object?, Object?>? input = {null: null};

        final result = input.normalizeAsDataAccess();

        expect(result, {});
      });

      test('handles empty map input', () {
        final input = <Object?, Object?>{};

        final result = input.normalizeAsDataAccess();

        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('handles empty inner maps', () {
        final input = <Object?, Object?>{
          'steps': <Object?, Object?>{},
        };

        final result = input.normalizeAsDataAccess();

        expect(result?['steps'], isNotNull);
        expect(result?['steps'], isEmpty);
      });

      test('handles complex real-world Pigeon response', () {
        final input = <Object?, Object?>{
          'steps': <Object?, Object?>{
            'read': 'granted',
            'write': 'notDetermined',
          },
          'bloodPressure.systolic': <Object?, Object?>{
            'read': 'granted',
            'write': 'denied',
          },
          'bloodPressure.diastolic': <Object?, Object?>{
            'read': 'granted',
            'write': 'denied',
          },
          'workout': <Object?, Object?>{
            'read': 'notSupported',
            'write': 'notSupported',
          },
        };

        final result = input.normalizeAsDataAccess();

        expect(result?.length, 4);
        expect(result?['steps']?['read'], 'granted');
        expect(result?['steps']?['write'], 'notDetermined');
        expect(result?['bloodPressure.systolic']?['read'], 'granted');
        expect(result?['workout']?['read'], 'notSupported');
      });

      test('handles mixed valid and invalid entries', () {
        final input = <Object?, Object?>{
          'valid1': <Object?, Object?>{'read': 'granted'},
          123: <Object?, Object?>{'read': 'granted'}, // Invalid key
          'valid2': <Object?, Object?>{'write': 'denied'},
          'invalid': 'not a map', // Invalid value
          'valid3': <Object?, Object?>{'read': 'unknown'},
        };

        final result = input.normalizeAsDataAccess();

        expect(result?.length, 3);
        expect(result?['valid1'], isNotNull);
        expect(result?['valid2'], isNotNull);
        expect(result?['valid3'], isNotNull);
      });

      test('preserves all inner map entries', () {
        final input = <Object?, Object?>{
          'heartRate': <Object?, Object?>{
            'read': 'granted',
            'write': 'denied',
            'custom': 'value',
          },
        };

        final result = input.normalizeAsDataAccess();

        expect(result?['heartRate']?.length, 3);
        expect(result?['heartRate']?['read'], 'granted');
        expect(result?['heartRate']?['write'], 'denied');
        expect(result?['heartRate']?['custom'], 'value');
      });

      test('handles toString conversion for non-String inner values', () {
        final input = <Object?, Object?>{
          'steps': <Object?, Object?>{
            'read': true, // bool
            'write': null, // null
            'count': 42, // int
          },
        };

        final result = input.normalizeAsDataAccess();

        expect(result?['steps']?['read'], 'true');
        expect(result?['steps']?['write'], 'null');
        expect(result?['steps']?['count'], '42');
      });
    });
  });
}
