import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_blood_pressure.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';

void main() {
  group('CKBloodPressure', () {
    late CKSource source;
    late DateTime now;

    setUp(() {
      source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
      now = DateTime.now().toUtc();
    });

    group('Constructor and basic functionality', () {
      test('creates blood pressure with required parameters', () {
        final systolic = CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury);
        final diastolic = CKQuantityValue(80.0, CKUnit.pressure.millimetersOfMercury);

        final bloodPressure = CKBloodPressure(
          time: now,
          source: source,
          systolic: systolic,
          diastolic: diastolic,
        );

        expect(bloodPressure.systolic.value, equals(120.0));
        expect(bloodPressure.diastolic.value, equals(80.0));
        expect(bloodPressure.systolic.unit, equals(CKUnit.pressure.millimetersOfMercury));
        expect(bloodPressure.diastolic.unit, equals(CKUnit.pressure.millimetersOfMercury));
        expect(bloodPressure.bodyPosition, isNull);
        expect(bloodPressure.measurementLocation, isNull);
      });

      test('creates blood pressure with optional parameters', () {
        final systolic = CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury);
        final diastolic = CKQuantityValue(80.0, CKUnit.pressure.millimetersOfMercury);
        const zoneOffset = Duration(hours: 5);

        final bloodPressure = CKBloodPressure(
          time: now,
          zoneOffset: zoneOffset,
          source: source,
          systolic: systolic,
          diastolic: diastolic,
          bodyPosition: CKBodyPosition.sittingDown,
          measurementLocation: CKMeasurementLocation.leftUpperArm,
          metadata: {'device': 'home_monitor'},
        );

        expect(bloodPressure.startTime, equals(now));
        expect(bloodPressure.endTime, equals(now));
        expect(bloodPressure.startZoneOffset, equals(zoneOffset));
        expect(bloodPressure.endZoneOffset, equals(zoneOffset));
        expect(bloodPressure.bodyPosition, equals(CKBodyPosition.sittingDown));
        expect(bloodPressure.measurementLocation, equals(CKMeasurementLocation.leftUpperArm));
        expect(bloodPressure.metadata, equals({'device': 'home_monitor'}));
      });

      test('mmHg factory creates blood pressure with correct units', () {
        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 120.0,
          diastolic: 80.0,
          time: now,
          source: source,
        );

        expect(bloodPressure.systolic.value, equals(120.0));
        expect(bloodPressure.diastolic.value, equals(80.0));
        expect(bloodPressure.systolic.unit, equals(CKUnit.pressure.millimetersOfMercury));
        expect(bloodPressure.diastolic.unit, equals(CKUnit.pressure.millimetersOfMercury));
      });

      test('mmHg factory accepts optional parameters', () {
        const zoneOffset = Duration(hours: 2);
        final metadata = {'notes': 'post-exercise'};

        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 130.0,
          diastolic: 85.0,
          time: now,
          zoneOffset: zoneOffset,
          source: source,
          metadata: metadata,
          bodyPosition: CKBodyPosition.reclining,
          measurementLocation: CKMeasurementLocation.rightWrist,
        );

        expect(bloodPressure.systolic.value, equals(130.0));
        expect(bloodPressure.diastolic.value, equals(85.0));
        expect(bloodPressure.startZoneOffset, equals(zoneOffset));
        expect(bloodPressure.metadata, equals(metadata));
        expect(bloodPressure.bodyPosition, equals(CKBodyPosition.reclining));
        expect(bloodPressure.measurementLocation, equals(CKMeasurementLocation.rightWrist));
      });
    });

    group('Validation', () {
      test('validates successfully with valid blood pressure', () {
        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 120.0,
          diastolic: 80.0,
          time: now,
          source: source,
        );

        expect(() => bloodPressure.validate(), returnsNormally);
      });

      test('throws error when systolic and diastolic use different units', () {
        final systolic = CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury);
        final diastolic = CKQuantityValue(80.0, CKUnit.scalar.count); // Different unit

        final bloodPressure = CKBloodPressure(
          time: now,
          source: source,
          systolic: systolic,
          diastolic: diastolic,
        );

        expect(
          () => bloodPressure.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('must use same unit'),
          )),
        );
      });

      test('throws error when systolic is less than diastolic', () {
        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 80.0, // Lower than diastolic
          diastolic: 120.0,
          time: now,
          source: source,
        );

        expect(
          () => bloodPressure.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Systolic (80.0) cannot be less than diastolic (120.0)'),
          )),
        );
      });

      test('allows equal systolic and diastolic values', () {
        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 100.0,
          diastolic: 100.0, // Equal values
          time: now,
          source: source,
        );

        expect(() => bloodPressure.validate(), returnsNormally);
      });

      test('allows high but reasonable blood pressure values', () {
        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 200.0, // High but possible
          diastolic: 120.0,
          time: now,
          source: source,
        );

        expect(() => bloodPressure.validate(), returnsNormally);
      });
    });

    group('CKRecord inheritance', () {
      test('blood pressure extends CKRecord correctly', () {
        final bloodPressure = CKBloodPressure.mmHg(
          systolic: 120.0,
          diastolic: 80.0,
          time: now,
          source: source,
        );

        expect(bloodPressure, isA<CKRecord>());
        expect(bloodPressure.startTime, equals(now));
        expect(bloodPressure.endTime, equals(now));
        expect(bloodPressure.source, equals(source));
        expect(bloodPressure.isInstantaneous, isTrue);
      });

      test('accepts optional CKRecord parameters', () {
        final systolic = CKQuantityValue(120.0, CKUnit.pressure.millimetersOfMercury);
        final diastolic = CKQuantityValue(80.0, CKUnit.pressure.millimetersOfMercury);

        final bloodPressure = CKBloodPressure(
          id: 'test-id',
          time: now,
          source: source,
          systolic: systolic,
          diastolic: diastolic,
        );

        expect(bloodPressure.id, equals('test-id'));
      });
    });

    group('CKBodyPosition enum', () {
      test('contains all expected positions', () {
        final positions = CKBodyPosition.values;
        expect(positions, contains(CKBodyPosition.standingUp));
        expect(positions, contains(CKBodyPosition.sittingDown));
        expect(positions, contains(CKBodyPosition.lyingDown));
        expect(positions, contains(CKBodyPosition.reclining));
        expect(positions, contains(CKBodyPosition.unknown));
        expect(positions.length, equals(5));
      });

      test('toString returns enum name', () {
        expect(CKBodyPosition.sittingDown.toString(), equals('CKBodyPosition.sittingDown'));
        expect(CKBodyPosition.unknown.toString(), equals('CKBodyPosition.unknown'));
      });
    });

    group('CKMeasurementLocation enum', () {
      test('contains all expected locations', () {
        final locations = CKMeasurementLocation.values;
        expect(locations, contains(CKMeasurementLocation.leftWrist));
        expect(locations, contains(CKMeasurementLocation.rightWrist));
        expect(locations, contains(CKMeasurementLocation.leftUpperArm));
        expect(locations, contains(CKMeasurementLocation.rightUpperArm));
        expect(locations, contains(CKMeasurementLocation.unknown));
        expect(locations.length, equals(5));
      });

      test('toString returns enum name', () {
        expect(CKMeasurementLocation.leftUpperArm.toString(), equals('CKMeasurementLocation.leftUpperArm'));
        expect(CKMeasurementLocation.unknown.toString(), equals('CKMeasurementLocation.unknown'));
      });
    });

    group('Integration tests', () {
      test('creates complete blood pressure reading with all parameters', () {
        final bloodPressure = CKBloodPressure(
          id: 'bp-123',
          time: now,
          zoneOffset: Duration.zero,
          source: source,
          metadata: {'device': 'omron_hem-7322', 'notes': 'evening reading'},
          systolic: CKQuantityValue(135.0, CKUnit.pressure.millimetersOfMercury),
          diastolic: CKQuantityValue(85.0, CKUnit.pressure.millimetersOfMercury),
          bodyPosition: CKBodyPosition.sittingDown,
          measurementLocation: CKMeasurementLocation.leftUpperArm,
        );

        expect(bloodPressure.id, equals('bp-123'));
        expect(bloodPressure.systolic.value, equals(135.0));
        expect(bloodPressure.diastolic.value, equals(85.0));
        expect(bloodPressure.bodyPosition, equals(CKBodyPosition.sittingDown));
        expect(bloodPressure.measurementLocation, equals(CKMeasurementLocation.leftUpperArm));
        expect(bloodPressure.metadata, equals({'device': 'omron_hem-7322', 'notes': 'evening reading'}));
        expect(() => bloodPressure.validate(), returnsNormally);
      });

      test('handles different body positions and measurement locations', () {
        final combinations = [
          {
            'bodyPosition': CKBodyPosition.standingUp,
            'measurementLocation': CKMeasurementLocation.rightWrist,
          },
          {
            'bodyPosition': CKBodyPosition.lyingDown,
            'measurementLocation': CKMeasurementLocation.leftUpperArm,
          },
          {
            'bodyPosition': CKBodyPosition.reclining,
            'measurementLocation': CKMeasurementLocation.rightUpperArm,
          },
        ];

        for (final combo in combinations) {
          final bloodPressure = CKBloodPressure.mmHg(
            systolic: 120.0,
            diastolic: 80.0,
            time: now,
            source: source,
            bodyPosition: combo['bodyPosition'] as CKBodyPosition?,
            measurementLocation: combo['measurementLocation'] as CKMeasurementLocation?,
          );

          expect(bloodPressure.bodyPosition, equals(combo['bodyPosition']));
          expect(bloodPressure.measurementLocation, equals(combo['measurementLocation']));
          expect(() => bloodPressure.validate(), returnsNormally);
        }
      });
    });
  });
}