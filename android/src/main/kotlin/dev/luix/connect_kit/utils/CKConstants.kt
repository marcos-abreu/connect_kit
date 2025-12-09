package dev.luix.connect_kit.utils

/**
 * Defines shared constants used for cross-platform string logic and communication between Dart and
 * Native code.
 */
object CKConstants {

    // === Logging Tags ===
    const val TAG_CONNECT_KIT = "ConnectKit"
    const val TAG_CK_HOST_API = "CKHostApi"
    const val TAG_PERMISSION_SERVICE = "PermissionService"
    const val TAG_WRITE_SERVICE = "WriteService"
    const val TAG_RECORD_TYPE_MAPPER = "RecordTypeMapper"
    const val TAG_RECORD_MAPPER = "RecordMapper"
    const val TAG_DATA_RECORD_MAPPER = "DataRecordMapper"
    const val TAG_RECORD_MAPPER_UTILS = "RecordMapperUtils"
    const val TAG_BLOOD_PRESSURE_MAPPER = "BloodPressureMapper"
    const val TAG_NUTRITION_MAPPER = "NutritionMapper"
    const val TAG_SLEEP_SESSION_MAPPER = "SleepSessionMapper"
    const val TAG_WORKOUT_MAPPER = "WorkoutMapper"

    // === Health Connect SDK Status (Must match Dart sdk status interpretation) ===
    const val SDK_STATUS_AVAILABLE = "available"
    const val SDK_STATUS_UNAVAILABLE = "unavailable"
    const val SDK_STATUS_UPDATE_REQUIRED = "updateRequired"

    // === Access Types (Must match Dart access type interpretation) ===
    const val ACCESS_TYPE_READ = "read"
    const val ACCESS_TYPE_WRITE = "write"

    // === Status Types (Must match Dart permission status interpretation) ===
    const val PERMISSION_STATUS_GRANTED = "granted"
    const val PERMISSION_STATUS_DENIED = "denied"
    const val PERMISSION_STATUS_NOT_SUPPORTED = "notSupported"
    // Note: STATUS_NOT_DETERMINED and STATUS_UNKNOWN are typically iOS only

    // === Write Outcome (Must match Dart write outcome interpretation) ===
    const val WRITE_OUTCOME_COMPLETE_SUCCESS = "completeSuccess"
    const val WRITE_OUTCOME_PARTIAL_SUCCESS = "partialSuccess"
    const val WRITE_OUTCOME_FAILURE = "failure"

    // === RecordMapper Record Kind (Must match Dart Request Mapper RecordKind) ===
    const val RECORD_KIND_DATA_RECORD = "data"
    const val RECORD_KIND_BLOOD_PRESSURE = "bloodPressure"
    const val RECORD_KIND_WORKOUT = "workout"
    const val RECORD_KIND_NUTRITION = "nutrition"
    const val RECORD_KIND_SLEEP_SESSION = "sleepSession"
    const val RECORD_KIND_AUDIOGRAM = "audiogram"
    const val RECORD_KIND_ECG = "ecg"

    // === RecordMapper Errors ===
    const val MAPPER_ERROR_NO_RECORD = "NoRecordError"
    const val MAPPER_ERROR_HEALTH_CONNECT_INSERT = "HealthConnectInsert"
    const val MAPPER_ERROR_DECODE = "DecodeError"
    const val MAPPER_ERROR_UNSUPPORTED_TYPE = "UnsupportedType"
    const val MAPPER_ERROR_UNEXPECTED = "UnexpectedError"
    const val MAPPER_ERROR_UNKNOWN = "Unknown"
    const val MAPPER_ERROR_INVALID_FORMAT = "InvalidFormat"
    const val MAPPER_ERROR_DURING_SESSION_DECODE = "DuringSessionDecodeError"
    const val MAPPER_ERROR_DURING_SESSION_INVALID_TYPE = "InvalidDuringSessionType"

    // === Data Record Value Patterns ===
    const val VALUE_PATTERN_LABEL = "label"
    const val VALUE_PATTERN_QUANTITY = "quantity"
    const val VALUE_PATTERN_CATEGORY = "category"
    const val VALUE_PATTERN_MULTIPLE = "multiple"
    const val VALUE_PATTERN_SAMPLES = "samples"

    // === Error Codes (For use with FlutterError) ===
    const val ERROR_CODE_PERMISSION_REQUEST_FAILED = "PERMISSION_REQUEST_FAILED"
    const val ERROR_CODE_PERMISSION_CHECK_FAILED = "PERMISSION_CHECK_FAILED"
    // ... other error codes

    // === Other Constants ===
    // RecordMapperFailure.indexPath, when error isn't related to an index path
    const val ERROR_NO_INDEX_PATH = -1;
}
