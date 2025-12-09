import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_device.dart';

// Create a concrete implementation for testing
class TestRecord extends CKRecord {
  TestRecord({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    super.metadata,
  });
}

void main() {
  group('CKRecord', () {
    late DateTime startTime;
    late DateTime endTime;
    late CKSource source;

    setUp(() {
      startTime = DateTime(2024, 1, 15, 7, 0).toUtc();
      endTime = startTime.add(const Duration(hours: 1, minutes: 30));
      source = CKSource(recordingMethod: CKRecordingMethod.manualEntry);
    });

    group('Constructor', () {
      test('creates record with minimum required parameters', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
        );

        expect(record.startTime, equals(startTime));
        expect(record.endTime, equals(endTime));
        expect(record.id, isNull);
        expect(record.source, isNull);
        expect(record.metadata, isNull);
        expect(record.startZoneOffset, equals(record.startTime.timeZoneOffset));
        expect(record.endZoneOffset, equals(record.endTime.timeZoneOffset));
      });

      test('creates record with all parameters', () {
        final metadata = {'device': 'test_device'};
        final zoneOffset = const Duration(hours: -5);

        final record = TestRecord(
          id: 'record-123',
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
          source: source,
          metadata: metadata,
        );

        expect(record.id, equals('record-123'));
        expect(record.startTime, equals(startTime));
        expect(record.endTime, equals(endTime));
        expect(record.startZoneOffset, equals(zoneOffset));
        expect(record.endZoneOffset, equals(zoneOffset));
        expect(record.source, equals(source));
        expect(record.metadata, equals(metadata));
      });

      test('creates record with partial zone offsets', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: const Duration(hours: -8),
        );

        expect(record.startZoneOffset, equals(const Duration(hours: -8)));
        expect(record.endZoneOffset, equals(Duration.zero)); // defaults to zero
      });

      test('creates record with fixed dates', () {
        final fixedStartTime = DateTime(2024, 1, 15);
        final fixedEndTime = DateTime(2024, 1, 16);

        final record = TestRecord(
          startTime: fixedStartTime,
          endTime: fixedEndTime,
        );

        expect(record.startTime, equals(fixedStartTime));
        expect(record.endTime, equals(fixedEndTime));
      });
    });

    group('validate method', () {
      test('passes validation for valid time range', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
        );

        expect(() => record.validate(), returnsNormally);
      });

      test('passes validation for equal start and end times', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: startTime, // instantaneous
        );

        expect(() => record.validate(), returnsNormally);
      });

      test('throws ArgumentError when endTime is before startTime', () {
        final record = TestRecord(
          startTime: endTime,
          endTime: startTime, // invalid - endTime before startTime
        );

        expect(
          () => record.validate(),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('endTime must be >= startTime'),
          )),
        );
      });

      test('logs warning when source is null', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
          source: null, // no source provided
        );

        // Should not throw, but should log warning
        expect(() => record.validate(), returnsNormally);
      });

      test('passes validation when source is provided', () {
        final device =
            CKDevice.phone(manufacturer: 'Apple', model: 'iPhone 15');
        final recordSource = CKSource(
          recordingMethod: CKRecordingMethod.activelyRecorded,
          device: device,
        );

        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
          source: recordSource,
        );

        expect(() => record.validate(), returnsNormally);
      });
    });

    group('isInstantaneous getter', () {
      test('returns true when start and end times are equal', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: startTime, // same time
        );

        expect(record.isInstantaneous, isTrue);
      });

      test('returns false when start and end times are different', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime, // different time
        );

        expect(record.isInstantaneous, isFalse);
      });

      test('returns false for very short duration', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: startTime.add(const Duration(microseconds: 1)),
        );

        expect(record.isInstantaneous, isFalse);
      });
    });

    group('duration getter', () {
      test('returns correct duration for interval record', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
        );

        expect(record.duration, equals(const Duration(hours: 1, minutes: 30)));
      });

      test('returns zero duration for instantaneous record', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: startTime, // same time
        );

        expect(record.duration, equals(Duration.zero));
      });

      test('handles negative duration (invalid but should not crash)', () {
        final record = TestRecord(
          startTime: endTime,
          endTime: startTime, // endTime before startTime
        );

        expect(record.duration.isNegative, isTrue);
      });

      test('handles very long duration', () {
        final weekLater = startTime.add(const Duration(days: 7));
        final record = TestRecord(
          startTime: startTime,
          endTime: weekLater,
        );

        expect(record.duration, equals(const Duration(days: 7)));
      });

      test('handles microsecond precision', () {
        final microsecondLater =
            startTime.add(const Duration(microseconds: 500));
        final record = TestRecord(
          startTime: startTime,
          endTime: microsecondLater,
        );

        expect(record.duration, equals(const Duration(microseconds: 500)));
      });
    });

    group('Edge cases', () {
      test('handles metadata with various data types', () {
        final complexMetadata = {
          'string': 'test',
          'number': 42,
          'boolean': true,
          'list': [1, 2, 3],
          'nested': {'key': 'value'},
        };

        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
          metadata: complexMetadata,
        );

        expect(record.metadata, equals(complexMetadata));
        expect(record.metadata!.length, equals(5));
      });

      test('handles empty metadata', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
          metadata: {},
        );

        expect(record.metadata, isEmpty);
      });

      test('handles very long ID', () {
        final veryLongId = 'a' * 1000;
        final record = TestRecord(
          id: veryLongId,
          startTime: startTime,
          endTime: endTime,
        );

        expect(record.id, equals(veryLongId));
        expect(record.id!.length, equals(1000));
      });

      test('handles timezone offsets across different zones', () {
        final record = TestRecord(
          startTime: startTime,
          endTime: endTime,
          startZoneOffset: const Duration(hours: -8), // PST
          endZoneOffset: const Duration(hours: -5), // EST (traveled east)
        );

        expect(record.startZoneOffset, equals(const Duration(hours: -8)));
        expect(record.endZoneOffset, equals(const Duration(hours: -5)));
      });
    });
  });
}
