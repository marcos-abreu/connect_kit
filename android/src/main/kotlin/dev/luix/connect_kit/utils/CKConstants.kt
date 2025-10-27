package dev.luix.connect_kit.utils

/**
 * Defines shared constants used for cross-platform string logic and communication between Dart and
 * Native code.
 */
object CKConstants {

    // --- Logging Tags ---
    const val TAG_CONNECT_KIT = "ConnectKit"
    const val TAG_PERMISSION_SERVICE = "PermissionService"

    // --- Health Connect SDK Status ---
    const val SDK_STATUS_AVAILABLE = "available"
    const val SDK_STATUS_UNAVAILABLE = "unavailable"
    const val SDK_STATUS_UPDATE_REQUIRED = "updateRequired"

    // --- Access Types (Must match Dart/Pigeon definitions) ---
    const val ACCESS_TYPE_READ = "read"
    const val ACCESS_TYPE_WRITE = "write"

    // --- Status Types (Must match Dart status interpretation) ---
    const val PERMISSION_STATUS_GRANTED = "granted"
    const val PERMISSION_STATUS_DENIED = "denied"
    const val PERMISSION_STATUS_NOT_SUPPORTED = "notSupported"
    // Note: STATUS_NOT_DETERMINED and STATUS_UNKNOWN are typically iOS only

    // --- Error Codes (For use with FlutterError) ---
    const val ERROR_CODE_PERMISSION_REQUEST_FAILED = "PERMISSION_REQUEST_FAILED"
    const val ERROR_CODE_PERMISSION_CHECK_FAILED = "PERMISSION_CHECK_FAILED"
    // ... other error codes
}
