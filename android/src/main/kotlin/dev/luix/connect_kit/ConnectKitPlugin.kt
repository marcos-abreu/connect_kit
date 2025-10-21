package dev.luix.connect_kit

import androidx.annotation.NonNull
import dev.luix.connect_kit.logging.CKLogger
import dev.luix.connect_kit.pigeon.ConnectKitHostApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

// Tag for logging purposes
private const val TAG = "ConnectKitPlugin"

/**
 * Main entry point for the ConnectKit Flutter plugin - Composition Root and Lifecycle Manager
 *
 * This class manages the plugin lifecycle, handles communication with the Flutter engine, and
 * coordinates between Flutter and native Android components. It implements both [FlutterPlugin] and
 * [ActivityAware] to properly handle plugin and Activity lifecycle events.
 *
 * @constructor Creates a new ConnectKitPlugin instance
 */
class ConnectKitPlugin : FlutterPlugin, ActivityAware {

    private var hostApi: CKHostApi? = null

    // CoroutineScope for all asynchronous work within the plugin
    // Uses SupervisorJob to allow child coroutines to fail without canceling the entire scope
    // Dispatchers.Main is used because the plugin primarily interacts with UI-related components
    private val pluginScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    /**
     * Called when the plugin is attached to the Flutter engine.
     *
     * This method initializes the plugin's components and sets up the Pigeon communication channel.
     * It serves as the composition root for dependency injection.
     *
     * @param flutterPluginBinding Provides the binding to the Flutter engine
     */
    override fun onAttachedToEngine(
            @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        CKLogger.i(TAG, "onAttachedToEngine: Setting up CKHostApi")
        // DEPENDENCY INJECTION: Instantiate services here (The Composition Root).
        // val flutterApi = ConnectKitFlutterApi(flutterPluginBinding.binaryMessenger)

        // Services
        // val permissionService = PermissionService(flutterPluginBinding.applicationContext,
        // pluginScope)

        // INFO: In the future we will be passing: permissionService, flutterApi, pluginScope
        hostApi = CKHostApi()

        // BINDING: Set up the Pigeon communication channel.
        ConnectKitHostApi.setUp(flutterPluginBinding.binaryMessenger, hostApi)
    }

    // --- ActivityAware Implementation ---

    /**
     * Called when the plugin is attached to an Activity.
     *
     * This method provides the Activity reference to the host API, enabling it to perform
     * operations that require Activity context.
     *
     * @param binding Provides access to the Activity and related components
     */
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        CKLogger.i(TAG, "onAttachedToActivity: ...")
        // ATTACH ACTIVITY: Store the reference and perform setup requiring the Activity.
        hostApi?.onAttachedToActivity(binding)
                ?: CKLogger.w(TAG, "onAttachedToActivity called but hostApi is null")
    }

    /**
     * Called when the Activity is about to be destroyed due to a configuration change.
     *
     * This method allows the plugin to clean up transient Activity references that should not
     * survive configuration changes (e.g., screen rotation).
     *
     * @param binding The ActivityPluginBinding that was previously attached
     */
    override fun onDetachedFromActivityForConfigChanges() {
        CKLogger.i(TAG, "onDetachedFromActivityForConfigChanges: ...")
        // CONFIGURATION CHANGE: Clean up transient Activity references (e.g., screen rotation)
        hostApi?.onDetachedFromActivity()
                ?: CKLogger.w(
                        TAG,
                        "onDetachedFromActivityForConfigChanges called but hostApi is null"
                )
    }

    /**
     * Called when the Activity has been re-created after a configuration change.
     *
     * This method allows the plugin to re-establish the Activity reference and re-register any
     * listeners or launchers that were cleaned up during the configuration change.
     *
     * @param binding The new ActivityPluginBinding after re-creation
     */
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        CKLogger.i(TAG, "onReattachedToActivityForConfigChanges: ...")
        // RE-ATTACH: Re-establish the Activity reference and re-register listeners/launchers.
        hostApi?.onAttachedToActivity(binding)
                ?: CKLogger.w(
                        TAG,
                        "onReattachedToActivityForConfigChanges called but hostApi is null"
                )
    }

    /**
     * Called when the Activity is permanently destroyed.
     *
     * This method performs final cleanup of the Activity reference and any resources that should
     * not persist after the Activity is destroyed.
     */
    override fun onDetachedFromActivity() {
        CKLogger.i(TAG, "onDetachedFromActivity: ...")
        // DETACH ACTIVITY: Final cleanup of the Activity reference.
        hostApi?.onDetachedFromActivity()
                ?: CKLogger.w(TAG, "onDetachedFromActivity called but hostApi is null")
    }

    // --- Plugin Detachment ---

    /**
     * Called when the plugin is detached from the Flutter engine.
     *
     * This method performs final cleanup, including unregistering the Pigeon API and canceling the
     * CoroutineScope to prevent memory leaks.
     *
     * @param binding The FlutterPluginBinding that was previously attached
     */
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        CKLogger.i(TAG, "onDetachedFromEngine: final cleanup")

        // FINAL CLEANUP: Unregister the Pigeon API and cancel the Coroutine Scope
        ConnectKitHostApi.setUp(binding.binaryMessenger, null)
        pluginScope.cancel() // Crucial to prevent leaks and stop all background work
        hostApi = null
    }
}
