import Foundation

/// Defines shared constants used for cross-platform string logic and communication between Dart and
/// Native iOS code. These constants must match the Android CKConstants.kt values.
public struct CKConstants {

    // MARK: - Logging Tags (one per file)

    static let TAG_CONNECT_KIT = "ConnectKit"
    static let TAG_CK_HOST_API = "CKHostApi"
    static let TAG_PERMISSION_SERVICE = "PermissionService"
    static let TAG_WRITE_SERVICE = "WriteService"
    static let TAG_RECORD_TYPE_MAPPER = "RecordTypeMapper"
    static let TAG_RECORD_MAPPER = "RecordMapper"
    static let TAG_DATA_RECORD_MAPPER = "DataRecordMapper"
    static let TAG_RECORD_MAPPER_UTILS = "RecordMapperUtils"
    static let TAG_BLOOD_PRESSURE_MAPPER = "BloodPressureMapper"
    static let TAG_NUTRITION_MAPPER = "NutritionMapper"
    static let TAG_SLEEP_SESSION_MAPPER = "SleepSessionMapper"
    static let TAG_WORKOUT_MAPPER = "WorkoutMapper"
    static let TAG_AUDIOGRAM_MAPPER = "AudiogramMapper"
    static let TAG_ECG_MAPPER = "ECGMapper"

    // MARK: - HealthKit SDK Status

    static let SDK_STATUS_AVAILABLE = "available"
    static let SDK_STATUS_UNAVAILABLE = "unavailable"
    static let SDK_STATUS_UPDATE_REQUIRED = "updateRequired"

    // MARK: - Access Types (Must match Dart/Pigeon definitions)

    static let ACCESS_TYPE_READ = "read"
    static let ACCESS_TYPE_WRITE = "write"

    // MARK: - Permission Status Types (Must match Dart status interpretation)

    static let PERMISSION_STATUS_GRANTED = "granted"
    static let PERMISSION_STATUS_DENIED = "denied"
    static let PERMISSION_STATUS_NOT_DETERMINED = "notDetermined"
    static let PERMISSION_STATUS_UNKNOWN = "unknown"
    static let PERMISSION_STATUS_UNSUPPORTED = "unsupported"

    // MARK: - Write Outcome (Must match Dart write outcome interpretation)

    static let WRITE_OUTCOME_COMPLETE_SUCCESS = "completeSuccess"
    static let WRITE_OUTCOME_PARTIAL_SUCCESS = "partialSuccess"
    static let WRITE_OUTCOME_FAILURE = "failure"

    // MARK: - RecordMapper Record Kind (Must match Dart Request Mapper RecordKind)

    static let RECORD_KIND_DATA_RECORD = "data"
    static let RECORD_KIND_BLOOD_PRESSURE = "bloodPressure"
    static let RECORD_KIND_WORKOUT = "workout"
    static let RECORD_KIND_NUTRITION = "nutrition"
    static let RECORD_KIND_SLEEP_SESSION = "sleepSession"
    static let RECORD_KIND_AUDIOGRAM = "audiogram"
    static let RECORD_KIND_ECG = "ecg"

    // MARK: - Value Pattern Types (Must match Dart ValuePattern definitions)

    static let VALUE_PATTERN_QUANTITY = "quantity"
    static let VALUE_PATTERN_LABEL = "label"
    static let VALUE_PATTERN_CATEGORY = "category"
    static let VALUE_PATTERN_SAMPLES = "samples"
    static let VALUE_PATTERN_MULTIPLE = "multiple"

    // MARK: - Error Codes (For use with FlutterError)

    static let ERROR_CODE_PERMISSION_REQUEST_FAILED = "PERMISSION_REQUEST_FAILED"
    static let ERROR_CODE_PERMISSION_CHECK_FAILED = "PERMISSION_CHECK_FAILED"
    static let ERROR_CODE_HEALTHKIT_NOT_AVAILABLE = "HEALTHKIT_NOT_AVAILABLE"
    static let ERROR_CODE_INVALID_HEALTH_TYPE = "INVALID_HEALTH_TYPE"

    // MARK: - RecordMapper Errors (for RecordMapperFailure.type)

    static let MAPPER_ERROR_NO_RECORD = "NoRecordError"
    static let MAPPER_ERROR_HEALTH_CONNECT_INSERT = "HealthConnectInsert"
    static let MAPPER_ERROR_DECODE = "DecodeError"
    static let MAPPER_ERROR_DURING_SESSION_DECODE = "DuringSessionDecodeError"
    static let MAPPER_ERROR_DURING_SESSION_INVALID_TYPE = "InvalidDuringSessionType"
    static let MAPPER_ERROR_UNEXPECTED = "UnexpectedError"

    // MARK: - Other Constants

    /// RecordMapperFailure.indexPath, when error isn't related to an index path
    static let ERROR_NO_INDEX_PATH = -1
}