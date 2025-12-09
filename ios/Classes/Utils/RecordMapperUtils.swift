import Foundation
import HealthKit

/// Common utility functions for all record mappers.
///
/// Provides reusable extraction and conversion methods to minimize code duplication
/// across specialized record mappers. All methods follow a consistent error handling
/// pattern using RecordMapperException.
///
/// **Design Principles**:
/// - Fail fast with clear error messages
/// - Type-safe extraction with proper validation
/// - Consistent null handling
/// - Need-driven approach: methods added only when actual needs are discovered
///
/// **Need-Driven Development**:
/// This class starts empty and will be populated incrementally during mapper implementation.
/// When duplicate code patterns emerge in mappers, corresponding utility methods will be added
/// here by researching the Android equivalent and implementing identical logic.
public class RecordMapperUtils {

    private static let TAG = "RecordMapperUtils"

    // MARK: - Required Field Extraction

    /// Extracts a required string field from the map.
    /// - Throws: RecordMapperException if field is missing or not a String
    public static func getRequiredString(
        _ map: [String: Any],
        key: String,
        recordKind: String
    ) throws -> String {
        guard let value = map[key] else {
            throw RecordMapperException.missingField(fieldName: key, recordKind: recordKind)
        }

        guard let stringValue = value as? String else {
            throw RecordMapperException.invalidFieldType(
                fieldName: key,
                expectedType: "String",
                actualValue: value,
                recordKind: recordKind
            )
        }

        return stringValue
    }

    /// Extracts a required nested map.
    /// - Throws: RecordMapperException if field is missing or not a Map
    public static func getRequiredMap(
        _ map: [String: Any],
        key: String,
        recordKind: String
    ) throws -> [String: Any] {
        guard let value = map[key] else {
            throw RecordMapperException.missingField(fieldName: key, recordKind: recordKind)
        }

        guard let mapValue = value as? [String: Any] else {
            throw RecordMapperException.invalidFieldType(
                fieldName: key,
                expectedType: "Map",
                actualValue: value,
                recordKind: recordKind
            )
        }

        return mapValue
    }

    // MARK: - Optional Field Extraction

    /// Extracts an optional nested map.
    public static func getOptionalMap(_ map: [String: Any], key: String) -> [String: Any]? {
        return map[key] as? [String: Any]
    }

    /// Extracts an optional integer field.
    public static func getOptionalInt(_ map: [String: Any], key: String) -> Int? {
        if let intValue = map[key] as? Int {
            return intValue
        } else if let doubleValue = map[key] as? Double {
            return Int(doubleValue)
        }
        return nil
    }

    /// Extracts a required integer field from the map.
    /// - Throws: RecordMapperException if field is missing or not a Number
    public static func getRequiredInt(
        _ map: [String: Any],
        key: String,
        recordKind: String
    ) throws -> Int {
        guard let value = map[key] else {
            throw RecordMapperException.missingField(fieldName: key, recordKind: recordKind)
        }

        if let intValue = value as? Int {
            return intValue
        } else if let doubleValue = value as? Double {
            return Int(doubleValue)
        }

        throw RecordMapperException.invalidFieldType(
            fieldName: key,
            expectedType: "Int",
            actualValue: value,
            recordKind: recordKind
        )
    }

    // MARK: - Time Handling

    /// Parses milliseconds-since-epoch timestamp to Date.
    public static func parseInstant(
        _ timestampMs: Int,
        fieldName: String,
        recordKind: String
    ) throws -> Date {
        return Date(timeIntervalSince1970: Double(timestampMs) / 1000.0)
    }

    /**
     Extracts start and end times from the workout map.
     Validates that end time is not before start time.
     */
    public static func extractTimeRange(
        from map: [String: Any],
        recordKind: String
    ) throws -> (start: Date, end: Date) {
        let startTimeMs = try getRequiredInt(
            map, key: "startTime", recordKind: recordKind)
        let endTimeMs = try getRequiredInt(
            map, key: "endTime", recordKind: recordKind)

        let startTime = try parseInstant(
            startTimeMs, fieldName: "startTime", recordKind: recordKind)

        let endTime = try parseInstant(
            endTimeMs, fieldName: "endTime", recordKind: recordKind)

        try validateTimeOrder(
            startTime: startTime, endTime: endTime, recordKind: recordKind)

        return (startTime, endTime)
    }

    /// Validates that end time is not before start time.
    /// - Throws: RecordMapperException if validation fails
    public static func validateTimeOrder(
        startTime: Date,
        endTime: Date,
        recordKind: String
    ) throws {
        if endTime < startTime {
            throw RecordMapperException(
                message: "End time (\(endTime)) cannot be before start time (\(startTime))",
                recordKind: recordKind
            )
        }
    }

    // MARK: - Unit Parsing

    /// Parses a unit string into an HKUnit object.
    ///
    /// Supports common health data units used in ConnectKit.
    ///
    /// - Parameter unitString: The unit string to parse (e.g., "count", "kg", "bpm")
    /// - Returns: Corresponding HKUnit object
    /// - Throws: RecordMapperException if unit string is not supported
    public static func parseUnit(_ unitString: String) throws -> HKUnit {
        let normalized = unitString.lowercased().replacingOccurrences(of: " ", with: "")

        switch normalized {
        // Count units
        case "count":
            return HKUnit.count()
        case "percent", "%":
            return HKUnit.percent()

        // Mass units
        case "kg", "kilogram", "kilograms":
            return HKUnit.gramUnit(with: .kilo)
        case "g", "gram", "grams":
            return HKUnit.gram()
        case "mg", "milligram", "milligrams":
            return HKUnit.gramUnit(with: .milli)
        case "mcg", "ug", "microgram", "micrograms", "μg":
            return HKUnit.gramUnit(with: .micro)
        case "lb", "pound", "pounds":
            return HKUnit.pound()
        case "oz", "ounce", "ounces":
            return HKUnit.ounce()

        // Length units
        case "m", "meter", "meters":
            return HKUnit.meter()
        case "cm", "centimeter", "centimeters":
            return HKUnit.meterUnit(with: .centi)
        case "mm", "millimeter", "millimeters":
            return HKUnit.meterUnit(with: .milli)
        case "km", "kilometer", "kilometers":
            return HKUnit.meterUnit(with: .kilo)
        case "in", "inch", "inches":
            return HKUnit.inch()
        case "ft", "foot", "feet":
            return HKUnit.foot()
        case "mi", "mile", "miles":
            return HKUnit.mile()

        // Volume units
        case "l", "liter", "liters":
            return HKUnit.liter()
        case "ml", "milliliter", "milliliters":
            return HKUnit.literUnit(with: .milli)
        case "floz", "fluidounce", "fl.oz":
            return HKUnit.fluidOunceUS()

        // Energy units
        case "kcal", "kilocalorie", "kilocalories":
            return HKUnit.kilocalorie()
        case "cal", "calorie", "calories":
            return HKUnit.calorie()
        case "j", "joule", "joules":
            return HKUnit.joule()
        case "kj", "kilojoule", "kilojoules":
            return HKUnit.jouleUnit(with: .kilo)

        // Temperature units
        case "c", "celsius", "°c":
            return HKUnit.degreeCelsius()
        case "f", "fahrenheit", "°f":
            return HKUnit.degreeFahrenheit()

        // Pressure units
        case "mmhg", "millimeterofmercury":
            return HKUnit.millimeterOfMercury()
        case "db(a)", "dba":
            return HKUnit.decibelAWeightedSoundPressureLevel()

        // Blood glucose units
        case "mg/dl", "mgdl", "milligramsperdeciliter":
            return HKUnit(from: "mg/dL")
        case "mmol/l", "mmol", "millimolesperliter":
            return HKUnit(from: "mmol/L")

        // Frequency units
        case "hz":
            return HKUnit.hertz()

        // Power units
        case "w", "watt", "watts":
            if #available(iOS 16.0, *) {
                return HKUnit.watt()
            } else {
                return HKUnit.joule().unitDivided(by: HKUnit.second())
            }
        case "kcal/day", "kilocalories/day":
            return HKUnit.kilocalorie().unitDivided(by: HKUnit.day())

        // Time units
        case "s", "second":
            return HKUnit.second()
        case "ms", "millisecond":
            return HKUnit.secondUnit(with: .milli)
        case "min", "minute":
            return HKUnit.minute()
        case "h", "hour":
            return HKUnit.hour()

        // Speed units
        case "m/s", "meterspersecond", "meters/second":
            return HKUnit.meter().unitDivided(by: HKUnit.second())
        case "km/h", "kmh", "kilometersperhour", "kilometers/hour":
            return HKUnit.meterUnit(with: .kilo).unitDivided(by: HKUnit.hour())
        case "mph", "milesperhour", "miles/hour":
            return HKUnit.mile().unitDivided(by: HKUnit.hour())

        // Other Compound units
        case "bpm", "beats/min":
            return HKUnit.count().unitDivided(by: HKUnit.minute())

        default:
            throw RecordMapperException(
                message: "Unsupported unit '\(unitString)'",
                recordKind: "data",
                fieldName: "unit"
            )
        }
    }

    // MARK: - Metadata Handling

    /// Creates HKDevice from source map (iOS 9+).
    ///
    /// - Parameter sourceMap: The 'source' field from Dart record
    /// - Returns: HKDevice instance or nil
    public static func createHKDevice(from map: [String: Any]) -> HKDevice? {
        guard #available(iOS 9.0, *) else { return nil }

        guard let source = map["source"] as? [String: Any],
            let deviceMap = source["device"] as? [String: Any]
        else {
            return nil
        }

        let manufacturer = deviceMap["manufacturer"] as? String
        let model = deviceMap["model"] as? String
        let hardwareVersion = deviceMap["hardwareVersion"] as? String
        let softwareVersion = deviceMap["softwareVersion"] as? String

        return HKDevice(
            name: model,
            manufacturer: manufacturer,
            model: model,
            hardwareVersion: hardwareVersion,
            firmwareVersion: nil,
            softwareVersion: softwareVersion,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    /**
     Creates metadata dictionary with common fields and optional custom steps.
    
     **Workflow:**
     1. Source metadata (recording method, device, sync IDs)
     2. Timezone metadata
     3. **Extra Steps** (Caller-provided logic)
     4. Custom Dart metadata (with ck_ prefix)
     
     - Parameters:
        - map: The record map from Dart
        - extraSteps: Optional closure to inject specific metadata before step 4
     - Returns: Completed metadata dictionary
     */
    public static func createMetadata(
        from map: [String: Any],
        extraSteps: ((inout [String: Any]) -> Void)? = nil
    ) -> [String: Any] {
        var metadata: [String: Any] = [:]

        // === 1. Source Metadata ===
        // --------------------------------------------------------------
        if let sourceMap = map["source"] as? [String: Any] {

            if let appRecordUUID = sourceMap["appRecordUUID"] as? String {
                metadata[HKMetadataKeyExternalUUID] = appRecordUUID
            }

            if let sdkRecordId = sourceMap["sdkRecordId"] as? String {
                metadata[HKMetadataKeySyncIdentifier] = sdkRecordId
            }

            if let sdkRecordVersion = sourceMap["sdkRecordVersion"] as? Int {
                metadata[HKMetadataKeySyncVersion] = sdkRecordVersion
            } else if let sdkRecordVersionDouble = sourceMap["sdkRecordVersion"] as? Double {
                metadata[HKMetadataKeySyncVersion] = Int(sdkRecordVersionDouble)
            }

            if let recordingMethod = sourceMap["recordingMethod"] as? String {
                metadata[HKMetadataKeyWasUserEntered] = (recordingMethod == "manualEntry")
                metadata["ck_recordingMethod"] = recordingMethod
            }

            // But kept here for general purpose usage by other mappers if needed
             if #unavailable(iOS 9.0) {
                if let deviceMap = sourceMap["device"] as? [String: Any] {
                    if let manufacturer = deviceMap["manufacturer"] as? String {
                        metadata[HKMetadataKeyDeviceManufacturerName] = manufacturer
                    }
                    if let model = deviceMap["model"] as? String {
                        metadata[HKMetadataKeyDeviceName] = model
                    }
                }
            }
        }

        // === 2. Timezone metadata ===
        // --------------------------------------------------------------
        if let zoneOffset = map["zoneOffsetSeconds"] as? Int {
            if let tz = TimeZone(secondsFromGMT: zoneOffset) {
                metadata[HKMetadataKeyTimeZone] = tz.identifier
            }
            metadata["ck_startZoneOffsetSeconds"] = zoneOffset
            metadata["ck_endZoneOffsetSeconds"] = zoneOffset  // Same for instantaneous
        }
        
        // === 3. Extra Steps (Caller Logic) ===
        // --------------------------------------------------------------
        extraSteps?(&metadata)

        // === 4. Custom Dart metadata ===
        // --------------------------------------------------------------
        if let customMetadata = map["metadata"] as? [String: Any] {
            for (customKey, customValue) in customMetadata {
                if metadata[customKey] != nil {
                    continue  // Don't override existing metadata
                }

                guard let sanitizedValue = sanitizeMetadataValue(customValue) else {
                    continue // Skip nil values
                }

                // Add with ck_ prefix if not already prefixed
                if customKey.hasPrefix("HKMetadataKey") || customKey.hasPrefix("ck_") {
                    metadata[customKey] = sanitizedValue
                } else {
                    metadata["ck_\(customKey)"] = sanitizedValue
                }
            }
        }

        return metadata
    }

    /// Sanitizes metadata values to ensure they are HealthKit compliant.
    /// HealthKit only accepts NSString, NSNumber, or NSDate as metadata values.
    /// Complex types (Arrays, Dictionaries) are converted to JSON strings.
    public static func sanitizeMetadataValue(_ value: Any) -> Any? {
        // Pass through valid types
        if value is String || value is Int || value is Double || value is Bool || value is Date {
            return value
        }

        // Handle Collections (Array, Dictionary) -> JSON String
        if value is [Any] || value is [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
            } catch {
                CKLogger.w(
                    tag: TAG,
                    message: "Failed to serialize metadata value to JSON: \(error.localizedDescription)"
                )
            }
        }

        // Fallback: String representation
        return String(describing: value)
    }    
}
