import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';

void main() {
  group('CKUnitExtension', () {
    group('validateValue', () {
      test('passes validation for positive values', () {
        expect(() => CKUnit.scalar.count.validateValue(1), returnsNormally);
        expect(() => CKUnit.scalar.count.validateValue(100.5), returnsNormally);
        expect(() => CKUnit.scalar.count.validateValue(0.1), returnsNormally);
      });

      test('throws ArgumentError for zero value', () {
        expect(
          () => CKUnit.scalar.count.validateValue(0),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unit value must be positive'),
          )),
        );
      });

      test('throws ArgumentError for negative values', () {
        expect(
          () => CKUnit.scalar.count.validateValue(-1),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unit value must be positive'),
          )),
        );

        expect(
          () => CKUnit.scalar.count.validateValue(-100.5),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unit value must be positive'),
          )),
        );
      });

      test('works with different unit types', () {
        // Test with mass units
        expect(() => CKUnit.mass.kilogram.validateValue(70.5), returnsNormally);
        expect(() => CKUnit.mass.kilogram.validateValue(-5), throwsArgumentError);

        // Test with length units
        expect(() => CKUnit.length.meter.validateValue(1.75), returnsNormally);
        expect(() => CKUnit.length.meter.validateValue(0), throwsArgumentError);

        // Test with energy units
        expect(() => CKUnit.energy.kilocalorie.validateValue(250), returnsNormally);
        expect(() => CKUnit.energy.kilocalorie.validateValue(-10), throwsArgumentError);

        // Test with compound units
        expect(() => CKUnit.compound.beatsPerMin.validateValue(72), returnsNormally);
        expect(() => CKUnit.compound.beatsPerMin.validateValue(-1), throwsArgumentError);
      });

      test('handles very small positive values', () {
        expect(() => CKUnit.length.meter.validateValue(0.001), returnsNormally);
        expect(() => CKUnit.mass.kilogram.validateValue(0.0001), returnsNormally);
      });

      test('provides detailed error messages with actual values', () {
        expect(
          () => CKUnit.scalar.percent.validateValue(-42.5),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            equals('Unit value must be positive. Got: -42.5'),
          )),
        );
      });
    });

    group('Unit access and symbols', () {
      test('can access different unit types and symbols', () {
        // Mass units
        expect(CKUnit.mass.kilogram.symbol, equals('kg'));
        expect(CKUnit.mass.gram.symbol, equals('g'));
        expect(CKUnit.mass.pound.symbol, equals('lb'));

        // Length units
        expect(CKUnit.length.kilometer.symbol, equals('km'));
        expect(CKUnit.length.meter.symbol, equals('m'));
        expect(CKUnit.length.mile.symbol, equals('mi'));

        // Energy units
        expect(CKUnit.energy.kilocalorie.symbol, equals('kcal'));
        expect(CKUnit.energy.calorie.symbol, equals('cal'));
        expect(CKUnit.energy.kilojoule.symbol, equals('kJ'));

        // Compound units
        expect(CKUnit.compound.beatsPerMin.symbol, equals('bpm'));

        // Scalar units
        expect(CKUnit.scalar.count.symbol, equals('count'));
        expect(CKUnit.scalar.percent.symbol, equals('%'));
      });

      test('can access all unit namespaces', () {
        expect(CKUnit.mass, isNotNull);
        expect(CKUnit.length, isNotNull);
        expect(CKUnit.energy, isNotNull);
        expect(CKUnit.power, isNotNull);
        expect(CKUnit.pressure, isNotNull);
        expect(CKUnit.temperature, isNotNull);
        expect(CKUnit.frequency, isNotNull);
        expect(CKUnit.velocity, isNotNull);
        expect(CKUnit.volume, isNotNull);
        expect(CKUnit.scalar, isNotNull);
        expect(CKUnit.bloodGlucose, isNotNull);
        expect(CKUnit.time, isNotNull);
        expect(CKUnit.compound, isNotNull);
      });
    });
  });
}