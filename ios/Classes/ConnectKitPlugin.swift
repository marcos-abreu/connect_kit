import Flutter
import UIKit

/// Main entry point for the ConnectKit Flutter plugin on iOS.
/// This class handles the Flutter engine lifecycle and acts as the Composition Root
public class ConnectKitPlugin: NSObject, FlutterPlugin {

    // Tag for logging purposes
    private static let TAG = "ConnectKitPlugin"

    // The Pigeon facade implementation
    private var hostApi: CKHostApi

    /// The Composition Root: Instantiate services and inject them.
    override init() {
        // DEPENDENCY INJECTION: Instantiate services here
        // self.flutterApi = ConnectKitFlutterApi(binaryMessenger: binaryMessenger)
        // self.permissionService = PermissionService()

        // Instantiate the Host API facade
        self.hostApi = CKHostApi()

        super.init()
    }

    /// Called when the plugin is registered with the Flutter engine.
    /// This is where the Pigeon communication channel is set up
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let instance = ConnectKitPlugin()

        // Set up the Pigeon communication channel. This replaces all MethodChannel delegates
        ConnectKitHostApiSetup.setUp(binaryMessenger: messenger, api: instance.hostApi)
        // Set up Flutter API callbacks
        // ConnectKitFlutterApiSetup.setUp(binaryMessenger: messenger, api: permissionService)

        CKLogger.i(tag: TAG, message: "Plugin registered")
    }

    // MARK: - FlutterPlugin Protocol

    /// Called when the plugin is detached from the Flutter engine.
    public static func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        // Clean up: Unregister the Pigeon API to prevent leaks and stop messages.
        ConnectKitHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)

        CKLogger.i(tag: TAG, message: "Plugin detached from engine")
    }
}

// // MARK: - FlutterAppLifeCycleProvider (Optional for future use)
// extension ConnectKitPlugin: FlutterAppLifeCycleProvider {

//     /// Handle app moving to the background (e.g., pause timers/work)
//     public func applicationDidEnterBackground(_ application: UIApplication) {
//         // hostApi.handleBackground()
//     }

//     /// Handle app returning to the foreground (e.g., resume work)
//     public func applicationWillEnterForeground(_ application: UIApplication) {
//         // hostApi.handleForeground()
//     }
// }
