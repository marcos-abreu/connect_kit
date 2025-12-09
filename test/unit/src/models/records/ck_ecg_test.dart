import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_ecg.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';

void main() {
  group('CKEcg', () {
    late CKSource source;
    late DateTime startTime;
    late DateTime endTime;

    setUp(() {
      source = CKSource(recordingMethod: CKRecordingMethod.automaticallyRecorded, device: null);
      startTime = DateTime.now().toUtc();
      endTime = startTime.add(const Duration(seconds: 30));
    });

    group('Constructor and basic functionality', () {
      test('creates ECG with minimum required parameters', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.sinusRhythm,
          source: source,
        );

        expect(ecg.startTime, equals(startTime));
        expect(ecg.endTime, equals(endTime));
        expect(ecg.source, equals(source));
        expect(ecg.classification, equals(CKEcgClassification.sinusRhythm));
        expect(ecg.averageHeartRate, isNull);
        expect(ecg.symptoms, isEmpty);
        expect(ecg.voltageMeasurements, isNull);
      });

      test('creates ECG with all parameters', () {
        final voltageMeasurements = [
          CKEcgVoltageMeasurement(timeSinceStart: 0.0, microvolts: 100.0),
          CKEcgVoltageMeasurement(timeSinceStart: 0.001, microvolts: 150.0),
        ];

        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          source: source,
          classification: CKEcgClassification.atrialFibrillation,
          averageHeartRate: 85.0,
          symptoms: [CKEcgSymptom.rapidPoundingHeartbeat, CKEcgSymptom.fatigue],
          voltageMeasurements: voltageMeasurements,
          metadata: {'device': 'apple_watch'},
        );

        expect(ecg.classification, equals(CKEcgClassification.atrialFibrillation));
        expect(ecg.averageHeartRate, equals(85.0));
        expect(ecg.symptoms, hasLength(2));
        expect(ecg.symptoms, contains(CKEcgSymptom.rapidPoundingHeartbeat));
        expect(ecg.symptoms, contains(CKEcgSymptom.fatigue));
        expect(ecg.voltageMeasurements, hasLength(2));
        expect(ecg.voltageMeasurements!.first.timeSinceStart, equals(0.0));
        expect(ecg.voltageMeasurements!.first.microvolts, equals(100.0));
        expect(ecg.metadata, equals({'device': 'apple_watch'}));
      });

      test('uses empty list as default for symptoms', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.sinusRhythm,
          source: source,
        );

        expect(ecg.symptoms, isEmpty);
        expect(ecg.symptoms, isA<List<CKEcgSymptom>>());
      });
    });

    group('CKRecord inheritance', () {
      test('ECG extends CKRecord correctly', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.sinusRhythm,
          source: source,
        );

        expect(ecg, isA<CKRecord>());
        expect(ecg.startTime, equals(startTime));
        expect(ecg.endTime, equals(endTime));
        expect(ecg.source, equals(source));
        expect(ecg.duration, equals(const Duration(seconds: 30)));
      });

      test('supports optional CKRecord parameters', () {
        const zoneOffset = Duration(hours: -5);

        final ecg = CKEcg(
          id: 'ecg-123',
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
          source: source,
          classification: CKEcgClassification.sinusRhythm,
        );

        expect(ecg.id, equals('ecg-123'));
        expect(ecg.startZoneOffset, equals(zoneOffset));
        expect(ecg.endZoneOffset, equals(zoneOffset));
      });
    });

    group('Computed properties', () {
      test('recordingDuration calculates correct duration', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.sinusRhythm,
          source: source,
        );

        expect(ecg.recordingDuration, equals(const Duration(seconds: 30)));
      });

      test('detectedAFib returns true for atrial fibrillation', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.atrialFibrillation,
          source: source,
        );

        expect(ecg.detectedAFib, isTrue);
      });

      test('detectedAFib returns false for other classifications', () {
        final classifications = [
          CKEcgClassification.sinusRhythm,
          CKEcgClassification.inconclusiveLowHeartRate,
          CKEcgClassification.inconclusiveHighHeartRate,
          CKEcgClassification.inconclusiveOther,
          CKEcgClassification.inconclusive,
          CKEcgClassification.unrecognized,
          CKEcgClassification.notSet,
        ];

        for (final classification in classifications) {
          final ecg = CKEcg(
            startTime: startTime,
            endTime: endTime,
            classification: classification,
            source: source,
          );

          expect(ecg.detectedAFib, isFalse,
                 reason: '$classification should not detect AFib');
        }
      });

      test('isConclusive returns false for inconclusive classifications', () {
        final inconclusiveClassifications = [
          CKEcgClassification.inconclusiveLowHeartRate,
          CKEcgClassification.inconclusiveHighHeartRate,
          CKEcgClassification.inconclusiveOther,
          CKEcgClassification.inconclusive,
        ];

        for (final classification in inconclusiveClassifications) {
          final ecg = CKEcg(
            startTime: startTime,
            endTime: endTime,
            classification: classification,
            source: source,
          );

          expect(ecg.isConclusive, isFalse,
                 reason: '$classification should be inconclusive');
        }
      });

      test('isConclusive returns true for conclusive classifications', () {
        final conclusiveClassifications = [
          CKEcgClassification.sinusRhythm,
          CKEcgClassification.atrialFibrillation,
          CKEcgClassification.unrecognized,
          CKEcgClassification.notSet,
        ];

        for (final classification in conclusiveClassifications) {
          final ecg = CKEcg(
            startTime: startTime,
            endTime: endTime,
            classification: classification,
            source: source,
          );

          expect(ecg.isConclusive, isTrue,
                 reason: '$classification should be conclusive');
        }
      });
    });

    group('CKEcgClassification enum', () {
      test('contains all expected classifications', () {
        final classifications = CKEcgClassification.values;
        expect(classifications, hasLength(8));
        expect(classifications, contains(CKEcgClassification.notSet));
        expect(classifications, contains(CKEcgClassification.sinusRhythm));
        expect(classifications, contains(CKEcgClassification.atrialFibrillation));
        expect(classifications, contains(CKEcgClassification.inconclusiveLowHeartRate));
        expect(classifications, contains(CKEcgClassification.inconclusiveHighHeartRate));
        expect(classifications, contains(CKEcgClassification.inconclusiveOther));
        expect(classifications, contains(CKEcgClassification.inconclusive));
        expect(classifications, contains(CKEcgClassification.unrecognized));
      });

      test('toString returns enum name', () {
        expect(CKEcgClassification.sinusRhythm.toString(),
               equals('CKEcgClassification.sinusRhythm'));
        expect(CKEcgClassification.atrialFibrillation.toString(),
               equals('CKEcgClassification.atrialFibrillation'));
      });
    });

    group('CKEcgSymptom enum', () {
      test('contains all expected symptoms', () {
        final symptoms = CKEcgSymptom.values;
        expect(symptoms, hasLength(7));
        expect(symptoms, contains(CKEcgSymptom.none));
        expect(symptoms, contains(CKEcgSymptom.rapidPoundingHeartbeat));
        expect(symptoms, contains(CKEcgSymptom.skippedHeartbeat));
        expect(symptoms, contains(CKEcgSymptom.fatigue));
        expect(symptoms, contains(CKEcgSymptom.shortnessOfBreath));
        expect(symptoms, contains(CKEcgSymptom.chestPainOrDiscomfort));
        expect(symptoms, contains(CKEcgSymptom.dizzinessOrLightheadedness));
      });

      test('toString returns enum name', () {
        expect(CKEcgSymptom.none.toString(), equals('CKEcgSymptom.none'));
        expect(CKEcgSymptom.rapidPoundingHeartbeat.toString(),
               equals('CKEcgSymptom.rapidPoundingHeartbeat'));
      });
    });

    group('CKEcgVoltageMeasurement', () {
      test('creates voltage measurement with required parameters', () {
        final measurement = CKEcgVoltageMeasurement(
          timeSinceStart: 1.5,
          microvolts: 250.0,
        );

        expect(measurement.timeSinceStart, equals(1.5));
        expect(measurement.microvolts, equals(250.0));
      });

      test('supports various time and voltage values', () {
        final measurements = [
          CKEcgVoltageMeasurement(timeSinceStart: 0.0, microvolts: -100.0),
          CKEcgVoltageMeasurement(timeSinceStart: 0.001, microvolts: 0.0),
          CKEcgVoltageMeasurement(timeSinceStart: 30.0, microvolts: 500.0),
          CKEcgVoltageMeasurement(timeSinceStart: 15.5, microvolts: -250.0),
        ];

        for (final measurement in measurements) {
          expect(measurement.timeSinceStart, isA<double>());
          expect(measurement.microvolts, isA<double>());
        }
      });

      test('is const constructible', () {
        const measurement = CKEcgVoltageMeasurement(
          timeSinceStart: 0.0,
          microvolts: 0.0,
        );

        expect(measurement.timeSinceStart, equals(0.0));
        expect(measurement.microvolts, equals(0.0));
      });
    });

    group('Integration tests', () {
      test('creates comprehensive ECG record with medical scenario', () {
        final recordingStart = DateTime(2024, 1, 15, 14, 30).toUtc();
        final recordingEnd = recordingStart.add(const Duration(seconds: 30));

        final ecg = CKEcg(
          id: 'ecg-456',
          startTime: recordingStart,
          endTime: recordingEnd,
          source: CKSource.automaticallyRecorded(
            device: CKDevice.watch(
              manufacturer: 'Apple',
              model: 'Apple Watch Series 8',
            ),
          ),
          classification: CKEcgClassification.atrialFibrillation,
          averageHeartRate: 95.0,
          symptoms: [
            CKEcgSymptom.rapidPoundingHeartbeat,
            CKEcgSymptom.fatigue,
            CKEcgSymptom.shortnessOfBreath,
          ],
          voltageMeasurements: [
            CKEcgVoltageMeasurement(timeSinceStart: 0.0, microvolts: 100.0),
            CKEcgVoltageMeasurement(timeSinceStart: 0.001, microvolts: 150.0),
            CKEcgVoltageMeasurement(timeSinceStart: 0.002, microvolts: 125.0),
          ],
          metadata: {
            'device': 'apple_watch_series_8',
            'firmware': '9.2',
            'recording_quality': 'good',
          },
        );

        // Verify all properties
        expect(ecg.id, equals('ecg-456'));
        expect(ecg.startTime, equals(recordingStart));
        expect(ecg.endTime, equals(recordingEnd));
        expect(ecg.source?.recordingMethod, equals(CKRecordingMethod.automaticallyRecorded));
        expect(ecg.source?.device?.model, equals('Apple Watch Series 8'));
        expect(ecg.classification, equals(CKEcgClassification.atrialFibrillation));
        expect(ecg.averageHeartRate, equals(95.0));
        expect(ecg.symptoms, hasLength(3));
        expect(ecg.symptoms, contains(CKEcgSymptom.rapidPoundingHeartbeat));
        expect(ecg.symptoms, contains(CKEcgSymptom.fatigue));
        expect(ecg.symptoms, contains(CKEcgSymptom.shortnessOfBreath));
        expect(ecg.voltageMeasurements, hasLength(3));
        expect(ecg.detectedAFib, isTrue);
        expect(ecg.isConclusive, isTrue);
        expect(ecg.recordingDuration, equals(const Duration(seconds: 30)));
        expect(ecg.metadata, equals({
          'device': 'apple_watch_series_8',
          'firmware': '9.2',
          'recording_quality': 'good',
        }));
      });

      test('handles normal sinus rhythm scenario', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.sinusRhythm,
          averageHeartRate: 65.0,
          symptoms: [CKEcgSymptom.none],
          source: source,
        );

        expect(ecg.classification, equals(CKEcgClassification.sinusRhythm));
        expect(ecg.averageHeartRate, equals(65.0));
        expect(ecg.symptoms, contains(CKEcgSymptom.none));
        expect(ecg.detectedAFib, isFalse);
        expect(ecg.isConclusive, isTrue);
      });

      test('handles inconclusive low heart rate scenario', () {
        final ecg = CKEcg(
          startTime: startTime,
          endTime: endTime,
          classification: CKEcgClassification.inconclusiveLowHeartRate,
          averageHeartRate: 45.0, // Too low for classification
          symptoms: [CKEcgSymptom.fatigue],
          source: source,
        );

        expect(ecg.classification, equals(CKEcgClassification.inconclusiveLowHeartRate));
        expect(ecg.averageHeartRate, equals(45.0));
        expect(ecg.detectedAFib, isFalse);
        expect(ecg.isConclusive, isFalse); // Inconclusive results are not conclusive
      });
    });
  });
}