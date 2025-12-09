import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_audiogram.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';

void main() {
  group('CKAudiogram', () {
    group('Constructor and basic functionality', () {
      test('creates audiogram with single sensitivity point', () {
        final point = CKAudiogramPoint(
          frequency: 1000.0,
          leftEarSensitivity: 10.0,
        );

        final source = CKSource(recordingMethod: CKRecordingMethod.automaticallyRecorded, device: null);
        final now = DateTime.now().toUtc();

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [point],
        );

        expect(audiogram.sensitivityPoints.length, equals(1));
        expect(audiogram.sensitivityPoints.first.frequency, equals(1000.0));
        expect(audiogram.sensitivityPoints.first.leftEarSensitivity, equals(10.0));
        expect(audiogram.sensitivityPoints.first.rightEarSensitivity, isNull);
      });

      test('creates audiogram with multiple sensitivity points', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();

        final points = [
          CKAudiogramPoint(frequency: 250.0, leftEarSensitivity: -10.0),
          CKAudiogramPoint(frequency: 500.0, leftEarSensitivity: -5.0, rightEarSensitivity: -15.0),
          CKAudiogramPoint(frequency: 1000.0, leftEarSensitivity: 0.0, rightEarSensitivity: 10.0),
          CKAudiogramPoint(frequency: 2000.0, leftEarSensitivity: -20.0, rightEarSensitivity: -25.0),
        ];

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: points,
        );

        expect(audiogram.sensitivityPoints.length, equals(4));
        expect(audiogram.startTime, equals(now));
        expect(audiogram.source?.recordingMethod, equals(CKRecordingMethod.manualEntry));
      });

      test('creates audiogram with both ear measurements', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();

        final points = [
          CKAudiogramPoint.bothEars(
            frequency: 1000.0,
            leftSensitivity: 5.0,
            rightSensitivity: 10.0,
          ),
        ];

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: points,
        );

        expect(audiogram.sensitivityPoints.length, equals(1));
        expect(audiogram.sensitivityPoints.first.leftEarSensitivity, equals(5.0));
        expect(audiogram.sensitivityPoints.first.rightEarSensitivity, equals(10.0));
      });
    });

    group('Validation', () {
      test('validates successfully with valid data', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();
        final point = CKAudiogramPoint(frequency: 1000.0, leftEarSensitivity: 10.0);

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [point],
        );

        expect(() => audiogram.validate(), returnsNormally);
      });

      test('throws error when sensitivity points list is empty', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [],
        );

        expect(
          () => audiogram.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('must have at least one sensitivity point'),
          )),
        );
      });

      test('throws error when frequency is too low', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();
        final point = CKAudiogramPoint(frequency: 100.0, leftEarSensitivity: 10.0);

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [point],
        );

        expect(
          () => audiogram.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('outside typical range'),
          )),
        );
      });

      test('throws error when frequency is too high', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();
        final point = CKAudiogramPoint(frequency: 20000.0, leftEarSensitivity: 10.0);

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [point],
        );

        expect(
          () => audiogram.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('outside typical range'),
          )),
        );
      });

      test('allows edge case frequencies (125 and 16000 Hz)', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();
        final points = [
          CKAudiogramPoint(frequency: 125.0, leftEarSensitivity: 10.0),
          CKAudiogramPoint(frequency: 16000.0, leftEarSensitivity: 20.0),
        ];

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: points,
        );

        expect(() => audiogram.validate(), returnsNormally);
      });
    });

    group('Ear-specific getters', () {
      late CKAudiogram audiogram;
      late CKAudiogramPoint leftOnlyPoint;
      late CKAudiogramPoint rightOnlyPoint;
      late CKAudiogramPoint bothEarsPoint;

      setUp(() {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();

        leftOnlyPoint = CKAudiogramPoint.leftEar(frequency: 250.0, sensitivity: -10.0);
        rightOnlyPoint = CKAudiogramPoint.rightEar(frequency: 500.0, sensitivity: -15.0);
        bothEarsPoint = CKAudiogramPoint.bothEars(
          frequency: 1000.0,
          leftSensitivity: 0.0,
          rightSensitivity: 10.0,
        );

        audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [leftOnlyPoint, rightOnlyPoint, bothEarsPoint],
        );
      });

      test('leftEarPoints returns only points with left ear data', () {
        final leftPoints = audiogram.leftEarPoints;
        expect(leftPoints.length, equals(2));
        expect(leftPoints, contains(leftOnlyPoint));
        expect(leftPoints, contains(bothEarsPoint));
        expect(leftPoints, isNot(contains(rightOnlyPoint)));
      });

      test('rightEarPoints returns only points with right ear data', () {
        final rightPoints = audiogram.rightEarPoints;
        expect(rightPoints.length, equals(2));
        expect(rightPoints, contains(rightOnlyPoint));
        expect(rightPoints, contains(bothEarsPoint));
        expect(rightPoints, isNot(contains(leftOnlyPoint)));
      });

      test('leftEarAverageThreshold calculates correct average', () {
        final average = audiogram.leftEarAverageThreshold;
        expect(average, equals((-10.0 + 0.0) / 2)); // Average of -10 and 0
      });

      test('rightEarAverageThreshold calculates correct average', () {
        final average = audiogram.rightEarAverageThreshold;
        expect(average, equals((-15.0 + 10.0) / 2)); // Average of -15 and 10
      });

      test('average thresholds return null when no data available', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();

        final leftOnlyAudiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [leftOnlyPoint],
        );

        expect(leftOnlyAudiogram.rightEarAverageThreshold, isNull);

        final rightOnlyAudiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [rightOnlyPoint],
        );

        expect(rightOnlyAudiogram.leftEarAverageThreshold, isNull);
      });
    });

    group('CKAudiogramPoint constructors', () {
      test('leftEar factory creates point with left ear data only', () {
        final point = CKAudiogramPoint.leftEar(frequency: 1000.0, sensitivity: 5.0);

        expect(point.frequency, equals(1000.0));
        expect(point.leftEarSensitivity, equals(5.0));
        expect(point.rightEarSensitivity, isNull);
      });

      test('rightEar factory creates point with right ear data only', () {
        final point = CKAudiogramPoint.rightEar(frequency: 1000.0, sensitivity: 10.0);

        expect(point.frequency, equals(1000.0));
        expect(point.leftEarSensitivity, isNull);
        expect(point.rightEarSensitivity, equals(10.0));
      });

      test('bothEars factory creates point with both ears data', () {
        final point = CKAudiogramPoint.bothEars(
          frequency: 1000.0,
          leftSensitivity: 5.0,
          rightSensitivity: 10.0,
        );

        expect(point.frequency, equals(1000.0));
        expect(point.leftEarSensitivity, equals(5.0));
        expect(point.rightEarSensitivity, equals(10.0));
      });

      test('default constructor allows null sensitivities', () {
        final point = CKAudiogramPoint(frequency: 1000.0);

        expect(point.frequency, equals(1000.0));
        expect(point.leftEarSensitivity, isNull);
        expect(point.rightEarSensitivity, isNull);
      });
    });

    group('CKAudiogramFrequencies constants', () {
      test('standard frequencies contains expected values', () {
        expect(CKAudiogramFrequencies.standard.length, equals(6));
        expect(CKAudiogramFrequencies.standard, contains(250.0));
        expect(CKAudiogramFrequencies.standard, contains(500.0));
        expect(CKAudiogramFrequencies.standard, contains(1000.0));
        expect(CKAudiogramFrequencies.standard, contains(2000.0));
        expect(CKAudiogramFrequencies.standard, contains(4000.0));
        expect(CKAudiogramFrequencies.standard, contains(8000.0));
      });

      test('extended frequencies contains expected values', () {
        expect(CKAudiogramFrequencies.extended.length, equals(9));
        expect(CKAudiogramFrequencies.extended, contains(125.0));
        expect(CKAudiogramFrequencies.extended, contains(3000.0));
        expect(CKAudiogramFrequencies.extended, contains(6000.0));
        expect(CKAudiogramFrequencies.extended, containsAll(CKAudiogramFrequencies.standard));
      });

      test('speech frequencies contains expected values', () {
        expect(CKAudiogramFrequencies.speech.length, equals(4));
        expect(CKAudiogramFrequencies.speech, contains(500.0));
        expect(CKAudiogramFrequencies.speech, contains(1000.0));
        expect(CKAudiogramFrequencies.speech, contains(2000.0));
        expect(CKAudiogramFrequencies.speech, contains(4000.0));
        expect(CKAudiogramFrequencies.speech, everyElement(isIn(CKAudiogramFrequencies.standard)));
      });
    });

    group('CKRecord inheritance', () {
      test('audiogram extends CKRecord correctly', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();
        final point = CKAudiogramPoint(frequency: 1000.0, leftEarSensitivity: 10.0);

        final audiogram = CKAudiogram(
          time: now,
          source: source,
          sensitivityPoints: [point],
        );

        expect(audiogram, isA<CKRecord>());
        expect(audiogram.startTime, equals(now));
        expect(audiogram.endTime, equals(now));
        expect(audiogram.source, equals(source));
      });

      test('accepts optional parameters', () {
        final source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
        final now = DateTime.now().toUtc();
        final point = CKAudiogramPoint(frequency: 1000.0, leftEarSensitivity: 10.0);
        const zoneOffset = Duration(hours: 5);

        final audiogram = CKAudiogram(
          time: now,
          zoneOffset: zoneOffset,
          source: source,
          sensitivityPoints: [point],
          id: 'test-id',
        );

        expect(audiogram.id, equals('test-id'));
        expect(audiogram.startZoneOffset, equals(zoneOffset));
        expect(audiogram.endZoneOffset, equals(zoneOffset));
      });
    });
  });
}