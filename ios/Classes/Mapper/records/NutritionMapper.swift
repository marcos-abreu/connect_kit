import Foundation
import HealthKit

/// Maps nutrition records between Dart representation and iOS HealthKit HKQuantitySample objects.
///
/// **Architecture:**
/// Nutrition in HealthKit is represented as **multiple HKQuantitySample objects**, one per nutrient.
/// This differs significantly from Android which uses a single NutritionRecord with all nutrients.
///
/// **Key Responsibilities:**
/// - Extract all nutrient values from Dart map (30+ possible nutrients)
/// - Map each non-null nutrient to its corresponding HKQuantityType
/// - Create separate HKQuantitySample for each nutrient
/// - Handle session-level metadata (name, mealType) by storing in all samples
/// - Map nutrient types and units to HealthKit identifiers
///
/// **iOS HealthKit Specifics:**
/// - Each nutrient is a separate HKQuantityType (e.g., .dietaryEnergyConsumed, .dietaryProtein)
/// - Available nutrients: 40+ dietary quantity types
/// - Samples can be grouped using HKCorrelation(.food) but this is optional
/// - All samples share the same timestamp (meal consumption time)
/// - No native meal-level container object in HealthKit
///
/// **Platform Differences:**
/// - **iOS**: Multiple HKQuantitySample objects (one per nutrient)
/// - **Android**: Single NutritionRecord with all nutrients as fields
/// - **Android-specific**: Name and mealType fields (stored as custom metadata)
/// - **iOS note**: Some nutrients from Android may not have iOS equivalents (transFat, unsaturatedFat)
///
/// **Important Notes:**
/// - Name and mealType are meal-level fields
/// - Minimum 1 nutrient required (empty nutrition record is invalid)
/// - Uses HKCorrelation(.food) to group nutrient samples
public class NutritionMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    private static let TAG = CKConstants.TAG_NUTRITION_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_NUTRITION

    // MARK: - Initialization

    /**
     * Initializes NutritionMapper with required dependencies.
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
     Decodes a CK nutrition record map into multiple HealthKit HKQuantitySample objects.
    
     **Workflow:**
     1. Extract meal-level metadata (name, mealType, time)
     2. Extract all nutrient values (30+ possible fields)
     3. Map each nutrient to HKQuantityTypeIdentifier
     4. Create HKQuantitySample for each non-null nutrient
     5. Attach meal metadata to all samples
    
     **Returns:** Array containing a single HKCorrelation object
    
     - Parameter map: The nutrition record map from Dart (via Pigeon)
     - Returns: Array containing a single HKCorrelation object
     - Throws: RecordMapperException if decoding fails
     */
    public func decode(_ map: [String: Any]) throws -> ([HKObject], [RecordMapperFailure]?) {
        CKLogger.d(tag: Self.TAG, message: "Decoding nutrition record")

        // Extract time range (nutrition is typically instantaneous or meal duration)
        let timeRange = try RecordMapperUtils.extractTimeRange(
            from: map,
            recordKind: Self.RECORD_KIND
        )

        // Extract optional meal fields
        let name = map["name"] as? String
        let mealType = map["mealType"] as? String

        // Extract device
        let hkDevice = RecordMapperUtils.createHKDevice(from: map)

        // Create base metadata (meal-level, will be attached to all samples)
        let metadata = createNutritionMetadata(
            from: map,
            name: name,
            mealType: mealType
        )

        // Extract nutrients map
        // This map contains only nutrient fields, grouped by the Dart mapper
        guard let nutrientsMap = map["nutrients"] as? [String: Any] else {
            throw RecordMapperException(
                message: "Nutrition record missing 'nutrients' map",
                recordKind: Self.RECORD_KIND
            )
        }

        var validationFailures: [RecordMapperFailure] = []
        var samples: [HKQuantitySample] = []

        // Sort keys to ensure deterministic indexing for error reporting
        let sortedKeys = nutrientsMap.keys.sorted()

        // Iterate over the nutrients map
        for (index, key) in sortedKeys.enumerated() {
            guard let value = nutrientsMap[key] else { continue }

            // Construct candidate record type identifier
            // e.g., "protein" -> "nutrition.protein"
            let candidateRecordType = "\(Self.RECORD_KIND).\(key)"

            // Check if this is a supported nutrient type using the Single Source of Truth
            guard
                let objectType = RecordTypeMapper.getObjectType(recordType: candidateRecordType),
                let quantityType = objectType as? HKQuantityType
            else {
                // Not a supported nutrient type, skip it
                continue
            }

            // It is a supported nutrient, proceed to decode
            guard let nutrientMap = value as? [String: Any] else {
                validationFailures.append(
                    RecordMapperFailure(
                        indexPath: [index], // Deterministic sub-index based on sorted keys
                        message: "Nutrient '\(key)' has invalid format (expected Map)",
                        type: CKConstants.MAPPER_ERROR_DECODE
                    )
                )
                continue
            }

            do {
                let sample = try createNutrientSample(
                    fieldName: key,
                    quantityType: quantityType, // Pass resolved type directly
                    nutrientMap: nutrientMap,
                    timeRange: timeRange,
                    metadata: metadata,
                    device: hkDevice
                )
                samples.append(sample)
            } catch let error as RecordMapperException {
                validationFailures.append(
                    RecordMapperFailure(
                        indexPath: [index], // Deterministic sub-index based on sorted keys
                        message: "Failed to decode nutrient '\(key)': \(error.message)",
                        type: CKConstants.MAPPER_ERROR_DECODE
                    )
                )
            }
        }

        // Validate at least one nutrient was decoded
        if samples.isEmpty {
            throw RecordMapperException(
                message: "Nutrition record must have at least one valid nutrient value",
                recordKind: Self.RECORD_KIND
            )
        }

        // Create correlation
        guard let correlationType = HKCorrelationType.correlationType(forIdentifier: .food) else {
            throw RecordMapperException(
                message: "Failed to get food correlation type",
                recordKind: Self.RECORD_KIND
            )
        }

        let objects: Set<HKSample> = Set(samples)
        let correlation: HKCorrelation
        if let device = hkDevice, #available(iOS 9.0, *) {
            correlation = HKCorrelation(
                type: correlationType,
                start: timeRange.start,
                end: timeRange.end,
                objects: objects,
                device: device,
                metadata: metadata
            )
        } else {
            correlation = HKCorrelation(
                type: correlationType,
                start: timeRange.start,
                end: timeRange.end,
                objects: objects,
                metadata: metadata
            )
        }

        CKLogger.d(
            tag: Self.TAG,
            message:
                "Successfully created food correlation with \(samples.count) nutrient samples"
        )

        return ([correlation], validationFailures.isEmpty ? nil : validationFailures)
    }

    // MARK: - Private Helpers

    /**
     Creates a single nutrient HKQuantitySample.
     */
    private func createNutrientSample(
        fieldName: String,
        quantityType: HKQuantityType,
        nutrientMap: [String: Any],
        timeRange: (start: Date, end: Date),
        metadata: [String: Any],
        device: HKDevice?
    ) throws -> HKQuantitySample {

        // Extract value and unit
        guard let value = nutrientMap["value"] as? Double else {
            throw RecordMapperException(
                message: "Missing or invalid 'value' field for nutrient '\(fieldName)'",
                recordKind: Self.RECORD_KIND,
                fieldName: fieldName
            )
        }

        guard let unitString = nutrientMap["unit"] as? String else {
            throw RecordMapperException(
                message: "Missing or invalid 'unit' field for nutrient '\(fieldName)'",
                recordKind: Self.RECORD_KIND,
                fieldName: fieldName
            )
        }

        let unit = try RecordMapperUtils.parseUnit(unitString)

        // Create quantity
        let quantity = HKQuantity(unit: unit, doubleValue: value)

        // Create sample
        let sample: HKQuantitySample
        if let device = device, #available(iOS 9.0, *) {
            sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: timeRange.start,
                end: timeRange.end,
                device: device,
                metadata: metadata
            )
        } else {
            sample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: timeRange.start,
                end: timeRange.end,
                metadata: metadata
            )
        }

        return sample
    }

    /**
     Creates nutrition metadata dictionary.
    
     Includes:
     1. Source metadata (recording method, device, sync IDs)
     2. Timezone metadata
     3. Meal-level fields (name, mealType) as custom metadata
     4. Custom Dart metadata (with ck_ prefix)
    
     **Note:** This metadata is attached to ALL nutrient samples since iOS has no meal container.
     */
    private func createNutritionMetadata(
        from map: [String: Any],
        name: String?,
        mealType: String?
    ) -> [String: Any] {
        return RecordMapperUtils.createMetadata(from: map) { metadata in
            // === 3. Meal-level fields (as custom metadata) ===
            // --------------------------------------------------------------
            // iOS doesn't have a meal container, so attach meal fields to all nutrient samples

            // iOS expects HKMetadataKeyFoodType to be the name of the food not types like "lunch", etc.
            // "
            //    When creating correlations representing food, always use the HKMetadataKeyFoodType 
            //    key to provide the food’s name.
            // "
            if let name = name {
                metadata[HKMetadataKeyFoodType] = name
            }

            if let mealType = mealType {
                metadata["ck_mealType"] = mealType
                if name == nil {
                    metadata[HKMetadataKeyFoodType] = mealType
                }
            }
        }
    }
}