package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.BloodPressureRecord
import androidx.health.connect.client.units.*
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.utils.RecordMapperUtils
import dev.luix.connect_kit.mapper.CategoryMapper
import dev.luix.connect_kit.mapper.RecordTypeMapper
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.utils.CKConstants
import java.time.Instant
import java.time.ZoneOffset

/**
 * Responsible for translating between Pigeon message maps and [BloodPressureRecord] objects.
 *
 * This mapper handles both directions of data flow:
 * - **decode()**: Converts a Map<String, Any> received from Dart into a [BloodPressureRecord].
 * - **encode()** (future): Converts a [BloodPressureRecord] into a Map<String, Any> to send back to Dart.
 *
 * The decoding process validates required fields (e.g. `time`, `systolic`, `diastolic`)
 * and parses optional data such as `zoneOffset`, `bodyPosition`, and `measurementLocation`.
 *
 * This class is intended to be used by the [RecordMapper], which delegates decoding
 * to this class when handling RECORD_KIND_BLOOD_PRESSURE
 *
 * **Example (decode flow):**
 * ```
 * RecordMapper
 *   └─> BloodPressureMapper.decode(map)
 * ```
 *
 * **Note:** The Health Connect client is injected for potential future use (e.g. checking feature availability),
 * even though it’s not required during decoding.
 *
 * @property healthConnectClient The Health Connect client instance.
 */
class BloodPressureMapper(
    private val healthConnectClient: HealthConnectClient,
    private val categoryMapper: CategoryMapper,
) {
    companion object {
        private const val TAG = CKConstants.TAG_BLOOD_PRESSURE_MAPPER
        private const val RECORD_KIND = CKConstants.RECORD_KIND_BLOOD_PRESSURE
    }

    /**
     * Decodes a Pigeon message map into a [BloodPressureRecord].
     *
     * @param map The map received from the Dart layer representing a blood pressure record.
     * @return A [BloodPressureRecord] instance ready for insertion into Health Connect.
     *
     * @throws IllegalArgumentException if required fields are missing or have invalid formats.
     */
    fun decode(map: Map<String, Any?>): BloodPressureRecord {
        // === Core times ===
        val timeRange = RecordMapperUtils.extractTimeRange(map, RECORD_KIND)

        // Check data integrity
        if (timeRange.startTime != timeRange.endTime) {
            CKLogger.w(
                tag = TAG,
                message =
                    "Blood pressure has different start/end times. Using start time for both."
            )
        }

        // Extract systolic/diastolic
        val systolicMap = RecordMapperUtils.getRequiredMap(map, "systolic", "bloodPressure")
        val systolicValue = RecordMapperUtils.getRequiredDouble(systolicMap, "value", RECORD_KIND)
        val systolicUnit = systolicMap["unit"] as? String

        val diastolicMap = RecordMapperUtils.getRequiredMap(map, "diastolic", "bloodPressure")
        val diastolicValue = RecordMapperUtils.getRequiredDouble(diastolicMap, "value", RECORD_KIND)
        val diastolicUnit = diastolicMap["unit"] as? String

        // Validate systolic > diastolic
        if (systolicValue <= diastolicValue) {
            throw RecordMapperException(
                "Systolic value must be greater than diastolic value",
                RECORD_KIND,
                "systolic/diastolic"
            )
        }

        // Extract optional bodyPosition and measurementLocation
        val bodyPosition = RecordMapperUtils.getOptionalInt(map, "bodyPosition")
            ?: BloodPressureRecord.BODY_POSITION_UNKNOWN
        val measurementLocation = RecordMapperUtils.getOptionalInt(map, "measurementLocation")
            ?: BloodPressureRecord.MEASUREMENT_LOCATION_UNKNOWN

        // Extract source and build metadata
        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        return BloodPressureRecord(
            time = timeRange.startTime,
            zoneOffset = timeRange.startZoneOffset,
            systolic = RecordMapperUtils.convertToPressure(systolicValue, systolicUnit, RECORD_KIND),
            diastolic = RecordMapperUtils.convertToPressure(diastolicValue, diastolicUnit, RECORD_KIND),
            bodyPosition = bodyPosition,
            measurementLocation = measurementLocation,
            metadata = metadata
        )
    }
}
