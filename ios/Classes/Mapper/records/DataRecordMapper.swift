import Foundation
import HealthKit

public class DataRecordMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    private static let TAG = CKConstants.TAG_DATA_RECORD_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_DATA_RECORD

    // MARK: - Initialization

    /**
     * Initializes DataRecordMapper with required dependencies.
     *
     * - Parameter healthStore: HealthKit store for type validation
     * - Parameter categoryMapper: Category mapper for enum conversions
     */
    public init(
        healthStore: HKHealthStore, categoryMapper: CategoryMapper.Type = CategoryMapper.self
    ) {
        self.healthStore = healthStore
        self.categoryMapper = categoryMapper
    }

    // MARK: - Public API

    /**
     Decodes a CK data record map into a HealthKit sample object.
    
     - Parameter map: The ck record map from Dart (via Pigeon)
     - Returns: Configured HKObject
     - Throws: RecordMapperException if mapping fails
     */
    public func decode(_ map: [String: Any]) throws -> [HKObject] {
        let type = try RecordMapperUtils.getRequiredString(
            map, key: "type", recordKind: Self.RECORD_KIND)

        let dataMap = try RecordMapperUtils.getRequiredMap(
            map, key: "data", recordKind: Self.RECORD_KIND)

        CKLogger.d(tag: Self.TAG, message: "Mapping data record type: '\(type)'")

        guard
            let hkObjectType = RecordTypeMapper.getObjectType(recordType: type, accessType: .write)
        else {
            throw RecordMapperException(
                message: "Type '\(type)' is not supported for write operations on iOS HealthKit",
                recordKind: Self.RECORD_KIND,
                fieldName: "type"
            )
        }

        let timeRange = try RecordMapperUtils.extractTimeRange(
            from: map, recordKind: Self.RECORD_KIND)

        let hkDevice = RecordMapperUtils.createHKDevice(from: map)

        let (mainValue, mainUnit, mainValuePattern, derivedMetadata) = try unwrapData(
            dataMap: dataMap,
            recordMap: map,
            type: type,
        )

        let metadata = createDataRecordMetadata(
            from: map,
            derivedMetadata: derivedMetadata,
            mainValue: mainValue,
            mainUnit: mainUnit,
            mainValuePattern: mainValuePattern,
            type: type,
        )

        if let quantityType = hkObjectType as? HKQuantityType {
            return try createQuantitySamples(
                type: type,
                quantityType: quantityType,
                value: mainValue,
                unit: mainUnit,
                timeRange: timeRange,
                metadata: metadata,
                device: hkDevice
            )
        } else if let categoryType = hkObjectType as? HKCategoryType {
            let sample = try createCategorySample(
                type: type,
                categoryType: categoryType,
                value: mainValue,
                timeRange: timeRange,
                metadata: metadata,
                device: hkDevice
            )
            return [sample]
        } else {
            throw RecordMapperException(
                message: "Unsupported HKObjectType: \(String(describing: hkObjectType))",
                recordKind: Self.RECORD_KIND,
                fieldName: "type"
            )
        }
    }

    // MARK: - Private Helpers

    /**
     Unwraps the incoming `data` dictionary into:
       - unit (String?)
       - main value (Any) - Double, String, Array, or Map depending on pattern
       - main valuePattern (String)
       - customMetadata dictionary (non-main fields mapped to simple values, NOT prefixed with ck_ yet)
     Rules implemented here:
       - For MULTIPLE: `metadata["mainProperty"]` (from fullMap["metadata"]) is REQUIRED and authoritative.
       - For MULTIPLE non-main properties: collect into customMetadata (strings/doubles/arrays)
         and DO NOT apply `ck_` prefix here (prefixing happens in createMetadata).
       - Category-specific behavior for non-main fields uses METADATA_MAP if available (transform & put into processedMetadata later).
     */
    private func unwrapData(
        dataMap: [String: Any],
        recordMap: [String: Any],
        type: String,
        unwrapMultiple: Bool = true
    ) throws -> (value: Any, unit: String?, valuePattern: String, derivedMetadata: [String: Any]) {

        let rootValuePattern = try RecordMapperUtils.getRequiredString(
            dataMap, key: "valuePattern", recordKind: Self.RECORD_KIND)
        let rootValue = dataMap["value"]
        let rootUnit = dataMap["unit"] as? String

        // -------------- QUANTITY / CATEGORY / SAMPLES follow unchanged patterns --------------
        switch rootValuePattern {
        case CKConstants.VALUE_PATTERN_QUANTITY:
            guard let quantityDouble = rootValue as? Double else {
                throw RecordMapperException(
                    message:
                        "Invalid quantity value: expected Double, got \(String(describing: rootValue))",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "value"
                )
            }
            return (quantityDouble, rootUnit, rootValuePattern, [:])

        case CKConstants.VALUE_PATTERN_CATEGORY:
            guard let categoryValue = rootValue as? String else {
                throw RecordMapperException(
                    message:
                        "Invalid category value: expected String, got '\(String(describing: rootValue))'",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "value"
                )
            }
            guard let categoryName = dataMap["categoryName"] as? String else {
                throw RecordMapperException(
                    message:
                        "Invalid categoryName for value: expected String, got '\(String(describing: rootValue))'",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "categoryName"
                )
            }
            let categoryMap = [
                "value": categoryValue,
                "categoryName": categoryName,
            ]
            return (categoryMap, rootUnit, rootValuePattern, [:])

        case CKConstants.VALUE_PATTERN_SAMPLES:
            guard let samplesArray = rootValue as? [[String: Any]] else {
                throw RecordMapperException(
                    message: "Invalid samples value: expected Array, got '\(String(describing: rootValue))'",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "value"
                )
            }
            return (samplesArray, rootUnit, rootValuePattern, [:])

        case CKConstants.VALUE_PATTERN_LABEL:
            guard let labelValue = rootValue as? String else {
                throw RecordMapperException(
                    message: "Invalid label value: expected String, got '\(String(describing: rootValue))'",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "value"
                )
            }
            return (labelValue, rootUnit, rootValuePattern, [:])

        case CKConstants.VALUE_PATTERN_MULTIPLE where unwrapMultiple:
            guard let multipleMap = rootValue as? [String: Any] else {
                throw RecordMapperException(
                    message: "Invalid multiple value: expected Map, got '\(String(describing: rootValue))'",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "value"
                )
            }

            guard let customMetadata = recordMap["metadata"] as? [String: Any],
                let mainPropertyKey = customMetadata["mainProperty"] as? String,
                !mainPropertyKey.isEmpty
            else {
                throw RecordMapperException(
                    message:
                        "Missing required 'mainProperty' in record metadata for MULTIPLE value",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "metadata.mainProperty"
                )
            }

            guard let mainPropertyMap = multipleMap[mainPropertyKey] as? [String: Any] else {
                throw RecordMapperException(
                    message: "Main property '\(mainPropertyKey)' not found in MULTIPLE value",
                    recordKind: Self.RECORD_KIND,
                    fieldName: mainPropertyKey
                )
            }

            // Note: no inner multiple unwrap, then ignore the innerMainMetadata
            let (mainValue, mainUnit, mainValuePattern, innerMainMetadata) = try unwrapData(
                dataMap: mainPropertyMap,
                recordMap: recordMap,
                type: type,
                unwrapMultiple: false  // Prevent nested MULTIPLE unwrapping
            )

            // Collect non-main properties into customMetadata for later processing
            var derivedMetadata: [String: Any] = [:]

            // Process all non-main properties
            for (propKey, propRaw) in multipleMap {
                if propKey == mainPropertyKey { continue }  // Skip main property

                guard let propMap = propRaw as? [String: Any] else {
                    CKLogger.w(
                        tag: Self.TAG,
                        message: "MULTIPLE property '\(propKey)' is not a map, skipping")
                    continue
                }

                // Note: no inner multiple unwrap, then ignore the innerPropMetadata
                let (propValue, propUnit, propValuePattern, innerPropMetadata) = try unwrapData(
                    dataMap: propMap,
                    recordMap: recordMap,
                    type: type,
                    unwrapMultiple: false  // Prevent nested MULTIPLE unwrapping
                )

                derivedMetadata[propKey] = [
                    "value": propValue, "unit": propUnit as Any, "valuePattern": propValuePattern,
                ]
            }

            return (mainValue as Any, mainUnit, mainValuePattern, derivedMetadata)

        default:
            throw RecordMapperException(
                message: "Unsupported valuePattern '\(rootValuePattern)'",
                recordKind: Self.RECORD_KIND,
                fieldName: "valuePattern"
            )
        }
    }

    /**
     Creates the final metadata dictionary for HKSample.
     Merge order:
       1) data derived metadata - build from source, HKMetadata handlers, and non-main properties
       2) dart metadata - provided directly by the dart record (merged, but doesn't override)
     */
    private func createDataRecordMetadata(
        from map: [String: Any],
        derivedMetadata: [String: Any],
        mainValue: Any,
        mainUnit: String?,
        mainValuePattern: String,
        type: String,
    ) -> [String: Any] {
        return RecordMapperUtils.createMetadata(from: map) { metadata in

            // === 3. Derived metadata (from MULTIPLE non-main properties) ===
            // --------------------------------------------------------------
            for (propKey, propRawValue) in derivedMetadata {
                guard let propDict = propRawValue as? [String: Any] else {
                    continue
                }
                let propValue = propDict["value"] as Any

                if let hkKey = self.tryMapToHKMetadata(propertyKey: propKey, value: propValue, type: type) {
                    if let transformed = hkKey.value {
                        metadata[hkKey.key] = transformed
                    }
                }
                // propDict (as defined in unwrapData)
                //   value: dict for category, array for samples, double for quantity, string for label
                //   unit: optional string
                //   valuePattern: string
                guard let sanitizedValue = RecordMapperUtils.sanitizeMetadataValue(propDict) else {
                    continue // Skip nil values
                }
                metadata["ck_\(propKey)"] = sanitizedValue
            }

            // === 4. Main value metadata (categoryName, unit) ===
            // --------------------------------------------------------------
            if mainValuePattern == CKConstants.VALUE_PATTERN_CATEGORY {
                if let categoryMap = mainValue as? [String: Any],
                    let categoryName = categoryMap["categoryName"] as? String
                {
                    metadata["ck_categoryName"] = categoryName
                }
            }

            if let unit = mainUnit {
                metadata["ck_unit"] = unit
            }

            metadata["ck_valuePattern"] = mainValuePattern
        }
    }

    /// Attempts to map a derived property to HK metadata key.
    /// Returns (key, transformedValue) tuple or nil if no mapping exists.
    private func tryMapToHKMetadata(
        propertyKey: String,
        value: Any,
        type: String
    ) -> (key: String, value: Any?)? {
        // Type-specific mappings
        switch type {
        case "bloodGlucose":
            switch propertyKey {
            case "mealTime":
                if let catMap = value as? [String: Any],
                    let catValue = catMap["value"] as? String,
                    let catName = catMap["categoryName"] as? String,
                    let decoded = categoryMapper.decode(categoryName: catName, value: catValue)
                {
                    return (HKMetadataKeyBloodGlucoseMealTime, NSNumber(value: decoded))
                }
            case "mealType":
                if let catMap = value as? [String: Any],
                    let catValue = catMap["value"] as? String
                {
                    return (HKMetadataKeyFoodType, catValue)
                }
            default:
                break
            }

        case "bodyTemperature", "basalBodyTemperature":
            if propertyKey == "measurementLocation" {
                if let catMap = value as? [String: Any],
                    let catValue = catMap["value"] as? String,
                    let catName = catMap["categoryName"] as? String,
                    let decoded = categoryMapper.decode(categoryName: catName, value: catValue)
                {
                    return (HKMetadataKeyBodyTemperatureSensorLocation, NSNumber(value: decoded))
                }
            }
        case "vo2Max":
            if propertyKey == "measurementMethod" {
                if let catMap = value as? [String: Any],
                    let catValue = catMap["value"] as? String,
                    let catName = catMap["categoryName"] as? String,
                    let decoded = categoryMapper.decode(categoryName: catName, value: catValue)
                {
                    return (HKMetadataKeyVO2MaxTestType, NSNumber(value: decoded))
                }
            }

        case "menstrualFlow":
            if propertyKey == "cycleStart" {
                if let boolValue = value as? Bool {
                    return (HKMetadataKeyMenstrualCycleStart, NSNumber(value: boolValue))
                }
            }

        default:
            break
        }

        return nil
    }

    // MARK: - Sample creators (quantity/category)

    private func createQuantitySamples(
        type: String,
        quantityType: HKQuantityType,
        value: Any,
        unit: String?,
        timeRange: (start: Date, end: Date),
        metadata: [String: Any],
        device: HKDevice?
    ) throws -> [HKQuantitySample] {
        guard let unitString = unit,
            let hkUnit = try? RecordMapperUtils.parseUnit(unitString)
        else {
            throw RecordMapperException(
                message: "Missing or invalid unit for quantity type '\(type)'",
                recordKind: Self.RECORD_KIND,
                fieldName: "unit"
            )
        }

        var samples: [HKQuantitySample] = []

        // Single value
        if let doubleValue = value as? Double {
            let quantity = HKQuantity(unit: hkUnit, doubleValue: doubleValue)
            let sample: HKQuantitySample
            if let device = device, #available(iOS 9.0, *) {
                sample = HKQuantitySample(
                    type: quantityType, quantity: quantity, start: timeRange.start,
                    end: timeRange.end, device: device, metadata: metadata)
            } else {
                sample = HKQuantitySample(
                    type: quantityType, quantity: quantity, start: timeRange.start,
                    end: timeRange.end, metadata: metadata)
            }

            samples.append(sample)
            return samples
        }

        // Samples array
        if let samplesArray = value as? [[String: Any]] {
            for sampleMap in samplesArray {
                guard let sampleValue = sampleMap["value"] as? Double else {
                    throw RecordMapperException(
                        message: "Invalid sample: missing 'value'",
                        recordKind: Self.RECORD_KIND,
                        fieldName: "samples.value"
                    )
                }
                guard let timeMs = sampleMap["time"] as? Int else {
                    throw RecordMapperException(
                        message: "Invalid sample: missing 'time'",
                        recordKind: Self.RECORD_KIND,
                        fieldName: "samples.time"
                    )
                }

                let sampleTime = Date(timeIntervalSince1970: Double(timeMs) / 1000.0)
                let quantity = HKQuantity(unit: hkUnit, doubleValue: sampleValue)
                let sample: HKQuantitySample
                if let device = device, #available(iOS 9.0, *) {
                    sample = HKQuantitySample(
                        type: quantityType, quantity: quantity, start: sampleTime,
                        end: sampleTime, device: device, metadata: metadata
                    )
                } else {
                    sample = HKQuantitySample(
                        type: quantityType, quantity: quantity, start: sampleTime,
                        end: sampleTime, metadata: metadata
                    )
                }

                samples.append(sample)
            }

            return samples
        }

        throw RecordMapperException(
            message: "Invalid value for quantity type: expected Double or Array",
            recordKind: Self.RECORD_KIND,
            fieldName: "value"
        )
    }

    private func createCategorySample(
        type: String,
        categoryType: HKCategoryType,
        value: Any,
        timeRange: (start: Date, end: Date),
        metadata: [String: Any],
        device: HKDevice?
    ) throws -> HKCategorySample {
        guard let categoryMap = value as? [String: Any],
            let categoryValue = categoryMap["value"] as? String,
            let categoryName = categoryMap["categoryName"] as? String
        else {
            throw RecordMapperException(
                message: "Invalid category value: expected Map with 'value' and 'categoryName'",
                recordKind: Self.RECORD_KIND,
                fieldName: "value"
            )
        }

        // Decode into the integer value that HealthKit expects
        let categoryIntValue: Int
        if type == "sexualActivity" {  // special value for this type
            categoryIntValue = (categoryValue == "protected") ? 1 : 0
        } else {
            guard
                let decoded = categoryMapper.decode(
                    categoryName: categoryName, value: categoryValue)
            else {
                throw RecordMapperException(
                    message:
                        "Invalid category value '\(categoryValue)' for category '\(categoryName)'",
                    recordKind: Self.RECORD_KIND,
                    fieldName: "value"
                )
            }
            categoryIntValue = decoded
        }

        if let device = device, #available(iOS 9.0, *) {
            return HKCategorySample(
                type: categoryType, value: categoryIntValue, start: timeRange.start,
                end: timeRange.end, device: device, metadata: metadata
            )
        } else {
            return HKCategorySample(
                type: categoryType, value: categoryIntValue, start: timeRange.start,
                end: timeRange.end, metadata: metadata
            )
        }
    }
}
