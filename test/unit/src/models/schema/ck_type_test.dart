// test/unit/src/models/ck_record/ck_type_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';

void main() {
  group('CKType', () {
    group('basic properties', () {
      test('toString returns the type name', () {
        expect(CKType.steps.toString(), 'steps');
        expect(CKType.height.toString(), 'height');
        expect(CKType.bloodPressure.toString(), 'bloodPressure');
      });

      test('displayName converts camelCase to Title Case', () {
        expect(CKType.steps.displayName, 'Steps');
        expect(CKType.restingEnergy.displayName, 'Resting Energy');
        expect(CKType.bodyMassIndex.displayName, 'Body Mass Index');
      });

      test('equality works correctly', () {
        expect(CKType.steps, equals(CKType.steps));
        expect(CKType.height, isNot(equals(CKType.weight)));
      });

      test('hashCode is consistent', () {
        expect(CKType.steps.hashCode, equals(CKType.steps.hashCode));
        expect(CKType.height.hashCode, isNot(equals(CKType.weight.hashCode)));
      });

      test('name getter returns correct type name', () {
        expect(CKType.steps.name, 'steps');
        expect(CKType.height.name, 'height');
        expect(CKType.heartRate.name, 'heartRate');
        expect(CKType.bloodPressure.name, 'bloodPressure');
      });

      test('pattern getter returns correct value pattern', () {
        expect(CKType.steps.pattern, CKValuePattern.quantity);
        expect(CKType.heartRate.pattern, CKValuePattern.samples);
        expect(CKType.bloodPressure.pattern, CKValuePattern.multiple);
        expect(CKType.speed.pattern, CKValuePattern.samples);
      });

      test('timePattern getter returns correct time pattern', () {
        expect(CKType.steps.timePattern, CKTimePattern.interval);
        expect(CKType.height.timePattern, CKTimePattern.instantaneous);
        expect(CKType.bloodPressure.timePattern, CKTimePattern.instantaneous);
        expect(CKType.workout.timePattern, CKTimePattern.interval);
      });
    });

    group('simple types', () {
      test('simple types have empty defaultComponents', () {
        expect(CKType.steps.defaultComponents, isEmpty);
        expect(CKType.height.defaultComponents, isEmpty);
        expect(CKType.weight.defaultComponents, isEmpty);
        expect(CKType.heartRate.defaultComponents, isEmpty);
      });
    });

    group('composite types', () {
      group('bloodPressure', () {
        test('has correct components', () {
          expect(CKType.bloodPressure.defaultComponents.length, 2);
          expect(CKType.bloodPressure.defaultComponents,
              contains(CKType.bloodPressure.systolic));
          expect(CKType.bloodPressure.defaultComponents,
              contains(CKType.bloodPressure.diastolic));
        });

        test('component types have correct names', () {
          expect(CKType.bloodPressure.systolic.toString(),
              'bloodPressure.systolic');
          expect(CKType.bloodPressure.diastolic.toString(),
              'bloodPressure.diastolic');
        });

        test('components have empty defaultComponents', () {
          expect(CKType.bloodPressure.systolic.defaultComponents, isEmpty);
          expect(CKType.bloodPressure.diastolic.defaultComponents, isEmpty);
        });
      });

      group('nutrition', () {
        test('has correct components', () {
          expect(CKType.nutrition.defaultComponents.length, 6);
          expect(CKType.nutrition.defaultComponents,
              contains(CKType.nutrition.energy));
          expect(CKType.nutrition.defaultComponents,
              contains(CKType.nutrition.protein));
          expect(CKType.nutrition.defaultComponents,
              contains(CKType.nutrition.carbs));
          expect(CKType.nutrition.defaultComponents,
              contains(CKType.nutrition.fat));
          expect(CKType.nutrition.defaultComponents,
              contains(CKType.nutrition.fiber));
          expect(CKType.nutrition.defaultComponents,
              contains(CKType.nutrition.sugar));
        });

        test('component types have correct names', () {
          expect(CKType.nutrition.energy.toString(), 'nutrition.energy');
          expect(CKType.nutrition.protein.toString(), 'nutrition.protein');
          expect(CKType.nutrition.carbs.toString(), 'nutrition.carbs');
          expect(CKType.nutrition.fat.toString(), 'nutrition.fat');
        });
      });

      group('workout', () {
        test('has correct components', () {
          expect(CKType.workout.defaultComponents.length, 3);
          // workout includes itself + energy + distance
          expect(CKType.workout.defaultComponents, contains(CKType.workout));
          expect(CKType.workout.defaultComponents,
              contains(CKType.workout.energy));
          expect(CKType.workout.defaultComponents,
              contains(CKType.workout.distance));
        });

        test('component types have correct names', () {
          expect(CKType.workout.distance.toString(), 'workout.distance');
          expect(CKType.workout.heartRate.toString(), 'workout.heartRate');
          expect(CKType.workout.energy.toString(), 'workout.energy');
        });
      });

      group('sleepSession', () {
        test('all getter returns all sleep session stages', () {
          final allStages = CKType.sleepSession.all;
          expect(allStages, hasLength(7));
          expect(allStages, contains(CKType.sleepSession.inBed));
          expect(allStages, contains(CKType.sleepSession.asleep));
          expect(allStages, contains(CKType.sleepSession.awake));
          expect(allStages, contains(CKType.sleepSession.light));
          expect(allStages, contains(CKType.sleepSession.deep));
          expect(allStages, contains(CKType.sleepSession.rem));
          expect(allStages, contains(CKType.sleepSession.outOfBed));
        });

        test('defaultComponents returns all sleep stages', () {
          final defaultComponents = CKType.sleepSession.defaultComponents;
          expect(defaultComponents, equals(CKType.sleepSession.all));
          expect(defaultComponents, hasLength(7));
        });

        test('all getter contains expected stage types', () {
          expect(CKType.sleepSession.inBed.timePattern, CKTimePattern.interval);
          expect(CKType.sleepSession.asleep.timePattern, CKTimePattern.interval);
          expect(CKType.sleepSession.awake.timePattern, CKTimePattern.interval);
          expect(CKType.sleepSession.light.timePattern, CKTimePattern.interval);
          expect(CKType.sleepSession.deep.timePattern, CKTimePattern.interval);
          expect(CKType.sleepSession.rem.timePattern, CKTimePattern.interval);
          expect(CKType.sleepSession.outOfBed.timePattern, CKTimePattern.interval);
        });
      });
    });

    group('fromString', () {
      test('returns correct type for valid simple type string', () {
        expect(CKType.fromString('steps'), equals(CKType.steps));
        expect(CKType.fromString('height'), equals(CKType.height));
        expect(CKType.fromString('heartRate'), equals(CKType.heartRate));
      });

      test('returns correct type for valid composite type string', () {
        expect(
            CKType.fromString('bloodPressure'), equals(CKType.bloodPressure));
        expect(CKType.fromString('nutrition'), equals(CKType.nutrition));
        expect(CKType.fromString('workout'), equals(CKType.workout));
      });

      test('returns correct type for valid component type string', () {
        expect(CKType.fromString('bloodPressure.systolic'),
            equals(CKType.bloodPressure.systolic));
        expect(
            CKType.fromString('nutrition.energy'),
            equals(
              CKType.nutrition.energy,
            ));
        expect(CKType.fromString('workout.distance'),
            equals(CKType.workout.distance));
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => CKType.fromString('invalidType'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown health type'),
          )),
        );
      });

      test('throws ArgumentError for empty string', () {
        expect(
          () => CKType.fromString(''),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Type string cannot be empty',
          )),
        );
      });

      test('is case sensitive', () {
        expect(
          () => CKType.fromString('STEPS'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => CKType.fromString('Steps'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('fromStringOrNull', () {
      test('returns correct type for valid string', () {
        expect(CKType.fromStringOrNull('steps'), equals(CKType.steps));
        expect(CKType.fromStringOrNull('bloodPressure'),
            equals(CKType.bloodPressure));
      });

      test('returns null for invalid string', () {
        expect(CKType.fromStringOrNull('invalidType'), isNull);
      });

      test('returns null for empty string', () {
        expect(CKType.fromStringOrNull(''), isNull);
      });
    });

    group('isValid', () {
      test('returns true for valid type strings', () {
        expect(CKType.isValid('steps'), isTrue);
        expect(CKType.isValid('bloodPressure'), isTrue);
        expect(CKType.isValid('bloodPressure.systolic'), isTrue);
        expect(CKType.isValid('nutrition.energy'), isTrue);
      });

      test('returns false for invalid type strings', () {
        expect(CKType.isValid('invalidType'), isFalse);
        expect(CKType.isValid(''), isFalse);
        expect(CKType.isValid('STEPS'), isFalse);
      });
    });

    group('allTypes', () {
      test('returns non-empty list', () {
        expect(CKType.allTypes, isNotEmpty);
      });

      test('contains expected types', () {
        final allTypes = CKType.allTypes;
        expect(allTypes, contains(CKType.steps));
        expect(allTypes, contains(CKType.height));
        expect(allTypes, contains(CKType.bloodPressure));
        expect(allTypes, contains(CKType.bloodPressure.systolic));
        expect(allTypes, contains(CKType.nutrition.energy));
      });

      test('returns all registered types from generated registry', () {
        // Should have all types from ck_type.g.dart registry
        expect(CKType.allTypes.length, greaterThan(40)); // We have many types
      });
    });

    group('allTypeNames', () {
      test('returns non-empty list', () {
        expect(CKType.allTypeNames, isNotEmpty);
      });

      test('contains expected type names as strings', () {
        final allNames = CKType.allTypeNames;
        expect(allNames, contains('steps'));
        expect(allNames, contains('height'));
        expect(allNames, contains('bloodPressure'));
        expect(allNames, contains('bloodPressure.systolic'));
        expect(allNames, contains('nutrition.energy'));
      });

      test('length matches allTypes', () {
        expect(CKType.allTypeNames.length, equals(CKType.allTypes.length));
      });

      test('every name is valid', () {
        for (final name in CKType.allTypeNames) {
          expect(CKType.isValid(name), isTrue);
        }
      });
    });

    group('generated registry integration', () {
      test('fromString uses generated registry', () {
        // Test that generated types are accessible
        final types = ['steps', 'height', 'bloodPressure', 'nutrition.energy'];
        for (final typeName in types) {
          expect(() => CKType.fromString(typeName), returnsNormally);
        }
      });

      test('all types in allTypes can be converted back to string', () {
        for (final type in CKType.allTypes) {
          final name = type.toString();
          expect(CKType.fromString(name), equals(type));
        }
      });

      test('all type names can be converted to types', () {
        for (final name in CKType.allTypeNames) {
          expect(() => CKType.fromString(name), returnsNormally);
        }
      });
    });
  });
}
