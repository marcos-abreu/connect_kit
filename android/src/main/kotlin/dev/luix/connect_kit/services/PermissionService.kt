package dev.luix.connect_kit.services

import android.os.Build
import android.content.Context
import android.content.Intent;
import android.net.Uri
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.pigeon.AccessStatusMessage
import dev.luix.connect_kit.mapper.RecordTypeMapper
import dev.luix.connect_kit.utils.CKConstants
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Service for managing Health Connect permissions and availability on Android Handles
 * production-ready permission request flows with Activity integration and coroutine support
 */
class PermissionService(
    private val context: Context,
    private val scope: CoroutineScope,
    private val healthConnectClient: HealthConnectClient
) {

    companion object {
        private const val TAG = CKConstants.TAG_PERMISSION_SERVICE
    }

    // Launcher for starting the Health Connect permission UI
    private lateinit var permissionRequestLauncher: ActivityResultLauncher<Set<String>>

    // Coroutine Continuation to hold the suspended call until the UI returns
    private var pendingPermissionRequest: CancellableContinuation<Boolean>? = null

    // The specific set of permissions requested, needed for verification after the UI closes
    private var lastRequestedPermissions: Set<String>? = null

    // --- Lifecycle Management (Called by ConnectKitHostApiImpl) ---

    /**
     * Registers the launcher for the Health Connect permission request This MUST be called when the
     * Activity is attached, before its STARTED state
     */
    fun registerActivityResultLauncher(activity: FragmentActivity) {
        // Use the official Health Connect Contract for reliable results
        permissionRequestLauncher =
            activity.registerForActivityResult(
                PermissionController.createRequestPermissionResultContract()
            ) { grantedPermissions: Set<String> ->
                // This is the synchronous callback on the Main Thread

                // Store locally before clearing
                val pending = pendingPermissionRequest
                val requested = lastRequestedPermissions

                // Immediately clear the state before processing (prevent leaks)
                pendingPermissionRequest = null
                lastRequestedPermissions = null

                if (pending == null || requested == null) {
                    CKLogger.w(
                        tag = TAG,
                        message = "Permission result received but no pending request was active"
                    )
                    return@registerForActivityResult
                }

                // This allows us to call the suspended `checkAllPermissionsGranted`
                // without blocking the Main Thread (avoiding ANR)
                scope.launch {
                    // Perform the final, authoritative check with the Health Connect client
                    val success = checkAllPermissionsGranted(requested)

                    // Resume the original suspended Dart call with the result
                    pending.resume(success)
                }
            }

        CKLogger.i(tag = TAG, message = "Permission request launcher registered successfully")
    }

    /** Cleans up transient references when the Activity detaches */
    fun removeActivityReferences() {
        // Cancel the continuation if a request was pending when the Activity was detached
        pendingPermissionRequest?.cancel()
        pendingPermissionRequest = null
        lastRequestedPermissions = null
    }

    // --- Permission Management ---

    /**
     * Check if Health Connect SDK is available on this device
     *
     * @return String indicating the SDK availability status
     */
    fun isSdkAvailable(): String {
        return try {
            val sdkStatus = HealthConnectClient.getSdkStatus(context)
            when (sdkStatus) {
                HealthConnectClient.SDK_AVAILABLE -> CKConstants.SDK_STATUS_AVAILABLE
                HealthConnectClient.SDK_UNAVAILABLE -> CKConstants.SDK_STATUS_UNAVAILABLE
                HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED ->
                    CKConstants.SDK_STATUS_UPDATE_REQUIRED

                else -> CKConstants.SDK_STATUS_UNAVAILABLE
            }
        } catch (e: Exception) {
            CKConstants.SDK_STATUS_UNAVAILABLE
        }
    }

    /**
     * Requests permissions and SUSPENDS until the user returns from the Health Connect UI, then
     * verifies if ALL requested permissions were granted
     * @return Boolean: true if all requested permissions were granted, false otherwise
     */
    suspend fun requestPermissions(
        readTypes: List<String>?,
        writeTypes: List<String>?,
        forHistory: Boolean?,
        forBackground: Boolean?
    ): Boolean = suspendCancellableCoroutine { continuation ->
        if (!::permissionRequestLauncher.isInitialized) {
            continuation.resumeWithException(
                IllegalStateException(
                    "Permission launcher not initialized. Plugin is not attached to a FragmentActivity."
                )
            )
            return@suspendCancellableCoroutine
        }

        val permissions = buildPermissions(readTypes, writeTypes, forHistory, forBackground)

        if (permissions.isEmpty()) {
            CKLogger.w(
                tag = TAG,
                message = "No valid permissions to request. All types were filtered out. " +
                        "Check logs above for reasons."
            )
            continuation.resume(true)
            return@suspendCancellableCoroutine
        }

        // Log what we're requesting
        CKLogger.i(
            tag = TAG,
            message = "Requesting ${permissions.size} permissions from Health Connect"
        )

        // Safety check
        if (pendingPermissionRequest != null) {
            continuation.resumeWithException(
                IllegalStateException("A permission request is already in progress.")
            )
            return@suspendCancellableCoroutine
        }

        try {
            // Store the state BEFORE launching the UI
            pendingPermissionRequest = continuation
            lastRequestedPermissions = permissions

            // Launch the Health Connect permission screen
            permissionRequestLauncher.launch(permissions)

            // Clean up state if the Dart side cancels the request (e.g., Timeout)
            continuation.invokeOnCancellation {
                pendingPermissionRequest = null
                lastRequestedPermissions = null
            }
        } catch (e: Exception) {
            pendingPermissionRequest = null
            lastRequestedPermissions = null
            continuation.resumeWithException(e)
        }
    }

    /**
     * Check current permission status for health data access.
     *
     * @param request Permission check request with types and optional boolean flags
     * @return Permission check result with detailed status information
     */
    suspend fun checkPermissions(
        forData: Map<String, List<String>>?,
        forHistory: Boolean?,
        forBackground: Boolean?
    ): AccessStatusMessage {
        // Early return if nothing to check
        if (forData == null && forHistory != true && forBackground != true) {
            return AccessStatusMessage(
                dataAccess = emptyMap(),
                historyAccess = null,
                backgroundAccess = null
            )
        }

        val grantedPermissions =
            healthConnectClient.permissionController.getGrantedPermissions()

        val dataAccess: MutableMap<String, Map<String, String>> = mutableMapOf()

        forData?.forEach { (healthType, accessTypes) ->
            // Get record class with full validation (including feature availability)
            val recordClass = RecordTypeMapper.getRecordClass(healthType, healthConnectClient)

            if (recordClass == null) {
                // Type not supported - return unsupported status for all requested access types
                val unsupportedMap = accessTypes.associateWith {
                    CKConstants.PERMISSION_STATUS_NOT_SUPPORTED
                }
                dataAccess[healthType] = unsupportedMap
                // getRecordClass already logged the specific reason
                return@forEach
            }

            // Build access type map
            val accessTypeMap: Map<String, String> = buildMap(accessTypes.size) {
                accessTypes.forEach { accessType ->
                    val permission = when (accessType) {
                        CKConstants.ACCESS_TYPE_READ ->
                            HealthPermission.getReadPermission(recordClass)

                        CKConstants.ACCESS_TYPE_WRITE ->
                            HealthPermission.getWritePermission(recordClass)

                        else -> {
                            CKLogger.w(
                                tag = TAG,
                                message = "Invalid access type '$accessType' for health type '$healthType'"
                            )
                            null
                        }
                    }

                    // Add permission status
                    permission?.let {
                        put(
                            accessType,
                            if (grantedPermissions.contains(it)) {
                                CKConstants.PERMISSION_STATUS_GRANTED
                            } else {
                                CKConstants.PERMISSION_STATUS_DENIED
                            }
                        )
                    }
                }
            }

            if (accessTypeMap.isNotEmpty()) {
                dataAccess[healthType] = accessTypeMap
            }
        }

        // Check history permission (uses feature flag)
        val historyAccess = when {
            forHistory != true -> null
            else -> {
                // Check if feature is available
                val featureAvailable = try {
                    healthConnectClient.features.getFeatureStatus(
                        HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY
                    ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
                } catch (e: Exception) {
                    CKLogger.w(tag = TAG, message = "Failed to check history feature: ${e.message}")
                    false
                }

                if (!featureAvailable) {
                    CKConstants.PERMISSION_STATUS_NOT_SUPPORTED
                } else if (grantedPermissions.contains(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY)) {
                    CKConstants.PERMISSION_STATUS_GRANTED
                } else {
                    CKConstants.PERMISSION_STATUS_DENIED
                }
            }
        }

        // Check background permission (uses feature flag)
        val backgroundAccess = when {
            forBackground != true -> null
            else -> {
                // Check if feature is available
                val featureAvailable = try {
                    healthConnectClient.features.getFeatureStatus(
                        HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_IN_BACKGROUND
                    ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
                } catch (e: Exception) {
                    CKLogger.w(tag = TAG, message = "Failed to check background feature: ${e.message}")
                    false
                }

                if (!featureAvailable) {
                    CKConstants.PERMISSION_STATUS_NOT_SUPPORTED
                } else if (grantedPermissions.contains(HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)) {
                    CKConstants.PERMISSION_STATUS_GRANTED
                } else {
                    CKConstants.PERMISSION_STATUS_DENIED
                }
            }
        }

        return AccessStatusMessage(
            dataAccess = dataAccess,
            historyAccess = historyAccess,
            backgroundAccess = backgroundAccess
        )
    }

    /**
     * Revokes ALL Health Connect permissions for this app.
     *
     * IMPORTANT NOTES:
     * - This revokes ALL permissions at once (cannot revoke individual types)
     * - Changes may not be immediately reflected in permission checks
     * - App restart may be required for changes to take full effect
     * - Android recommends directing users to Settings instead (more transparent)
     *
     * Consider using openHealthSettings() for a more reliable user experience.
     *
     * @return Boolean: true if revocation API call succeeded, false otherwise
     */
    suspend fun revokePermissions(): Boolean {
        return try {
            // Check if any permissions are currently granted
            val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()

            if (grantedPermissions.isEmpty()) {
                CKLogger.i(tag = TAG, message = "No permissions to revoke - none are granted")
                return true
            }

            CKLogger.i(
                tag = TAG,
                message = "Revoking ${grantedPermissions.size} Health Connect permissions"
            )

            // Revoke all permissions
            healthConnectClient.permissionController.revokeAllPermissions()

            CKLogger.i(
                tag = TAG,
                message = "Permission revocation API call completed successfully. " +
                        "Note: Changes may require app restart to take full effect."
            )

            true
        } catch (e: Exception) {
            CKLogger.e(
                tag = TAG,
                message = "Failed to revoke permissions: ${e.message}",
                error = e
            )
            false
        }
    }


    /**
     * Opens Health Connect or app settings for permission management.
     *
     * Priority order (most specific to least specific):
     * 1. Android 14+: App's Health Connect permission screen (if available)
     * 2. Android 13-: General Health Connect settings (if available)
     * 3. Fallback: App's system settings page
     *
     * Note: Method 1 requires GRANT_RUNTIME_PERMISSIONS (privileged permission),
     * so it will fail for 3rd party apps but gracefully falls back to method 2/3.
     *
     * @return Boolean indicating if any settings screen was successfully opened
     */
    fun openHealthSettings(): Boolean {
        // Try Method 1: Android 14+ - Direct to app's Health Connect permissions
        // NOTE: Although this intent is part of public SDK, lauching it requires
        //       privileged system-only `GRANT_RUNTIME_PERMISSIONS, currently only
        //       privileged OEM apps or system-signed apps, not 3rd party apps (yet).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                val intent = Intent(
                    android.health.connect.HealthConnectManager.ACTION_MANAGE_HEALTH_PERMISSIONS
                ).apply {
                    putExtra(Intent.EXTRA_PACKAGE_NAME, context.packageName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }

                context.startActivity(intent)
                CKLogger.i(
                    tag = TAG,
                    message = "Opened Health Connect app permission screen (Android 14+)"
                )
                return true
            } catch (e: Exception) {
                CKLogger.w(
                    tag = TAG,
                    message = "Health Connect permission intent failed (Android 14+). Likely restricted to system apps: ${e.message}"
                )
                // Continue to fallback
            }
        }

        // Try Method 2: Android 13- - General Health Connect settings
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                val intent = Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }

                context.startActivity(intent)
                CKLogger.i(
                    tag = TAG,
                    message = "Opened Health Connect general settings (Android 13-)"
                )
                return true
            } catch (e: Exception) {
                CKLogger.w(
                    tag = TAG,
                    message = "Failed to open Health Connect settings: ${e.message}"
                )
                // Continue to fallback
            }
        }

        // Fallback: App system settings
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }

            context.startActivity(intent)
            CKLogger.i(
                tag = TAG,
                message = "Opened app system settings as fallback"
            )
            true
        } catch (e: Exception) {
            CKLogger.e(
                tag = TAG,
                message = "Failed to open any settings screen: ${e.message}",
                error = e
            )
            false
        }
    }

    // --- Helpers ---

    /**
     * Authoritative check: uses the Health Connect client to confirm all permissions are granted
     */
    private suspend fun checkAllPermissionsGranted(permissions: Set<String>): Boolean {
        // Health Connect API call (Suspend function)
        val grantedPermissions = healthConnectClient.permissionController.getGrantedPermissions()

        // Return true only if the granted set contains ALL of the requested permissions
        return grantedPermissions.containsAll(permissions)
    }

    /**
     * Build Health Connect permissions from the request message Maps the Dart/Pigeon message into a
     * set of permission strings using Health Connect API
     */
    private fun buildPermissions(
        readTypes: List<String>?,
        writeTypes: List<String>?,
        forHistory: Boolean?,
        forBackground: Boolean?
    ): Set<String> {
        val permissions = mutableSetOf<String>()

        // Add history permission if requested AND feature is available
        if (forHistory == true) {
            val historyFeatureAvailable = try {
                healthConnectClient.features.getFeatureStatus(
                    HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY
                ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
            } catch (e: Exception) {
                CKLogger.w(tag = TAG, message = "History feature check failed: ${e.message}")
                false
            }

            if (historyFeatureAvailable) {
                permissions.add(HealthPermission.PERMISSION_READ_HEALTH_DATA_HISTORY)
            } else {
                CKLogger.w(
                    tag = TAG,
                    message = "History data feature not available - user needs to update Health Connect"
                )
            }
        }

        // Add background permission if requested AND feature is available
        if (forBackground == true) {
            val backgroundFeatureAvailable = try {
                healthConnectClient.features.getFeatureStatus(
                    HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_IN_BACKGROUND
                ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
            } catch (e: Exception) {
                CKLogger.w(tag = TAG, message = "Background feature check failed: ${e.message}")
                false
            }

            if (backgroundFeatureAvailable) {
                permissions.add(HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)
            } else {
                CKLogger.w(
                    tag = TAG,
                    message = "Background read feature not available - user needs to update Health Connect"
                )
            }
        }

        // Process read permissions
        readTypes?.forEach { typeName ->
            val recordClass = RecordTypeMapper.getRecordClass(typeName, healthConnectClient)
            if (recordClass != null) {
                permissions.add(HealthPermission.getReadPermission(recordClass))
            }
            // getRecordClass already logged if it's unsupported
        }

        // Process write permissions
        writeTypes?.forEach { typeName ->
            val recordClass = RecordTypeMapper.getRecordClass(typeName, healthConnectClient)
            if (recordClass != null) {
                permissions.add(HealthPermission.getWritePermission(recordClass))
            }
            // getRecordClass already logged if it's unsupported
        }

        return permissions
    }
}
