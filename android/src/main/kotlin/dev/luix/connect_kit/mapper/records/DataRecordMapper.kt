package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.units.*
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.mapper.RecordTypeMapper
import dev.luix.connect_kit.mapper.CategoryMapper
import dev.luix.connect_kit.utils.RecordMapperUtils
import dev.luix.connect_kit.utils.RecordTimeRange
import dev.luix.connect_kit.utils.UnwrappedValue
import dev.luix.connect_kit.utils.CKConstants
import dev.luix.connect_kit.utils.RecordMapperUtils.DataSample

import kotlin.reflect.KClass
import java.time.Instant

/**
 * Mapper for quantity/category records
 *
 * Handles the RECORD_KIND_DATA_RECORD from Dart, which represents simple health
 * measurements like steps, weight, heart rate, etc.
 *
 * Used internally by [RecordMapper] to handle RECORD_KIND_DATA_RECORD
 *
 * @property healthConnectClient The Health Connect client (for type validation)
 */
class DataRecordMapper(
    private val healthConnectClient: HealthConnectClient,
    private val categoryMapper: CategoryMapper,
) {
    companion object {
        private const val TAG = CKConstants.TAG_DATA_RECORD_MAPPER
        private const val RECORD_KIND = CKConstants.RECORD_KIND_DATA_RECORD
    }

    /**
     * Decodes a "data" record map into a Health Connect Record.
     *
     * **Process**:
     * 1. Extract and validate common fields (type, value, timestamps)
     * 2. Determine appropriate Health Connect Record class
     * 3. Convert value/unit to proper Health Connect types
     * 4. Build and return the Record object
     *
     * @param map The record map from Dart
     * @return Health Connect Record subclass instance
     * @throws RecordMapperException If decoding fails
     */
    fun decode(map: Map<String, Any?>): Record {
        val type = RecordMapperUtils.getRequiredString(map, "type", RECORD_KIND)
        val dataMap = RecordMapperUtils.getRequiredMap(map, "data", RECORD_KIND)

        CKLogger.w(tag = TAG, message = "Mapping data record type: '$type'")

        val recordClass = RecordTypeMapper.getRecordClass(type, healthConnectClient)
            ?: throw RecordMapperException(
                message = "Record type '$type' is not supported on HealthConnect. " +
                        RecordTypeMapper.getUnsupportedReason(type, healthConnectClient),
                recordKind = RECORD_KIND,
                fieldName = "type"
            )

        val timeRange = RecordMapperUtils.extractTimeRange(map, RECORD_KIND)

        val valueMap = RecordMapperUtils.unwrapData(
            dataMap = dataMap,
            recordMap = map,
            type = type,
            recordKind = RECORD_KIND,
        )

        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        return decodeByType(
            recordClass = recordClass,
            type = type,
            valueMap = valueMap,
            timeRange = timeRange,
            metadata = metadata
        )
    }

    /**
     * Decodes based on specific Health Connect Record class.
     *
     * This method maps generic (value, unit, time) data to the appropriate
     * Health Connect Record constructor with proper unit conversions.
     */
    private fun decodeByType(
        recordClass: KClass<out Record>,
        type: String,
        valueMap: UnwrappedValue,
        timeRange: RecordTimeRange,
        metadata: androidx.health.connect.client.records.metadata.Metadata
    ): Record {

        return when (recordClass) {

            // === Instantaneous Records (single time point) ===

            BasalMetabolicRateRecord::class -> {
                val power = RecordMapperUtils.convertToPower(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                BasalMetabolicRateRecord(
                    basalMetabolicRate = power,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            HeightRecord::class -> {
                val length = RecordMapperUtils.convertToLength(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                HeightRecord(
                    height = length,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            WeightRecord::class -> {
                val mass = RecordMapperUtils.convertToMass(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                WeightRecord(
                    weight = mass,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            BodyFatRecord::class -> {
                BodyFatRecord(
                    percentage = Percentage(valueMap.value as Double), // Health Connect expects Percentage
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            LeanBodyMassRecord::class -> {
                val mass = RecordMapperUtils.convertToMass(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                LeanBodyMassRecord(
                    mass = mass,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            BoneMassRecord::class -> {
                val mass = RecordMapperUtils.convertToMass(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                BoneMassRecord(
                    mass = mass,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            BodyWaterMassRecord::class -> {
                val mass = RecordMapperUtils.convertToMass(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                BodyWaterMassRecord(
                    mass = mass,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            BasalBodyTemperatureRecord::class -> {
                val temperature = RecordMapperUtils.convertToTemperature(
                    valueMap.value as Double,
                    valueMap.unit,
                    RECORD_KIND
                )
                val measurementLocation = (valueMap.derivedMetadata["measurementLocation"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_UNKNOWN

                BasalBodyTemperatureRecord(
                    temperature = temperature,
                    measurementLocation = measurementLocation,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            RestingHeartRateRecord::class -> {
                RestingHeartRateRecord(
                    beatsPerMinute = (valueMap.value as Double).toLong(), // Health Connect expects Long
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            BloodGlucoseRecord::class -> {
                val level = RecordMapperUtils.convertToBloodGlucoseLevel(
                    valueMap.value as Double,
                    valueMap.unit,
                    RECORD_KIND
                )

                val specimenSource = (valueMap.derivedMetadata["specimenSource"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: BloodGlucoseRecord.SPECIMEN_SOURCE_UNKNOWN

                val mealType = (valueMap.derivedMetadata["mealType"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: MealType.MEAL_TYPE_UNKNOWN

                val relationToMeal = (valueMap.derivedMetadata["relationToMeal"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: BloodGlucoseRecord.RELATION_TO_MEAL_UNKNOWN

                BloodGlucoseRecord(
                    level = level,
                    specimenSource = specimenSource,
                    mealType = mealType,
                    relationToMeal = relationToMeal,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            BodyTemperatureRecord::class -> {
                val temperature = RecordMapperUtils.convertToTemperature(
                    valueMap.value as Double,
                    valueMap.unit,
                    RECORD_KIND
                )
                val measurementLocation = (valueMap.derivedMetadata["measurementLocation"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->   
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_UNKNOWN

                BodyTemperatureRecord(
                    temperature = temperature,
                    measurementLocation = measurementLocation,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            OxygenSaturationRecord::class -> {
                OxygenSaturationRecord(
                    percentage = Percentage(valueMap.value as Double),
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            RespiratoryRateRecord::class -> {
                RespiratoryRateRecord(
                    rate = valueMap.value as Double, // Health Connect expects Double
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            Vo2MaxRecord::class -> {
                val measurementMethod = (valueMap.derivedMetadata["measurementMethod"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: Vo2MaxRecord.MEASUREMENT_METHOD_OTHER

                Vo2MaxRecord(
                    vo2MillilitersPerMinuteKilogram = valueMap.value as Double, // Health Connect expects Double
                    measurementMethod = measurementMethod,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            // === Interval Records (time range) ===

            ActiveCaloriesBurnedRecord::class -> {
                val energy = RecordMapperUtils.convertToEnergy(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                ActiveCaloriesBurnedRecord(
                    energy = energy,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            TotalCaloriesBurnedRecord::class -> {
                val energy = RecordMapperUtils.convertToEnergy(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                TotalCaloriesBurnedRecord(
                    energy = energy,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            StepsRecord::class -> {
                StepsRecord(
                    count = (valueMap.value as Double).toLong(), // Health Connect expects Long
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            DistanceRecord::class -> {
                val distance = RecordMapperUtils.convertToLength(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                DistanceRecord(
                    distance = distance,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            FloorsClimbedRecord::class -> {
                FloorsClimbedRecord(
                    floors = valueMap.value as Double, // Health Connect expects Double
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            ElevationGainedRecord::class -> {
                val elevation = RecordMapperUtils.convertToLength(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                ElevationGainedRecord(
                    elevation = elevation, // Health Connect expects Double
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            HydrationRecord::class -> {
                val volume = RecordMapperUtils.convertToVolume(valueMap.value as Double, valueMap.unit, RECORD_KIND)
                HydrationRecord(
                    volume = volume,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            WheelchairPushesRecord::class -> {
                WheelchairPushesRecord(
                    count = (valueMap.value as Double).toLong(), // Health Connect expects Long
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            // === Records That Require SAMPLES (even if single value) ===

            SpeedRecord::class -> {
                val speedSamples = (valueMap.value as List<DataSample>).map { sample ->
                    SpeedRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        speed = RecordMapperUtils.convertToVelocity(sample.value, valueMap.unit, RECORD_KIND)
                    )
                }

                SpeedRecord(
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    samples = speedSamples,
                    metadata = metadata
                )
            }

            HeartRateRecord::class -> {
                val heartRateSamples = (valueMap.value as List<DataSample>).map { sample ->
                    HeartRateRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        beatsPerMinute = sample.value.toLong() // Health Connect expects Long
                    )
                }

                HeartRateRecord(
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    samples = heartRateSamples,
                    metadata = metadata
                )
            }

            PowerRecord::class -> {
                val powerSamples = (valueMap.value as List<DataSample>).map { sample ->
                    PowerRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        power = RecordMapperUtils.convertToPower(sample.value, valueMap.unit, RECORD_KIND)
                    )
                }

                PowerRecord(
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    samples = powerSamples,
                    metadata = metadata
                )
            }

            CyclingPedalingCadenceRecord::class -> {
                val cyclingCadenceSamples = (valueMap.value as List<DataSample>).map { sample ->
                    CyclingPedalingCadenceRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        revolutionsPerMinute = sample.value // Health Connect expects Double
                    )
                }

                CyclingPedalingCadenceRecord(
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    samples = cyclingCadenceSamples,
                    metadata = metadata
                )
            }

            SkinTemperatureRecord::class -> {
                val deltaSamples = (valueMap.value as List<DataSample>).map { sample ->
                    SkinTemperatureRecord.Delta(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        delta = RecordMapperUtils.convertToTemperatureDelta(sample.value, valueMap.unit, RECORD_KIND)
                    )
                }

                val measurementLocation = (valueMap.derivedMetadata["measurementLocation"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: SkinTemperatureRecord.MEASUREMENT_LOCATION_UNKNOWN

                val baseline = (valueMap.derivedMetadata["baseline"] as? UnwrappedValue)
                    ?.let { RecordMapperUtils.convertToTemperature(it.value as Double, it.unit, RECORD_KIND) }

                SkinTemperatureRecord(
                    deltas = deltaSamples,
                    baseline = baseline,
                    measurementLocation = measurementLocation,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            // === Category Records (no value/unit, uses type constants) ===

            MindfulnessSessionRecord::class -> {
                val sessionType = (valueMap.value as? Map<String, String>)?.let { map ->
                    categoryMapper.decode(map["categoryName"], map["value"])
                } ?: throw RecordMapperException(
                    "Invalid category value '${(valueMap.value as? Map<String, String>)?.get("value")}' for '${(valueMap.value as? Map<String, String>)?.get("categoryName")}'",
                    RECORD_KIND,
                    "sessionType"
                )

                MindfulnessSessionRecord(
                    mindfulnessSessionType = sessionType,
                    title = valueMap.derivedMetadata["title"]?.let { it as UnwrappedValue }?.value as String,
                    notes = valueMap.derivedMetadata["notes"]?.let { it as UnwrappedValue }?.value as String,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            MenstruationFlowRecord::class -> {
                val flow = (valueMap.value as? Map<String, String>)?.let { map ->
                    categoryMapper.decode(map["categoryName"], map["value"])
                } ?: throw RecordMapperException(
                    "Invalid category value '${(valueMap.value as? Map<String, String>)?.get("value")}' for '${(valueMap.value as? Map<String, String>)?.get("categoryName")}'",
                    RECORD_KIND,
                    "MenstruationFlow"
                )

                MenstruationFlowRecord(
                    flow = flow,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            CervicalMucusRecord::class -> {
                val appearance = (valueMap.value as? Map<String, String>)?.let { map ->
                    categoryMapper.decode(map["categoryName"], map["value"])
                } ?: CervicalMucusRecord.APPEARANCE_UNKNOWN

                val sensation = (valueMap.derivedMetadata["sensation"] as? UnwrappedValue)
                    ?.value?.let { it as? Map<String, String> }?.let { map ->
                        categoryMapper.decode(map["categoryName"], map["value"])
                    } ?: CervicalMucusRecord.SENSATION_UNKNOWN

                CervicalMucusRecord(
                    appearance = appearance,
                    sensation = sensation,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            OvulationTestRecord::class -> {
                val result = (valueMap.value as? Map<String, String>)?.let { map ->
                    categoryMapper.decode(map["categoryName"], map["value"])
                } ?: throw RecordMapperException(
                    "Invalid category value '${(valueMap.value as? Map<String, String>)?.get("value")}' for '${(valueMap.value as? Map<String, String>)?.get("categoryName")}'",
                    RECORD_KIND,
                    "OvulationTestResult"
                )

                OvulationTestRecord(
                    result = result,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            SexualActivityRecord::class -> {
                val protectionUsed = (valueMap.value as? Map<String, String>)?.let { map ->
                    categoryMapper.decode(map["categoryName"], map["value"])
                } ?: throw RecordMapperException(
                    "Invalid category value '${(valueMap.value as? Map<String, String>)?.get("value")}' for '${(valueMap.value as? Map<String, String>)?.get("categoryName")}'",
                    RECORD_KIND,
                    "SexualActivityProtection"
                )

                SexualActivityRecord(
                    protectionUsed = protectionUsed,
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            ActivityIntensityRecord::class -> {
                val activityIntensityType = (valueMap.value as? Map<String, String>)?.let { map ->
                    categoryMapper.decode(map["categoryName"], map["value"])
                } ?: throw RecordMapperException(
                    "Invalid category value '${(valueMap.value as? Map<String, String>)?.get("value")}' for '${(valueMap.value as? Map<String, String>)?.get("categoryName")}'",
                    RECORD_KIND,
                    "ActivityIntensityType"
                )

                ActivityIntensityRecord(
                    activityIntensityType = activityIntensityType,
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            // === Session/Flag Records (no value needed) ===

            IntermenstrualBleedingRecord::class -> { // Value/unit ignored
                IntermenstrualBleedingRecord(
                    time = timeRange.startTime,
                    zoneOffset = timeRange.startZoneOffset,
                    metadata = metadata
                )
            }

            MenstruationPeriodRecord::class -> { // Value/unit ignored
                MenstruationPeriodRecord(
                    startTime = timeRange.startTime,
                    endTime = timeRange.endTime,
                    startZoneOffset = timeRange.startZoneOffset,
                    endZoneOffset = timeRange.endZoneOffset,
                    metadata = metadata
                )
            }

            else -> {
                throw RecordMapperException(
                    message = "Record class ${recordClass.simpleName} is recognized but not yet " +
                            "implemented in DataRecordMapper. Please add implementation.",
                    recordKind = RECORD_KIND
                )
            }
        }
    }
}
