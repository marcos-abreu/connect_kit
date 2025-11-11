package dev.luix.connect_kit.mapper.records

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.units.*
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.mapper.RecordTypeMapper
import dev.luix.connect_kit.mapper.CategoryMapper
import dev.luix.connect_kit.utils.RecordMapperUtils
import dev.luix.connect_kit.utils.CKConstants
import dev.luix.connect_kit.utils.RecordMapperUtils.FieldData
import dev.luix.connect_kit.utils.RecordMapperUtils.RawSample

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
 * **Supported Record Types**:
 * - StepsRecord
 * - WeightRecord
 * - HeartRateRecord
 * - DistanceRecord
 * - And many more quantity/instantaneous records
 *
 * **Architecture**:
 * This mapper follows the pattern used by all record mappers:
 * 1. Extract common fields (time, metadata)
 * 2. Extract type-specific fields (value, unit)
 * 3. Map to appropriate Health Connect Record class
 * 4. Handle platform-specific conversions and validations
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
        // Extract required fields
        val type = RecordMapperUtils.getRequiredString(map, "type", RECORD_KIND)
        val dataMap = RecordMapperUtils.getRequiredMap(map, "data", RECORD_KIND)

        val startTimeString = RecordMapperUtils.getRequiredString(map, "startTime", RECORD_KIND)
        val endTimeString = RecordMapperUtils.getRequiredString(map, "endTime", RECORD_KIND)

        // Parse timestamps
        val startTime = RecordMapperUtils.parseInstant(startTimeString, "startTime", RECORD_KIND)
        val endTime = RecordMapperUtils.parseInstant(endTimeString, "endTime", RECORD_KIND)

        // Validate time order
        RecordMapperUtils.validateTimeOrder(startTime, endTime, RECORD_KIND)

        // Parse zone offsets
        val startZoneOffsetSeconds = RecordMapperUtils.getRequiredInt(
            map, "startZoneOffsetSeconds", RECORD_KIND
        )
        val endZoneOffsetSeconds = RecordMapperUtils.getRequiredInt(
            map, "endZoneOffsetSeconds", RECORD_KIND
        )

        val startZoneOffset = RecordMapperUtils.parseZoneOffset(startZoneOffsetSeconds)
        val endZoneOffset = RecordMapperUtils.parseZoneOffset(endZoneOffsetSeconds)

        // Extract source and build metadata
        val sourceMap = RecordMapperUtils.getOptionalMap(map, "source")
        val metadata = RecordMapperUtils.buildMetadata(sourceMap)

        // Extract value and unit
        val value = RecordMapperUtils.getRequiredMap(map, "value", RECORD_KIND)
        val valuePattern = RecordMapperUtils.getRequiredString(map, "valuePattern", RECORD_KIND)
        val unit = RecordMapperUtils.getOptionalString(map, "unit")

        // Validate that type is supported
        val recordClass = RecordTypeMapper.getRecordClass(type, healthConnectClient)
            ?: throw RecordMapperException(
                message = "Record type '$type' is not supported on this device. " +
                        RecordTypeMapper.getUnsupportedReason(type, healthConnectClient),
                recordKind = RECORD_KIND
            )

        // Delegate to type-specific decoder
        return decodeByType(
            recordClass = recordClass,
            type = type,
            valuePattern = valuePattern,
            value = value,
            unit = unit,
            startTime = startTime,
            endTime = endTime,
            startZoneOffset = startZoneOffset,
            endZoneOffset = endZoneOffset,
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
        valuePattern: String,
        value: Any,
        unit: String?,
        startTime: java.time.Instant,
        endTime: java.time.Instant,
        startZoneOffset: java.time.ZoneOffset,
        endZoneOffset: java.time.ZoneOffset,
        metadata: androidx.health.connect.client.records.metadata.Metadata
    ): Record {

        return when (recordClass) {

            // === Instantaneous Records (single time point) ===

            BasalMetabolicRateRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val power = RecordMapperUtils.convertToPower(numericValue, unit, RECORD_KIND)
                BasalMetabolicRateRecord(
                    basalMetabolicRate = power,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            HeightRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val length = RecordMapperUtils.convertToLength(numericValue, unit, RECORD_KIND)
                HeightRecord(
                    height = length,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            WeightRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val mass = RecordMapperUtils.convertToMass(numericValue, unit, RECORD_KIND)
                WeightRecord(
                    weight = mass,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            BodyFatRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                BodyFatRecord(
                    percentage = Percentage(numericValue), // Health Connect expects Percentage
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            LeanBodyMassRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val mass = RecordMapperUtils.convertToMass(numericValue, unit, RECORD_KIND)
                LeanBodyMassRecord(
                    mass = mass,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            BoneMassRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val mass = RecordMapperUtils.convertToMass(numericValue, unit, RECORD_KIND)
                BoneMassRecord(
                    mass = mass,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            BodyWaterMassRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val mass = RecordMapperUtils.convertToMass(numericValue, unit, RECORD_KIND)
                BodyWaterMassRecord(
                    mass = mass,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            BasalBodyTemperatureRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "temperature" to CKConstants.VALUE_PATTERN_QUANTITY,
                        "measurementLocation" to CKConstants.VALUE_PATTERN_CATEGORY
                    ),
                    recordKind = RECORD_KIND
                )

                val temperatureData = valueMap["temperature"]
                    ?: throw RecordMapperException("Missing 'temperature' field", RECORD_KIND, type)
                val temperatureValue = RecordMapperUtils.expectNumericValue(
                    temperatureData.value,
                    temperatureData.valuePattern,
                    recordKind = RECORD_KIND
                )
                val temperature = RecordMapperUtils.convertToTemperature(
                    temperatureValue,
                    temperatureData.unit,
                    RECORD_KIND
                )

                val measurementLocation = categoryMapper.decodeFromField(
                    valueMap, "measurementLocation", "BodyTemperatureMeasurementLocation", RECORD_KIND, type
                ) ?: BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_UNKNOWN

                BasalBodyTemperatureRecord(
                    temperature = temperature,
                    measurementLocation = measurementLocation,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            RestingHeartRateRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                RestingHeartRateRecord(
                    beatsPerMinute = numericValue.toLong(), // Health Connect expects Long
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            BloodGlucoseRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "level" to CKConstants.VALUE_PATTERN_QUANTITY,
                        "specimenSource" to CKConstants.VALUE_PATTERN_CATEGORY,
                        "mealType" to CKConstants.VALUE_PATTERN_CATEGORY,
                        "relationToMeal" to CKConstants.VALUE_PATTERN_CATEGORY,
                    ),
                    recordKind = RECORD_KIND
                )

                val levelData = valueMap["level"]
                    ?: throw RecordMapperException("Missing 'level' field", RECORD_KIND, type)
                val levelValue = RecordMapperUtils.expectNumericValue(
                    levelData.value,
                    levelData.valuePattern,
                    recordKind = RECORD_KIND
                )
                val level = RecordMapperUtils.convertToBloodGlucoseLevel(
                    levelValue,
                    levelData.unit,
                    RECORD_KIND
                )

                val specimenSource = categoryMapper.decodeFromField(
                    valueMap, "specimenSource", "SpecimenSource", RECORD_KIND, type
                ) ?: BloodGlucoseRecord.SPECIMEN_SOURCE_UNKNOWN

                val mealType = categoryMapper.decodeFromField(
                    valueMap, "mealType", "MealType", RECORD_KIND, type
                ) ?: MealType.MEAL_TYPE_UNKNOWN

                val relationToMeal = categoryMapper.decodeFromField(
                    valueMap, "relationToMeal", "RelationToMeal", RECORD_KIND, type
                ) ?: BloodGlucoseRecord.RELATION_TO_MEAL_UNKNOWN

                BloodGlucoseRecord(
                    level = level,
                    specimenSource = specimenSource,
                    mealType = mealType,
                    relationToMeal = relationToMeal,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            BodyTemperatureRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "temperature" to CKConstants.VALUE_PATTERN_QUANTITY,
                        "measurementLocation" to CKConstants.VALUE_PATTERN_CATEGORY,
                    ),
                    recordKind = RECORD_KIND
                )

                val temperatureData = valueMap["temperature"]
                    ?: throw RecordMapperException("Missing 'temperature' field", RECORD_KIND, type)
                val temperatureValue = RecordMapperUtils.expectNumericValue(
                    temperatureData.value,
                    temperatureData.valuePattern,
                    recordKind = RECORD_KIND
                )
                val temperature = RecordMapperUtils.convertToTemperature(
                    temperatureValue,
                    temperatureData.unit,
                    RECORD_KIND
                )
                val measurementLocation = categoryMapper.decodeFromField(
                    valueMap, "measurementLocation", "BodyTemperatureMeasurementLocation", RECORD_KIND, type
                ) ?: BodyTemperatureMeasurementLocation.MEASUREMENT_LOCATION_UNKNOWN

                BodyTemperatureRecord(
                    temperature = temperature,
                    measurementLocation = measurementLocation,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            OxygenSaturationRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                OxygenSaturationRecord(
                    percentage = Percentage(numericValue),
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            RespiratoryRateRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                RespiratoryRateRecord(
                    rate = numericValue, // Health Connect expects Double
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            Vo2MaxRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "vo2Max" to CKConstants.VALUE_PATTERN_QUANTITY,
                        "measurementMethod" to CKConstants.VALUE_PATTERN_CATEGORY,
                    ),
                    recordKind = RECORD_KIND
                )

                val vo2MaxData = valueMap["vo2Max"]
                    ?: throw RecordMapperException("Missing 'vo2Max' field", RECORD_KIND, type)
                val vo2MaxValue = RecordMapperUtils.expectNumericValue(
                    vo2MaxData.value,
                    vo2MaxData.valuePattern,
                    recordKind = RECORD_KIND
                )

                val measurementMethod = categoryMapper.decodeFromField(
                    valueMap, "measurementMethod", "Vo2MaxMeasurementMethod", RECORD_KIND, type
                ) ?: Vo2MaxRecord.MEASUREMENT_METHOD_OTHER

                Vo2MaxRecord(
                    vo2MillilitersPerMinuteKilogram = vo2MaxValue, // Health Connect expects Double
                    measurementMethod = measurementMethod,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            // === Interval Records (time range) ===

            ActiveCaloriesBurnedRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val energy = RecordMapperUtils.convertToEnergy(numericValue, unit, RECORD_KIND)
                ActiveCaloriesBurnedRecord(
                    energy = energy,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            TotalCaloriesBurnedRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val energy = RecordMapperUtils.convertToEnergy(numericValue, unit, RECORD_KIND)
                TotalCaloriesBurnedRecord(
                    energy = energy,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            StepsRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                StepsRecord(
                    count = numericValue.toLong(), // Health Connect expects Long
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            DistanceRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val distance = RecordMapperUtils.convertToLength(numericValue, unit, RECORD_KIND)
                DistanceRecord(
                    distance = distance,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            FloorsClimbedRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                FloorsClimbedRecord(
                    floors = numericValue, // Health Connect expects Double
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            ElevationGainedRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val elevation = RecordMapperUtils.convertToLength(numericValue, unit, RECORD_KIND)
                ElevationGainedRecord(
                    elevation = elevation, // Health Connect expects Double
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            HydrationRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                val volume = RecordMapperUtils.convertToVolume(numericValue, unit, RECORD_KIND)
                HydrationRecord(
                    volume = volume,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            WheelchairPushesRecord::class -> {
                val numericValue = RecordMapperUtils.expectNumericValue(value, valuePattern, type)
                WheelchairPushesRecord(
                    count = numericValue.toLong(), // Health Connect expects Long
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            // === Records That Require SAMPLES (even if single value) ===

            SpeedRecord::class -> {
                val rawSamples = RecordMapperUtils.expectSamplesValue(value, valuePattern, type)
                val speedSamples = rawSamples.map { sample ->
                    SpeedRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        speed = RecordMapperUtils.convertToVelocity(sample.value, unit, RECORD_KIND)
                    )
                }

                SpeedRecord(
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    samples = speedSamples,
                    metadata = metadata
                )
            }

            HeartRateRecord::class -> {
                val samples = RecordMapperUtils.expectSamplesValue(value, valuePattern, type)
                val heartRateSamples = samples.map { sample ->
                    HeartRateRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        beatsPerMinute = sample.value.toLong() // Health Connect expects Long
                    )
                }

                HeartRateRecord(
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    samples = heartRateSamples,
                    metadata = metadata
                )
            }

            PowerRecord::class -> {
                val samples = RecordMapperUtils.expectSamplesValue(value, valuePattern, type)
                val powerSamples = samples.map { sample ->
                    PowerRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        power = RecordMapperUtils.convertToPower(sample.value, unit, RECORD_KIND)
                    )
                }

                PowerRecord(
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    samples = powerSamples,
                    metadata = metadata
                )
            }

            CyclingPedalingCadenceRecord::class -> {
                val samples = RecordMapperUtils.expectSamplesValue(value, valuePattern, type)
                val cyclingCadenceSamples = samples.map { sample ->
                    CyclingPedalingCadenceRecord.Sample(
                        time = Instant.ofEpochMilli(sample.timeMillis),
                        revolutionsPerMinute = sample.value // Health Connect expects Double
                    )
                }

                CyclingPedalingCadenceRecord(
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    samples = cyclingCadenceSamples,
                    metadata = metadata
                )
            }

            SkinTemperatureRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "deltas" to CKConstants.VALUE_PATTERN_SAMPLES,
                        "baseline" to CKConstants.VALUE_PATTERN_QUANTITY,
                        "measurementLocation" to CKConstants.VALUE_PATTERN_CATEGORY,
                    ),
                    recordKind = RECORD_KIND
                )

                val measurementLocation = categoryMapper.decodeFromField(
                    valueMap, "measurementLocation", "SkinTemperatureMeasurementLocation", RECORD_KIND, type
                ) ?: SkinTemperatureRecord.MEASUREMENT_LOCATION_UNKNOWN

                val baseline = valueMap["baseline"]?.let { data ->
                    RecordMapperUtils.convertToTemperature(
                        RecordMapperUtils.expectNumericValue(data.value, data.valuePattern, RECORD_KIND),
                        RecordMapperUtils.requireUnit(data.unit, RECORD_KIND),
                        RECORD_KIND
                    )
                }

                val deltaSamples = valueMap["deltas"]?.let { data ->
                    val samples = RecordMapperUtils.expectSamplesValue(data.value, data.valuePattern, type)
                    samples.map { sample ->
                        SkinTemperatureRecord.Delta(
                            time = Instant.ofEpochMilli(sample.timeMillis),
                            delta = RecordMapperUtils.convertToTemperatureDelta(
                                sample.value,
                                data.unit,
                                RECORD_KIND
                            )
                        )
                    }
                } ?: throw RecordMapperException("Missing 'deltas' field", RECORD_KIND, type)

                SkinTemperatureRecord(
                    deltas = deltaSamples,
                    baseline = baseline,
                    measurementLocation = measurementLocation,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            // === Category Records (no value/unit, uses type constants) ===

            MindfulnessSessionRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "mindfulnessSessionType" to CKConstants.VALUE_PATTERN_CATEGORY,
                        "title" to CKConstants.VALUE_PATTERN_LABEL,
                        "notes" to CKConstants.VALUE_PATTERN_LABEL,
                    ),
                    recordKind = RECORD_KIND
                )

                val mindfulnessSessionType = categoryMapper.decodeFromField(
                    valueMap, "mindfulnessSessionType", "MindfulnessSessionType", RECORD_KIND, type
                ) ?: throw RecordMapperException(
                    "Invalid category value '${valueMap["mindfulnessSessionType"]?.value}' for 'MindfulnessSessionType'",
                    RECORD_KIND,
                    "MindfulnessSessionType"
                )

                MindfulnessSessionRecord(
                    mindfulnessSessionType = mindfulnessSessionType,
                    title = valueMap["title"]?.value as String,
                    notes = valueMap["notes"]?.value as String,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            MenstruationFlowRecord::class -> {
                val categoryValue = RecordMapperUtils.expectCategoryValue(value, valuePattern, type)
                val flow = categoryMapper.decode("MenstruationFlow", categoryValue)
                    ?: throw RecordMapperException(
                        "Invalid category value '$categoryValue' for 'MenstruationFlow'",
                        RECORD_KIND,
                        "MenstruationFlow"
                    )
                MenstruationFlowRecord(
                    flow = flow,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            CervicalMucusRecord::class -> {
                val valueMap = RecordMapperUtils.expectMultipleValue(
                    value = value,
                    valuePattern = valuePattern,
                    type = type,
                    possibleFields = mapOf(
                        "appearance" to CKConstants.VALUE_PATTERN_CATEGORY,
                        "sensation" to CKConstants.VALUE_PATTERN_CATEGORY,
                    ),
                    recordKind = RECORD_KIND
                )
                val appearance = categoryMapper.decodeFromField(
                    valueMap, "appearance", "CervicalMucusAppearance", RECORD_KIND, type
                ) ?: CervicalMucusRecord.APPEARANCE_UNKNOWN

                val sensation = categoryMapper.decodeFromField(
                    valueMap, "sensation", "CervicalMucusSensation", RECORD_KIND, type
                ) ?: CervicalMucusRecord.SENSATION_UNKNOWN

                CervicalMucusRecord(
                    appearance = appearance,
                    sensation = sensation,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            OvulationTestRecord::class -> {
                val categoryValue = RecordMapperUtils.expectCategoryValue(value, valuePattern, type)
                val result = categoryMapper.decode("OvulationTestResult", categoryValue)
                    ?: throw RecordMapperException(
                        "Invalid category value '$categoryValue' for 'OvulationTestResult'",
                        RECORD_KIND,
                        "OvulationTestResult"
                    )
                OvulationTestRecord(
                    result = result,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            SexualActivityRecord::class -> {
                val categoryValue = RecordMapperUtils.expectCategoryValue(value, valuePattern, type)
                val protectionUsed = categoryMapper.decode("SexualActivityProtection", categoryValue)
                    ?: throw RecordMapperException(
                        "Invalid category value '$categoryValue' for 'SexualActivityProtection'",
                        RECORD_KIND,
                        "SexualActivityProtection"
                    )
                SexualActivityRecord(
                    protectionUsed = protectionUsed,
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            ActivityIntensityRecord::class -> {
                val categoryValue = RecordMapperUtils.expectCategoryValue(value, valuePattern, type)
                val activityIntensityType = categoryMapper.decode("ActivityIntensityType", categoryValue)
                    ?: throw RecordMapperException(
                        "Invalid category value '$categoryValue' for 'ActivityIntensityType'",
                        RECORD_KIND,
                        "ActivityIntensityType"
                    )
                ActivityIntensityRecord(
                    activityIntensityType = activityIntensityType,
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            // === Session/Flag Records (no value needed) ===

            IntermenstrualBleedingRecord::class -> {
                // Value/unit ignored
                IntermenstrualBleedingRecord(
                    time = startTime,
                    zoneOffset = startZoneOffset,
                    metadata = metadata
                )
            }

            MenstruationPeriodRecord::class -> {
                // Value/unit ignored
                MenstruationPeriodRecord(
                    startTime = startTime,
                    endTime = endTime,
                    startZoneOffset = startZoneOffset,
                    endZoneOffset = endZoneOffset,
                    metadata = metadata
                )
            }

            else -> {
                // Unsupported record class
                throw RecordMapperException(
                    message = "Record class ${recordClass.simpleName} is recognized but not yet " +
                            "implemented in DataRecordMapper. Please add implementation.",
                    recordKind = RECORD_KIND
                )
            }
        }
    }
}
