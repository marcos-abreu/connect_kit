import Foundation
import HealthKit

/// Maps workout records between Dart representation and iOS HealthKit HKWorkout objects.
///
/// **Architecture:**
/// Handles conversion of CKWorkout records from Dart into HKWorkout + associated quantity samples.
/// Uses HKWorkoutBuilder (iOS 12+) as Apple's recommended approach for creating workouts,
/// replacing the deprecated HKWorkout initializers (deprecated iOS 17).
///
/// **Key Responsibilities:**
/// - Activity type mapping from Dart strings to HKWorkoutActivityType
/// - Workout metadata extraction and mapping to HealthKit metadata keys
/// - DuringSession samples decoding using DataRecordMapper
/// - Using HKWorkoutBuilder to construct workouts (supports historical data, not just live)
/// - Proper error handling with index path tracking for nested failures
///
/// **iOS HealthKit Specifics:**
/// - HKWorkout is an HKSample that represents a single physical activity
/// - As of iOS 17, all HKWorkout initializers are deprecated
/// - HKWorkoutBuilder (iOS 12+) is the official replacement for creating ALL workouts
/// - HKWorkoutBuilder supports both live AND historical workout creation
/// - Samples are added to the builder, then finalized with finishWorkout()
///
/// **Builder Pattern Clarification:**
/// - HKWorkoutBuilder: For any workout (live or historical) - iOS 12+
/// - HKLiveWorkoutBuilder: For LIVE workouts with auto data collection - watchOS 5+ (watchOS only)
/// - Our use case: HKWorkoutBuilder for historical data import
///
/// **Future Enhancements (Out of Scope):**
/// - HKWorkoutActivity breakdown (iOS 16+) for interval/multi-sport workouts
/// - HKWorkoutRoute for GPS tracking
/// - HKWorkoutEvent for pause/resume events
@available(iOS 12.0, *)
public class WorkoutMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type
    private let dataRecordMapper: DataRecordMapper

    private static let TAG = CKConstants.TAG_WORKOUT_MAPPER
    private static let RECORD_KIND = CKConstants.RECORD_KIND_WORKOUT

    // MARK: - Initialization

    /**
     * Initializes WorkoutMapper with required dependencies.
     *
     * - Parameter healthStore: HealthKit store for type validation
     * - Parameter categoryMapper: Category mapper for enum conversions
     * - Parameter dataRecordMapper: Data record mapper for quantity/category HKSample creation
     */
    public init(
        healthStore: HKHealthStore,
        categoryMapper: CategoryMapper.Type = CategoryMapper.self,
        dataRecordMapper: DataRecordMapper? = nil
    ) {
        self.healthStore = healthStore
        self.categoryMapper = categoryMapper
        self.dataRecordMapper =
            dataRecordMapper
            ?? DataRecordMapper(healthStore: healthStore, categoryMapper: categoryMapper)
    }

    // MARK: - Public API

    /**
     Decodes a CK workout record map into HealthKit objects using HKWorkoutBuilder.
    
     Returns a tuple containing:
     - The main HKWorkout object (created via builder)
     - Array of associated HKQuantitySample objects from duringSession
     - Optional array of failures that occurred during duringSession sample decoding
    
     **Workflow:**
     1. Extract and validate workout properties (activity type, times, title)
     2. Create HKWorkoutBuilder with configuration
     3. Begin collection with start date
     4. Add metadata to builder
     5. Decode and add duringSession samples to builder
     6. Finish workout to create the HKWorkout
    
     **Error Handling:**
     - Main workout decode failures: throw RecordMapperException immediately
     - DuringSession sample failures: collect and return in tuple for partial success handling
    
     - Parameter map: The workout record map from Dart (via Pigeon)
     - Returns: Tuple of (HKWorkout, [HKQuantitySample], [RecordMapperFailure]?)
     - Throws: RecordMapperException if main workout decoding fails
     */
    public func decode(_ map: [String: Any]) throws -> (
        HKWorkout, [HKQuantitySample], [RecordMapperFailure]?
    ) {
        CKLogger.d(tag: Self.TAG, message: "Decoding workout record using HKWorkoutBuilder")

        // Extract time range
        let timeRange = try RecordMapperUtils.extractTimeRange(
            from: map, recordKind: Self.RECORD_KIND)

        // Extract and map activity type
        let activityType = try extractActivityType(from: map)

        // Extract optional fields
        let title = map["title"] as? String

        // Extract device
        let hkDevice = RecordMapperUtils.createHKDevice(from: map)

        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        // Note: locationType defaults to .unknown, can be extended in future

        // Create metadata
        let metadata = createWorkoutMetadata(from: map, title: title)

        // Create HKWorkoutBuilder
        let builder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: configuration,
            device: hkDevice
        )

        // Begin collection - this is REQUIRED before adding samples or metadata
        var beginError: Error?
        let beginSemaphore = DispatchSemaphore(value: 0)

        builder.beginCollection(withStart: timeRange.start) { success, error in
            if !success {
                beginError = error
            }
            beginSemaphore.signal()
        }

        beginSemaphore.wait()

        if let error = beginError {
            builder.discardWorkout()
            throw RecordMapperException(
                message: "Failed to begin workout collection: \(error.localizedDescription)",
                recordKind: Self.RECORD_KIND,
                cause: error
            )
        }

        // Add metadata to builder
        for (key, value) in metadata {
            builder.addMetadata([key: value]) { success, error in
                if !success {
                    CKLogger.w(
                        tag: Self.TAG,
                        message:
                            "Failed to add metadata key '\(key)': \(error?.localizedDescription ?? "unknown")"
                    )
                }
            }
        }

        // Decode duringSession samples
        let (duringSessionSamples, duringSessionFailures) = try decodeDuringSessionSamples(
            from: map,
            workoutTimeRange: timeRange
        )

        // Add samples to builder
        if !duringSessionSamples.isEmpty {
            var addSamplesError: Error?
            let addSamplesSemaphore = DispatchSemaphore(value: 0)

            builder.add(duringSessionSamples) { success, error in
                if !success {
                    addSamplesError = error
                }
                addSamplesSemaphore.signal()
            }

            addSamplesSemaphore.wait()

            if let error = addSamplesError {
                CKLogger.w(
                    tag: Self.TAG,
                    message: "Failed to add samples to workout: \(error.localizedDescription)"
                )
                // Don't fail the workout, just log - samples can be added separately
            }
        }

        // Finish workout - creates the HKWorkout
        var finishError: Error?
        var finishedWorkout: HKWorkout?
        let finishSemaphore = DispatchSemaphore(value: 0)

        builder.endCollection(withEnd: timeRange.end) { success, error in
            if !success {
                finishError = error
            }
            finishSemaphore.signal()
        }

        finishSemaphore.wait()

        if let error = finishError {
            builder.discardWorkout()
            throw RecordMapperException(
                message: "Failed to end workout collection: \(error.localizedDescription)",
                recordKind: Self.RECORD_KIND,
                cause: error
            )
        }

        // Now finish the workout to get the HKWorkout object
        let workoutFinishSemaphore = DispatchSemaphore(value: 0)

        builder.finishWorkout { workout, error in
            if let error = error {
                finishError = error
            } else {
                finishedWorkout = workout
            }
            workoutFinishSemaphore.signal()
        }

        workoutFinishSemaphore.wait()

        if let error = finishError {
            builder.discardWorkout()
            throw RecordMapperException(
                message: "Failed to finish workout: \(error.localizedDescription)",
                recordKind: Self.RECORD_KIND,
                cause: error
            )
        }

        guard let workout = finishedWorkout else {
            builder.discardWorkout()
            throw RecordMapperException(
                message: "Workout builder returned nil workout without error",
                recordKind: Self.RECORD_KIND
            )
        }

        CKLogger.d(
            tag: Self.TAG,
            message:
                "Successfully created workout via builder: \(activityType) with \(duringSessionSamples.count) samples"
        )

        return (workout, duringSessionSamples, duringSessionFailures)
    }

    // MARK: - Private Helpers

    /**
     Extracts and maps activity type from Dart string to HKWorkoutActivityType.
    
     Dart uses camelCase strings (e.g., "running", "cycling", "yoga")
     iOS HealthKit uses HKWorkoutActivityType enum
    
     Throws RecordMapperException if activity type is missing or unsupported.
     */
    private func extractActivityType(from map: [String: Any]) throws -> HKWorkoutActivityType {
        let activityTypeStr = try RecordMapperUtils.getRequiredString(
            map, key: "activityType", recordKind: Self.RECORD_KIND)

        guard let activityType = WorkoutActivityTypeMapper.map(activityTypeStr) else {
            throw RecordMapperException(
                message: "Unsupported activity type: '\(activityTypeStr)'",
                recordKind: Self.RECORD_KIND,
                fieldName: "activityType"
            )
        }

        return activityType
    }

    /**
     Creates workout-specific metadata dictionary.
    
     Merges:
     1. Source metadata (recording method, device info, sync IDs)
     2. Timezone metadata
     3. Workout-specific HealthKit metadata keys
     4. Custom Dart metadata (with ck_ prefix)
    
     **Workout Metadata Keys:**
     - HKMetadataKeyIndoorWorkout: Bool
     - HKMetadataKeyWeatherTemperature: HKQuantity
     - HKMetadataKeyWeatherHumidity: HKQuantity
     - Custom fields stored with ck_ prefix for round-trip compatibility
     */
    private func createWorkoutMetadata(from map: [String: Any], title: String?) -> [String: Any] {
        return RecordMapperUtils.createMetadata(from: map) { metadata in
            // === 3. Workout-specific fields ===
            // --------------------------------------------------------------
            if let title = title {
                metadata["ck_title"] = title
            }
        }
    }

    /**
     Decodes duringSession samples from the workout map.
    
     Uses DataRecordMapper to decode each sample, collecting failures for partial success.
    
     **Key Points:**
     - DuringSession samples are quantity samples associated with the workout
     - Each sample is validated to be within workout time bounds
     - Failures are collected without failing the entire workout
     - Only HKQuantitySample objects are supported (no category samples in workouts)
    
     Returns tuple of (samples, failures)
     */
    private func decodeDuringSessionSamples(
        from map: [String: Any],
        workoutTimeRange: (start: Date, end: Date)
    ) throws -> ([HKQuantitySample], [RecordMapperFailure]?) {
        guard let duringSessionArray = map["duringSession"] as? [[String: Any]] else {
            // No duringSession samples - this is valid
            return ([], nil)
        }

        if duringSessionArray.isEmpty {
            return ([], nil)
        }

        var samples: [HKQuantitySample] = []
        var failures: [RecordMapperFailure] = []

        for (index, sampleMap) in duringSessionArray.enumerated() {
            do {
                // Decode using DataRecordMapper
                let decodedObjects = try dataRecordMapper.decode(sampleMap)

                // Validate and collect only HKQuantitySample objects
                for obj in decodedObjects {
                    if let quantitySample = obj as? HKQuantitySample {
                        // Validate sample time is within workout bounds
                        if quantitySample.startDate < workoutTimeRange.start
                            || quantitySample.endDate > workoutTimeRange.end
                        {
                            failures.append(
                                RecordMapperFailure(
                                    indexPath: [index],
                                    message:
                                        "Sample time (\(quantitySample.startDate) - \(quantitySample.endDate)) "
                                        + "is outside workout bounds (\(workoutTimeRange.start) - \(workoutTimeRange.end))",
                                    type: CKConstants.MAPPER_ERROR_DURING_SESSION_DECODE
                                )
                            )
                            continue
                        }

                        samples.append(quantitySample)
                    } else {
                        // Non-quantity samples not supported in duringSession
                        failures.append(
                            RecordMapperFailure(
                                indexPath: [index],
                                message:
                                    "DuringSession sample must be a quantity type, got: \(type(of: obj))",
                                type: CKConstants.MAPPER_ERROR_DURING_SESSION_INVALID_TYPE
                            )
                        )
                    }
                }

            } catch let error as RecordMapperException {
                // Collect decode failure for this sample
                failures.append(
                    RecordMapperFailure(
                        indexPath: [index],
                        message: "Failed to decode duringSession sample: \(error.message)",
                        type: CKConstants.MAPPER_ERROR_DURING_SESSION_DECODE
                    )
                )
            } catch {
                // Unexpected error
                failures.append(
                    RecordMapperFailure(
                        indexPath: [index],
                        message: "Unexpected error decoding duringSession sample: \(error)",
                        type: CKConstants.MAPPER_ERROR_UNEXPECTED
                    )
                )
            }
        }

        return (samples, failures.isEmpty ? nil : failures)
    }
}
