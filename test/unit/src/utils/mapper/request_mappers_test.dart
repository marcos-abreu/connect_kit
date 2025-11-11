// test/unit/src/mapper/request_mappers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/mapper/request_mappers.dart';

void main() {
  group('CKTypeMapping extension', () {
    group('expandCompositeTypes', () {
      test('expands composite type to its default components', () {
        final input = {CKType.bloodPressure};
        final result = input.expandCompositeTypes();

        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
        expect(result, isNot(contains(CKType.bloodPressure)));
      });

      test('keeps simple types unchanged', () {
        final input = {CKType.steps, CKType.height};
        final result = input.expandCompositeTypes();

        expect(result, equals(input));
      });

      test('keeps component types unchanged', () {
        final input = {CKType.nutrition.energy, CKType.nutrition.protein};
        final result = input.expandCompositeTypes();

        expect(result, equals(input));
      });

      test('expands nutrition composite type', () {
        final input = {CKType.nutrition};
        final result = input.expandCompositeTypes();

        expect(result, contains(CKType.nutrition.energy));
        expect(result, contains(CKType.nutrition.protein));
        expect(result, contains(CKType.nutrition.carbs));
        expect(result, contains(CKType.nutrition.fat));
        expect(result, isNot(contains(CKType.nutrition)));
      });

      test('expands workout composite type', () {
        final input = {CKType.workout};
        final result = input.expandCompositeTypes();

        // workout's default includes workout itself + distance
        expect(result, contains(CKType.workout));
        expect(result, contains(CKType.workout.distance));
      });

      test('handles mix of composite and simple types', () {
        final input = {
          CKType.steps,
          CKType.bloodPressure,
          CKType.height,
        };
        final result = input.expandCompositeTypes();

        expect(result, contains(CKType.steps));
        expect(result, contains(CKType.height));
        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
        expect(result, isNot(contains(CKType.bloodPressure)));
      });

      test('handles empty set', () {
        final input = <CKType>{};
        final result = input.expandCompositeTypes();

        expect(result, isEmpty);
      });

      test('does not duplicate types', () {
        final input = {
          CKType.bloodPressure,
          CKType.bloodPressure.systolic,
        };
        final result = input.expandCompositeTypes();

        // systolic should appear only once
        expect(
            result.where((t) => t == CKType.bloodPressure.systolic).length, 1);
        expect(result, contains(CKType.bloodPressure.systolic));
        expect(result, contains(CKType.bloodPressure.diastolic));
      });
    });

    group('mapToRequest', () {
      test('converts CKType set to string list', () {
        final input = {CKType.steps, CKType.height, CKType.weight};
        final result = input.mapToRequest();

        expect(result, isA<List<String>>());
        expect(result, contains('steps'));
        expect(result, contains('height'));
        expect(result, contains('weight'));
      });

      test('handles composite component types', () {
        final input = {CKType.nutrition.energy, CKType.nutrition.protein};
        final result = input.mapToRequest();

        expect(result, contains('nutrition.energy'));
        expect(result, contains('nutrition.protein'));
      });

      test('handles empty set', () {
        final input = <CKType>{};
        final result = input.mapToRequest();

        expect(result, isEmpty);
      });

      test('preserves all types in conversion', () {
        final input = {
          CKType.steps,
          CKType.bloodPressure.systolic,
          CKType.heartRate,
        };
        final result = input.mapToRequest();

        expect(result.length, 3);
      });
    });

    group('chained operations', () {
      test('expandCompositeTypes then mapToRequest works correctly', () {
        final input = {CKType.bloodPressure, CKType.steps};
        final result = input.expandCompositeTypes().mapToRequest();

        expect(result, contains('bloodPressure.systolic'));
        expect(result, contains('bloodPressure.diastolic'));
        expect(result, contains('steps'));
        expect(result, isNot(contains('bloodPressure')));
      });
    });
  });

  group('DataAccessStatus extension', () {
    group('mapToRequest', () {
      test('converts simple types with access types', () {
        final input = {
          CKType.steps: {CKAccessType.read, CKAccessType.write},
          CKType.height: {CKAccessType.read},
        };
        final result = input.mapToRequest();

        expect(result['steps'], containsAll(['read', 'write']));
        expect(result['height'], equals(['read']));
      });

      test('expands composite types automatically', () {
        final input = {
          CKType.bloodPressure: {CKAccessType.read, CKAccessType.write},
        };
        final result = input.mapToRequest();

        expect(
            result['bloodPressure.systolic'], containsAll(['read', 'write']));
        expect(
            result['bloodPressure.diastolic'], containsAll(['read', 'write']));
        expect(result, isNot(contains('bloodPressure')));
      });

      test('handles component types correctly', () {
        final input = {
          CKType.nutrition.energy: {CKAccessType.read},
          CKType.nutrition.protein: {CKAccessType.write},
        };
        final result = input.mapToRequest();

        expect(result['nutrition.energy'], equals(['read']));
        expect(result['nutrition.protein'], equals(['write']));
      });

      test('handles empty map', () {
        final input = <CKType, Set<CKAccessType>>{};
        final result = input.mapToRequest();

        expect(result, isEmpty);
      });

      test('handles empty access type set', () {
        final input = {
          CKType.steps: <CKAccessType>{},
        };
        final result = input.mapToRequest();

        expect(result['steps'], isEmpty);
      });

      test('handles mix of composite and simple types', () {
        final input = {
          CKType.steps: {CKAccessType.read},
          CKType.bloodPressure: {CKAccessType.write},
          CKType.height: {CKAccessType.read, CKAccessType.write},
        };
        final result = input.mapToRequest();

        expect(result['steps'], equals(['read']));
        expect(result['bloodPressure.systolic'], equals(['write']));
        expect(result['bloodPressure.diastolic'], equals(['write']));
        expect(result['height'], containsAll(['read', 'write']));
      });

      test('applies same access types to all expanded components', () {
        final input = {
          CKType.nutrition: {CKAccessType.read, CKAccessType.write},
        };
        final result = input.mapToRequest();

        // All nutrition components should have same access types
        expect(result['nutrition.energy'], containsAll(['read', 'write']));
        expect(result['nutrition.protein'], containsAll(['read', 'write']));
        expect(result['nutrition.carbs'], containsAll(['read', 'write']));
        expect(result['nutrition.fat'], containsAll(['read', 'write']));
      });

      test('workout special case includes workout itself', () {
        final input = {
          CKType.workout: {CKAccessType.read},
        };
        final result = input.mapToRequest();

        // workout defaultComponents includes workout + distance
        expect(result['workout'], equals(['read']));
        expect(result['workout.distance'], equals(['read']));
      });
    });
  });
}
