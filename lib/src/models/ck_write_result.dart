import 'package:connect_kit/src/utils/enum_helper.dart';

/// Represents the result of writing one or more records to the
/// underlying health data store.
///
/// This object summarizes both the **overall outcome** of the operation
/// and details about possible pre-persistence failures
class CKWriteResult {
  /// Summary of the write operation outcome
  final WriteOutcome outcome;

  /// Records that were successfully persisted
  final List<String>? persistedRecordIds;

  /// Records that failed validation or decoding before persistence
  final List<RecordFailure>? validationFailures;

  /// Creates a new [CKWriteResult] describing the write outcome
  CKWriteResult({
    required this.outcome,
    this.persistedRecordIds,
    this.validationFailures,
  });

  /// Returns `true` if any record failed validation or decoding
  bool get hasValidationFailures => validationFailures?.isNotEmpty ?? false;

  /// Returns `true` if any record was persisted
  bool get hasPersistedRecords => persistedRecordIds?.isNotEmpty ?? false;
}

/// Describes the high-level outcome of a record write operation
///
/// This indicates whether all, some, or none of the records
/// were successfully persisted.
enum WriteOutcome {
  /// All records succeeded end-to-end (validated, decoded, and persisted)
  completeSuccess,

  /// Some records failed validation or decoding, but at least one persisted
  partialSuccess,

  /// All records failed at some stage (nothing persisted)
  failure;

  /// Converts outcome string into an enum value
  static WriteOutcome fromString(String outcomeString) {
    return enumFromStringOrDefault(
      WriteOutcome.values,
      outcomeString,
      WriteOutcome.failure,
    );
  }
}

/// Represents a record that failed validation or decoding and therefore
/// no persistence attempt (insert/save calls) was made.
class RecordFailure {
  /// Path of indices identifying the location of the failed record.
  ///
  /// - For top-level records: a single-element list (e.g., `[0]` = first record).
  /// - For duringSession records: two-element list where the first index is the
  ///   top-level record and the second is the duringSession record index
  ///   (e.g., `[0, 2]` = third record in duringSession of the first top-level record).
  final List<int> indexPath;

  /// Human-readable explanation of the issue
  /// (e.g., "Missing field 'startDate'" or "Invalid unit for field 'bloodGlucose'")
  final String message;

  /// Optional machine-readable error type/category.
  /// Used for programmatic handling (e.g., "ValidationError", "DecodeError")
  final String? type;

  /// Creates a [RecordFailure] for a record that failed validation or decoding
  RecordFailure({
    required this.indexPath,
    required this.message,
    this.type,
  });
}
