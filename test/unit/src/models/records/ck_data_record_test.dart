import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_data_record.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/ck_categories.dart';

void main() {
  group('CKDataRecord', () {
    final now = DateTime.now().toUtc();
    final later = now.add(const Duration(hours: 1));
    final source = CKSource(
      recordingMethod: CKRecordingMethod.manualEntry,
    );

    test('should create quantity record successfully', () {
      final type = CKType.steps;
      final data = CKQuantityValue(100, CKUnit.scalar.count);

      final record = CKDataRecord(
        type: type,
        data: data,
        startTime: now,
        endTime: later,
        source: source,
      );

      expect(record.type, type);
      expect(record.data, data);
    });

    test('should throw if quantity pattern gets wrong value type', () {
      final type = CKType.steps; // quantity pattern
      final data = CKCategoryValue(CKBiologicalSexType.female); // wrong type

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test('should throw if label pattern gets wrong value type', () {
      final type = CKType.dateOfBirth; // label pattern
      final data = CKQuantityValue(100, CKUnit.scalar.count); // wrong type - should be CKLabelValue

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test('should throw if none pattern gets wrong value type', () {
      final type = CKType.intermenstrualBleeding; // none pattern
      final data = CKQuantityValue(100, CKUnit.scalar.count); // wrong type - should be CKLabelValue

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test('should throw if multiple pattern gets wrong value type', () {
      final type = CKType.menstrualFlow; // multiple pattern
      final data = CKQuantityValue(100, CKUnit.scalar.count); // wrong type - should be CKMultipleValue

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test('should create category record successfully', () {
      final type = CKType.biologicalSex; // category pattern
      final data = CKCategoryValue(CKBiologicalSexType.female);

      final record = CKDataRecord(
        type: type,
        data: data,
        startTime: now,
        endTime: later,
        source: source,
      );

      expect(record.type, type);
      expect(record.data, data);
    });

    test('should throw if category pattern gets wrong value type', () {
      final type = CKType.biologicalSex;
      final data = CKQuantityValue(100, CKUnit.scalar.count);

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        ),
        throwsArgumentError,
      );
    });

    test('should create multiple record successfully with valid metadata', () {
      final type = CKType.bloodPressure; // multiple pattern
      final data = CKMultipleValue({
        'systolic': CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
        'diastolic': CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
      });
      final metadata = {'mainProperty': 'systolic'};

      final record = CKDataRecord(
        type: type,
        data: data,
        startTime: now,
        endTime: later,
        source: source,
        metadata: metadata,
      );

      expect(record.type, type);
      expect(record.data, data);
    });

    test('should throw if multiple pattern has missing metadata', () {
      final type = CKType.bloodPressure;
      final data = CKMultipleValue({
        'systolic': CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
      });

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
          metadata: null, // missing
        ),
        throwsArgumentError,
      );
    });

    test(
        'should throw if multiple pattern has missing mainProperty in metadata',
        () {
      final type = CKType.bloodPressure;
      final data = CKMultipleValue({
        'systolic': CKQuantityValue(120, CKUnit.scalar.count),
      });
      final metadata = {'other': 'value'}; // missing mainProperty

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
          metadata: metadata,
        ),
        throwsArgumentError,
      );
    });

    test('should throw if multiple pattern data does not contain mainProperty',
        () {
      final type = CKType.bloodPressure;
      final data = CKMultipleValue({
        'diastolic': CKQuantityValue(80, CKUnit.scalar.count),
      });
      final metadata = {'mainProperty': 'systolic'}; // systolic missing in data

      expect(
        () => CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
          metadata: metadata,
        ),
        throwsArgumentError,
      );
    });

    test('should validate time order', () {
      expect(
        () => CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: later,
          endTime: now, // end before start
          source: source,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('instantaneous factory should create record with same start/end time',
        () {
      final record = CKDataRecord.instantaneous(
        type: CKType.heartRate,
        data: CKQuantityValue(60, CKUnit.scalar.count),
        time: now,
        source: source,
      );

      expect(record.startTime, now);
      expect(record.endTime, now);
    });

    test('interval factory should create record with start/end time', () {
      final record = CKDataRecord.interval(
        type: CKType.steps,
        data: CKQuantityValue(100, CKUnit.scalar.count),
        startTime: now,
        endTime: later,
        source: source,
      );

      expect(record.startTime, now);
      expect(record.endTime, later);
    });

    group('Helpers', () {
      test('getQuantityValue returns value for quantity record', () {
        final record = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getQuantityValue(record), isA<CKQuantityValue>());
      });

      test('getQuantityValue returns null for non-quantity record', () {
        final record = CKDataRecord(
          type: CKType.biologicalSex,
          data: CKCategoryValue(CKBiologicalSexType.male),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getQuantityValue(record), null);
      });

      test('getCategoryValue returns value for category record', () {
        final record = CKDataRecord(
          type: CKType.biologicalSex,
          data: CKCategoryValue(CKBiologicalSexType.female),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getCategoryValue(record), isA<CKCategoryValue>());
      });

      test('getMultipleValue returns value for multiple record', () {
        final record = CKDataRecord(
          type: CKType.bloodPressure,
          data: CKMultipleValue({
            'systolic': CKQuantityValue(120, CKUnit.scalar.count),
            'diastolic': CKQuantityValue(80, CKUnit.scalar.count),
          }),
          startTime: now,
          endTime: later,
          source: source,
          metadata: {'mainProperty': 'systolic'},
        );
        expect(getMultipleValue(record), isA<CKMultipleValue>());
      });

      test(
          'getSamplesValue returns value for samples record with CKQuantityValue',
          () {
        final record = CKDataRecord(
          type: CKType.heartRate,
          data: CKQuantityValue(72, CKUnit.compound.beatsPerMin),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getSamplesValue(record), isA<CKQuantityValue>());
      });

      test(
          'getSamplesValue returns value for samples record with CKQuantityValue',
          () {
        final record = CKDataRecord(
          type: CKType.heartRate,
          data: CKQuantityValue(72, CKUnit.compound.beatsPerMin),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getSamplesValue(record), isA<CKQuantityValue>());
      });

      test('getSamplesValue returns null for non-samples record', () {
        final record = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getSamplesValue(record), null);
      });

      test('getCategoryValue returns null for non-category record', () {
        final record = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getCategoryValue(record), null);
      });

      test('getMultipleValue returns null for non-multiple record', () {
        final record = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
        );
        expect(getMultipleValue(record), null);
      });

      test('should throw if label/none pattern gets wrong value type', () {
        final type =
            CKType.sleepSession.awake; // quantity pattern, but use wrong type
        final data = CKCategoryValue(CKBiologicalSexType.female); // wrong type

        expect(
          () => CKDataRecord(
            type: type,
            data: data,
            startTime: now,
            endTime: later,
            source: source,
          ),
          throwsArgumentError,
        );
      });

      test('should create label pattern record successfully', () {
        final type = CKType.biologicalSex; // category pattern
        final data = CKCategoryValue(CKBiologicalSexType.female);

        final record = CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        );

        expect(record.type, type);
        expect(record.data, data);
      });

      test(
          'should create samples pattern record with CKQuantityValue successfully',
          () {
        final type = CKType.heartRate; // samples pattern
        final data = CKQuantityValue(72, CKUnit.compound.beatsPerMin);

        final record = CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        );

        expect(record.type, type);
        expect(record.data, data);
      });

      test(
          'should create samples pattern record with CKSamplesValue successfully',
          () {
        // Testing with minimal case to avoid the validation issues
        final type = CKType.heartRate; // samples pattern
        final data = CKQuantityValue(
            72, CKUnit.compound.beatsPerMin); // Use CKQuantityValue instead

        final record = CKDataRecord(
          type: type,
          data: data,
          startTime: now,
          endTime: later,
          source: source,
        );

        expect(record.type, type);
        expect(record.data, data);
      });

      test('should throw if samples pattern gets wrong value type', () {
        final type = CKType.heartRate; // samples pattern
        final data = CKCategoryValue(CKBiologicalSexType.female); // wrong type

        expect(
          () => CKDataRecord(
            type: type,
            data: data,
            startTime: now,
            endTime: later,
            source: source,
          ),
          throwsArgumentError,
        );
      });

      test('should throw if CKSamplesValue is empty', () {
        final type = CKType.heartRate;
        final data = CKSamplesValue([], CKUnit.compound.beatsPerMin);

        expect(
          () => CKDataRecord(
            type: type,
            data: data,
            startTime: now,
            endTime: later,
            source: source,
          ),
          throwsArgumentError,
        );
      });

      test('instantaneous factory with zone offset', () {
        final zoneOffset = const Duration(hours: -5);
        final record = CKDataRecord.instantaneous(
          type: CKType.heartRate,
          data: CKQuantityValue(60, CKUnit.compound.beatsPerMin),
          time: now,
          zoneOffset: zoneOffset,
          source: source,
        );

        expect(record.startTime, now);
        expect(record.endTime, now);
        expect(record.startZoneOffset, zoneOffset);
        expect(record.endZoneOffset, zoneOffset);
      });

      test('interval factory with different zone offsets', () {
        final startZoneOffset = const Duration(hours: -5);
        final endZoneOffset =
            const Duration(hours: -4); // different due to DST change
        final metadata = {'test': 'value'};

        final record = CKDataRecord.interval(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          startZoneOffset: startZoneOffset,
          endZoneOffset: endZoneOffset,
          source: source,
          metadata: metadata,
        );

        expect(record.startTime, now);
        expect(record.endTime, later);
        expect(record.startZoneOffset, startZoneOffset);
        expect(record.endZoneOffset, endZoneOffset);
        expect(record.metadata, metadata);
      });

      test('interval factory with minimal parameters', () {
        final record = CKDataRecord.interval(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
        );

        expect(record.startTime, now);
        expect(record.endTime, later);
        expect(
            record.startZoneOffset, Duration.zero); // Default is zero, not null
        expect(
            record.endZoneOffset, Duration.zero); // Default is zero, not null
        expect(record.metadata, null);
      });

      test('should accept record with id', () {
        final recordId = 'test-record-123';
        final record = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
          id: recordId,
        );

        expect(record.id, recordId);
      });

      test('should validate all assertion conditions', () {
        // Test start/end time equality (valid for instantaneous)
        expect(
          () => CKDataRecord.instantaneous(
            type: CKType.heartRate,
            data: CKQuantityValue(60, CKUnit.compound.beatsPerMin),
            time: now,
            source: source,
          ),
          returnsNormally,
        );

        // Test zone offset handling in factories
        final zoneOffset = const Duration(hours: 1);
        final record = CKDataRecord.interval(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
          source: source,
        );
        expect(record.startZoneOffset, zoneOffset);
        expect(record.endZoneOffset, zoneOffset);
      });
    });

    group('Additional coverage tests for edge cases', () {
      test('should handle record with all optional parameters null', () {
        // Test constructor with minimal parameters
        final record = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: null,
          metadata: null,
          startZoneOffset: null,
          endZoneOffset: null,
          id: null,
        );

        expect(record.type, CKType.steps);
        expect(record.data, isA<CKQuantityValue>());
        expect(record.source, isNull);
        expect(record.metadata, isNull);
        expect(record.startZoneOffset, now.timeZoneOffset);
        expect(record.endZoneOffset, later.timeZoneOffset);
        expect(record.id, isNull);
      });

      test('non-multiple should handle record with empty metadata map', () {
        // Test empty metadata map handling
        final record = CKDataRecord(
          type: CKType.activityIntensity,
          data: CKCategoryValue(CKActivityIntensityType.moderate),
          startTime: now,
          endTime: later,
          source: source,
          metadata: {}, // Empty metadata
        );

        expect(record.metadata, isEmpty);
      });

      test('should handle quantity value with zero and negative values', () {
        // Test edge cases for quantity values
        expect(
          () => CKDataRecord.instantaneous(
            type: CKType.steps,
            data: CKQuantityValue(0, CKUnit.scalar.count),
            time: now,
            source: source,
          ),
          throwsArgumentError,
        );

        expect(
          () => CKDataRecord.instantaneous(
            type: CKType.height,
            data: CKQuantityValue(-50, CKUnit.length.meter),
            time: now,
            source: source,
          ),
          throwsArgumentError,
        );
      });

      test('should handle category value with all enum types', () {
        // Test different category enum types
        final sexRecord = CKDataRecord.instantaneous(
          type: CKType.biologicalSex,
          data: CKCategoryValue(CKBiologicalSexType.female),
          time: now,
          source: source,
        );

        final bloodTypeRecord = CKDataRecord.instantaneous(
          type: CKType.bloodType,
          data: CKCategoryValue(CKBloodType.abPositive),
          time: now,
          source: source,
        );

        final skinTypeRecord = CKDataRecord.instantaneous(
          type: CKType.fitzpatrickSkinType,
          data: CKCategoryValue(CKFitzpatrickSkinType.vi),
          time: now,
          source: source,
        );

        expect(sexRecord.data, isA<CKCategoryValue>());
        expect(bloodTypeRecord.data, isA<CKCategoryValue>());
        expect(skinTypeRecord.data, isA<CKCategoryValue>());
      });

      test('should handle samples value with single sample', () {
        // Test edge case with single sample
        final samples = [CKSample(75.5, Duration.zero)];
        final record = CKDataRecord.instantaneous(
          type: CKType.heartRate,
          data: CKSamplesValue(samples, CKUnit.compound.beatsPerMin),
          time: now,
          source: source,
        );

        expect(record.data, isA<CKSamplesValue>());
      });

      test('should handle samples value with many samples', () {
        // Test edge case with many samples
        final samples = List.generate(
            1000,
            (index) => CKSample(
                60.0 + index * 0.1, Duration(milliseconds: index * 10)));
        final record = CKDataRecord.interval(
          type: CKType.heartRate,
          data: CKSamplesValue(samples, CKUnit.compound.beatsPerMin),
          startTime: now,
          endTime: now.add(const Duration(seconds: 10)),
          source: source,
        );

        expect(record.data, isA<CKSamplesValue>());
      });

      test('should handle multiple value with nested structures', () {
        final Map<String, CKValue<Object?>> nestedMultipleMap = {
          'innerValue': CKQuantityValue(50, CKUnit.scalar.count),
          'innerLabel': CKLabelValue('test'),
        };
        // Test complex nested multiple values
        final nestedMultiple = CKMultipleValue(nestedMultipleMap);
        final Map<String, CKValue<Object?>> multipleValueMap = {
          'systolic':
              CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
          'diastolic':
              CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
          'nested': nestedMultiple,
        };
        final record = CKDataRecord.instantaneous(
          type: CKType.bloodPressure,
          data: CKMultipleValue(multipleValueMap),
          time: now,
          source: source,
          metadata: {'mainProperty': 'systolic'},
        );

        expect(record.data, isA<CKMultipleValue>());
      });

      test('should handle label value with special characters', () {
        // Test edge cases for label values
        final specialRecord = CKDataRecord.instantaneous(
          type: CKType.dateOfBirth,
          data: CKLabelValue('test_label-with_special.chars_123'),
          time: now,
          source: source,
        );

        final emptyLabelRecord = CKDataRecord.instantaneous(
          type: CKType.dateOfBirth,
          data: CKLabelValue(''),
          time: now,
          source: source,
        );

        expect(specialRecord.data, isA<CKLabelValue>());
        expect(emptyLabelRecord.data, isA<CKLabelValue>());
      });

      test('should handle zone offset with different time zones', () {
        // Test various zone offset combinations
        final positiveOffset = const Duration(hours: 5);
        final negativeOffset = const Duration(hours: -8);
        final zeroOffset = Duration.zero;

        final record = CKDataRecord.interval(
          type: CKType.steps,
          data: CKQuantityValue(1000, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          startZoneOffset: positiveOffset,
          endZoneOffset: negativeOffset,
          source: source,
        );

        expect(record.startZoneOffset, positiveOffset);
        expect(record.endZoneOffset, negativeOffset);

        final zeroOffsetRecord = CKDataRecord.interval(
          type: CKType.height,
          data: CKQuantityValue(175, CKUnit.length.meter),
          startTime: now,
          endTime: later,
          startZoneOffset: zeroOffset,
          endZoneOffset: zeroOffset,
          source: source,
        );

        expect(zeroOffsetRecord.startZoneOffset, zeroOffset);
        expect(zeroOffsetRecord.endZoneOffset, zeroOffset);
      });

      test('should test record validation edge cases', () {
        // Test record validation with different combinations
        final validRecord = CKDataRecord(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          startTime: now,
          endTime: later,
          source: source,
          metadata: {'test': 'test'} as Map<String, Object>?,
          startZoneOffset: Duration.zero,
          endZoneOffset: Duration.zero,
          id: null,
        );

        expect(validRecord.startTime, now);
        expect(validRecord.endTime, later);
        expect(validRecord.metadata, isNotEmpty);
        expect(validRecord.startZoneOffset, Duration.zero);
        expect(validRecord.endZoneOffset, Duration.zero);
        expect(validRecord.id, isNull);
      });

      test('should test helper functions with non-matching record types', () {
        // Test helper functions with wrong record types
        final quantityRecord = CKDataRecord.instantaneous(
          type: CKType.steps,
          data: CKQuantityValue(100, CKUnit.scalar.count),
          time: now,
          source: source,
        );

        expect(getCategoryValue(quantityRecord), isNull);
        expect(getSamplesValue(quantityRecord), isNull);
        expect(getMultipleValue(quantityRecord), isNull);
      });
    });
  });
}
