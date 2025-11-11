package dev.luix.connect_kit

import android.app.Activity
import android.os.Build
import androidx.fragment.app.FragmentActivity
import dev.luix.connect_kit.pigeon.AccessStatusMessage
import dev.luix.connect_kit.pigeon.ConnectKitHostApi
import dev.luix.connect_kit.pigeon.WriteResultMessage
import dev.luix.connect_kit.services.PermissionService
import dev.luix.connect_kit.services.WriteService
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.utils.CKConstants
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Implementation of the ConnectKitHostApi for Android platform.
 *
 * This class serves as a façade for platform-specific implementations, handling communication
 * between Flutter and native Android code. It delegates to specialized services for specific
 * functionality while maintaining a clean API surface.
 *
 * @constructor Creates a new CKHostApi instance
 */
class CKHostApi(
    private val scope: CoroutineScope,
    private val permissionService: PermissionService,
    private val writeService: WriteService
) : ConnectKitHostApi {

    companion object {
        // Tag for logging purposes
        private const val TAG = CKConstants.TAG_WRITE_SERVICE
    }

    // Reference to the currently attached Activity.
    // This reference is nullable to properly handle lifecycle events where the Activity
    // might be temporarily unavailable (e.g., during configuration changes).
    private var activity: Activity? = null

    // --- Lifecycle Management (Called by ConnectKitPlugin) ---

    /**
     * Called when the plugin is attached to an Activity.
     *
     * This method stores the Activity reference and performs any setup that requires an Activity
     * context. It also ensures the Activity is a FragmentActivity to support modern Androidx
     * Activity Result APIs.
     *
     * @param binding The ActivityPluginBinding containing the Activity reference
     */
    fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity

        // The host Activity must be a FragmentActivity to use modern Androidx Activity Result APIs
        (binding.activity as? FragmentActivity)?.let { fragmentActivity ->
            // Pass the FragmentActivity to the service to register the ActivityResultLauncher
            permissionService.registerActivityResultLauncher(fragmentActivity)
        }
    }

    /**
     * Called when the Activity is detached.
     *
     * This method clears the Activity reference to prevent memory leaks and notifies any services
     * to clean up pending requests or references.
     */
    fun onDetachedFromActivity() {
        // Clear the Activity reference to prevent leaks when the Activity is destroyed
        this.activity = null
        // Tell the service to clean up any pending requests/references
        permissionService.removeActivityReferences()
    }

    // --- Pigeon API Implementation ---

    /**
     * Retrieves the platform version information from the Android system.
     *
     * This method returns a formatted string containing the Android version and API level. Note:
     * This method is primarily for testing purposes and may be removed in future versions as it
     * doesn't provide value for the core health data functionality.
     *
     * @param callback The callback to return the platform version or error
     */
    override fun getPlatformVersion(callback: (Result<String>) -> Unit) {
        try {
            val platformVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
            callback(Result.success(platformVersion))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    /**
     * Checks if Health Connect SDK is available on this device.
     *
     * This method queries the Health Connect SDK status and returns one of:
     * - "available": SDK is installed and ready
     * - "unavailable": SDK is not available on this device
     * - "updateRequired": SDK is installed but needs an update
     *
     * **Usage:**
     * Call this before requesting permissions or performing any health data operations.
     * If unavailable or update required, guide users to install/update Health Connect.
     *
     * @param callback Returns SDK status string or error
     */
    override fun isSdkAvailable(callback: (Result<String>) -> Unit) {
        try {
            val isSdkAvailable = permissionService.isSdkAvailable()
            callback(Result.success(isSdkAvailable))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    /**
     * Requests Health Connect permissions for specified data types.
     *
     * This method launches a permissions prompt allowing the user to grant access to
     * read and/or write health data types, optionally including history and background permissions.
     * The permission request uses the AndroidX Activity Result API to handle results safely across
     * configuration changes.
     *
     * **Usage:**
     * - Must be called when the app has an active Activity context.
     * - Typically invoked before attempting to read or write any health records.
     *
     * @param readTypes A list of record types the app wants to read
     * @param writeTypes A list of record types the app wants to write
     * @param forHistory Whether to request permission for historical data access
     * @param forBackground Whether to request permission for background data access
     * @param callback Returns `true` if all requested permissions are granted, or an error otherwise
     */
    override fun requestPermissions(
        readTypes: List<String>?,
        writeTypes: List<String>?,
        forHistory: Boolean?,
        forBackground: Boolean?,
        callback: (Result<Boolean>) -> Unit
    ) {
        scope.launch {
            try {
                val allPermissionsGranted =
                    permissionService.requestPermissions(
                        readTypes,
                        writeTypes,
                        forHistory,
                        forBackground
                    )
                callback(Result.success(allPermissionsGranted))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    /**
     * Checks the current Health Connect permission status.
     *
     * This method verifies which permissions are currently granted for reading and/or writing
     * health data. It helps determine if a permission request is necessary before accessing data.
     *
     * **Usage:**
     * - Call this before performing operations that require permission checks.
     * - Can be used to update the UI to reflect the app’s permission state.
     *
     * @param forData A map containing requested read/write data types
     * @param forHistory Whether to include historical data permissions in the check
     * @param forBackground Whether to include background data permissions in the check
     * @param callback Returns an [AccessStatusMessage] containing detailed access information,
     * or an error if permission status cannot be determined
     */
    override fun checkPermissions(
        forData: Map<String, List<String>>?,
        forHistory: Boolean?,
        forBackground: Boolean?,
        callback: (Result<AccessStatusMessage>) -> Unit
    ) {
        scope.launch {
            try {
                val permissionsGranted =
                    permissionService.checkPermissions(forData, forHistory, forBackground)
                callback(Result.success(permissionsGranted))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    /**
     * Revokes all Health Connect permissions previously granted to the app.
     *
     * This method programmatically removes access to all health data types, effectively
     * resetting the app’s authorization state. It is useful for sign-out or privacy-related flows.
     *
     * **Usage:**
     * - Call this when the user explicitly chooses to revoke Health Connect access.
     * - After revocation, all read/write operations will fail until permissions are re-requested.
     *
     * @param callback Returns `true` if permissions were successfully revoked, or an error otherwise
     */
    override fun revokePermissions(
        callback: (Result<Boolean>) -> Unit
    ) {
        scope.launch {
            try {
                val isPermissionRevoked = permissionService.revokePermissions()
                callback(Result.success(isPermissionRevoked))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    /**
     * Opens the Health Connect settings screen.
     *
     * This method launches the Health Connect system settings page, allowing the user
     * to manually review or adjust app permissions. It is typically used when guiding users
     * to fix denied permissions or manage access after setup.
     *
     * **Usage:**
     * - Call this when the user wants to manage permissions manually.
     * - Returns immediately with success if the settings activity was opened.
     *
     * @param callback Returns `true` if the Health Connect settings page was opened successfully,
     * or an error otherwise
     */
    override fun openHealthSettings(callback: (Result<Boolean>) -> Unit) {
        try {
            val isHealthSettingsOpened = permissionService.openHealthSettings()
            callback(Result.success(isHealthSettingsOpened))
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }


    /**
     * Writes health records to the Health Connect database.
     *
     * This method encodes and writes one or more health records (e.g., workouts, nutrition,
     * sleep sessions) to Health Connect. Each record must conform to a recognized schema
     * supported by the connected platform.
     *
     * **Usage:**
     * - Ensure all required permissions are granted before calling.
     * - Use record mappers to build record maps that match expected input formats.
     * - Returns a list of record IDs that were successfully written.
     *
     * @param records A list of record maps containing the data to write
     * @param callback Returns WriteResultMessage or error
     */
    override fun writeRecords(
        records: List<Map<String, Any?>>,
        callback: (Result<WriteResultMessage>) -> Unit
    ) {
        scope.launch {
            try {
                val result = writeService.writeRecords(records)
                callback(Result.success(result))
            } catch (error: Exception) {
                CKLogger.e(
                    tag = TAG,
                    message = "Write records failed: ${error.message}",
                    error = error
                )
                callback(Result.failure(error))
            }
        }
    }
}
