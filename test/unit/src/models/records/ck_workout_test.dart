import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_workout.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/records/ck_data_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';

void main() {
  group('CKWorkout', () {
    late CKSource source;
    late DateTime startTime;
    late DateTime endTime;

    setUp(() {
      source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
      startTime = DateTime(2024, 1, 15, 7, 0).toUtc();
      endTime = startTime.add(const Duration(hours: 1, minutes: 30));
    });

    group('Constructor and basic functionality', () {
      test('creates workout with minimum required parameters', () {
        final workout = CKWorkout(
          startTime: startTime,
          endTime: endTime,
          activityType: CKWorkoutActivityType.running,
          source: source,
        );

        expect(workout.startTime, equals(startTime));
        expect(workout.endTime, equals(endTime));
        expect(workout.source, equals(source));
        expect(workout.activityType, equals(CKWorkoutActivityType.running));
        expect(workout.title, isNull);
        expect(workout.duringSession, isNull);
      });

      test('creates workout with all parameters', () {
        final dataRecords = [
          CKDataRecord.instantaneous(
            type: CKType.heartRate,
            data: CKQuantityValue(150, CKUnit.compound.beatsPerMin),
            time: startTime.add(const Duration(minutes: 30)),
            source: source,
          ),
          CKDataRecord.instantaneous(
            type: CKType.steps,
            data: CKQuantityValue(5000, CKUnit.scalar.count),
            time: startTime.add(const Duration(minutes: 45)),
            source: source,
          ),
        ];

        final workout = CKWorkout(
          id: 'workout-123',
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: const Duration(hours: -5),
          endZoneOffset: const Duration(hours: -5),
          source: source,
          metadata: {'device': 'running_watch'},
          activityType: CKWorkoutActivityType.cycling,
          title: 'Morning Run',
          duringSession: dataRecords,
        );

        expect(workout.id, equals('workout-123'));
        expect(workout.activityType, equals(CKWorkoutActivityType.cycling));
        expect(workout.title, equals('Morning Run'));
        expect(workout.duringSession, hasLength(2));
        expect(workout.metadata, equals({'device': 'running_watch'}));
        expect(workout.startZoneOffset, equals(const Duration(hours: -5)));
        expect(workout.endZoneOffset, equals(const Duration(hours: -5)));
      });

      test('creates workout with empty duringSession list', () {
        final workout = CKWorkout(
          startTime: startTime,
          endTime: endTime,
          activityType: CKWorkoutActivityType.swimming,
          source: source,
          duringSession: [],
        );

        expect(workout.duringSession, isEmpty);
        expect(workout.activityType, equals(CKWorkoutActivityType.swimming));
      });
    });

    group('CKRecord inheritance', () {
      test('workout extends CKRecord correctly', () {
        final workout = CKWorkout(
          startTime: startTime,
          endTime: endTime,
          activityType: CKWorkoutActivityType.walking,
          source: source,
        );

        expect(workout, isA<CKRecord>());
        expect(workout.startTime, equals(startTime));
        expect(workout.endTime, equals(endTime));
        expect(workout.source, equals(source));
        expect(workout.duration, equals(const Duration(hours: 1, minutes: 30)));
      });

      test('supports optional CKRecord parameters', () {
        const zoneOffset = Duration(hours: -8);
        final metadata = {'app': 'strava'};

        final workout = CKWorkout(
          id: 'workout-456',
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
          source: source,
          metadata: metadata,
          activityType: CKWorkoutActivityType.yoga,
        );

        expect(workout.id, equals('workout-456'));
        expect(workout.startZoneOffset, equals(zoneOffset));
        expect(workout.endZoneOffset, equals(zoneOffset));
        expect(workout.metadata, equals(metadata));
      });
    });

    group('CKWorkoutActivityType enum', () {
      test('contains all expected activity types', () {
        final activityTypes = CKWorkoutActivityType.values;
        expect(activityTypes, hasLength(6));
        expect(activityTypes, contains(CKWorkoutActivityType.running));
        expect(activityTypes, contains(CKWorkoutActivityType.walking));
        expect(activityTypes, contains(CKWorkoutActivityType.cycling));
        expect(activityTypes, contains(CKWorkoutActivityType.swimming));
        expect(activityTypes, contains(CKWorkoutActivityType.yoga));
        expect(activityTypes, contains(CKWorkoutActivityType.hiking));
      });

      test('toString returns enum name', () {
        expect(CKWorkoutActivityType.running.toString(), equals('CKWorkoutActivityType.running'));
        expect(CKWorkoutActivityType.cycling.toString(), equals('CKWorkoutActivityType.cycling'));
        expect(CKWorkoutActivityType.swimming.toString(), equals('CKWorkoutActivityType.swimming'));
      });
    });

    group('Integration tests', () {
      test('creates comprehensive workout with heart rate and steps data', () {
        final workoutStartTime = DateTime(2024, 1, 15, 6, 30).toUtc();
        final workoutEndTime = workoutStartTime.add(const Duration(hours: 1));

        final sessionData = [
          // Heart rate readings during workout
          CKDataRecord.instantaneous(
            type: CKType.heartRate,
            data: CKQuantityValue(120, CKUnit.compound.beatsPerMin),
            time: workoutStartTime.add(const Duration(minutes: 5)),
            source: source,
          ),
          CKDataRecord.instantaneous(
            type: CKType.heartRate,
            data: CKQuantityValue(145, CKUnit.compound.beatsPerMin),
            time: workoutStartTime.add(const Duration(minutes: 30)),
            source: source,
          ),
          CKDataRecord.instantaneous(
            type: CKType.heartRate,
            data: CKQuantityValue(160, CKUnit.compound.beatsPerMin),
            time: workoutStartTime.add(const Duration(minutes: 55)),
            source: source,
          ),
          // Step counts during workout
          CKDataRecord.instantaneous(
            type: CKType.steps,
            data: CKQuantityValue(1000, CKUnit.scalar.count),
            time: workoutStartTime.add(const Duration(minutes: 15)),
            source: source,
          ),
          CKDataRecord.instantaneous(
            type: CKType.steps,
            data: CKQuantityValue(3000, CKUnit.scalar.count),
            time: workoutStartTime.add(const Duration(minutes: 30)),
            source: source,
          ),
          CKDataRecord.instantaneous(
            type: CKType.steps,
            data: CKQuantityValue(8000, CKUnit.scalar.count),
            time: workoutStartTime.add(const Duration(minutes: 45)),
            source: source,
          ),
        ];

        final workout = CKWorkout(
          id: 'morning-run-789',
          startTime: workoutStartTime,
          endTime: workoutEndTime,
          source: CKSource(
            recordingMethod: CKRecordingMethod.automaticallyRecorded,
            device: CKDevice.watch(
              manufacturer: 'Garmin',
              model: 'Forerunner 945',
            ),
          ),
          metadata: {
            'app': 'garmin_connect',
            'weather_condition': 'sunny',
            'elevation_gain': '125m',
          },
          activityType: CKWorkoutActivityType.running,
          title: 'Morning Trail Run',
          duringSession: sessionData,
        );

        // Verify basic properties
        expect(workout.id, equals('morning-run-789'));
        expect(workout.title, equals('Morning Trail Run'));
        expect(workout.activityType, equals(CKWorkoutActivityType.running));
        expect(workout.duration, equals(const Duration(hours: 1)));

        // Verify data records
        expect(workout.duringSession, hasLength(6));

        // Verify heart rate data
        final heartRateRecords = workout.duringSession!
            .where((record) => record.type == CKType.heartRate)
            .toList();
        expect(heartRateRecords, hasLength(3));

        // Verify step data
        final stepRecords = workout.duringSession!
            .where((record) => record.type == CKType.steps)
            .toList();
        expect(stepRecords, hasLength(3));

        // Verify metadata and source
        expect(workout.metadata, equals({
          'app': 'garmin_connect',
          'weather_condition': 'sunny',
          'elevation_gain': '125m',
        }));
        expect(workout.source?.recordingMethod, equals(CKRecordingMethod.automaticallyRecorded));
        expect(workout.source?.device?.model, equals('Forerunner 945'));
      });

      test('creates simple workout without session data', () {
        final workout = CKWorkout(
          startTime: startTime,
          endTime: endTime,
          activityType: CKWorkoutActivityType.yoga,
          source: source,
          title: 'Yoga Session',
        );

        expect(workout.activityType, equals(CKWorkoutActivityType.yoga));
        expect(workout.title, equals('Yoga Session'));
        expect(workout.duringSession, isNull);
        expect(workout.duration, equals(const Duration(hours: 1, minutes: 30)));
      });

      test('creates workout with different activity types', () {
        final activityTypes = [
          CKWorkoutActivityType.running,
          CKWorkoutActivityType.walking,
          CKWorkoutActivityType.cycling,
          CKWorkoutActivityType.swimming,
          CKWorkoutActivityType.yoga,
          CKWorkoutActivityType.hiking,
        ];

        for (final activityType in activityTypes) {
          final workout = CKWorkout(
            startTime: startTime,
            endTime: endTime,
            activityType: activityType,
            source: source,
          );

          expect(workout.activityType, equals(activityType));
          expect(workout.title, isNull);
          expect(workout.duringSession, isNull);
        }
      });

      test('handles empty title and null duringSession', () {
        final workout = CKWorkout(
          startTime: startTime,
          endTime: endTime,
          activityType: CKWorkoutActivityType.cycling,
          source: source,
          title: '',
          duringSession: null,
        );

        expect(workout.title, equals(''));
        expect(workout.duringSession, isNull);
      });

      test('handles workout with negative duration (edge case)', () {
        // This represents an invalid workout but the constructor should still work
        final workout = CKWorkout(
          startTime: endTime,
          endTime: startTime, // Negative duration
          activityType: CKWorkoutActivityType.running,
          source: source,
        );

        expect(workout.startTime, equals(endTime));
        expect(workout.endTime, equals(startTime));
        expect(workout.activityType, equals(CKWorkoutActivityType.running));
        expect(workout.duration.isNegative, isTrue);
      });

      test('handles zero duration workout', () {
        final workout = CKWorkout(
          startTime: startTime,
          endTime: startTime, // Zero duration
          activityType: CKWorkoutActivityType.running,
          source: source,
        );

        expect(workout.duration, equals(Duration.zero));
      });

      test('handles workout with complex metadata', () {
        final complexMetadata = {
          'app': 'nike_run_club',
          'user_id': 'user123',
          'shoes': 'Nike Air Zoom Pegasus',
          'route_name': 'Morning Loop',
          'distance_meters': 10000,
          'calories_burned': 650,
          'avg_pace_min_per_km': 6.0,
          'max_heart_rate': 175,
          'avg_heart_rate': 145,
          'elevation_gain_meters': 50,
          'weather_temperature_celsius': 18,
          'weather_humidity_percent': 65,
          'tags': ['morning', 'outdoor', 'training'],
          'personal_record': true,
        };

        final workout = CKWorkout(
          startTime: startTime,
          endTime: endTime,
          activityType: CKWorkoutActivityType.running,
          source: source,
          metadata: complexMetadata,
        );

        expect(workout.metadata, equals(complexMetadata));
        expect(workout.metadata!.length, equals(14));
      });
    });
  });
}