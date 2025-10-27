import Foundation
import HealthKit

/// Service for managing HealthKit permissions and availability on iOS.
/// Provides comprehensive permission request flows with robust error handling and logging.
class PermissionService {
    private let healthStore: HKHealthStore
    private static let TAG = CKConstants.TAG_PERMISSION_SERVICE

    init() {
        self.healthStore = HKHealthStore()
        CKLogger.i(tag: PermissionService.TAG, message: "PermissionService initialized")
    }

    /**
     * Get the current HealthStore instance for further HealthKit operations.
     *
     * @return the HKHealthStore instance
     */
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }

    // MARK: - ConnectKitFlutterApi Implementation

    // TODDO: This file uses lots of string values, this should use some kind of
    //        enum or contants - similar how the Android CKConstants work

    /// TODO: add documentation
    func isSdkAvailable() -> String {
        guard HKHealthStore.isHealthDataAvailable() else {
            return "unavailable"
        }
        return "available"
    }

    /**
     * Request permissions for health data access.
     *
     * This method validates all requested types and filters out unsupported ones before
     * making the authorization request. Invalid types are logged but don't cause failure.
     *
     * @param readTypes Array of type identifiers for read access
     * @param writeTypes Array of type identifiers for write access
     * @return Boolean indicating if the authorization dialog was shown successfully
     * @throws Error if HealthKit authorization fails
     */
    func requestPermissions(readTypes: [String]?, writeTypes: [String]?) async throws -> Bool {
        // Clean input
        let readTypeNames = readTypes ?? []
        let writeTypeNames = writeTypes ?? []

        // Build validated type sets using our robust getObjectType
        var hkReadTypes = Set<HKObjectType>()
        var hkWriteTypes = Set<HKSampleType>()

        // Validate and collect READ types
        for typeName in readTypeNames {
            if let objectType = RecordTypeMapper.getObjectType(
                recordType: typeName,
                accessType: .read
            ) {
                hkReadTypes.insert(objectType)
            }
            // getObjectType already logged why it failed
        }

        // Validate and collect WRITE types
        for typeName in writeTypeNames {
            if let objectType = RecordTypeMapper.getObjectType(
                recordType: typeName,
                accessType: .write
            ) {
                // getObjectType guarantees this is an HKSampleType for write access
                hkWriteTypes.insert(objectType as! HKSampleType)
            }
            // getObjectType already logged why it failed (read-only, correlation, etc.)
        }

        // Check if we have any valid types to request
        if hkReadTypes.isEmpty && hkWriteTypes.isEmpty {
            CKLogger.w(
                tag: PermissionService.TAG,
                message: "No valid permissions to request. All requested types were filtered out. "
                    + "Check logs above for reasons."
            )
            return true  // No error, just nothing to do
        }

        // Log what we're actually requesting
        CKLogger.i(
            tag: PermissionService.TAG,
            message: "Requesting authorization for \(hkReadTypes.count) read types "
                + "and \(hkWriteTypes.count) write types"
        )

        // TODO: investigate this:
        //       Using the requestAuthorization(toShare:read:) method to request read access to any data types that require per-object authorization fails with an HKError.Code.errorInvalidArgument error.
        //       ref: https://developer.apple.com/documentation/healthkit/hkobjecttype/requiresperobjectauthorization()
        //       ref: https://developer.apple.com/documentation/healthkit/hkhealthstore/requestperobjectreadauthorization(for:predicate:completion:)

        // Make the authorization request
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: hkWriteTypes, read: hkReadTypes) {
                success, error in
                if let error = error {
                    CKLogger.e(
                        tag: PermissionService.TAG,
                        message: "Authorization request failed: \(error.localizedDescription)",
                        error: error
                    )
                    continuation.resume(throwing: error)
                } else {
                    // Reference: https://developer.apple.com/documentation/healthkit/hkhealthstore/requestauthorization(toshare:read:completion:)
                    // The 'success' parameter indicates whether the request succeeded (no errors occurred)
                    // It does NOT indicate whether the user actually granted permission

                    CKLogger.i(
                        tag: PermissionService.TAG,
                        message: "Authorization dialog shown successfully"
                    )
                    continuation.resume(returning: success)
                }
            }
        }
    }

    /// Checks the current permission status for specified health data types.
    ///
    /// This method determines the authorization status for requested health data types.
    /// On iOS, read permissions may return 'unknown' status due to Apple's privacy rules.
    /// When 'unknown' is returned for read access, you must attempt to read the actual
    /// health data to determine if access is truly granted.
    ///
    /// - Parameter forData: Dictionary mapping health data types to access types (read/write)
    /// - Returns: AccessStatusMessage containing detailed permission status information
    func checkPermissions(forData: [String: [String]]?) async throws -> AccessStatusMessage {
        // Early return if nothing to check
        guard let forData = forData, !forData.isEmpty else {
            return AccessStatusMessage(dataAccess: [:])
        }

        var dataAccess: [String: [String: String]] = [:]

        for (shortName, requestedAccessTypes) in forData {
            var accessTypeMap: [String: String] = [:]

            // Check READ
            if requestedAccessTypes.contains(CKConstants.ACCESS_TYPE_READ) {
                if let readType = RecordTypeMapper.getObjectType(
                    recordType: shortName,
                    accessType: .read
                ) {
                    let status = healthStore.authorizationStatus(for: readType)
                    accessTypeMap[CKConstants.ACCESS_TYPE_READ] = statusToString(status)
                } else {
                    // INFO: getObjectType already logged why it failed
                    // Type doesn't exist, OS version too old, or other technical reason
                    accessTypeMap[CKConstants.ACCESS_TYPE_READ] =
                        CKConstants.PERMISSION_STATUS_UNSUPPORTED
                }
            }

            // Check WRITE
            if requestedAccessTypes.contains(CKConstants.ACCESS_TYPE_WRITE) {
                // getObjectType handles ALL validation logic
                if let writeType = RecordTypeMapper.getObjectType(
                    recordType: shortName,
                    accessType: .write
                ) {
                    // If returned, it's guaranteed to be a writable HKSampleType
                    let sampleType = writeType as! HKSampleType
                    let status = healthStore.authorizationStatus(for: sampleType)
                    accessTypeMap[CKConstants.ACCESS_TYPE_WRITE] = statusToString(status)
                } else {
                    // INFO: getObjectType already logged why it failed (read-only, correlation, etc.)
                    // Type is read-only, correlation, doesn't exist, or OS too old
                    accessTypeMap[CKConstants.ACCESS_TYPE_WRITE] =
                        CKConstants.PERMISSION_STATUS_UNSUPPORTED
                }
            }

            if !accessTypeMap.isEmpty {
                dataAccess[shortName] = accessTypeMap
            }
        }

        return AccessStatusMessage(dataAccess: dataAccess)
    }

    // *--- revokePermissions ---------------------------------------
    /// NOTE: revokePermissions is not implemented here because iOS HealthKit does not support
    /// programmatic permission revocation. The method is handled in CKHostApi where it
    /// returns false to indicate the limitation, guiding users to manually manage permissions
    /// through iOS Settings.
    // *-------------------------------------------------------------

    /// Opens iOS Settings where users can manage app settings.
    ///
    /// Opens the app's settings page in iOS Settings. From there, users can navigate:
    /// Settings → [Your App] → Health → Data Access & Devices → [Your App]
    ///
    /// iOS does not provide deep linking to specific HealthKit permission screens.
    ///
    /// - Returns: Boolean indicating whether settings were successfully opened
    /// - Throws: Error if settings URL creation or opening fails
    func openHealthSettings() async throws -> Bool {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            CKLogger.w(
                tag: PermissionService.TAG,
                message: "Failed to create iOS settings URL"
            )
            throw NSError(
                domain: "PermissionService",
                code: 1002,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create iOS settings URL"
                ]
            )
        }

        CKLogger.i(
            tag: PermissionService.TAG,
            message: "Opening iOS app settings"
        )

        let result = await UIApplication.shared.open(settingsUrl)

        if result {
            CKLogger.i(
                tag: PermissionService.TAG,
                message: "Successfully opened iOS app settings"
            )
        } else {
            CKLogger.w(
                tag: PermissionService.TAG,
                message: "Failed to open iOS settings - UIApplication.open returned false"
            )
        }

        return result
    }

    // MARK: - Helpers

    /// Converts HealthKit authorization status to string constants.
    ///
    /// This method maps the native HealthKit status codes to the unified string constants
    /// used across the ConnectKit API. These constants must match the Android implementation.
    ///
    /// - Parameter status: The HKAuthorizationStatus from HealthKit
    /// - Returns: String constant representing the permission status
    private func statusToString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            // User hasn't been asked for permission yet or request is pending
            return CKConstants.PERMISSION_STATUS_NOT_DETERMINED
        case .sharingDenied:
            // User explicitly denied permission access
            return CKConstants.PERMISSION_STATUS_DENIED
        case .sharingAuthorized:
            // User granted permission access
            return CKConstants.PERMISSION_STATUS_GRANTED
        @unknown default:
            // Unknown status (future iOS versions or edge cases)
            return CKConstants.PERMISSION_STATUS_UNKNOWN
        }
    }
}
