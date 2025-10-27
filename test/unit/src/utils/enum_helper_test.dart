// test/unit/src/utils/enum_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/utils/enum_helper.dart';

enum TestEnum {
  first,
  second,
  third,
}

void main() {
  group('enumFromStringOrDefault', () {
    test('returns matching enum value when name is found', () {
      final result = enumFromStringOrDefault(TestEnum.values, 'second');
      expect(result, TestEnum.second);
    });

    test('returns provided default when name not found', () {
      final result = enumFromStringOrDefault(
        TestEnum.values,
        'invalid',
        TestEnum.first,
      );
      expect(result, TestEnum.first);
    });

    test('returns last value when name not found and no default provided', () {
      final result = enumFromStringOrDefault(TestEnum.values, 'invalid');
      expect(result, TestEnum.third); // last value
    });

    test('handles empty string input with default', () {
      final result = enumFromStringOrDefault(
        TestEnum.values,
        '',
        TestEnum.second,
      );
      expect(result, TestEnum.second);
    });

    test('handles empty string input without default (uses last)', () {
      final result = enumFromStringOrDefault(TestEnum.values, '');
      expect(result, TestEnum.third);
    });

    test('is case sensitive', () {
      final result = enumFromStringOrDefault(
        TestEnum.values,
        'FIRST',
        TestEnum.second,
      );
      expect(result, TestEnum.second); // not found, returns default
    });
  });

  group('enumFromString', () {
    test('returns matching enum value when name is found', () {
      final result = enumFromString(TestEnum.values, 'first');
      expect(result, TestEnum.first);
    });

    test('throws ArgumentError when name not found', () {
      expect(
        () => enumFromString(TestEnum.values, 'invalid'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'No enum value found for name: invalid',
        )),
      );
    });

    test('throws ArgumentError for empty string', () {
      expect(
        () => enumFromString(TestEnum.values, ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('is case sensitive', () {
      expect(
        () => enumFromString(TestEnum.values, 'FIRST'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('enumFromStringOrNull', () {
    test('returns matching enum value when name is found', () {
      final result = enumFromStringOrNull(TestEnum.values, 'third');
      expect(result, TestEnum.third);
    });

    test('returns null when name not found', () {
      final result = enumFromStringOrNull(TestEnum.values, 'invalid');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = enumFromStringOrNull(TestEnum.values, '');
      expect(result, isNull);
    });

    test('is case sensitive', () {
      final result = enumFromStringOrNull(TestEnum.values, 'SECOND');
      expect(result, isNull);
    });
  });
}
