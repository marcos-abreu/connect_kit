package dev.luix.connect_kit

import android.app.Activity
import android.os.Build
import androidx.fragment.app.FragmentActivity
import dev.luix.connect_kit.pigeon.ConnectKitHostApi
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Implementation of the ConnectKitHostApi for Android platform.
 *
 * This class serves as a façade for platform-specific implementations, handling communication
 * between Flutter and native Android code. It delegates to specialized services for specific
 * functionality while maintaining a clean API surface.
 *
 * @constructor Creates a new CKHostApi instance
 */
class CKHostApi() : ConnectKitHostApi {

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
            // permissionService.registerActivityResultLauncher(fragmentActivity)
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
        // permissionService.removeActivityReferences()
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
}
