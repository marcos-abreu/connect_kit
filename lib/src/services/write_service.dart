import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/utils/operation_guard.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/mapper/request_mappers.dart';
import 'package:connect_kit/src/mapper/response_mappers.dart';
import 'package:connect_kit/src/models/ck_write_result.dart';
import 'package:connect_kit/src/logging/ck_logger.dart';
import 'package:connect_kit/src/utils/ck_constants.dart';

/// TODO: add proper documentation
///  Service for handling SDK availability and permission management
class WriteService {
  /// Static log TAG
  static const String logTag = 'WriteService';

  final ConnectKitHostApi _hostApi;

  /// TODO: Add documentation
  WriteService(this._hostApi);

  /// Writes one or more health records with best-effort semantics.
  ///
  /// **Process:**
  /// 1. Validates and maps records on Dart (common valitaion) side
  /// 2. Sends valid records to native platform
  /// 3. Receives WriteResultMessage with native decoding/validation failures
  /// 4. Merges Dart failures + native failures
  /// 5. Returns unified CKWriteResult - with overall outcome and possible failures
  ///
  /// **Failure Types:**
  /// - Common validation failures: Caught before platform call
  /// - Native platform specific decode/validation failures from main/duringSession records
  Future<CKWriteResult> writeRecords(List<CKRecord> records) async {
    final result = await OperationGuard.executeAsync(
      () async {
        final dartFailures = <RecordFailure>[];
        final validRecordMaps = <Map<String, Object?>>[];

        // Validate and encode each record
        for (var i = 0; i < records.length; i++) {
          try {
            records[i].validate();
            validRecordMaps.add(records[i].mapToRequest());
          } catch (error) {
            // Capture Dart validation failure
            dartFailures.add(
              RecordFailure(
                indexPath: [i],
                message: 'Dart validation/encoding failed: ${error.toString()}',
                type: CKConstants.dartValidationError,
              ),
            );
            CKLogger.e(
              WriteService.logTag,
              'Record $i failed Dart validation: $error',
              error,
            );
          }
        }

        // Call native platform with valid records
        final apiResult = await _hostApi.writeRecords(validRecordMaps);

        // Parse native result
        final nativeResult = apiResult.parseWriteResultResponse();

        // Merge Dart failures with native failures
        final mergedFailures = <RecordFailure>[
          ...?nativeResult.validationFailures,
          ...dartFailures,
        ];

        // Determine de facto outcome
        final outcome = nativeResult.hasPersistedRecords
            ? (mergedFailures.isEmpty
                ? WriteOutcome.completeSuccess
                : WriteOutcome.partialSuccess)
            : WriteOutcome.failure;

        return CKWriteResult(
          outcome: outcome,
          persistedRecordIds: nativeResult.persistedRecordIds,
          validationFailures: mergedFailures.isEmpty ? null : mergedFailures,
        );
      },
      operationName: 'Write records',
      parameters: {
        'records':
            records.map((r) => r.mapToRequest()).toList(), // shallow copy
      },
    );

    return result.dataOrThrow;
  }
}
