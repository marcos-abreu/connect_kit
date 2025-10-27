import Flutter
import UIKit

/// Main entry point for the ConnectKit Flutter plugin on iOS.
/// This class handles the Flutter engine lifecycle and acts as the Composition Root
public class ConnectKitPlugin: NSObject, FlutterPlugin {

    // Tag for logging purposes
    private static let TAG = "ConnectKitPlugin"

    // Services and components
    private var hostApi: CKHostApi
    private var permissionService: PermissionService

    // Plugin scope for async operations (iOS equivalent of Android's pluginScope)
    private let pluginQueue = DispatchQueue(
        label: "dev.luix.connect_kit.plugin", qos: .userInitiated)

    /// Called once when the plugin is registered with the Flutter engine.
    /// This is where the Pigeon communication channel is set up
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Create plugin instance
        //
        // IMPORTANT TIMING NOTE:
        // The line below IMMEDIATELY triggers the init() method, which:
        // 1. Creates and initializes all services (PermissionService, CKHostApi)
        // 2. Sets up dependency injection (services are passed to their dependents)
        // 3. Configures lifecycle observers
        //
        // This means by the time we reach the next line, `instance.hostApi` is a fully
        // initialized object ready to handle Flutter messages. This is different from
        // some other platforms where initialization might be deferred or lazy.
        let instance = ConnectKitPlugin()

        // Setup Flutter communication channel
        // At this point, instance.hostApi is fully initialized and ready to handle messages
        let messenger = registrar.messenger()
        ConnectKitHostApiSetup.setUp(binaryMessenger: messenger, api: instance.hostApi)

        // CRITICAL: Publish instance to enable lifecycle callbacks (detachFromEngineForRegistrar)
        // This follows Flutter's recommended pattern for proper resource cleanup
        registrar.publish(instance)

        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "Plugin registered successfully")
    }

    /// The Composition Root: Instantiate services and inject them.
    /// Following Android's pattern from onAttachedToEngine
    private override init() {
        // DEPENDENCY INJECTION: Instantiate services here (Composition Root)
        // This follows Android's pattern where services are created in onAttachedToEngine
        // NOTE: All properties must be initialized before calling super.init() in Swift
        self.permissionService = PermissionService()
        self.hostApi = CKHostApi(permissionService: self.permissionService)

        super.init()

        // Setup lifecycle observers for Android-equivalent lifecycle management
        setupLifecycleObservers()

        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "ConnectKit initialized with services")
    }

    // MARK: - Lifecycle Management (Android-equivalent)

    /// Setup iOS lifecycle observers to match Android's ActivityAware behavior
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )

        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "Lifecycle observers setup complete")
    }

    /// Called when app enters background (equivalent to Android's onDetachedFromActivity)
    @objc private func appDidEnterBackground() {
        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "App entered background")
        // Similar to Android: pause operations, save state
        hostApi.onAppDidEnterBackground()
    }

    /// Called when app will enter foreground (equivalent to Android's onReattachedToActivityForConfigChanges)
    @objc private func appWillEnterForeground() {
        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "App will enter foreground")
        // Similar to Android: resume operations, refresh state
        hostApi.onAppWillEnterForeground()
    }

    /// Called when app will terminate (final cleanup, similar to Android's onDetachedFromEngine)
    @objc private func appWillTerminate() {
        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "App will terminate")
        // Final cleanup before app termination
        cleanup()
    }

    /// Cleanup method for proper resource management
    private func cleanup() {
        // Remove observers
        NotificationCenter.default.removeObserver(self)

        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "Plugin cleanup completed")
    }

    // MARK: - FlutterPlugin Protocol

    /// Called when the plugin is detached from the Flutter engine.
    /// This follows the current FlutterPlugin protocol signature for iOS.
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        // Clean up: Unregister the Pigeon API to prevent leaks and stop messages.
        ConnectKitHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)

        // Perform additional cleanup
        cleanup()

        CKLogger.i(tag: ConnectKitPlugin.TAG, message: "Plugin detached from engine")
    }
}
