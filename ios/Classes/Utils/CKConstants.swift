import Foundation

/// Defines shared constants used for cross-platform string logic and communication between Dart and
/// Native iOS code. These constants must match the Android CKConstants.kt values.
public struct CKConstants {

    // MARK: - Logging Tags

    /// Main tag for ConnectKit logging
    static let TAG_CONNECT_KIT = "ConnectKit"

    /// Tag for PermissionService logging
    static let TAG_PERMISSION_SERVICE = "PermissionService"

    // MARK: - HealthKit SDK Status

    /// HealthKit is available and ready to use
    static let SDK_STATUS_AVAILABLE = "available"

    /// HealthKit is not available on this device
    static let SDK_STATUS_UNAVAILABLE = "unavailable"

    /// HealthKit requires an update (iOS-specific equivalent)
    static let SDK_STATUS_UPDATE_REQUIRED = "updateRequired"

    // MARK: - Access Types (Must match Dart/Pigeon definitions)

    /// Read access to health data
    static let ACCESS_TYPE_READ = "read"

    /// Write access to health data
    static let ACCESS_TYPE_WRITE = "write"

    // MARK: - Permission Status Types (Must match Dart status interpretation)

    /// Permission has been granted by the user
    static let PERMISSION_STATUS_GRANTED = "granted"

    /// Permission has been denied by the user
    static let PERMISSION_STATUS_DENIED = "denied"

    /// Permission status has not been determined yet (iOS specific)
    static let PERMISSION_STATUS_NOT_DETERMINED = "notDetermined"

    /// Permission status cannot be determined due to privacy rules (iOS read access specific)
    static let PERMISSION_STATUS_UNKNOWN = "unknown"

    /// Permission status cannot be determined due to privacy rules (iOS read access specific)
    static let PERMISSION_STATUS_UNSUPPORTED = "unsupported"

    // MARK: - Error Codes (For use with FlutterError)

    /// Permission request failed or was interrupted
    static let ERROR_CODE_PERMISSION_REQUEST_FAILED = "PERMISSION_REQUEST_FAILED"

    /// Permission status check failed
    static let ERROR_CODE_PERMISSION_CHECK_FAILED = "PERMISSION_CHECK_FAILED"

    /// HealthKit is not available on this device
    static let ERROR_CODE_HEALTHKIT_NOT_AVAILABLE = "HEALTHKIT_NOT_AVAILABLE"

    /// Invalid health data type requested
    static let ERROR_CODE_INVALID_HEALTH_TYPE = "INVALID_HEALTH_TYPE"
}
