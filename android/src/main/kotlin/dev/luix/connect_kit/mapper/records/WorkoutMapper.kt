package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.ExerciseSessionRecord
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.records.DataRecordMapper
import dev.luix.connect_kit.mapper.WorkoutActivityTypeMapper
import dev.luix.connect_kit.mapper.CategoryMapper
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.mapper.RecordMapperFailure
import dev.luix.connect_kit.utils.RecordMapperUtils
import dev.luix.connect_kit.utils.CKConstants
import java.time.Instant
import java.time.ZoneOffset

/**
 * Responsible for translating between Pigeon message maps and [ExerciseSessionRecord] objects,
 * along with any data records send in duringSession.
 *
 * This mapper handles the decode flow from Dart to Android Health Connect:
 * - **decode()**: Converts a Map<String, Any> representing a workout into an [ExerciseSessionRecord],
 *   as well as a list of duringSession Health Connect records.
 *
 * The decoding process validates required fields (e.g., `startTime`, `endTime`, `activityType`)
 * and parses optional fields such as `title` and `duringSession`.
 *
 * **Example (decode flow):**
 * ```
 * RecordMapper
 *   └─> WorkoutMapper.decode(map)
 * ```
 *
 * **Note:** duringSession data records are delegated to [DataRecordMapper.decode]
 *           for proper record kind handling.
 *
 * @property healthConnectClient The Health Connect client instance.
 */
class WorkoutMapper(
    private val healthConnectClient: HealthConnectClient,
    private val categoryMapper: CategoryMapper,
) {
    companion object {
        private const val TAG = CKConstants.TAG_WORKOUT_MAPPER
        private const val RECORD_KIND = CKConstants.RECORD_KIND_WORKOUT
    }

    // Specialized mappers (lazy initialization)
    private val dataRecordMapper by lazy { DataRecordMapper(healthConnectClient, categoryMapper) }

    /**
     * Decodes a Pigeon message map into an [ExerciseSessionRecord] and duringSession data records.
     *
     * This function:
     * 1. Parses required timestamps (`startTime`, `endTime`) and validates their order.
     * 2. Parses optional zone offsets (`startZoneOffsetSeconds`, `endZoneOffsetSeconds`).
     * 3. Extracts optional attributes (`title`, `duringSession`).
     * 4. Decodes `duringSession` if present, delegating to [DataRecordMapper.decode].
     * 5. Builds Health Connect [Metadata] including optional source information
     *
     * @param map The map received from the Dart layer representing a workout.
     * @return A pair containing the [ExerciseSessionRecord] and a list of duringSession Health Connect records.
     *
     * @throws RecordMapperException if required fields are missing or have invalid formats.
     */
    fun decode(map: Map<String, Any?>): Triple<ExerciseSessionRecord, List<Record>, List<RecordMapperFailure>?> {
        // === Core times ===
        val timeRange = RecordMapperUtils.extractTimeRange(map, RECORD_KIND)

        // === Optional fields ===
        val title = RecordMapperUtils.getOptionalString(map, "title")

        // Extract source and build metadata
        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        // === Build main ExerciseSessionRecord ===
        val exerciseRecord = ExerciseSessionRecord(
            title = title,
            startTime = timeRange.startTime,
            startZoneOffset = timeRange.startZoneOffset,
            endTime = timeRange.endTime,
            endZoneOffset = timeRange.endZoneOffset,
            exerciseType = WorkoutActivityTypeMapper.map(
                RecordMapperUtils.getRequiredString(map, "activityType", RECORD_KIND)
            ),
            metadata = metadata
        )

        // === duringSession data with failure tracking ===
        val duringSessionRecords = mutableListOf<Record>()
        val duringSessionFailures = mutableListOf<RecordMapperFailure>()

        RecordMapperUtils.getOptionalList(map, "duringSession")?.forEachIndexed { index, dataItem ->
            val dataMap = dataItem as? Map<String, Any>
            if (dataMap == null) {
                duringSessionFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(index),
                        message = "${RECORD_KIND} duringSession record at index: $index is not a valid map",
                        type = CKConstants.MAPPER_ERROR_DURING_SESSION_INVALID_TYPE
                    )
                )
                CKLogger.w(TAG, "${RECORD_KIND} duringSession record at index: $index is not a valid map, skipping")
                return@forEachIndexed
            }

            try {
                val record = dataRecordMapper.decode(dataMap)
                duringSessionRecords.add(record)
            } catch (e: RecordMapperException) {
                duringSessionFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(index),
                        message = "${e.recordKind ?: "Unknown RecordKind"} | ${e.fieldName ?: ""} | ${e.message}",
                        type = CKConstants.MAPPER_ERROR_DURING_SESSION_DECODE
                    )
                )
                CKLogger.w(
                    tag = TAG,
                    message = "Failed to decode ${RECORD_KIND} duringSession record at index $index: ${e.message}",
                    error = e
                )
            } catch (e: Exception) {
                duringSessionFailures.add(
                    RecordMapperFailure(
                        indexPath = listOf(index),
                        message = "${RECORD_KIND} decode - Unexpected error: ${e.message}",
                        type = CKConstants.MAPPER_ERROR_UNEXPECTED
                    )
                )
                // Log the error and skip this duringSession record
                CKLogger.e(
                    tag = TAG,
                    message = "Unexpected error decoding duringSession record at index $index",
                    error = e
                )
            }
        }

        // Log summary if there were failures
        if (duringSessionFailures.isNotEmpty()) {
            CKLogger.w(
                TAG,
                "Workout decoded with ${duringSessionRecords.size} successful and " +
                        "${duringSessionFailures.size} failed duringSession record(s)"
            )
        }

        return Triple(
            exerciseRecord,
            duringSessionRecords,
            duringSessionFailures.ifEmpty { null } // Return null if no failures
        )
    }
}
