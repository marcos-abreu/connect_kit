import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_sleep_session.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';

void main() {
  group('CKSleepSession', () {
    late CKSource source;
    late DateTime startTime;
    late DateTime endTime;

    setUp(() {
      source = CKSource(
          recordingMethod: CKRecordingMethod.automaticallyRecorded,
          device: null);
      startTime = DateTime(2024, 1, 15, 22, 0).toUtc();
      endTime = DateTime(2024, 1, 16, 6, 0).toUtc(); // 8 hours later
    });

    group('Constructor and basic functionality', () {
      test('creates sleep session with minimum required parameters', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.sleeping,
        );

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: [stage],
        );

        expect(sleepSession.startTime, equals(startTime));
        expect(sleepSession.endTime, equals(endTime));
        expect(sleepSession.source, equals(source));
        expect(sleepSession.stages, hasLength(1));
        expect(
            sleepSession.stages.first.stage, equals(CKSleepStageType.sleeping));
        expect(sleepSession.title, isNull);
        expect(sleepSession.notes, isNull);
      });

      test('creates sleep session with all parameters', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.light,
        );

        final sleepSession = CKSleepSession(
          id: 'sleep-123',
          startTime: startTime,
          endTime: endTime,
          source: source,
          title: 'Night Sleep',
          notes: 'Good sleep quality',
          stages: [stage],
          metadata: {'device': 'sleep_tracker'},
        );

        expect(sleepSession.id, equals('sleep-123'));
        expect(sleepSession.title, equals('Night Sleep'));
        expect(sleepSession.notes, equals('Good sleep quality'));
        expect(sleepSession.metadata, equals({'device': 'sleep_tracker'}));
      });

      test('creates sleep session with multiple stages', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 1)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 1)),
            endTime: startTime.add(const Duration(hours: 3)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 3)),
            endTime: startTime.add(const Duration(hours: 5)),
            stage: CKSleepStageType.rem,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 5)),
            endTime: endTime,
            stage: CKSleepStageType.light,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(sleepSession.stages, hasLength(4));
        expect(sleepSession.stages[0].stage, equals(CKSleepStageType.light));
        expect(sleepSession.stages[1].stage, equals(CKSleepStageType.deep));
        expect(sleepSession.stages[2].stage, equals(CKSleepStageType.rem));
        expect(sleepSession.stages[3].stage, equals(CKSleepStageType.light));
      });
    });

    group('Factory methods', () {
      test('simple factory creates sleep session with single sleeping stage',
          () {
        final sleepSession = CKSleepSession.simple(
          startTime: startTime,
          endTime: endTime,
          source: source,
          title: 'Simple Sleep',
          notes: 'Basic sleep tracking',
        );

        expect(sleepSession.startTime, equals(startTime));
        expect(sleepSession.endTime, equals(endTime));
        expect(sleepSession.source, equals(source));
        expect(sleepSession.title, equals('Simple Sleep'));
        expect(sleepSession.notes, equals('Basic sleep tracking'));
        expect(sleepSession.stages, hasLength(1));
        expect(
            sleepSession.stages.first.stage, equals(CKSleepStageType.sleeping));
        expect(sleepSession.stages.first.startTime, equals(startTime));
        expect(sleepSession.stages.first.endTime, equals(endTime));
      });

      test('simple factory works with minimal parameters', () {
        final sleepSession = CKSleepSession.simple(
          startTime: startTime,
          endTime: endTime,
          source: source,
        );

        expect(sleepSession.title, isNull);
        expect(sleepSession.notes, isNull);
        expect(sleepSession.metadata, isNull);
      });

      test('detailed factory creates sleep session with provided stages', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 2)),
            endTime: endTime,
            stage: CKSleepStageType.light,
          ),
        ];

        final sleepSession = CKSleepSession.detailed(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
          title: 'Detailed Sleep',
          notes: 'Multi-stage sleep',
          startZoneOffset: const Duration(hours: -5),
          endZoneOffset: const Duration(hours: -5),
        );

        expect(sleepSession.stages, equals(stages));
        expect(sleepSession.title, equals('Detailed Sleep'));
        expect(sleepSession.notes, equals('Multi-stage sleep'));
        expect(sleepSession.startZoneOffset, equals(const Duration(hours: -5)));
        expect(sleepSession.endZoneOffset, equals(const Duration(hours: -5)));
      });
    });

    group('Validation', () {
      test('validates successfully with valid data', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.sleeping,
        );

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: [stage],
        );

        expect(() => sleepSession.validate(), returnsNormally);
      });

      test('throws error when stage starts before session', () {
        final stage = CKSleepStage(
          startTime: startTime.subtract(const Duration(hours: 1)),
          endTime: endTime,
          stage: CKSleepStageType.sleeping,
        );

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: [stage],
        );

        expect(
          () => sleepSession.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('is before session start'),
          )),
        );
      });

      test('throws error when stage ends after session', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime.add(const Duration(hours: 1)),
          stage: CKSleepStageType.sleeping,
        );

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: [stage],
        );

        expect(
          () => sleepSession.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('is after session end'),
          )),
        );
      });

      test('throws error when stages overlap', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime:
                startTime.add(const Duration(hours: 1)), // Overlaps with first
            endTime: startTime.add(const Duration(hours: 3)),
            stage: CKSleepStageType.deep,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(
          () => sleepSession.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Overlapping stages'),
          )),
        );
      });

      test('allows sequential stages', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime: startTime
                .add(const Duration(hours: 2)), // Starts when first ends
            endTime: startTime.add(const Duration(hours: 4)),
            stage: CKSleepStageType.deep,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(() => sleepSession.validate(), returnsNormally);
      });

      test('validates with stages in any order (sorts them internally)', () {
        final stages = [
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 4)),
            endTime: startTime.add(const Duration(hours: 6)),
            stage: CKSleepStageType.rem,
          ),
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 2)),
            endTime: startTime.add(const Duration(hours: 4)),
            stage: CKSleepStageType.deep,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(() => sleepSession.validate(), returnsNormally);
      });
    });

    group('CKRecord inheritance', () {
      test('sleep session extends CKRecord correctly', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.sleeping,
        );

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: [stage],
        );

        expect(sleepSession, isA<CKRecord>());
        expect(sleepSession.startTime, equals(startTime));
        expect(sleepSession.endTime, equals(endTime));
        expect(sleepSession.source, equals(source));
        expect(sleepSession.duration, equals(endTime.difference(startTime)));
      });
    });

    group('CKSleepSessionAnalysis extension', () {
      test('totalDuration calculates correct duration', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.light,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(sleepSession.totalDuration, equals(const Duration(hours: 8)));
      });

      test('totalSleepTime excludes awake stages', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 1)),
            stage: CKSleepStageType.inBed,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 1)),
            endTime: startTime.add(const Duration(hours: 5)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 5)),
            endTime: startTime.add(const Duration(hours: 6)),
            stage: CKSleepStageType.awake,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 6)),
            endTime: endTime,
            stage: CKSleepStageType.rem,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        // Should include deep (4 hours) + rem (2 hours) = 6 hours
        // Exclude inBed (1 hour) + awake (1 hour) = 2 hours
        expect(sleepSession.totalSleepTime, equals(const Duration(hours: 6)));
      });

      test('timeInStage calculates duration for specific stage type', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 2)),
            endTime: startTime.add(const Duration(hours: 4)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 4)),
            endTime: startTime.add(const Duration(hours: 5)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 5)),
            endTime: endTime,
            stage: CKSleepStageType.light,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(sleepSession.timeInStage(CKSleepStageType.light),
            equals(const Duration(hours: 5)));
        expect(sleepSession.timeInStage(CKSleepStageType.deep),
            equals(const Duration(hours: 3)));
        expect(sleepSession.timeInStage(CKSleepStageType.rem),
            equals(Duration.zero));
      });

      test('sleepEfficiency calculates correct percentage', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 1)),
            stage: CKSleepStageType.inBed, // Not counted as sleep
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 1)),
            endTime: endTime,
            stage: CKSleepStageType.sleeping, // 7 hours of sleep
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        // 7 hours sleep / 8 hours total = 0.875 = 87.5%
        expect(sleepSession.sleepEfficiency, equals(0.875));
      });

      test('sleepEfficiency handles zero duration', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: startTime, // Zero duration
          stage: CKSleepStageType.sleeping,
        );

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: startTime, // Zero total duration
          source: source,
          stages: [stage],
        );

        expect(sleepSession.sleepEfficiency, equals(0.0));
      });

      test('awakenings counts awake stages', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 2)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 2)),
            endTime: startTime.add(const Duration(hours: 2, minutes: 30)),
            stage: CKSleepStageType.awake,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 2, minutes: 30)),
            endTime: startTime.add(const Duration(hours: 4)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 4)),
            endTime: startTime.add(const Duration(hours: 4, minutes: 15)),
            stage: CKSleepStageType.awake,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 4, minutes: 15)),
            endTime: endTime,
            stage: CKSleepStageType.rem,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(sleepSession.awakenings, equals(2));
      });

      test('awakenings returns zero when no awake stages', () {
        final stages = [
          CKSleepStage(
            startTime: startTime,
            endTime: startTime.add(const Duration(hours: 3)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: startTime.add(const Duration(hours: 3)),
            endTime: endTime,
            stage: CKSleepStageType.rem,
          ),
        ];

        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: stages,
        );

        expect(sleepSession.awakenings, equals(0));
      });
    });

    group('CKSleepStage', () {
      test('creates sleep stage with required parameters', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.light,
        );

        expect(stage.startTime, equals(startTime));
        expect(stage.endTime, equals(endTime));
        expect(stage.stage, equals(CKSleepStageType.light));
      });

      test('duration calculates correct duration', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: startTime.add(const Duration(hours: 2, minutes: 30)),
          stage: CKSleepStageType.deep,
        );

        expect(stage.duration, equals(const Duration(hours: 2, minutes: 30)));
      });

      test('creates stage with specific values', () {
        final stage = CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.rem,
        );

        expect(stage.stage, equals(CKSleepStageType.rem));
        expect(stage.startTime, equals(startTime));
        expect(stage.endTime, equals(endTime));
      });
    });

    group('CKSleepStageType enum', () {
      test('contains all expected stage types', () {
        final stageTypes = CKSleepStageType.values;
        expect(stageTypes, hasLength(8));
        expect(stageTypes, contains(CKSleepStageType.inBed));
        expect(stageTypes, contains(CKSleepStageType.outOfBed));
        expect(stageTypes, contains(CKSleepStageType.sleeping));
        expect(stageTypes, contains(CKSleepStageType.awake));
        expect(stageTypes, contains(CKSleepStageType.light));
        expect(stageTypes, contains(CKSleepStageType.deep));
        expect(stageTypes, contains(CKSleepStageType.rem));
        expect(stageTypes, contains(CKSleepStageType.unknown));
      });

      test('toString returns enum name', () {
        expect(CKSleepStageType.light.toString(),
            equals('CKSleepStageType.light'));
        expect(
            CKSleepStageType.deep.toString(), equals('CKSleepStageType.deep'));
        expect(CKSleepStageType.rem.toString(), equals('CKSleepStageType.rem'));
      });
    });

    group('Integration tests', () {
      test('creates comprehensive sleep session with analysis', () {
        final bedTime = DateTime(2024, 1, 15, 22, 30).toUtc();
        final wakeTime = DateTime(2024, 1, 16, 6, 30).toUtc(); // 8 hours

        final stages = [
          CKSleepStage(
            startTime: bedTime,
            endTime: bedTime.add(const Duration(minutes: 15)),
            stage: CKSleepStageType.inBed,
          ),
          CKSleepStage(
            startTime: bedTime.add(const Duration(minutes: 15)),
            endTime: bedTime.add(const Duration(hours: 1, minutes: 30)),
            stage: CKSleepStageType.light,
          ),
          CKSleepStage(
            startTime: bedTime.add(const Duration(hours: 1, minutes: 30)),
            endTime: bedTime.add(const Duration(hours: 3)),
            stage: CKSleepStageType.deep,
          ),
          CKSleepStage(
            startTime: bedTime.add(const Duration(hours: 3)),
            endTime: bedTime.add(const Duration(hours: 3, minutes: 20)),
            stage: CKSleepStageType.awake,
          ),
          CKSleepStage(
            startTime: bedTime.add(const Duration(hours: 3, minutes: 20)),
            endTime: bedTime.add(const Duration(hours: 5, minutes: 30)),
            stage: CKSleepStageType.rem,
          ),
          CKSleepStage(
            startTime: bedTime.add(const Duration(hours: 5, minutes: 30)),
            endTime: wakeTime.add(const Duration(minutes: -30)),
            stage: CKSleepStageType.light,
          ),
        ];

        final sleepSession = CKSleepSession.detailed(
          startTime: bedTime,
          endTime: wakeTime,
          source: source,
          stages: stages,
          title: 'Overnight Sleep',
          notes: 'Good quality sleep with one awakening',
          metadata: {
            'device': 'oura_ring',
            'sleep_score': '85',
          },
        );

        // Verify basic properties
        expect(sleepSession.title, equals('Overnight Sleep'));
        expect(sleepSession.notes,
            equals('Good quality sleep with one awakening'));
        expect(sleepSession.stages, hasLength(6));
        expect(() => sleepSession.validate(), returnsNormally);

        // Verify analysis
        expect(sleepSession.totalDuration, equals(const Duration(hours: 8)));

        // Sleep time excludes inBed (15min) and awake (20min) = 6h 55min
        expect(sleepSession.totalSleepTime,
            equals(const Duration(hours: 6, minutes: 55)));

        // Sleep efficiency: total sleep should be recalculated based on actual values
        final totalSleepMinutes = sleepSession.totalSleepTime.inMinutes;
        final expectedEfficiency =
            totalSleepMinutes / 480.0; // 8 hours = 480 minutes
        expect(
            sleepSession.sleepEfficiency, closeTo(expectedEfficiency, 0.001));

        expect(sleepSession.awakenings, equals(1));
        expect(sleepSession.timeInStage(CKSleepStageType.deep),
            equals(const Duration(hours: 1, minutes: 30)));
        expect(sleepSession.timeInStage(CKSleepStageType.rem),
            equals(const Duration(hours: 2, minutes: 10)));
        expect(sleepSession.timeInStage(CKSleepStageType.light),
            equals(const Duration(hours: 3, minutes: 15)));
      });

      test('handles edge case with empty stages list', () {
        final sleepSession = CKSleepSession(
          startTime: startTime,
          endTime: endTime,
          source: source,
          stages: [],
        );

        expect(sleepSession.stages, isEmpty);
        expect(sleepSession.totalSleepTime, equals(Duration.zero));
        expect(sleepSession.awakenings, equals(0));
        expect(sleepSession.sleepEfficiency, equals(0.0));
        expect(sleepSession.timeInStage(CKSleepStageType.deep),
            equals(Duration.zero));
      });
    });
  });
}
