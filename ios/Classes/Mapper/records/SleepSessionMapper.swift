import Foundation
import HealthKit

/// Maps sleep session records between Dart representation and iOS HealthKit HKCategorySample objects.
///
/// **Architecture:**
/// Sleep in HealthKit is represented as **multiple HKCategorySample objects**, one per sleep stage.
/// This differs from Android which uses a single SleepSessionRecord with embedded stages.
///
/// **Key Responsibilities:**
/// - Extract sleep session time bounds and stages from Dart map
/// - Map each stage to corresponding HKCategoryValueSleepAnalysis value
/// - Create separate HKCategorySample for each stage
/// - Handle session-level metadata (title, notes) by storing in each sample
/// - Validate stages are sequential and non-overlapping
///
/// **iOS HealthKit Specifics:**
/// - Sleep represented as HKCategoryType(.sleepAnalysis) samples
/// - Each stage is a separate HKCategorySample with its own time range
/// - Available values: inBed, asleep, awake, asleepCore (light), asleepDeep, asleepREM, asleepUnspecified
/// - Sessions are implicitly grouped by overlapping/adjacent sample times
/// - No native "sleep session" container object in HealthKit
///
/// **Platform Differences:**
/// - **iOS**: Multiple HKCategorySample objects (one per stage)
/// - **Android**: Single SleepSessionRecord with embedded SleepStage list
/// - **Android-specific**: Notes field (stored as custom metadata)
/// - **Mapping challenge**: "outOfBed" stage not supported in iOS (mapped to awake)
///
/// **Important Notes:**
/// - Title and notes are session-level fields in Dart but must be duplicated across all samples in iOS
/// - Overlapping samples are allowed in HealthKit (e.g., inBed overlapping with asleep)
/// - The Dart model validates non-overlapping stages, but iOS supports overlaps for inBed
public class SleepSessionMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    private static let TAG = CKConstants.TAG_SLEEP_SESSION_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_SLEEP_SESSION

    // MARK: - Initialization

    /**
     * Initializes SleepSessionMapper with required dependencies.
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
     Decodes a CK sleep session record map into multiple HealthKit HKCategorySample objects.
    
     **Workflow:**
     1. Extract session-level metadata (title, notes, times)
     2. Extract and validate stages array
     3. Map each stage to HKCategoryValueSleepAnalysis value
     4. Create HKCategorySample for each stage
     5. Attach session metadata to all samples
    
     **Returns:** Array of HKCategorySample objects (one per stage)
    
     - Parameter map: The sleep session record map from Dart (via Pigeon)
     - Returns: Array of HKCategorySample objects representing all sleep stages
     - Throws: RecordMapperException if decoding fails
     */
    public func decode(_ map: [String: Any]) throws -> ([HKObject], [RecordMapperFailure]?) {
        CKLogger.d(tag: Self.TAG, message: "Decoding sleep session record")

        // Extract session time range (session bounds, not individual stages)
        let sessionTimeRange = try RecordMapperUtils.extractTimeRange(
            from: map,
            recordKind: Self.RECORD_KIND
        )

        // Extract optional session fields
        let title = map["title"] as? String
        let notes = map["notes"] as? String

        // Extract stages array
        guard let stagesArray = map["stages"] as? [[String: Any]], !stagesArray.isEmpty else {
            throw RecordMapperException(
                message: "Sleep session must have at least one stage",
                recordKind: Self.RECORD_KIND,
                fieldName: "stages"
            )
        }

        // Extract device
        let hkDevice = RecordMapperUtils.createHKDevice(from: map)

        // Create base metadata (session-level, will be attached to all samples)
        let metadata = createSleepSessionMetadata(
            from: map,
            title: title,
            notes: notes
        )

        // Decode each stage into HKCategorySample
        var samples: [HKCategorySample] = []
        var validationFailures: [RecordMapperFailure] = []

        for (index, stageMap) in stagesArray.enumerated() {
            do {
                let sample = try decodeSleepStage(
                    stageMap: stageMap,
                    stageIndex: index,
                    sessionBounds: sessionTimeRange,
                    metadata: metadata,
                    device: hkDevice
                )
                samples.append(sample)
            } catch let error as RecordMapperException {
                // Collect failure instead of throwing
                validationFailures.append(
                    RecordMapperFailure(
                        indexPath: [index], // Sub-index for the stage
                        message: "Stage \(index): \(error.message)",
                        type: CKConstants.MAPPER_ERROR_DECODE
                    )
                )
            }
        }

        CKLogger.d(
            tag: Self.TAG,
            message: "Successfully created \(samples.count) sleep stage samples"
        )

        return (samples, validationFailures.isEmpty ? nil : validationFailures)
    }

    // MARK: - Private Helpers

    /**
     Decodes a single sleep stage into HKCategorySample.
     */
    private func decodeSleepStage(
        stageMap: [String: Any],
        stageIndex: Int,
        sessionBounds: (start: Date, end: Date),
        metadata: [String: Any],
        device: HKDevice?
    ) throws -> HKCategorySample {

        // Extract stage time range (session bounds, not individual stages)
        let stageTimeRange = try RecordMapperUtils.extractTimeRange(
            from: stageMap,
            recordKind: Self.RECORD_KIND
        )

        // Validate stage is within session bounds
        if stageTimeRange.start < sessionBounds.start {
            throw RecordMapperException(
                message:
                    "Stage start time (\(stageTimeRange.start)) is before session start (\(sessionBounds.start))",
                recordKind: Self.RECORD_KIND,
                fieldName: "stages[\(stageIndex)].startTime"
            )
        }

        if stageTimeRange.end > sessionBounds.end {
            throw RecordMapperException(
                message:
                    "Stage end time (\(stageTimeRange.end)) is after session end (\(sessionBounds.end))",
                recordKind: Self.RECORD_KIND,
                fieldName: "stages[\(stageIndex)].endTime"
            )
        }

        // Extract and map stage type
        let stageTypeStr = try RecordMapperUtils.getRequiredString(
            stageMap,
            key: "stage",
            recordKind: Self.RECORD_KIND
        )

        // Decode sleep stage using CategoryMapper
        guard
            let categoryValue = CategoryMapper.decode(
                categoryName: "SleepSession",
                value: stageTypeStr
            )
        else {
            throw RecordMapperException(
                message: "Unknown sleep stage: \(stageTypeStr)",
                recordKind: Self.RECORD_KIND
            )
        }

        // Get sleep analysis type from the Single Source of Truth
        guard
            let objectType = RecordTypeMapper.getObjectType(recordType: Self.RECORD_KIND),
            let sleepType = objectType as? HKCategoryType
        else {
            throw RecordMapperException(
                message: "Failed to get sleep analysis category type",
                recordKind: Self.RECORD_KIND
            )
        }

        // Create sample
        let sample: HKCategorySample
        if let device = device, #available(iOS 9.0, *) {
            sample = HKCategorySample(
                type: sleepType,
                value: categoryValue,
                start: stageTimeRange.start,
                end: stageTimeRange.end,
                device: device,
                metadata: metadata
            )
        } else {
            sample = HKCategorySample(
                type: sleepType,
                value: categoryValue,
                start: stageTimeRange.start,
                end: stageTimeRange.end,
                metadata: metadata
            )
        }

        return sample
    }

    /**
     Creates sleep session metadata dictionary.
    
     Includes:
     1. Source metadata (recording method, device, sync IDs)
     2. Timezone metadata
     3. Session-level fields (title, notes) as custom metadata
     4. Custom Dart metadata (with ck_ prefix)
    
     **Note:** This metadata is attached to ALL stage samples since iOS has no session container.
     */
    private func createSleepSessionMetadata(
        from map: [String: Any],
        title: String?,
        notes: String?
    ) -> [String: Any] {
        return RecordMapperUtils.createMetadata(from: map) { metadata in
            // iOS doesn't have a sleep session container, so attach session fields to all samples

            if let title = title {
                metadata["ck_title"] = title
            }

            if let notes = notes {
                metadata["ck_notes"] = notes  // Android-specific, not in iOS
            }
        }
    }
}