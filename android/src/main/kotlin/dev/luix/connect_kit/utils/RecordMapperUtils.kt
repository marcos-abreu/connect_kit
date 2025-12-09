package dev.luix.connect_kit.utils

import androidx.health.connect.client.records.metadata.Device
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.*
import dev.luix.connect_kit.mapper.RecordMapperException
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.utils.CKConstants
import java.time.Instant
import java.time.ZoneOffset

data class RecordTimeRange(
    val startTime: Instant,
    val startZoneOffset: ZoneOffset?,
    val endTime: Instant,
    val endZoneOffset: ZoneOffset?
)

data class UnwrappedValue(
    val value: Any,
    val unit: String?,
    val valuePattern: String,
    val derivedMetadata: Map<String, Any>
)

/**
 * Common utility functions for all record mappers.
 *
 * Provides reusable extraction and conversion methods to minimize code duplication
 * across specialized record mappers. All methods follow a consistent error handling
 * pattern using [RecordMapperException].
 *
 * **Design Principles**:
 * - Fail fast with clear error messages
 * - Type-safe extraction with proper validation
 * - Consistent null handling
 */
object RecordMapperUtils {
    private const val TAG = CKConstants.TAG_RECORD_MAPPER_UTILS

    // === Required Field Extraction ===

    /**
     * Extracts a required string field from the map.
     * @throws RecordMapperException if field is missing or not a String
     */
    fun getRequiredString(
        map: Map<String, Any?>,
        key: String,
        recordKind: String
    ): String {
        val value = map[key]
            ?: throw RecordMapperException.missingField(key, recordKind)

        return value as? String
            ?: throw RecordMapperException.invalidFieldType(key, "String", value, recordKind)
    }

    /**
     * Extracts a required number field and converts to Double.
     * @throws RecordMapperException if field is missing or not a Number
     */
    fun getRequiredDouble(
        map: Map<String, Any?>,
        key: String,
        recordKind: String
    ): Double {
        val value = map[key]
            ?: throw RecordMapperException.missingField(key, recordKind)

        return (value as? Number)?.toDouble()
            ?: throw RecordMapperException.invalidFieldType(key, "Number", value, recordKind)
    }

    /**
     * Extracts a required integer field.
     * @throws RecordMapperException if field is missing or not a Number
     */
    fun getRequiredInt(
        map: Map<String, Any?>,
        key: String,
        recordKind: String
    ): Int {
        val value = map[key]
            ?: throw RecordMapperException.missingField(key, recordKind)

        return (value as? Number)?.toInt()
            ?: throw RecordMapperException.invalidFieldType(key, "Number", value, recordKind)
    }

    /**
     * Extracts a required nested map.
     * @throws RecordMapperException if field is missing or not a Map
     */
    @Suppress("UNCHECKED_CAST")
    fun getRequiredMap(
        map: Map<String, Any?>,
        key: String,
        recordKind: String
    ): Map<String, Any> {
        val value = map[key]
            ?: throw RecordMapperException.missingField(key, recordKind)

        return value as? Map<String, Any>
            ?: throw RecordMapperException.invalidFieldType(key, "Map", value, recordKind)
    }

    // === Optional Field Extraction ===

    /**
     * Extracts an optional string field.
     * @return String value or null if field is missing
     */
    fun getOptionalString(map: Map<String, Any?>, key: String): String? {
        return map[key] as? String
    }

    /**
     * Extracts an optional number field as Double.
     * @return Double value or null if field is missing
     */
    fun getOptionalDouble(map: Map<String, Any?>, key: String): Double? {
        return (map[key] as? Number)?.toDouble()
    }

    /**
     * Extracts an optional integer field.
     * @return Int value or null if field is missing
     */
    fun getOptionalInt(map: Map<String, Any?>, key: String): Int? {
        return (map[key] as? Number)?.toInt()
    }

    /**
     * Extracts an optional nested map.
     * @return Map or null if field is missing
     */
    @Suppress("UNCHECKED_CAST")
    fun getOptionalMap(map: Map<String, Any?>, key: String): Map<String, Any>? {
        return map[key] as? Map<String, Any>
    }

    /**
     * Extracts an optional list.
     * @return List or null if field is missing
     */
    @Suppress("UNCHECKED_CAST")
    fun getOptionalList(map: Map<String, Any?>, key: String): List<Any>? {
        return map[key] as? List<Any>
    }

    // === Time Handling ===

    /**
     * Parses milliseconds-since-epoch timestamp to Instant.
     */
    fun parseInstant(timestampMs: Long, fieldName: String, recordKind: String): Instant {
        return Instant.ofEpochMilli(timestampMs)
    }

    /**
     * Parses zone offset from seconds.
     */
    fun parseZoneOffset(seconds: Int): ZoneOffset {
        return ZoneOffset.ofTotalSeconds(seconds)
    }

    // /**
    //  Extracts start and end times from the workout map.
    //  Validates that end time is not before start time.
    //  */
    fun extractTimeRange(
        map: Map<String, Any?>,
        recordKind: String
    ): RecordTimeRange {
        val (startTime, startZoneOffset) = extractTime(map, "startTime", "startZoneOffsetSeconds", recordKind)
        val (endTime, endZoneOffset) = extractTime(map, "endTime", "endZoneOffsetSeconds", recordKind)

        // Validate time order
        validateTimeOrder(startTime, endTime, recordKind)

        return RecordTimeRange(
            startTime,
            startZoneOffset,
            endTime,
            endZoneOffset
        )
    }

    /**
     * Extracts a time and its zone offset from the map.
     */
    fun extractTime(
        map: Map<String, Any?>,
        timeKey: String,
        offsetKey: String,
        recordKind: String
    ): Pair<Instant, ZoneOffset> {
        val timestampMs = getRequiredInt(map, timeKey, recordKind)
        val timestamp = parseInstant(timestampMs.toLong(), timeKey, recordKind)

        val offsetSeconds = getRequiredInt(map, offsetKey, recordKind)
        val offset = parseZoneOffset(offsetSeconds)

        return Pair(timestamp, offset)
    }

    // === Value & Unit Handling ===

    /**
     * Unwraps the data from the map.
     */
    fun unwrapData(
        dataMap: Map<String, Any>,
        recordMap: Map<String, Any?>,
        type: String,
        recordKind: String,
        unwrapMultiple: Boolean = true
    ): UnwrappedValue {
        val rootValuePattern = getRequiredString(
            dataMap, "valuePattern", recordKind)

        val rootValue = dataMap["value"] ?: throw RecordMapperException(
            message = "Record data 'value' is missing",
            recordKind = recordKind,
            fieldName = "value"
        )
        val rootUnit = getOptionalString(dataMap, "unit")

        return when (rootValuePattern) {
            CKConstants.VALUE_PATTERN_QUANTITY -> {
                val quantityDouble = expectQuantityValue(rootValue, rootValuePattern, recordKind)
                UnwrappedValue(quantityDouble, rootUnit, rootValuePattern, emptyMap())
            }

            CKConstants.VALUE_PATTERN_CATEGORY -> {
                val categoryMap = expectCategoryValue(dataMap, rootValue, rootValuePattern, recordKind)
                UnwrappedValue(categoryMap, rootUnit, rootValuePattern, emptyMap())
            }

            CKConstants.VALUE_PATTERN_SAMPLES -> {
                val samplesValue = expectSamplesValue(rootValue, rootValuePattern, recordKind)
                UnwrappedValue(samplesValue, rootUnit, rootValuePattern, emptyMap())
            }

            CKConstants.VALUE_PATTERN_LABEL -> {
                val labelValue = expectLabelValue(rootValue, rootValuePattern, recordKind)
                UnwrappedValue(labelValue, rootUnit, rootValuePattern, emptyMap())
            }

            CKConstants.VALUE_PATTERN_MULTIPLE -> {
                if (!unwrapMultiple) {
                    throw RecordMapperException(
                        message = "Multiple value encountered but unwrapMultiple=false",
                        recordKind = recordKind,
                        fieldName = "value"
                    )
                }

                val multipleMap = rootValue as? Map<String, Any> ?: throw RecordMapperException(
                    message = "Invalid multiple value: expected Map, got '$rootValue'",
                    recordKind = recordKind,
                    fieldName = "value"
                )

                val customMetadata = recordMap["metadata"] as? Map<String, Any> ?: throw RecordMapperException(
                    message = "Missing required metadata for MULTIPLE value",
                    recordKind = recordKind,
                    fieldName = "metadata"
                )

                val mainPropertyKey = customMetadata["mainProperty"] as? String ?: throw RecordMapperException(
                    message = "Missing required 'mainProperty' in record metadata for MULTIPLE value",
                    recordKind = recordKind,
                    fieldName = "metadata.mainProperty"
                )

                if (mainPropertyKey.isEmpty()) {
                    throw RecordMapperException(
                        message = "'mainProperty' must not be empty",
                        recordKind = recordKind,
                        fieldName = "metadata.mainProperty"
                    )
                }

                val mainPropertyMap = multipleMap[mainPropertyKey] as? Map<String, Any> ?: throw RecordMapperException(
                    message = "Main property '$mainPropertyKey' not found in MULTIPLE value",
                    recordKind = recordKind,
                    fieldName = mainPropertyKey
                )

                // Recursively unwrap main property
                val main = unwrapData(
                    dataMap = mainPropertyMap,
                    recordMap = recordMap,
                    type = type,
                    recordKind = recordKind,
                    unwrapMultiple = false // important: prevent nested multiple
                )

                // Collect non-main properties into customMetadata for later processing
                val derivedMetadata = mutableMapOf<String, Any>()
                
                // Process all non-main properties
                for ((propKey, propRaw) in multipleMap) {
                    if (propKey == mainPropertyKey) continue // Skip main property

                    val propMap = propRaw as? Map<String, Any>
                    if (propMap == null) {
                        CKLogger.w(
                            tag = TAG,
                            message = "MULTIPLE property '$propKey' is not a map, skipping"
                        )
                        continue
                    }
                    
                    // Recursively unwrap non-main property
                    val prop = unwrapData(
                        dataMap = propMap,
                        recordMap = recordMap,
                        type = type,
                        recordKind = recordKind,
                        unwrapMultiple = false // important: prevent nested multiple
                    )

                    derivedMetadata[propKey] = prop
                }

                UnwrappedValue(main.value, main.unit, main.valuePattern, derivedMetadata)
            }

            else -> throw RecordMapperException(
                message = "Unsupported valuePattern '$rootValuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }
    }

    /**
     * TODO: add documentation
     */
    internal fun requireUnit(unit: String?, recordKind: String): String =
        unit ?: throw RecordMapperException(
            message = "Missing required unit",
            fieldName = "unit",
            recordKind = recordKind
        )

    /**
     * Ensures that the value is a valid label value and returns as String.
     *
     * @param value The value to check
     * @param valuePattern The value pattern to check
     * @param recordKind For logging/exception context
     * @return The label value as String
     * @throws RecordMapperException if the value pattern is incompatible
     */
    fun expectLabelValue(value: Any, valuePattern: String, recordKind: String): String {
        if (valuePattern != CKConstants.VALUE_PATTERN_LABEL) {
            throw RecordMapperException(
                message = "Expected valuePattern '${CKConstants.VALUE_PATTERN_LABEL}', got '$valuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }

        val labelValue =  value as? String ?: throw RecordMapperException(
            message = "Invalid label value: expected String, got '${value::class.simpleName}'",
            recordKind = recordKind,
            fieldName = "value"
        )

        return labelValue
    }

    /**
     * Ensures that the value is a valid quantity value and returns as Double.
     *
     * @param value The value to check
     * @param valuePattern The value pattern to check
     * @param recordKind For logging/exception context
     * @return The numeric value as Double
     * @throws RecordMapperException if the value pattern is incompatible
     */
    fun expectQuantityValue(value: Any, valuePattern: String, recordKind: String): Double {
        if (valuePattern != CKConstants.VALUE_PATTERN_QUANTITY) {
            throw RecordMapperException(
                message = "Expected valuePattern '${CKConstants.VALUE_PATTERN_QUANTITY}', got '$valuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }

        val quantityDouble = when (value) {
            is Double -> value
            is Float -> value.toDouble()
            is Long -> value.toDouble()
            is Int -> value.toDouble()
            else -> throw RecordMapperException(
                message = "Invalid quantity value: expected numeric type, got '${value::class.simpleName}'",
                recordKind = recordKind,
                fieldName = "value"
            )
        }
        return quantityDouble
    }

    /**
     * Ensures that the value is a valid category value and returns as Map.
     *
     * @param dataMap The data map containing the category name
     * @param value The value to check
     * @param valuePattern The value pattern to check
     * @param recordKind For logging/exception context
     * @return The category value as Map
     * @throws RecordMapperException if the value pattern is incompatible
     */
    fun expectCategoryValue(dataMap: Map<String, Any>, value: Any, valuePattern: String, recordKind: String): Map<String, Any> {
        if (valuePattern != CKConstants.VALUE_PATTERN_CATEGORY) {
            throw RecordMapperException(
                message = "Expected valuePattern '${CKConstants.VALUE_PATTERN_CATEGORY}', got '$valuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }

        val categoryValue = value as? String ?: throw RecordMapperException(
            message = "Invalid category value: expected String, got '${value::class.simpleName}'",
            recordKind = recordKind,
            fieldName = "value"
        )

        val rawCategory = dataMap["categoryName"]
        val rawType = rawCategory?.let { it::class.simpleName } ?: "null"
        val categoryName = rawCategory as? String ?: throw RecordMapperException(
            message = "Invalid categoryName for value: expected String, got '$rawType'",
            recordKind = recordKind,
            fieldName = "categoryName"
        )

        val categoryMap = mapOf(
            "value" to categoryValue,
            "categoryName" to categoryName
        )

        return categoryMap
    }

    /**
     * Represents a raw time-series sample received from Dart.
     *
     * - [value]: numeric measurement (e.g., heart rate in bpm, speed in m/s)
     * - [timeMillis]: absolute time in epoch milliseconds (from Dart's `time.inMilliseconds`)
     *
     * This is a **temporary parsing structure** — do not expose outside 
     */
    data class DataSample(
        val value: Double,
        val timeMillis: Long
    )

    /**
     * Parses a list of sample maps from Dart into a list of [DataSample].
     *
     * Each sample map must contain:
     * - "value": a numeric value (int or double)
     * - "time": an integer representing epoch milliseconds
     *
     * @param value The raw value from Dart (must be List<*>)
     * @param valuePattern Must be [CKConstants.VALUE_PATTERN_SAMPLES]
     * @param recordKind Used for error context
     * @return Non-empty list of [DataSample], or throws if invalid
     * @throws RecordMapperException if structure is invalid
     */
    fun expectSamplesValue(
        value: Any,
        valuePattern: String,
        recordKind: String
    ): List<DataSample> {
        if (valuePattern != CKConstants.VALUE_PATTERN_SAMPLES) {
            throw RecordMapperException(
                message = "Expected valuePattern '${CKConstants.VALUE_PATTERN_SAMPLES}', got '$valuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }

        val sampleList = value as? List<Map<String, Any>> ?: throw RecordMapperException(
            message = "Invalid samples value: expected List<Map<String, Any>>, got '${value::class.simpleName}'",
            recordKind = recordKind,
            fieldName = "value"
        )

        if (sampleList.isEmpty()) {
            throw RecordMapperException(
                message = "Sample list cannot be empty",
                recordKind = recordKind,
                fieldName = "value"
            )
        }

        return sampleList.map { item ->
            val map = item as? Map<*, *> ?: throw RecordMapperException(
                message = "Sample must be a Map, got ${item?.javaClass?.simpleName ?: "null"}",
                recordKind = recordKind
            )

            val rawValue = map["value"]
            val rawTime = map["time"]

            if (rawValue !is Number) {
                throw RecordMapperException(
                    message = "Sample 'value' must be numeric, got ${rawValue?.javaClass?.simpleName}",
                    recordKind = recordKind
                )
            }
            if (rawTime !is Number) {
                throw RecordMapperException(
                    message = "Sample 'time' must be numeric (epoch ms), got ${rawTime?.javaClass?.simpleName}",
                    recordKind = recordKind
                )
            }

            DataSample(
                value = rawValue.toDouble(),
                timeMillis = rawTime.toLong()
            )
        }
    }

    // === Unit Conversion ===

    /**
     * Converts value to Power based on unit string.
     */
    fun convertToPower(value: Double, unit: String?, recordKind: String): Power {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "w", "watt", "watts" -> Power.watts(value)
            "kcal/day", "kilocalories/day" -> Power.kilocaloriesPerDay(value)
            else -> {
                CKLogger.e(tag = TAG, message = "Unknown power unit '$safeUnit'")
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown power unit '$safeUnit'. Supported: watts, kilowatts, kcal/day",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Length based on unit string.
     */
    fun convertToLength(value: Double, unit: String?, recordKind: String): Length {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "m", "meter", "meters" -> Length.meters(value)
            "km", "kilometer", "kilometers" -> Length.kilometers(value)
            "mi", "mile", "miles" -> Length.miles(value)
            "ft", "foot", "feet" -> Length.feet(value)
            "in", "inch", "inches" -> Length.inches(value)
            else -> {
                CKLogger.e(
                    tag = TAG,
                    message = "Unknown length unit '$safeUnit' - rejecting write"
                )
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown length unit '$safeUnit'. Supported units: m, km, mi, ft, in",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Mass based on unit string.
     */
    fun convertToMass(value: Double, unit: String?, recordKind: String): Mass {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "kg", "kilogram", "kilograms" -> Mass.kilograms(value)
            "g", "gram", "grams" -> Mass.grams(value)
            "mg", "milligram", "milligrams" -> Mass.milligrams(value)
            "mcg", "microgram", "micrograms", "μg" -> Mass.micrograms(value)
            "lb", "pound", "pounds" -> Mass.pounds(value)
            "oz", "ounce", "ounces" -> Mass.ounces(value)
            else -> {
                CKLogger.e(
                    tag = TAG,
                    message = "Unknown mass unit '$safeUnit' - rejecting write"
                )
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown mass unit '$safeUnit'. Supported units: kg, g, mg, mcg/μg, lb, oz",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Temperature based on unit string.
     */
    fun convertToTemperature(value: Double, unit: String?, recordKind: String): Temperature {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "c", "celsius" -> Temperature.celsius(value)
            "f", "fahrenheit" -> Temperature.fahrenheit(value)
            else -> {
                CKLogger.e(tag = TAG, message = "Unknown temperature unit '$safeUnit'")
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown temperature unit '$safeUnit'. Supported: celsius, fahrenheit",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Temperature based on unit string.
     */
    fun convertToTemperatureDelta(value: Double, unit: String?, recordKind: String): TemperatureDelta {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "c", "celsius" -> TemperatureDelta.celsius(value)
            "f", "fahrenheit" -> TemperatureDelta.fahrenheit(value)
            else -> {
                CKLogger.e(tag = TAG, message = "Unknown temperature delta unit '$safeUnit'")
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown temperature delta unit '$safeUnit'. Supported: celsius, fahrenheit",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Blood Glucose based on unit string.
     */
    fun convertToBloodGlucoseLevel(value: Double, unit: String?, recordKind: String): BloodGlucose {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "mmol/l", "mmol", "millimolesperliter" -> BloodGlucose.millimolesPerLiter(value)
            "mg/dl", "mgdl", "milligramsperdeciliter" -> BloodGlucose.milligramsPerDeciliter(value)
            else -> {
                CKLogger.e(tag = TAG, message = "Unknown blood glucose unit '$safeUnit'")
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown blood glucose unit '$safeUnit'. Supported: mmol/L, mg/dL",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Energy based on unit string.
     */
    fun convertToEnergy(value: Double, unit: String?, recordKind: String): Energy {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "kcal", "kilocalorie", "kilocalories" -> Energy.kilocalories(value)
            "kj", "kilojoule", "kilojoules" -> Energy.kilojoules(value)
            "cal", "calorie", "calories" -> Energy.calories(value)
            else -> {
                CKLogger.e(
                    tag = TAG,
                    message = "Unknown energy unit '$safeUnit' - rejecting write"
                )
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown energy unit '$safeUnit'. Supported units: kcal, kj, cal",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Volume based on unit string.
     */
    fun convertToVolume(value: Double, unit: String?, recordKind: String): Volume {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "l", "liter", "liters" -> Volume.liters(value)
            "ml", "milliliter", "milliliters" -> Volume.milliliters(value)
            "fl oz", "fluidounce", "fluidounces" -> Volume.fluidOuncesUs(value)
            else -> {
                CKLogger.e(
                    tag = TAG,
                    message = "Unknown volume unit '$safeUnit' - rejecting write"
                )
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown volume unit '$safeUnit'. Supported units: l, ml, fl oz",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts a numeric value to a Velocity instance based on the given unit string.
     *
     * Supported units (case-insensitive):
     * - "m/s", "meterspersecond", "meters/second" → metersPerSecond
     * - "km/h", "kmh", "kilometersperhour", "kilometers/hour" → kilometersPerHour
     * - "mph", "milesperhour", "miles/hour" → milesPerHour
     *
     * @param value Numeric value of the velocity
     * @param unit Unit string, expected to match one of the supported units
     * @param recordKind For logging / exception context
     * @return Velocity instance
     * @throws RecordMapperException If unit is unknown
     */
    fun convertToVelocity(value: Double, unit: String?, recordKind: String): Velocity {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase().replace("\\s".toRegex(), "")) {
            "m/s", "meterspersecond", "meters/second" -> Velocity.metersPerSecond(value)
            "km/h", "kmh", "kilometersperhour", "kilometers/hour" -> Velocity.kilometersPerHour(value)
            "mph", "milesperhour", "miles/hour" -> Velocity.milesPerHour(value)
            else -> {
                CKLogger.e(
                    tag = TAG,
                    message = "Unknown velocity unit '$safeUnit' - rejecting write"
                )
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown velocity unit '$safeUnit'. Supported units: m/s, km/h, mph",
                    recordKind = recordKind
                )
            }
        }
    }

    /**
     * Converts value to Pressure based on unit string.
     */
    fun convertToPressure(value: Double, unit: String?, recordKind: String): Pressure {
        val safeUnit = requireUnit(unit, recordKind)
        return when (safeUnit.lowercase()) {
            "mmhg", "millimeterofmercury" -> Pressure.millimetersOfMercury(value)
            else -> {
                CKLogger.e(
                    tag = TAG,
                    message = "Unknown pressure unit '$safeUnit' - rejecting write"
                )
                throw RecordMapperException.invalidFieldValue(
                    fieldName = "unit",
                    reason = "Unknown pressure unit '$safeUnit'. Supported units: mmHg",
                    recordKind = recordKind
                )
            }
        }
    }

    // === Metadata Handling ===

    /**
     * Builds Health Connect Metadata from source map.
     *
     * @param sourceMap The 'source' field from Dart record
     * @return Health Connect Metadata object
     */
    fun buildMetadata(sourceMap: Map<String, Any>?): Metadata {
        // Default to unknown if no source provided
        if (sourceMap == null) {
            CKLogger.w(tag = TAG, message = "No source provided, using unknown recording method")
            return Metadata.unknownRecordingMethod()
        }

        val recordingMethodString = sourceMap["recordingMethod"] as? String
        val recordingMethod = mapRecordingMethod(recordingMethodString ?: "unknown")

        val sdkRecordId = sourceMap["sdkRecordId"] as? String
        val sdkRecordVersion = (sourceMap["sdkRecordVersion"] as? Number)?.toLong() ?: 0L

        val deviceMap = sourceMap["device"] as? Map<String, Any>
        val device = deviceMap?.let { buildDevice(it) }

        // Build metadata using factory methods
        return when (recordingMethod) {
            Metadata.RECORDING_METHOD_MANUAL_ENTRY -> {
                if (sdkRecordId != null) {
                    Metadata.manualEntry(sdkRecordId, sdkRecordVersion, device)
                } else {
                    Metadata.manualEntry(device) // Overload without clientRecordId
                }
            }

            Metadata.RECORDING_METHOD_ACTIVELY_RECORDED -> {
                if (device != null) {
                    if (sdkRecordId != null) {
                        Metadata.activelyRecorded(device, sdkRecordId, sdkRecordVersion)
                    } else {
                        Metadata.activelyRecorded(device) // Overload without clientRecordId
                    }
                } else {
                    CKLogger.w(
                        tag = TAG,
                        message = "Actively recorded data requires device, falling back to unknown"
                    )
                    if (sdkRecordId != null) {
                        Metadata.unknownRecordingMethod(sdkRecordId, sdkRecordVersion)
                    } else {
                        Metadata.unknownRecordingMethod()
                    }
                }
            }

            Metadata.RECORDING_METHOD_AUTOMATICALLY_RECORDED -> {
                if (device != null) {
                    if (sdkRecordId != null) {
                        Metadata.autoRecorded(device, sdkRecordId, sdkRecordVersion)
                    } else {
                        Metadata.autoRecorded(device) // Overload without clientRecordId
                    }
                } else {
                    CKLogger.w(
                        tag = TAG,
                        message = "Automatically recorded data requires device, falling back to unknown"
                    )
                    if (sdkRecordId != null) {
                        Metadata.unknownRecordingMethod(sdkRecordId, sdkRecordVersion)
                    } else {
                        Metadata.unknownRecordingMethod()
                    }
                }
            }

            else -> {
                if (sdkRecordId != null) {
                    Metadata.unknownRecordingMethod(sdkRecordId, sdkRecordVersion, device)
                } else {
                    Metadata.unknownRecordingMethod(device)
                }
            }
        }
    }

    /**
     * Maps recording method string to Health Connect constant.
     */
    fun mapRecordingMethod(method: String): Int {
        return when (method.lowercase()) {
            "manualentry" -> Metadata.RECORDING_METHOD_MANUAL_ENTRY
            "activelyrecorded" -> Metadata.RECORDING_METHOD_ACTIVELY_RECORDED
            "automaticallyrecorded" -> Metadata.RECORDING_METHOD_AUTOMATICALLY_RECORDED
            "unknown" -> Metadata.RECORDING_METHOD_UNKNOWN
            else -> {
                CKLogger.w(
                    tag = TAG,
                    message = "Unknown recording method '$method', using UNKNOWN"
                )
                Metadata.RECORDING_METHOD_UNKNOWN
            }
        }
    }

    /**
     * Builds Health Connect Device from device map.
     */
    fun buildDevice(deviceMap: Map<String, Any>): Device {
        val manufacturer = deviceMap["manufacturer"] as? String
        val model = deviceMap["model"] as? String
        val typeString = deviceMap["type"] as? String ?: "unknown"
        val type = mapDeviceType(typeString)

        return Device(
            manufacturer = manufacturer,
            model = model,
            type = type
        )
    }

    /**
     * Maps device type string to Health Connect constant.
     */
    fun mapDeviceType(type: String): Int {
        return when (type.lowercase()) {
            "phone" -> Device.TYPE_PHONE
            "watch" -> Device.TYPE_WATCH
            "scale" -> Device.TYPE_SCALE
            "ring" -> Device.TYPE_RING
            "cheststrap" -> Device.TYPE_CHEST_STRAP
            "fitnessband" -> Device.TYPE_FITNESS_BAND
            "headmounted" -> Device.TYPE_HEAD_MOUNTED
            "unknown" -> Device.TYPE_UNKNOWN
            else -> {
                CKLogger.w(
                    tag = TAG,
                    message = "Unknown device type '$type', using UNKNOWN"
                )
                Device.TYPE_UNKNOWN
            }
        }
    }

    // === Validation Helpers ===

    /**
     * Validates that end time is not before start time.
     * @throws RecordMapperException if validation fails
     */
    fun validateTimeOrder(
        startTime: Instant,
        endTime: Instant,
        recordKind: String
    ) {
        if (endTime.isBefore(startTime)) {
            throw RecordMapperException(
                message = "End time ($endTime) cannot be before start time ($startTime)",
                recordKind = recordKind
            )
        }
    }
}

