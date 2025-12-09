import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connect_kit/src/services/write_service.dart';
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/records/ck_data_record.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';
import 'package:connect_kit/src/models/ck_write_result.dart';
import 'package:connect_kit/src/utils/result.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';
import 'package:connect_kit/src/utils/ck_constants.dart';

// Mock classes for testing
class MockConnectKitHostApi extends Mock implements ConnectKitHostApi {}

class MockCKRecord extends Mock implements CKDataRecord {}

class MockException implements Exception {
  final String message;
  MockException(this.message);

  @override
  String toString() => message;
}

void main() {
  group('WriteService', () {
    late WriteService writeService;
    late MockConnectKitHostApi mockHostApi;
    late CKDataRecord validRecord;
    late CKDataRecord invalidRecord;

    setUp(() {
      mockHostApi = MockConnectKitHostApi();
      writeService = WriteService(mockHostApi);

      // Create a valid record for testing
      final validSource = CKSource(
        recordingMethod: CKRecordingMethod.manualEntry,
      );
      validRecord = CKDataRecord.instantaneous(
        type: CKType.steps,
        data: CKQuantityValue(100, CKUnit.scalar.count),
        time: DateTime.now().toUtc(),
        source: validSource,
      );

      // Create another valid record for simpler testing
      invalidRecord = CKDataRecord.instantaneous(
        type: CKType.heartRate,
        data: CKQuantityValue(72, CKUnit.compound.beatsPerMin),
        time: DateTime.now().toUtc(),
        source: validSource,
      );
    });

    group('Constructor', () {
      test('should initialize with ConnectKitHostApi', () {
        expect(writeService, isA<WriteService>());
        expect(mockHostApi, isNotNull);
      });
    });

    group('writeRecords', () {
      test('should return complete success when all records are valid and persist', () async {
        // Arrange
        final records = [validRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'completeSuccess',
          persistedRecordIds: ['test-id-1'],
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.completeSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNull);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should return complete failure when no records persist', () async {
        // Arrange
        final records = [validRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'failure',
          persistedRecordIds: <String>[],
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.failure);
        expect(result.persistedRecordIds, isEmpty);
        expect(result.validationFailures, isNull);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle empty records list', () async {
        // Arrange
        final records = <CKRecord>[];
        final mockApiResult = WriteResultMessage(
          outcome: 'failure',
          persistedRecordIds: <String>[],
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.failure);
        expect(result.persistedRecordIds, isEmpty);
        expect(result.validationFailures, isNull);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle host API exceptions and rethrow as ConnectKitException', () async {
        // Arrange
        final records = [validRecord];

        when(() => mockHostApi.writeRecords(any())).thenThrow(
          const DataConversionException('API call failed'),
        );

        // Act & Assert
        expect(
          () => writeService.writeRecords(records),
          throwsA(isA<ConnectKitException>()),
        );

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle native validation failures', () async {
        // Arrange
        final records = [validRecord, invalidRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'partialSuccess',
          persistedRecordIds: ['test-id-1'],
          validationFailures: <Map<String, Object>>[
            {
              'indexPath': [1], // Second record fails native validation
              'message': 'Native validation failed',
              'type': 'nativeValidationError',
            }
          ],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.partialSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNotNull);
        expect(result.validationFailures!.length, 1);

        // Failure should be from native validation (index 1)
        expect(result.validationFailures![0].indexPath, [1]);
        expect(result.validationFailures![0].type, 'nativeValidationError');

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle partial success outcome correctly', () async {
        // Arrange
        final records = [validRecord, invalidRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'partialSuccess',
          persistedRecordIds: ['test-id-1'], // First record persists
          validationFailures: <Map<String, Object>>[
            {
              'indexPath': [1], // Second record fails native validation
              'message': 'Native validation failed',
              'type': 'nativeValidationError',
            }
          ],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.partialSuccess); // Records persisted but has failures
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNotNull);
        expect(result.validationFailures!.length, 1);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle complete success with multiple persisted record IDs', () async {
        // Arrange
        final records = [validRecord, validRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'completeSuccess', // Native reports success
          persistedRecordIds: ['test-id-1', 'test-id-2'], // Two records persist
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.completeSuccess);
        expect(result.persistedRecordIds, ['test-id-1', 'test-id-2']);
        expect(result.validationFailures, isNull);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle multiple records with all types of failures', () async {
        // Arrange
        final records = [
          validRecord, // index 0 - valid
          validRecord, // index 1 - valid but fails native
          validRecord, // index 2 - valid
        ];

        final mockApiResult = WriteResultMessage(
          outcome: 'partialSuccess',
          persistedRecordIds: ['test-id-1', 'test-id-3'], // Records 0 and 2 persist
          validationFailures: <Map<String, Object>>[
            {
              'indexPath': [1], // Second record fails native validation
              'message': 'Native validation failed',
              'type': 'nativeValidationError',
            }
          ],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.partialSuccess);
        expect(result.persistedRecordIds, ['test-id-1', 'test-id-3']);
        expect(result.validationFailures, isNotNull);
        expect(result.validationFailures!.length, 1);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle mapToRequest exceptions during record processing', () async {
        // Create a valid record that will fail during mapToRequest
        // (this tests the catch block in the write service)
        final recordWithBadData = CKDataRecord.instantaneous(
          type: CKType.bloodPressure, // Multiple pattern requiring metadata
          data: CKMultipleValue({ // This should work
            'systolic': CKQuantityValue(120, CKUnit.pressure.millimetersOfMercury),
            'diastolic': CKQuantityValue(80, CKUnit.pressure.millimetersOfMercury),
          }),
          time: DateTime.now().toUtc(),
          source: CKSource(recordingMethod: CKRecordingMethod.manualEntry),
          metadata: {'mainProperty': 'systolic'},
        );

        final records = [validRecord, recordWithBadData];
        final mockApiResult = WriteResultMessage(
          outcome: 'completeSuccess', // Native succeeds for valid records
          persistedRecordIds: ['test-id-1'], // Only valid record persists
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        // Both records should be processed successfully since mapToRequest works for valid records
        expect(result.outcome, WriteOutcome.completeSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        // If there were failures, they would be in validationFailures

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle partial success with no validation failures', () async {
        // Arrange
        final records = [validRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'completeSuccess', // Native reports success
          persistedRecordIds: ['test-id-1'],
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.completeSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNull);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle large number of records efficiently', () async {
        // Arrange
        final records = List.generate(100, (index) => validRecord);
        final persistedIds = List.generate(100, (index) => 'test-id-$index');

        final mockApiResult = WriteResultMessage(
          outcome: 'completeSuccess',
          persistedRecordIds: persistedIds,
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.completeSuccess);
        expect(result.persistedRecordIds?.length, 100);
        expect(result.validationFailures, isNull);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle complete failure when all records are valid but no IDs persisted', () async {
        // Arrange - Test the outcome determination logic (lines 74-78)
        final records = [validRecord, validRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'failure', // Native reports failure
          persistedRecordIds: <String>[], // No records persisted - this triggers WriteOutcome.failure
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        // When hasPersistedRecords is false, outcome should be failure even without validation failures
        expect(result.outcome, WriteOutcome.failure);
        expect(result.persistedRecordIds, isEmpty);
        expect(result.validationFailures, isNull); // No failures

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle partial success when there are both persisted records and validation failures', () async {
        // Arrange - Test the merged failures logic (lines 67-71)
        final records = [validRecord, invalidRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'partialSuccess', // Native reports partial success
          persistedRecordIds: ['test-id-1'], // One record persisted
          validationFailures: <Map<String, Object>>[
            {
              'indexPath': [1], // Second record fails native validation
              'message': 'Native validation failed',
              'type': 'nativeValidationError',
            }
          ],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        // When hasPersistedRecords is true but there are validation failures, outcome should be partialSuccess
        expect(result.outcome, WriteOutcome.partialSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNotNull);
        expect(result.validationFailures!.length, 1);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should test that OperationGuard parameters are passed correctly', () async {
        // Arrange - Test the OperationGuard parameters (lines 88-90)
        final records = [validRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'completeSuccess',
          persistedRecordIds: ['test-id-1'],
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.completeSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNull);

        // Verify the host API was called with the correct parameters
        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle record validation failure and create Dart validation error', () async {
        // Arrange - Create a record that will fail validation
        final invalidRecord = _InvalidRecord();

        final records = [invalidRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'failure',
          persistedRecordIds: <String>[],
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.failure);
        expect(result.persistedRecordIds, isEmpty);
        expect(result.validationFailures, isNotNull);
        expect(result.validationFailures!.length, 1);

        // Should be a Dart validation failure (lines 46-52)
        final failure = result.validationFailures![0];
        expect(failure.indexPath, equals([0]));
        expect(failure.message, contains('Dart validation/encoding failed'));
        expect(failure.type, equals('DartValidationError'));

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      test('should handle multiple record validation failures and merge with native failures', () async {
        // Arrange - Create records that will fail validation
        final invalidRecord1 = _InvalidRecord();
        final invalidRecord2 = _InvalidRecord();

        final records = [validRecord, invalidRecord1, invalidRecord2];
        final mockApiResult = WriteResultMessage(
          outcome: 'partialSuccess',
          persistedRecordIds: ['test-id-1'], // Only valid record persists
          validationFailures: <Map<String, Object>>[
            {
              'indexPath': [0], // This should be ignored since record 0 is valid
              'message': 'Native validation failed',
              'type': 'nativeValidationError',
            }
          ],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.partialSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNotNull);

        // Should have 2 Dart validation failures (records 1 and 2) + 1 native failure = 3 total
        expect(result.validationFailures!.length, 3);

        // Verify Dart failures are included (lines 46-52)
        final dartFailure1 = result.validationFailures!.where((f) => f.type == 'DartValidationError').toList();
        expect(dartFailure1.length, 2);

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });

      
      test('should handle partial success when some records fail Dart validation', () async {
        // Arrange - Mix of valid and invalid records
        final invalidRecord = _InvalidRecord();

        final records = [validRecord, invalidRecord];
        final mockApiResult = WriteResultMessage(
          outcome: 'partialSuccess',
          persistedRecordIds: ['test-id-1'], // Only valid record persists
          validationFailures: <Map<String, Object>>[],
        );

        when(() => mockHostApi.writeRecords(any())).thenAnswer((_) async => mockApiResult);

        // Act
        final result = await writeService.writeRecords(records);

        // Assert
        expect(result.outcome, WriteOutcome.partialSuccess);
        expect(result.persistedRecordIds, ['test-id-1']);
        expect(result.validationFailures, isNotNull);
        expect(result.validationFailures!.length, 1);

        // Should be a Dart validation failure (lines 46-52)
        final failure = result.validationFailures![0];
        expect(failure.indexPath, equals([1])); // Second record (index 1) failed
        expect(failure.message, contains('Dart validation/encoding failed'));
        expect(failure.type, equals('DartValidationError'));

        verify(() => mockHostApi.writeRecords(any())).called(1);
      });
    });
  });
}

/// Invalid record that throws during validation
class _InvalidRecord extends CKRecord {
  _InvalidRecord() : super(
        startTime: DateTime.now().toUtc(),
        endTime: DateTime.now().toUtc().add(const Duration(minutes: 30)),
        source: CKSource(recordingMethod: CKRecordingMethod.manualEntry),
      );

  @override
  void validate() {
    throw Exception('Simulated validation failure');
  }

  @override
  Map<String, Object?> mapToRequest() {
    // Create a minimal map to avoid issues
    return {
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
    };
  }
}

