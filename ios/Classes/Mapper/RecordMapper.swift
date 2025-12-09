import Foundation
import HealthKit

/// Result of decoding a record map.
///
/// - First: Array of successfully decoded HKObject records (main + duringSession).
/// - Second: Failures that occurred **only in records duringSession** (e.g., workout samples).
///   Main record decode failures are thrown as RecordMapperException.
public typealias MapperResult = ([HKObject], [RecordMapperFailure]?)

/// Main orchestrator for encoding and decoding Pigeon record maps to and from HealthKit records.
///
/// Delegates conversion logic to specialized mappers based on record kind,
/// following the Strategy pattern for modular and maintainable translation.
///
/// **Architecture:**
/// ```
/// RecordMapper (orchestrator)
///    ├─> DataRecordMapper (simple quantity/category records)
///    ├─> SleepSessionMapper (sleep sessions with stages)
///    ├─> BloodPressureMapper (blood pressure correlation)
///    ├─> NutritionMapper (nutrition with 30+ fields)
///    ├─> WorkoutMapper (exercise sessions)
///    ├─> ECGMapper (iOS only)
///    └─> AudiogramMapper (iOS only)
/// ```
///
/// **Reusability:** Shared across ReadService, WriteService, and DeleteService.
/// - WriteService → decodes maps → HKObjects
/// - ReadService → encodes HKObjects → maps
/// - DeleteService → supports partial decoding for ID extraction
///
/// **Platform Differences:**
/// - **iOS Supports:** ECG, Audiogram (throws UnsupportedKindException on Android)
/// - **Android Supports:** Android-specific health metrics (throws UnsupportedKindException on iOS)
///
/// @property healthStore The HealthKit store instance, used for feature and capability checks.
/// @property categoryMapper Category mapper for enum conversions, default singleton used.
/// @property specializedMappers Injected for testability; defaults use the provided HealthStore.
public class RecordMapper {

    // MARK: - Properties

    private let healthStore: HKHealthStore
    private let categoryMapper: CategoryMapper.Type

    // Specialized mappers - to be implemented as needed
    // These will be injected for testability
    private let dataRecordMapper: DataRecordMapper
    private let workoutMapper: WorkoutMapper
    private let bloodPressureMapper: BloodPressureMapper
    private let nutritionMapper: NutritionMapper
    private let sleepSessionMapper: SleepSessionMapper
    private let ecgMapper: ECGMapper
    private let audiogramMapper: AudiogramMapper

    // MARK: - Constants

    private static let TAG = CKConstants.TAG_RECORD_MAPPER

    // MARK: - Initialization

    /**
     * Initializes RecordMapper with all specialized mappers.
     *
     * Default implementations will be provided for each mapper as they are created.
     * The design follows dependency injection for testability.
     *
     * - Parameter healthStore: HealthKit store for type validation and feature checks
     * - Parameter categoryMapper: Category mapper for enum conversions (default singleton)
     * - Parameter dataRecordMapper: Mapper for simple quantity/category records
     * - Parameter workoutMapper: Mapper for workout sessions with samples
     * - Parameter bloodPressureMapper: Mapper for blood pressure correlations
     * - Parameter nutritionMapper: Mapper for nutrition records with many fields
     * - Parameter sleepSessionMapper: Mapper for sleep sessions with stages
     * - Parameter ecgMapper: Mapper for ECG records (iOS-only)
     * - Parameter audiogramMapper: Mapper for audiogram records (iOS-only)
     */
    public init(
        healthStore: HKHealthStore,
        categoryMapper: CategoryMapper.Type = CategoryMapper.self,
        dataRecordMapper: DataRecordMapper? = nil,
        workoutMapper: WorkoutMapper? = nil,
        bloodPressureMapper: BloodPressureMapper? = nil,
        nutritionMapper: NutritionMapper? = nil,
        sleepSessionMapper: SleepSessionMapper? = nil,
        ecgMapper: ECGMapper? = nil,
        audiogramMapper: AudiogramMapper? = nil
    ) {
        self.healthStore = healthStore
        self.categoryMapper = categoryMapper

        // Initialize specialized mappers with defaults or injected instances
        self.dataRecordMapper =
            dataRecordMapper
            ?? DataRecordMapper(healthStore: healthStore, categoryMapper: categoryMapper)
        self.workoutMapper =
            workoutMapper ?? WorkoutMapper(healthStore: healthStore, categoryMapper: categoryMapper)
        self.bloodPressureMapper =
            bloodPressureMapper
            ?? BloodPressureMapper(healthStore: healthStore, categoryMapper: categoryMapper)
        self.nutritionMapper =
            nutritionMapper
            ?? NutritionMapper(healthStore: healthStore, categoryMapper: categoryMapper)
        self.sleepSessionMapper =
            sleepSessionMapper
            ?? SleepSessionMapper(healthStore: healthStore, categoryMapper: categoryMapper)
        self.ecgMapper =
            ecgMapper ?? ECGMapper(healthStore: healthStore, categoryMapper: categoryMapper)
        self.audiogramMapper =
            audiogramMapper
            ?? AudiogramMapper(healthStore: healthStore, categoryMapper: categoryMapper)
    }

    // MARK: - Public API

    /**
     * Decodes a CK record map into a HealthKit record object.
     *
     * This is the main entry point for all record mapping. It dispatches to
     * specialized mappers based on the 'recordKind' differentiator field.
     *
     * **Record Kind Differentiators**:
     * - RECORD_KIND_DATA_RECORD: Simple quantity or category records
     * - RECORD_KIND_BLOOD_PRESSURE: Blood pressure reading
     * - RECORD_KIND_WORKOUT: Exercise session
     * - RECORD_KIND_NUTRITION: Nutrition/food record
     * - RECORD_KIND_SLEEP_SESSION: Sleep session with stages
     * - RECORD_KIND_AUDIOGRAM: iOS only - supported on HealthKit
     * - RECORD_KIND_ECG: iOS only - supported on HealthKit
     *
     * **DuringSession Failure Handling**:
     * Main record decode failures throw RecordMapperException immediately.
     * DuringSession record decode failures are collected and returned as the second
     * element of the tuple, with proper index path mapping (e.g., [1,2] for third
     * duringSession record of second main record).
     *
     * - Parameter map: The ck record map from Dart (via Pigeon)
     * - Returns: A tuple containing the array of successfully decoded HKObjects, and a nullable array of decode failures that occurred for records within duringSession
     * - Throws: RecordMapperException if decoding fails (invalid data, missing fields, etc.)
     * - Throws: UnsupportedKindException if record kind is not supported on iOS
     */
    public func decode(_ map: [String: Any]) throws -> MapperResult {
        guard let recordKind = map["recordKind"] as? String else {
            throw RecordMapperException(
                message: "Missing required field 'recordKind'",
                recordKind: CKConstants.MAPPER_ERROR_UNEXPECTED
            )
        }

        CKLogger.d(tag: Self.TAG, message: "Mapping record kind: '\(recordKind)'")

        switch recordKind {
        case CKConstants.RECORD_KIND_DATA_RECORD:
            let records = try dataRecordMapper.decode(map)
            return (records, nil)

        case CKConstants.RECORD_KIND_WORKOUT:
            let (workoutRecord, duringSessionRecords, duringSessionFailures) =
                try workoutMapper.decode(map)
            let allRecords = [workoutRecord] + duringSessionRecords
            return (allRecords, duringSessionFailures)

        case CKConstants.RECORD_KIND_BLOOD_PRESSURE:
            let record = try bloodPressureMapper.decode(map)
            return ([record], nil)

        case CKConstants.RECORD_KIND_NUTRITION:
            let (records, failures) = try nutritionMapper.decode(map)
            return (records, failures)

        case CKConstants.RECORD_KIND_SLEEP_SESSION:
            let (records, failures) = try sleepSessionMapper.decode(map)
            return (records, failures)

        // iOS-only record kinds - supported on HealthKit
        case CKConstants.RECORD_KIND_AUDIOGRAM:
            let record = try audiogramMapper.decode(map)
            return ([record], nil)

        case CKConstants.RECORD_KIND_ECG:
            try ecgMapper.decode(map)
            // Should not be reached as ecgMapper.decode throws
            return ([], nil)

        default:
            throw RecordMapperException(
                message: "Unknown or unsupported record kind: '\(recordKind)'",
                recordKind: recordKind
            )
        }
    }
}
