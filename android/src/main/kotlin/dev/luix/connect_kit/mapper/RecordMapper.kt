package dev.luix.connect_kit.mapper

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.Record
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.UnsupportedKindException
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.mapper.RecordMapperFailure
import dev.luix.connect_kit.mapper.records.*
import dev.luix.connect_kit.utils.CKConstants

/**
 * Result of decoding a record map.
 *
 * - First: List of successfully decoded [Record]s (main + duringSession).
 * - Second: Failures that occurred **only in records duringSession** (e.g., workout samples).
 *   Main record decode failures are thrown as [RecordMapperException].
 */
typealias MapperResult = Pair<List<Record>, List<RecordMapperFailure>?>

/**
 * Main orchestrator for encoding and decoding Pigeon record maps to and from Health Connect Records.
 *
 * Delegates conversion logic to specialized mappers based on record kind,
 * following the Strategy pattern for modular and maintainable translation.
 *
 * **Architecture:**
 * ```
 * RecordMapper (orchestrator)
 *    ├─> DataRecordMapper (simple quantity/category records)
 *    ├─> SleepSessionMapper (sleep sessions with stages)
 *    ├─> BloodPressureMapper (blood pressure correlation)
 *    ├─> NutritionMapper (nutrition with 30+ fields)
 *    └─> WorkoutMapper (exercise sessions)
 * ```
 *
 * **Reusability:** Shared across ReadService, WriteService, and DeleteService.
 * - WriteService → decodes maps → Records
 * - ReadService → encodes Records → maps
 * - DeleteService → supports partial decoding for ID extraction
 *
 * @property healthConnectClient Health Connect client, used for feature and capability checks.
 */
class RecordMapper(
    private val healthConnectClient: HealthConnectClient,
    private val categoryMapper: CategoryMapper = CategoryMapper,
    // Specialized mappers — injected for testability; defaults use the provided HealthConnectClient
    private val dataRecordMapper: DataRecordMapper = DataRecordMapper(healthConnectClient, categoryMapper),
    private val workoutMapper: WorkoutMapper = WorkoutMapper(healthConnectClient, categoryMapper),
    private val bloodPressureMapper: BloodPressureMapper = BloodPressureMapper(healthConnectClient, categoryMapper),
    private val nutritionMapper: NutritionMapper = NutritionMapper(healthConnectClient, categoryMapper),
    private val sleepSessionMapper: SleepSessionMapper = SleepSessionMapper(healthConnectClient, categoryMapper)
) {
    companion object {
        private const val TAG = CKConstants.TAG_RECORD_MAPPER
    }

    /**
     * Decodes a CK record map into a Health Connect Record object.
     *
     * This is the main entry point for all record mapping. It dispatches to
     * specialized mappers based on the 'recordKind' differentiator field.
     *
     * **Record Kind Differentiators**:
     * - RECORD_KIND_DATA_RECORD: Simple quantity or category records
     * - RECORD_KIND_BLOOD_PRESSURE: Blood pressure reading
     * - RECORD_KIND_WORKOUT: Exercise session
     * - RECORD_KIND_NUTRITION: Nutrition/food record
     * - RECORD_KIND_SLEEP_SESSION: Sleep session with stages
     * - RECORD_KIND_AUDIOGRAM: Throws UnsupportedKindException (iOS only)
     * - RECORD_KIND_ECG: Throws UnsupportedKindException (iOS only)
     *
     * @param map The ck record map from Dart (via Pigeon)
     * @return A Pair containing the list of successfully decoded [Record]s, and a nullable
     * list of decode failures that occurred for records within duringSession.
     * @throws RecordMapperException If decoding fails (invalid data, missing fields, etc.)
     * @throws UnsupportedKindException If record kind is not supported on Android
     */
    fun decode(map: Map<String, Any?>): MapperResult {
        val recordKind = map["recordKind"] as? String
            ?: throw RecordMapperException(
                message = "Missing required field 'recordKind'",
                recordKind = CKConstants.MAPPER_ERROR_UNKNOWN
            )

        CKLogger.d(tag = TAG, message = "Mapping record kind: '$recordKind'")

        return when (recordKind) {
            CKConstants.RECORD_KIND_DATA_RECORD ->
                listOf(dataRecordMapper.decode(map)).toResult()

            CKConstants.RECORD_KIND_WORKOUT -> {
                val (exerciseRecord, duringSessionRecords, duringSessionFailures) = workoutMapper.decode(map)
                (listOf<Record>(exerciseRecord) + duringSessionRecords).toResult(duringSessionFailures)
            }

            CKConstants.RECORD_KIND_BLOOD_PRESSURE ->
                listOf(bloodPressureMapper.decode(map)).toResult()

            CKConstants.RECORD_KIND_NUTRITION ->
                listOf(nutritionMapper.decode(map)).toResult()

            CKConstants.RECORD_KIND_SLEEP_SESSION -> {
                val (record, failures) = sleepSessionMapper.decode(map)
                listOf(record).toResult(failures)
            }

            // iOS-only record kinds - throw clear error
            CKConstants.RECORD_KIND_AUDIOGRAM -> throw UnsupportedKindException(
                recordKind = CKConstants.RECORD_KIND_AUDIOGRAM,
                platform = "Android",
                message = "Audiogram records are only supported on iOS with HealthKit. " +
                        "Android Health Connect does not have an equivalent record type."
            )

            CKConstants.RECORD_KIND_ECG -> throw UnsupportedKindException(
                recordKind = CKConstants.RECORD_KIND_ECG,
                platform = "Android",
                message = "ECG/Electrocardiogram records are only supported on iOS with HealthKit. " +
                        "Android Health Connect does not have an equivalent record type."
            )

            else -> throw RecordMapperException(
                message = "Unknown record kind: '$recordKind'",
                recordKind = recordKind
            )
        }
    }

    /**
     * Converts a list of records into a MapperResult.
     *
     * Helper extension to lift List<Record> into the standardized MapperResult format.
     *
     * @param duringSessionFailures Optional list of duringSession record failures
     */
    private fun List<Record>.toResult(
        duringSessionFailures: List<RecordMapperFailure>? = null
    ): MapperResult {
        return Pair(this, duringSessionFailures)
    }
}
