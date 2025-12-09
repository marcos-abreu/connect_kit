import Foundation
import HealthKit

/// Maps blood pressure records between Dart representation and iOS HealthKit HKCorrelation objects.
///
/// **Architecture:**
/// Blood pressure in HealthKit is represented as an HKCorrelation containing two HKQuantitySample objects:
/// - Systolic blood pressure sample (.bloodPressureSystolic)
/// - Diastolic blood pressure sample (.bloodPressureDiastolic)
///
/// **Key Responsibilities:**
/// - Extract systolic and diastolic values from Dart map
/// - Create two separate HKQuantitySample objects
/// - Combine them into an HKCorrelation with .bloodPressure type
/// - Handle optional metadata (body position, measurement location)
/// - Map Android-specific metadata to iOS custom fields
///
/// **iOS HealthKit Specifics:**
/// - HKCorrelation groups related samples into a single entry
/// - Blood pressure correlation available since iOS 8.0
/// - Permission must be requested for .bloodPressureSystolic and .bloodPressureDiastolic
/// - Cannot request permission directly on correlation type
/// - Both samples must use the same unit and timestamp
///
/// **Platform Differences:**
/// - **iOS**: Uses HKCorrelation with two samples
/// - **Android**: Uses BloodPressureRecord with embedded systolic/diastolic values
/// - **Android-specific fields**: bodyPosition, measurementLocation (stored as custom metadata)
public class BloodPressureMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    private static let TAG = CKConstants.TAG_BLOOD_PRESSURE_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_BLOOD_PRESSURE

    // MARK: - Initialization

    /**
     * Initializes BloodPressureMapper with required dependencies.
     *
     * - Parameter healthStore: HealthKit store for type validation
     * - Parameter categoryMapper: Category mapper for enum conversions
     */
    public init(
        healthStore: HKHealthStore,
        categoryMapper: CategoryMapper.Type = CategoryMapper.self
    ) {
        self.healthStore = healthStore
        self.categoryMapper = categoryMapper
    }

    // MARK: - Public API

    /**
     Decodes a CK blood pressure record map into HealthKit HKCorrelation object.
    
     **Workflow:**
     1. Extract systolic and diastolic values (with units)
     2. Extract timestamp (blood pressure is instantaneous)
     3. Create systolic HKQuantitySample
     4. Create diastolic HKQuantitySample
     5. Combine into HKCorrelation with .bloodPressure type
     6. Add metadata (including Android-specific fields as custom metadata)
    
     - Parameter map: The blood pressure record map from Dart (via Pigeon)
     - Returns: HKCorrelation object containing systolic and diastolic samples
     - Throws: RecordMapperException if decoding fails
     */
    public func decode(_ map: [String: Any]) throws -> HKCorrelation {
        CKLogger.d(tag: Self.TAG, message: "Decoding blood pressure record")

        let timeRange = try RecordMapperUtils.extractTimeRange(
            from: map,
            recordKind: Self.RECORD_KIND
        )

        if timeRange.start != timeRange.end { // Validate it's instantaneous
            CKLogger.w(
                tag: Self.TAG,
                message:
                    "Blood pressure has different start/end times. Using start time for both."
            )
        }

        let time = timeRange.start

        let (systolicValue, systolicUnit, diastolicValue, diastolicUnit) = try unwrapData(from: map)

        let hkDevice = RecordMapperUtils.createHKDevice(from: map)

        let metadata = createBloodPressureMetadata(from: map)

        let systolicSample = try createSample(
            recordType: "bloodPressure.systolic",
            value: systolicValue,
            unit: systolicUnit,
            time: time,
            hkDevice: hkDevice,
            metadata: metadata
        )

        let diastolicSample = try createSample(
            recordType: "bloodPressure.diastolic",
            value: diastolicValue,
            unit: diastolicUnit,
            time: time,
            hkDevice: hkDevice,
            metadata: metadata
        )

        // Create correlation
        guard let correlationType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)
        else {
            throw RecordMapperException(
                message: "Failed to get blood pressure correlation type",
                recordKind: Self.RECORD_KIND
            )
        }

        let objects: Set<HKSample> = [systolicSample, diastolicSample]
        let correlation: HKCorrelation
        if let device = hkDevice, #available(iOS 9.0, *) {
            correlation = HKCorrelation(
                type: correlationType,
                start: time,
                end: time,
                objects: objects,
                device: device,
                metadata: metadata
            )
        } else {
            correlation = HKCorrelation(
                type: correlationType,
                start: time,
                end: time,
                objects: objects,
                metadata: metadata
            )
        }

        CKLogger.d(
            tag: Self.TAG,
            message:
                "Successfully created blood pressure correlation: \(systolicValue)/\(diastolicValue) \(systolicUnit.unitString)"
        )

        return correlation
    }

    // MARK: - Private Helpers

    private func unwrapData(from map: [String: Any]) throws -> (
        Double, HKUnit, Double, HKUnit
    ) {
        // Extract systolic value
        let systolicMap = try RecordMapperUtils.getRequiredMap(
            map,
            key: "systolic",
            recordKind: Self.RECORD_KIND
        )

        let (systolicValue, systolicUnit) = try extractQuantityValue(
            from: systolicMap,
            fieldName: "systolic"
        )

        // Extract diastolic value
        let diastolicMap = try RecordMapperUtils.getRequiredMap(
            map,
            key: "diastolic",
            recordKind: Self.RECORD_KIND
        )

        let (diastolicValue, diastolicUnit) = try extractQuantityValue(
            from: diastolicMap,
            fieldName: "diastolic"
        )

        // Validate units match
        if systolicUnit != diastolicUnit {
            throw RecordMapperException(
                message:
                    "Systolic and diastolic units must match: systolic=\(systolicUnit.unitString), diastolic=\(diastolicUnit.unitString)",
                recordKind: Self.RECORD_KIND,
                fieldName: "unit"
            )
        }

        // Validate systolic > diastolic
        if systolicValue < diastolicValue {
            throw RecordMapperException(
                message:
                    "Systolic (\(systolicValue)) cannot be less than diastolic (\(diastolicValue))",
                recordKind: Self.RECORD_KIND
            )
        }

        return (systolicValue, systolicUnit, diastolicValue, diastolicUnit)
    }

    /**
     Extracts quantity value and unit from a value map.
     Expects map with 'value' (Double) and 'unit' (String) fields.
     */
    private func extractQuantityValue(from map: [String: Any], fieldName: String) throws -> (
        Double, HKUnit
    ) {
        guard let value = map["value"] as? Double else {
            throw RecordMapperException(
                message: "Missing or invalid 'value' field",
                recordKind: Self.RECORD_KIND,
                fieldName: fieldName
            )
        }

        guard let unitString = map["unit"] as? String else {
            throw RecordMapperException(
                message: "Missing or invalid 'unit' field",
                recordKind: Self.RECORD_KIND,
                fieldName: fieldName
            )
        }

        let unit = try RecordMapperUtils.parseUnit(unitString)

        return (value, unit)
    }

    private func createBloodPressureMetadata(from map: [String: Any]) -> [String: Any] {
        return RecordMapperUtils.createMetadata(from: map) { metadata in
            // HealthKit doesn't have native support for bodyPosition or measurementLocation
            // Store as custom metadata for round-trip compatibility

            if let bodyPosition = map["bodyPosition"] as? String {
                metadata["ck_bodyPosition"] = bodyPosition
            }

            if let measurementLocation = map["measurementLocation"] as? String {
                metadata["ck_measurementLocation"] = measurementLocation
            }
        }
    }

    private func createSample(
        recordType: String,
        value: Double,
        unit: HKUnit,
        time: Date,
        hkDevice: HKDevice?,
        metadata: [String: Any]
    ) throws -> HKQuantitySample {
        guard
            let objectType = RecordTypeMapper.getObjectType(recordType: recordType),
            let quantityType = objectType as? HKQuantityType
        else {
            throw RecordMapperException(
                message: "Failed to resolve quantity type for '\(recordType)'",
                recordKind: Self.RECORD_KIND
            )
        }

        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample: HKQuantitySample
        if let device = hkDevice, #available(iOS 9.0, *) {
            sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: time,
                end: time,
                device: device,
                metadata: metadata
            )
        } else {
            sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: time,
                end: time,
                metadata: metadata
            )
        }

        return sample
    }
}