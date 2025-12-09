import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/models/ck_write_result.dart';

/// TODO: add documentation
extension RawPigeonResponseMapping on Map<Object?, Object?>? {
  /// TODO: add documentation
  Map<String, Map<String, String>>? normalizeAsDataAccess() {
    final input = this as Map;

    // 1. Get the entries from the raw input map.
    // 2. Filter out entries where the outer key isn't a String or the value isn't a Map.
    final validEntries = input.entries
        .where((entry) => entry.key is String && entry.value is Map);

    // 3. Use Map.fromEntries() to build the final, materialized map in a single pass.
    return Map.fromEntries(
      validEntries.map((entry) {
        final outerKey = entry.key as String;
        final rawInnerMap = entry.value as Map;

        // 4. Transform the inner map's entries and eagerly materialize them
        //    into a new concrete Map<String, String>.
        final innerMapCasted = Map<String, String>.fromEntries(
          rawInnerMap.entries.map((innerEntry) {
            // Safely convert all inner keys and values to String
            return MapEntry(
              innerEntry.key.toString(),
              innerEntry.value.toString(),
            );
          }),
        );

        return MapEntry(outerKey, innerMapCasted);
      }),
    );
  }
}

/// Provides mapping utilities to convert [WriteResultMessage] (a Pigeon-generated
/// platform message) into domain-specific Dart types like [CKWriteResult].
///
/// This extension handles type-safe deserialization of platform responses,
/// including enum conversion and structured error parsing.
extension WriteResultMessageMapping on WriteResultMessage {
  /// Parses a WriteResultMessage from the platform into a CKWriteResult.
  ///
  /// Handles conversion of:
  /// - outcome string → WriteOutcome enum
  /// - persistedRecordIds → persistedRecordIds (no change)
  /// - validationFailures map → List<RecordFailure> (with recordIndex, message and type)
  ///   recordIndex format: 9.9 (e.g., "2.1" = main record index 2, duringSession index 1)
  CKWriteResult parseWriteResultResponse() {
    List<RecordFailure>? parsedFailures;
    if (validationFailures != null && validationFailures!.isNotEmpty) {
      parsedFailures = validationFailures!.map((failureObj) {
        final failureMap = failureObj as Map<Object?, Object?>;
        return RecordFailure(
          indexPath: (failureMap['indexPath'] as List?)
                  ?.map((e) => e as int)
                  .toList() ??
              const [],
          message: (failureMap['message'] as String?) ?? 'Unknown error',
          type: failureMap['type'] as String?,
        );
      }).toList();
    }

    return CKWriteResult(
      outcome: WriteOutcome.fromString(outcome),
      persistedRecordIds: persistedRecordIds,
      validationFailures: parsedFailures,
    );
  }
}
