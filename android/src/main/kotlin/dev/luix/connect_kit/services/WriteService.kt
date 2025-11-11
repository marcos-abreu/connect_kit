package dev.luix.connect_kit.services

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.Record
// import androidx.health.connect.client.response.InsertRecordsResponse
import dev.luix.connect_kit.utils.CKConstants
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.RecordMapper
import dev.luix.connect_kit.mapper.UnsupportedKindException
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.mapper.RecordMapperFailure
import dev.luix.connect_kit.mapper.toMap
import dev.luix.connect_kit.pigeon.WriteResultMessage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext


/**
 * Service for writing health records to Android Health Connect.
 *
 * This service handles:
 * - Decoding Dart maps to Health Connect Record objects
 * - Batch insertion with automatic upsert support
 * - Error handling and validation
 * - Platform-specific field handling
 *
 * **Architecture**:
 * ```
 * Dart Maps → RecordDecoder → Health Connect Records → insertRecords() → WriteResultMessage
 * ```
 *
 * @property recordMapper The Decoder/Encoder for Pigeon Channel messages
 * @property healthConnectClient The Health Connect client for data operations
 */
class WriteService(
    private val recordMapper: RecordMapper,
    private val healthConnectClient: HealthConnectClient
) {
    companion object {
        private const val TAG = CKConstants.TAG_WRITE_SERVICE
    }

    /**
     * Writes health records to Health Connect with best-effort semantics.
     *
     * **Process:**
     * 1. Decode each record individually (catch failures per record)
     * 2. Track duringSession record failures separately (non-critical)
     * 3. Batch insert successfully decoded records to Health Connect
     * 4. Build WriteResultMessage with outcome, IDs, and all failures
     *
     * **Upsert Behavior**:
     * When both `clientRecordId` and `clientRecordVersion` available, Health Connect will:
     * - **UPDATE** the existing record if:
     *   - Same `clientRecordId` exists
     *   - New `clientRecordVersion` is HIGHER than existing version
     *   - Same app (dataOrigin matches)
     * - **INSERT** as new record if:
     *   - No matching `clientRecordId` exists
     *   - OR different app wrote the original record
     * - **IGNORE** the write if:
     *   - New `clientRecordVersion` is LOWER or EQUAL to existing version
     *
     * **Failure Handling:**
     * - Main record decode failure: Tracked and record not written
     * - duringSession record failure: Tracked and duringSession record not written
     * - Health Connect insertion failure: Tracked with no records written
     *
     * @return WriteResultMessage with outcome, persisted IDs, and failures
     */
    suspend fun writeRecords(records: List<Map<String, Any?>>): WriteResultMessage {
        // Early return for empty input
        if (records.isEmpty()) {
            return WriteResultMessage(
                outcome = CKConstants.WRITE_OUTCOME_FAILURE,
                persistedRecordIds = emptyList(),
                validationFailures = listOf(
                    RecordMapperFailure(
                        indexPath = listOf(CKConstants.ERROR_NO_INDEX_PATH),
                        message = "No records to write - empty input",
                        type = CKConstants.MAPPER_ERROR_NO_RECORD
                    ).toMap()
                )

            )
        }

        val decodedRecords = mutableListOf<Record>()
        val allFailures = mutableListOf<RecordMapperFailure>()

        // Decode records individually isolating failures
        records.forEachIndexed { index, recordMap ->
            try {
                val (records, duringSessionFailures) = recordMapper.decode(recordMap)
                decodedRecords.addAll(records)

                // Track duringSession record failures with decimal indices
                duringSessionFailures?.forEach { failure ->
                    allFailures.add(
                        failure.copy(indexPath = listOf(index) + failure.indexPath)
                    )
                }

            } catch (error: RecordMapperException) {
                allFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(index),
                        message = "${error.recordKind ?: "Unknown RecordKind"} | ${error.fieldName ?: ""} | ${error.message}",
                        type = CKConstants.MAPPER_ERROR_DECODE
                    )
                )
                CKLogger.e(
                    tag = TAG,
                    message = "Failed to decode record at index $index: ${error.message}",
                    error = error
                )

            } catch (error: UnsupportedKindException) {
                allFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(index),
                        message = "Unsupported record kind '${error.recordKind}' on Android: ${error.message}",
                        type = CKConstants.MAPPER_ERROR_UNSUPPORTED_TYPE
                    )
                )
                CKLogger.e(
                    tag = TAG,
                    message = "Unsupported record kind '${error.recordKind}' at index $index",
                    error = error
                )

            } catch (error: Exception) {
                allFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(index),
                        message = "Unexpected error: ${error.message}",
                        type = CKConstants.MAPPER_ERROR_UNEXPECTED
                    )
                )
                CKLogger.e(
                    tag = TAG,
                    message = "Unexpected error decoding record at index $index",
                    error = error
                )
            }
        }

        // Attempt to insert successfully decoded records
        val persistedIds: List<String> = if (decodedRecords.isNotEmpty()) {
            try {
                val response = healthConnectClient.insertRecords(decodedRecords)
                response.recordIdsList
            } catch (error: Exception) {
                allFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(CKConstants.ERROR_NO_INDEX_PATH),
                        message = "Health Connect failed to insert records",
                        type = CKConstants.MAPPER_ERROR_HEALTH_CONNECT_INSERT
                    )
                )
                CKLogger.e(
                    tag = TAG,
                    message = "Health Connect failed to insert records: ${error.message}",
                    error = error
                )
                emptyList() // no persisted ids
            }
        } else {
            emptyList()
        }

        // Determine outcome
        val outcome = when {
            persistedIds.isNotEmpty() && allFailures.isEmpty() -> "completeSuccess"
            persistedIds.isNotEmpty() -> "partialSuccess"
            else -> "failure"
        }

        val validationFailuresMap = allFailures.map { it.toMap() }
        return WriteResultMessage(
            outcome = outcome,
            persistedRecordIds = persistedIds.ifEmpty { null },
            validationFailures = validationFailuresMap.ifEmpty { null }
        )
    }
}
