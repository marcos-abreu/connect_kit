package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.SleepSessionRecord
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.CategoryMapper
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.utils.RecordMapperUtils
import dev.luix.connect_kit.utils.CKConstants
import java.time.Instant
import java.time.ZoneOffset

/**
 * Responsible for translating between Pigeon message maps and [SleepSessionRecord] objects.
 *
 * This mapper handles both directions of data flow:
 * - **decode()**: Converts a Map<String, Any> received from Dart into a [SleepSessionRecord].
 * - **encode()** (future): Converts a [SleepSessionRecord] into a Map<String, Any> to send back to Dart.
 *
 * The decoding process validates required fields (e.g., `startTime`, `endTime`)
 * and parses optional data such as `title`, `notes`, zone offsets, and sleep stages.
 *
 * This class is intended to be used by the [RecordMapper], which delegates decoding
 * to this class when handling RECORD_KIND_SLEEP_SESSION
 *
 * **Example (decode flow):**
 * ```
 * RecordMapper
 *   └─> SleepSessionMapper.decode(map)
 * ```
 *
 * **Note:** The Health Connect client is injected for potential future use,
 * even though it’s not required during decoding.
 *
 * @property healthConnectClient The Health Connect client instance.
 */
class SleepSessionMapper(
    private val healthConnectClient: HealthConnectClient,
    private val categoryMapper: CategoryMapper,
) {
    companion object {
        private const val TAG = CKConstants.TAG_SLEEP_SESSION_MAPPER
        private const val RECORD_KIND = CKConstants.RECORD_KIND_SLEEP_SESSION
    }

    /**
     * Decodes a Pigeon message map into a [SleepSessionRecord].
     *
     * This function:
     * 1. Parses required timestamps (`startTime`, `endTime`) and validates their order.
     * 2. Parses optional zone offsets (`startZoneOffsetSeconds`, `endZoneOffsetSeconds`).
     * 3. Extracts optional attributes (`title`, `notes`).
     * 4. Decodes sleep stages from a list of stage maps, mapping stage names to Health Connect constants.
     * 5. Builds Health Connect [Metadata] including optional source information
     *
     * @param map The map received from the Dart layer representing a sleep session.
     * @return A [SleepSessionRecord] instance ready for insertion into Health Connect.
     *
     * @throws RecordMapperException if required fields are missing or have invalid formats.
     */
    fun decode(map: Map<String, Any?>): SleepSessionRecord {
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

        // === Optional attributes ===
        val title = RecordMapperUtils.getOptionalString(map, "title")
        val notes = RecordMapperUtils.getOptionalString(map, "notes")

        // === Sleep stages ===
        val stagesList = RecordMapperUtils.getOptionalList(map, "stages")?.map { stageItem ->
            val stageMap = stageItem as? Map<String, Any>
                ?: throw RecordMapperException.invalidFieldType(
                    fieldName = "stages",
                    expectedType = "Map<String, Any>",
                    actualValue = stageItem,
                    recordKind = RECORD_KIND
                )
            decodeStage(stageMap)
        } ?: emptyList()

        // NOTE: Client-side validation disabled to evaluate performance vs. usability trade-off
        // Health Connect SDK already performs validation at write time, so this is defensive/redundant
        // Consider re-enabling if user feedback indicates poor native error messages
        //
        // Validate stage sequence
        // validateStages(stagesList, startTime, endTime)

        // Extract source and build metadata
        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        // === Build record ===
        return SleepSessionRecord(
            title = title,
            notes = notes,
            startTime = startTime,
            endTime = endTime,
            startZoneOffset = startZoneOffset,
            endZoneOffset = endZoneOffset,
            stages = stagesList,
            metadata = metadata
        )
    }

    /**
     * Decodes a single stage map into a [SleepSessionRecord.Stage].
     *
     * @param stageMap The map representing a single sleep stage.
     * @return A [SleepSessionRecord.Stage] instance.
     *
     * @throws RecordMapperException if required fields are missing or invalid.
     */
    private fun decodeStage(stageMap: Map<String, Any>): SleepSessionRecord.Stage {
        val stageStartStr = RecordMapperUtils.getRequiredString(stageMap, "startTime", RECORD_KIND)
        val stageEndStr = RecordMapperUtils.getRequiredString(stageMap, "endTime", RECORD_KIND)
        val stageStart = RecordMapperUtils.parseInstant(stageStartStr, "stages.startTime", RECORD_KIND)
        val stageEnd = RecordMapperUtils.parseInstant(stageEndStr, "stages.endTime", RECORD_KIND)
        RecordMapperUtils.validateTimeOrder(stageStart, stageEnd, RECORD_KIND)

        val stageTypeName = RecordMapperUtils.getRequiredString(stageMap, "stage", RECORD_KIND)
        val stageType = categoryMapper.decode("SleepSession", stageTypeName)
            ?: SleepSessionRecord.STAGE_TYPE_UNKNOWN

        return SleepSessionRecord.Stage(
            startTime = stageStart,
            endTime = stageEnd,
            stage = stageType
        )
    }

    /**
     * Validates a list of [SleepSessionRecord.Stage] against session start/end times.
     *
     * Rules:
     * 1. Sequential, Non-Overlapping: Each stage must start after the previous stage ends.
     * 2. Gaps Allowed: Stages don't need to be continuous.
     * 3. Within Session Bounds: All stages must fall within the session start/end.
     *
     * @param stages List of decoded sleep stages.
     * @param sessionStart Start time of the sleep session.
     * @param sessionEnd End time of the sleep session.
     *
     * @throws RecordMapperException if any stage violates the validation rules.
     */
    private fun validateStages(
        stages: List<SleepSessionRecord.Stage>,
        sessionStart: java.time.Instant,
        sessionEnd: java.time.Instant,
    ) {
        var lastEnd: Instant? = null

        for ((index, stage) in stages.withIndex()) {
            // Check bounds
            if (stage.startTime < sessionStart || stage.endTime > sessionEnd) {
                throw RecordMapperException(
                    message = "Stage at index $index is out of session bounds: " +
                            "(${stage.startTime} - ${stage.endTime}) not within ($sessionStart - $sessionEnd)",
                    recordKind = RECORD_KIND
                )
            }

            // Check sequential & non-overlapping
            lastEnd?.let {
                if (stage.startTime < it) {
                    throw RecordMapperException(
                        message = "Stage at index $index overlaps previous stage: " +
                                "starts at ${stage.startTime}, previous ended at $it",
                        recordKind = RECORD_KIND
                    )
                }
            }

            lastEnd = stage.endTime
        }
    }
}
