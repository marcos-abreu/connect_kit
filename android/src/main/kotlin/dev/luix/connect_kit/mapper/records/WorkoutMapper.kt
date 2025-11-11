package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.ExerciseSessionRecord
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.records.DataRecordMapper
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
        val startTimeStr = RecordMapperUtils.getRequiredString(map, "startTime", RECORD_KIND)
        val endTimeStr = RecordMapperUtils.getRequiredString(map, "endTime", RECORD_KIND)
        val startTime = RecordMapperUtils.parseInstant(startTimeStr, "startTime", RECORD_KIND)
        val endTime = RecordMapperUtils.parseInstant(endTimeStr, "endTime", RECORD_KIND)
        RecordMapperUtils.validateTimeOrder(startTime, endTime, RECORD_KIND)

        // === Zone offsets ===
        val startOffsetSeconds = RecordMapperUtils.getOptionalInt(map, "startZoneOffsetSeconds")
        val endOffsetSeconds = RecordMapperUtils.getOptionalInt(map, "endZoneOffsetSeconds")
        val startZoneOffset = startOffsetSeconds?.let(RecordMapperUtils::parseZoneOffset)
        val endZoneOffset = endOffsetSeconds?.let(RecordMapperUtils::parseZoneOffset)

        // === Optional fields ===
        val title = RecordMapperUtils.getOptionalString(map, "title")

        // Extract source and build metadata
        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        // === Build main ExerciseSessionRecord ===
        val exerciseRecord = ExerciseSessionRecord(
            title = title,
            startTime = startTime,
            startZoneOffset = startZoneOffset,
            endTime = endTime,
            endZoneOffset = endZoneOffset,
            exerciseType = mapActivityType(
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

    /**
     * Maps a string representation of a workout activity to Health Connect constants.
     *
     * You may extend this mapping based on all supported activity types in Health Connect:
     * https://developer.android.com/reference/kotlin/androidx/health/connect/client/records/ExerciseSessionRecord#activity-type-constants
     *
     * @param typeName The activity type name from Dart.
     * @return The integer constant corresponding to [ExerciseSessionRecord] activity type.
     */
    private fun mapActivityType(typeName: String): Int {
        return when (typeName.lowercase()) {
            "badminton" -> ExerciseSessionRecord.EXERCISE_TYPE_BADMINTON
            "baseball" -> ExerciseSessionRecord.EXERCISE_TYPE_BASEBALL
            "basketball" -> ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL
            "biking" -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING
            "biking_stationary" -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY
            "boot_camp" -> ExerciseSessionRecord.EXERCISE_TYPE_BOOT_CAMP
            "boxing" -> ExerciseSessionRecord.EXERCISE_TYPE_BOXING
            "calisthenics" -> ExerciseSessionRecord.EXERCISE_TYPE_CALISTHENICS
            "cricket" -> ExerciseSessionRecord.EXERCISE_TYPE_CRICKET
            "dancing" -> ExerciseSessionRecord.EXERCISE_TYPE_DANCING
            "elliptical" -> ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL
            "exercise_class" -> ExerciseSessionRecord.EXERCISE_TYPE_EXERCISE_CLASS
            "fencing" -> ExerciseSessionRecord.EXERCISE_TYPE_FENCING
            "football_american" -> ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AMERICAN
            "football_australian" -> ExerciseSessionRecord.EXERCISE_TYPE_FOOTBALL_AUSTRALIAN
            "frisbee_disc" -> ExerciseSessionRecord.EXERCISE_TYPE_FRISBEE_DISC
            "golf" -> ExerciseSessionRecord.EXERCISE_TYPE_GOLF
            "guided_breathing" -> ExerciseSessionRecord.EXERCISE_TYPE_GUIDED_BREATHING
            "gymnastics" -> ExerciseSessionRecord.EXERCISE_TYPE_GYMNASTICS
            "handball" -> ExerciseSessionRecord.EXERCISE_TYPE_HANDBALL
            "high_intensity_interval_training" -> ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING
            "hiking" -> ExerciseSessionRecord.EXERCISE_TYPE_HIKING
            "ice_hockey" -> ExerciseSessionRecord.EXERCISE_TYPE_ICE_HOCKEY
            "ice_skating" -> ExerciseSessionRecord.EXERCISE_TYPE_ICE_SKATING
            "martial_arts" -> ExerciseSessionRecord.EXERCISE_TYPE_MARTIAL_ARTS
            "paddling" -> ExerciseSessionRecord.EXERCISE_TYPE_PADDLING
            "paragliding" -> ExerciseSessionRecord.EXERCISE_TYPE_PARAGLIDING
            "pilates" -> ExerciseSessionRecord.EXERCISE_TYPE_PILATES
            "racquetball" -> ExerciseSessionRecord.EXERCISE_TYPE_RACQUETBALL
            "rock_climbing" -> ExerciseSessionRecord.EXERCISE_TYPE_ROCK_CLIMBING
            "roller_hockey" -> ExerciseSessionRecord.EXERCISE_TYPE_ROLLER_HOCKEY
            "rowing" -> ExerciseSessionRecord.EXERCISE_TYPE_ROWING
            "rowing_machine" -> ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE
            "rugby" -> ExerciseSessionRecord.EXERCISE_TYPE_RUGBY
            "running" -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING
            "running_treadmill" -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL
            "sailing" -> ExerciseSessionRecord.EXERCISE_TYPE_SAILING
            "scuba_diving" -> ExerciseSessionRecord.EXERCISE_TYPE_SCUBA_DIVING
            "skating" -> ExerciseSessionRecord.EXERCISE_TYPE_SKATING
            "skiing" -> ExerciseSessionRecord.EXERCISE_TYPE_SKIING
            "snowboarding" -> ExerciseSessionRecord.EXERCISE_TYPE_SNOWBOARDING
            "snowshoeing" -> ExerciseSessionRecord.EXERCISE_TYPE_SNOWSHOEING
            "soccer" -> ExerciseSessionRecord.EXERCISE_TYPE_SOCCER
            "softball" -> ExerciseSessionRecord.EXERCISE_TYPE_SOFTBALL
            "squash" -> ExerciseSessionRecord.EXERCISE_TYPE_SQUASH
            "stair_climbing" -> ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING
            "stair_climbing_machine" -> ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING_MACHINE
            "strength_training" -> ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
            "stretching" -> ExerciseSessionRecord.EXERCISE_TYPE_STRETCHING
            "surfing" -> ExerciseSessionRecord.EXERCISE_TYPE_SURFING
            "swimming_open_water" -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_OPEN_WATER
            "swimming_pool" -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL
            "table_tennis" -> ExerciseSessionRecord.EXERCISE_TYPE_TABLE_TENNIS
            "tennis" -> ExerciseSessionRecord.EXERCISE_TYPE_TENNIS
            "volleyball" -> ExerciseSessionRecord.EXERCISE_TYPE_VOLLEYBALL
            "walking" -> ExerciseSessionRecord.EXERCISE_TYPE_WALKING
            "water_polo" -> ExerciseSessionRecord.EXERCISE_TYPE_WATER_POLO
            "weightlifting" -> ExerciseSessionRecord.EXERCISE_TYPE_WEIGHTLIFTING
            "wheelchair" -> ExerciseSessionRecord.EXERCISE_TYPE_WHEELCHAIR
            "yoga" -> ExerciseSessionRecord.EXERCISE_TYPE_YOGA
            "other_workout" -> ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
            else -> {
                CKLogger.d(TAG, "Unknown workout activity type '$typeName', defaulting to OTHER")
                ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
            }
        }
    }
}
