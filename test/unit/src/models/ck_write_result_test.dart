import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/ck_write_result.dart';

void main() {
  group('CKWriteResult', () {
    group('Constructor and basic functionality', () {
      test('creates write result with minimum required parameters', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.completeSuccess,
        );

        expect(writeResult.outcome, equals(WriteOutcome.completeSuccess));
        expect(writeResult.persistedRecordIds, isNull);
        expect(writeResult.validationFailures, isNull);
        expect(writeResult.hasPersistedRecords, isFalse);
        expect(writeResult.hasValidationFailures, isFalse);
      });

      test('creates write result with all parameters', () {
        final recordIds = ['record-1', 'record-2', 'record-3'];
        final failures = [
          RecordFailure(
            indexPath: [0],
            message: 'Invalid data',
            type: 'ValidationError',
          ),
          RecordFailure(
            indexPath: [1, 2],
            message: 'Missing required field',
            type: 'DecodeError',
          ),
        ];

        final writeResult = CKWriteResult(
          outcome: WriteOutcome.partialSuccess,
          persistedRecordIds: recordIds,
          validationFailures: failures,
        );

        expect(writeResult.outcome, equals(WriteOutcome.partialSuccess));
        expect(writeResult.persistedRecordIds, equals(recordIds));
        expect(writeResult.validationFailures, equals(failures));
        expect(writeResult.hasPersistedRecords, isTrue);
        expect(writeResult.hasValidationFailures, isTrue);
      });

      test('creates write result with empty lists', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.failure,
          persistedRecordIds: [],
          validationFailures: [],
        );

        expect(writeResult.outcome, equals(WriteOutcome.failure));
        expect(writeResult.persistedRecordIds, isEmpty);
        expect(writeResult.validationFailures, isEmpty);
        expect(writeResult.hasPersistedRecords, isFalse);
        expect(writeResult.hasValidationFailures, isFalse);
      });
    });

    group('Computed properties', () {
      test('hasPersistedRecords returns true when record IDs exist', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.completeSuccess,
          persistedRecordIds: ['record-1'],
        );

        expect(writeResult.hasPersistedRecords, isTrue);
      });

      test('hasPersistedRecords returns false when record IDs is empty', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.failure,
          persistedRecordIds: [],
        );

        expect(writeResult.hasPersistedRecords, isFalse);
      });

      test('hasPersistedRecords returns false when record IDs is null', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.failure,
        );

        expect(writeResult.hasPersistedRecords, isFalse);
      });

      test('hasValidationFailures returns true when failures exist', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.partialSuccess,
          validationFailures: [
            RecordFailure(
              indexPath: [0],
              message: 'Validation error',
            ),
          ],
        );

        expect(writeResult.hasValidationFailures, isTrue);
      });

      test('hasValidationFailures returns false when failures is empty', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.completeSuccess,
          validationFailures: [],
        );

        expect(writeResult.hasValidationFailures, isFalse);
      });

      test('hasValidationFailures returns false when failures is null', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.completeSuccess,
        );

        expect(writeResult.hasValidationFailures, isFalse);
      });
    });

    group('WriteOutcome enum', () {
      test('contains all expected outcomes', () {
        final outcomes = WriteOutcome.values;
        expect(outcomes, hasLength(3));
        expect(outcomes, contains(WriteOutcome.completeSuccess));
        expect(outcomes, contains(WriteOutcome.partialSuccess));
        expect(outcomes, contains(WriteOutcome.failure));
      });

      test('fromString returns correct enum value for valid strings', () {
        expect(WriteOutcome.fromString('completeSuccess'), equals(WriteOutcome.completeSuccess));
        expect(WriteOutcome.fromString('partialSuccess'), equals(WriteOutcome.partialSuccess));
        expect(WriteOutcome.fromString('failure'), equals(WriteOutcome.failure));
      });

      test('fromString returns failure for invalid strings', () {
        expect(WriteOutcome.fromString('invalid'), equals(WriteOutcome.failure));
        expect(WriteOutcome.fromString(''), equals(WriteOutcome.failure));
        expect(WriteOutcome.fromString('unknown'), equals(WriteOutcome.failure));
      });

      test('fromString is case sensitive', () {
        expect(WriteOutcome.fromString('CompleteSuccess'), equals(WriteOutcome.failure));
        expect(WriteOutcome.fromString('COMPLETE_SUCCESS'), equals(WriteOutcome.failure));
      });

      test('toString returns enum name', () {
        expect(WriteOutcome.completeSuccess.toString(), equals('WriteOutcome.completeSuccess'));
        expect(WriteOutcome.partialSuccess.toString(), equals('WriteOutcome.partialSuccess'));
        expect(WriteOutcome.failure.toString(), equals('WriteOutcome.failure'));
      });
    });

    group('RecordFailure', () {
      test('creates record failure with minimum required parameters', () {
        final failure = RecordFailure(
          indexPath: [0],
          message: 'Test error',
        );

        expect(failure.indexPath, equals([0]));
        expect(failure.message, equals('Test error'));
        expect(failure.type, isNull);
      });

      test('creates record failure with all parameters', () {
        final failure = RecordFailure(
          indexPath: [1, 2, 3],
          message: 'Complex validation error',
          type: 'ValidationError',
        );

        expect(failure.indexPath, equals([1, 2, 3]));
        expect(failure.message, equals('Complex validation error'));
        expect(failure.type, equals('ValidationError'));
      });

      test('handles various indexPath patterns', () {
        final topLevelFailure = RecordFailure(
          indexPath: [0],
          message: 'Top-level record failed',
        );

        final duringSessionFailure = RecordFailure(
          indexPath: [0, 2],
          message: 'During session record failed',
        );

        final nestedFailure = RecordFailure(
          indexPath: [1, 3, 2],
          message: 'Deeply nested record failed',
        );

        expect(topLevelFailure.indexPath, equals([0]));
        expect(duringSessionFailure.indexPath, equals([0, 2]));
        expect(nestedFailure.indexPath, equals([1, 3, 2]));
      });

      test('handles error types systematically', () {
        final errorTypes = [
          'ValidationError',
          'DecodeError',
          'TypeMismatchError',
          'MissingFieldError',
          'InvalidUnitError',
          'OutOfRangeError',
        ];

        for (final errorType in errorTypes) {
          final failure = RecordFailure(
            indexPath: [0],
            message: 'Error occurred',
            type: errorType,
          );

          expect(failure.type, equals(errorType));
          expect(failure.message, equals('Error occurred'));
        }
      });

      test('handles complex error messages', () {
        final complexMessages = [
          'Missing required field \'startDate\' in record at index [0]',
          'Invalid unit \'millimetersOfMercury\' for field \'bloodPressure\' at index [1, 2]',
          'Value -50.0 is out of range for field \'heartRate\' (must be positive)',
          'Failed to decode JSON: Unexpected end of input at position 42',
          'Type validation failed: Expected integer but received string',
        ];

        for (final message in complexMessages) {
          final failure = RecordFailure(
            indexPath: [0],
            message: message,
            type: 'DecodeError',
          );

          expect(failure.message, equals(message));
          expect(failure.type, equals('DecodeError'));
        }
      });
    });

    group('Integration tests', () {
      test('creates comprehensive write result with mixed success and failures', () {
        final persistedIds = ['record-1', 'record-3', 'record-5'];
        final failures = [
          RecordFailure(
            indexPath: [0],
            message: 'Missing required field: startTime',
            type: 'ValidationError',
          ),
          RecordFailure(
            indexPath: [2],
            message: 'Invalid unit: kilometersPerHour for field \'bloodGlucose\'',
            type: 'ValidationError',
          ),
          RecordFailure(
            indexPath: [1, 0],
            message: 'Failed to decode duringSession record',
            type: 'DecodeError',
          ),
          RecordFailure(
            indexPath: [4],
            message: 'Value -10.0 is out of range for field \'heartRate\'',
            type: 'OutOfRangeError',
          ),
        ];

        final writeResult = CKWriteResult(
          outcome: WriteOutcome.partialSuccess,
          persistedRecordIds: persistedIds,
          validationFailures: failures,
        );

        expect(writeResult.outcome, equals(WriteOutcome.partialSuccess));
        expect(writeResult.persistedRecordIds, hasLength(3));
        expect(writeResult.validationFailures, hasLength(4));
        expect(writeResult.hasPersistedRecords, isTrue);
        expect(writeResult.hasValidationFailures, isTrue);

        // Verify specific persisted IDs
        expect(writeResult.persistedRecordIds, contains('record-1'));
        expect(writeResult.persistedRecordIds, contains('record-3'));
        expect(writeResult.persistedRecordIds, contains('record-5'));

        // Verify failure details
        expect(failures[0].type, equals('ValidationError'));
        expect(failures[0].indexPath, equals([0]));
        expect(failures[1].type, equals('ValidationError'));
        expect(failures[1].indexPath, equals([2]));
        expect(failures[2].type, equals('DecodeError'));
        expect(failures[2].indexPath, equals([1, 0]));
        expect(failures[3].type, equals('OutOfRangeError'));
        expect(failures[3].indexPath, equals([4]));
      });

      test('represents complete success scenario', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.completeSuccess,
          persistedRecordIds: ['record-1', 'record-2', 'record-3'],
        );

        expect(writeResult.outcome, equals(WriteOutcome.completeSuccess));
        expect(writeResult.hasPersistedRecords, isTrue);
        expect(writeResult.hasValidationFailures, isFalse);
        expect(writeResult.persistedRecordIds, hasLength(3));
        expect(writeResult.validationFailures, isNull);
      });

      test('represents complete failure scenario', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.failure,
          persistedRecordIds: [],
          validationFailures: [
            RecordFailure(
              indexPath: [0],
              message: 'All records failed validation',
              type: 'ValidationError',
            ),
            RecordFailure(
              indexPath: [1],
              message: 'Record decoding failed',
              type: 'DecodeError',
            ),
          ],
        );

        expect(writeResult.outcome, equals(WriteOutcome.failure));
        expect(writeResult.hasPersistedRecords, isFalse);
        expect(writeResult.hasValidationFailures, isTrue);
        expect(writeResult.persistedRecordIds, isEmpty);
        expect(writeResult.validationFailures, hasLength(2));
      });

      test('handles edge case with no persisted records and no failures', () {
        final writeResult = CKWriteResult(
          outcome: WriteOutcome.failure,
          persistedRecordIds: [],
          validationFailures: [],
        );

        expect(writeResult.hasPersistedRecords, isFalse);
        expect(writeResult.hasValidationFailures, isFalse);
        expect(writeResult.outcome, equals(WriteOutcome.failure));
      });
    });
  });
}