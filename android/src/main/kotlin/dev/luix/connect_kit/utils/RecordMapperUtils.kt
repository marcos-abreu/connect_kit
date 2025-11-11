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
     * Parses ISO 8601 timestamp string to Instant.
     * @throws RecordMapperException if timestamp is invalid
     */
    fun parseInstant(timestamp: String, fieldName: String, recordKind: String): Instant {
        return try {
            Instant.parse(timestamp)
        } catch (e: Exception) {
            throw RecordMapperException(
                message = "Invalid ISO 8601 timestamp: '$timestamp'",
                recordKind = recordKind,
                fieldName = fieldName,
                cause = e
            )
        }
    }

    /**
     * Parses zone offset from seconds.
     */
    fun parseZoneOffset(seconds: Int): ZoneOffset {
        return ZoneOffset.ofTotalSeconds(seconds)
    }

    // === Value & Unit Handling ===

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
     * Ensures that the value is numeric (Double/Long/Int) and returns as Double.
     *
     * @param value The value to check
     * @param valuePattern Expected value pattern
     * @param recordKind For logging/exception context
     * @return The numeric value as Double
     * @throws RecordMapperException if the value pattern is incompatible
     */
    fun expectNumericValue(value: Any, valuePattern: String, recordKind: String): Double {
        if (value !is Number) {
            throw RecordMapperException(
                message = "Expected numeric value for pattern '$valuePattern', got ${value::class.simpleName}",
                recordKind = recordKind
            )
        }
        return value.toDouble()
    }

    /**
     * Ensures that the value is a valid category (string)
     *
     * @param value The raw value from Dart
     * @param valuePattern Expected value pattern, should be "category"
     * @param recordKind For logging/exception context
     * @return String string representation of a category
     * @throws RecordMapperException if the value is not a valid category like
     */
    fun expectCategoryValue(value: Any?, valuePattern: String, recordKind: String): String {
        if (valuePattern != CKConstants.VALUE_PATTERN_CATEGORY) {
            throw RecordMapperException(
                message = "Expected valuePattern '${CKConstants.VALUE_PATTERN_CATEGORY}', got '$valuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }

        if (value !is String) {
            throw RecordMapperException(
                message = "Expected String for category value, got ${value?.javaClass?.name}",
                recordKind = recordKind,
                fieldName = "value"
            )
        }

        return value
    }

    /**
     * Represents a raw time-series sample received from Dart.
     *
     * - [value]: numeric measurement (e.g., heart rate in bpm, speed in m/s)
     * - [timeMillis]: absolute time in epoch milliseconds (from Dart's `time.inMilliseconds`)
     *
     * This is a **temporary parsing structure** — do not expose outside RecordMapperUtils.
     */
    data class RawSample(
        val value: Double,
        val timeMillis: Long
    )

    /**
     * Parses a list of sample maps from Dart into a list of [RawSample].
     *
     * Each sample map must contain:
     * - "value": a numeric value (int or double)
     * - "time": an integer representing epoch milliseconds
     *
     * @param value The raw value from Dart (must be List<*>)
     * @param valuePattern Must be [CKConstants.VALUE_PATTERN_SAMPLES]
     * @param recordKind Used for error context
     * @return Non-empty list of [RawSample], or throws if invalid
     * @throws RecordMapperException if structure is invalid
     */
    fun expectSamplesValue(
        value: Any,
        valuePattern: String,
        recordKind: String
    ): List<RawSample> {
        if (valuePattern != CKConstants.VALUE_PATTERN_SAMPLES) {
            throw RecordMapperException(
                message = "Expected valuePattern '${CKConstants.VALUE_PATTERN_SAMPLES}', got '$valuePattern'",
                recordKind = recordKind,
                fieldName = "valuePattern"
            )
        }

        val sampleList = value as? List<*> ?: throw RecordMapperException(
            message = "Expected List for samples, got ${value::class.simpleName}",
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

            RawSample(
                value = rawValue.toDouble(),
                timeMillis = rawTime.toLong()
            )
        }
    }


    /**
     * TODO: add documentation
     */
    data class FieldData(
        val value: Any,
        val unit: String?,
        val valuePattern: String
    )

    /**
     * Validates and extracts fields from a CKMultipleValue map.
     *
     * @param value The outer "value" object (must be Map<*, *>)
     * @param valuePattern Must be CKConstants.VALUE_PATTERN_MULTIPLE
     * @param type Record type, for logging
     * @param possibleFields Map of possible field names and their expected valuePatterns
     * @param recordKind For logging/exception context
     * @return Map of field name to FieldData
     * @throws RecordMapperException if structure is invalid
     */
    fun expectMultipleValue(
        value: Any,
        valuePattern: String,
        type: String,
        possibleFields: Map<String, String>,
        recordKind: String
    ): Map<String, FieldData> {
        if (valuePattern != CKConstants.VALUE_PATTERN_MULTIPLE) {
            throw RecordMapperException(
                message = "Expected '${CKConstants.VALUE_PATTERN_MULTIPLE}' valuePattern for CKMultipleValue, got '$valuePattern'",
                recordKind = recordKind,
                fieldName = type
            )
        }

        val valueMap = value as? Map<*, *> ?: throw RecordMapperException(
            message = "Expected Map for CKMultipleValue, got ${value::class.simpleName}",
            recordKind = recordKind,
            fieldName = type
        )

        val result = mutableMapOf<String, FieldData>()

        for ((key, expectedPattern) in possibleFields) {
            val fieldMap = valueMap[key] as? Map<*, *> ?: continue // optional field

            val fieldValue = fieldMap["value"]
                ?: throw RecordMapperException(
                    message = "Field '$key' missing 'value'",
                    recordKind = recordKind,
                    fieldName = type
                )
            val fieldUnit = fieldMap["unit"] as? String
            val fieldPattern = fieldMap["valuePattern"] as? String
                ?: throw RecordMapperException(
                    message = "Field '$key' missing 'valuePattern'",
                    recordKind = recordKind,
                    fieldName = type
                )

            if (fieldPattern != expectedPattern) {
                throw RecordMapperException(
                    message = "Field '$key' expected pattern '$expectedPattern', got '$fieldPattern'",
                    recordKind = recordKind,
                    fieldName = type
                )
            }

            result[key] = FieldData(
                value = fieldValue,
                unit = fieldUnit,
                valuePattern = fieldPattern
            )
        }
        return result
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
        val clientRecordId = sourceMap["clientRecordId"] as? String
        val clientRecordVersion = (sourceMap["clientRecordVersion"] as? Number)?.toLong() ?: 0L
        val deviceMap = sourceMap["device"] as? Map<String, Any>
        val device = deviceMap?.let { buildDevice(it) }

        // Build metadata using factory methods
        return when (recordingMethod) {
            Metadata.RECORDING_METHOD_MANUAL_ENTRY -> {
                if (clientRecordId != null) {
                    Metadata.manualEntry(clientRecordId, clientRecordVersion, device)
                } else {
                    Metadata.manualEntry(device) // Overload without clientRecordId
                }
            }

            Metadata.RECORDING_METHOD_ACTIVELY_RECORDED -> {
                if (device != null) {
                    if (clientRecordId != null) {
                        Metadata.activelyRecorded(device, clientRecordId, clientRecordVersion)
                    } else {
                        Metadata.activelyRecorded(device) // Overload without clientRecordId
                    }
                } else {
                    CKLogger.w(
                        tag = TAG,
                        message = "Actively recorded data requires device, falling back to unknown"
                    )
                    if (clientRecordId != null) {
                        Metadata.unknownRecordingMethod(clientRecordId, clientRecordVersion)
                    } else {
                        Metadata.unknownRecordingMethod()
                    }
                }
            }

            Metadata.RECORDING_METHOD_AUTOMATICALLY_RECORDED -> {
                if (device != null) {
                    if (clientRecordId != null) {
                        Metadata.autoRecorded(device, clientRecordId, clientRecordVersion)
                    } else {
                        Metadata.autoRecorded(device) // Overload without clientRecordId
                    }
                } else {
                    CKLogger.w(
                        tag = TAG,
                        message = "Automatically recorded data requires device, falling back to unknown"
                    )
                    if (clientRecordId != null) {
                        Metadata.unknownRecordingMethod(clientRecordId, clientRecordVersion)
                    } else {
                        Metadata.unknownRecordingMethod()
                    }
                }
            }

            else -> {
                if (clientRecordId != null) {
                    Metadata.unknownRecordingMethod(clientRecordId, clientRecordVersion, device)
                } else {
                    Metadata.unknownRecordingMethod(device)
                }
            }
        }
    }

    /**
     * Maps recording method string to Health Connect constant.
     */
    private fun mapRecordingMethod(method: String): Int {
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
    private fun buildDevice(deviceMap: Map<String, Any>): Device {
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
    private fun mapDeviceType(type: String): Int {
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

    // /**
    //  * Validates that a value is positive.
    //  * @throws RecordMapperException if value is negative or zero
    //  */
    // fun validatePositive(
    //     value: Double,
    //     fieldName: String,
    //     recordKind: String
    // ) {
    //     if (value <= 0) {
    //         throw RecordMapperException.invalidFieldValue(
    //             fieldName = fieldName,
    //             reason = "Value must be positive, got: $value",
    //             recordKind = recordKind
    //         )
    //     }
    // }

    // /**
    //  * Validates that a value is non-negative.
    //  * @throws RecordMapperException if value is negative
    //  */
    // fun validateNonNegative(
    //     value: Double,
    //     fieldName: String,
    //     recordKind: String
    // ) {
    //     if (value < 0) {
    //         throw RecordMapperException.invalidFieldValue(
    //             fieldName = fieldName,
    //             reason = "Value must be non-negative, got: $value",
    //             recordKind = recordKind
    //         )
    //     }
    // }

    // /**
    //  * Validates that a value is within a specified range.
    //  * @throws RecordMapperException if value is out of range
    //  */
    // fun validateRange(
    //     value: Double,
    //     min: Double,
    //     max: Double,
    //     fieldName: String,
    //     recordKind: String
    // ) {
    //     if (value < min || value > max) {
    //         throw RecordMapperException.invalidFieldValue(
    //             fieldName = fieldName,
    //             reason = "Value must be between $min and $max, got: $value",
    //             recordKind = recordKind
    //         )
    //     }
    // }
}
