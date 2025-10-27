I'll provide you with comprehensive information about Flutter iOS plugin implementation with Swift. Let me search for the most current official documentation and examples.Let me search for the actual Swift source code file.Let me try to get the source code from a raw GitHub URL.Now let me compile comprehensive information based on what I've found. I'll create a detailed answer covering all your questions with code examples.

Based on my research of Flutter's official documentation and real plugin implementations, here's comprehensive information about implementing Flutter plugins for iOS with Swift:

## 1. FlutterPlugin Protocol Definition

The FlutterPlugin protocol is defined in FlutterPlugin.h and includes both required and optional methods for plugin lifecycle management.

The protocol includes:

**Required Methods:**
```swift
public static func register(with registrar: FlutterPluginRegistrar)
```

**Optional Methods:**
```swift
public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar)
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
```

## 2. Method Types and Signatures

The `register(with:)` method is a **static class method** (marked as `staticrequired` in the protocol), while `detachFromEngineForRegistrar:` is an **optional instance method**.

**Exact Swift Signatures:**

```swift
// Static class method - REQUIRED
public static func register(with registrar: FlutterPluginRegistrar) {
    // Setup code here
}

// Instance method - OPTIONAL
public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar) {
    // Cleanup code here
}

// Instance method - OPTIONAL
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Handle method calls
}
```

## 3. Instance Lifecycle Management

Flutter creates plugin instances during the call to `PluginRegistry.add(FlutterPlugin)`, and the FlutterEngine invokes `onAttachedToEngine` on the plugin, maintaining the plugin instance as long as it's attached. The `detachFromEngineForRegistrar:` method is called when a plugin is being removed from a FlutterEngine, usually when the engine is deallocated, and is only received if the plugin registered itself via `-[FlutterPluginRegistry publish:]`.

Flutter maintains plugin instances after registration until the engine is destroyed.

## 4. Real-World Implementation Examples

Here's a complete example based on the pattern used in official Flutter plugins:

```swift
import Flutter
import UIKit

public class MyPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?

    // REQUIRED: Static registration method
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Create method channel
        let channel = FlutterMethodChannel(
            name: "my_plugin",
            binaryMessenger: registrar.messenger()
        )

        // Create plugin instance
        let instance = MyPlugin()
        instance.channel = channel

        // Register as method call handler
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Optional: Publish instance for lifecycle callbacks
        // registrar.publish(instance)
    }

    // OPTIONAL: Instance cleanup method
    public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar) {
        // Clean up resources
        channel?.setMethodCallHandler(nil)
        channel = nil

        // Remove observers, cancel timers, etc.
    }

    // Handle method calls from Dart
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

## 5. Resource Management Patterns

For proper cleanup, Android plugins use `onDetachedFromEngine` to set method call handlers to null and release resources. The iOS equivalent pattern is:

```swift
public class MyPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var observer: NSObjectProtocol?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "my_plugin",
            binaryMessenger: registrar.messenger()
        )
        let instance = MyPlugin()
        instance.channel = channel
        instance.setupObservers()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private func setupObservers() {
        // Add notification observers
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBackground()
        }
    }

    public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar) {
        // Remove observers to prevent memory leaks
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }

        // Clear method call handler
        channel?.setMethodCallHandler(nil)
        channel = nil
    }

    deinit {
        // Fallback cleanup
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleBackground() {
        // Handle background state
    }
}
```

## 6. Flutter Plugin Architecture

The registrar obtained from FlutterPluginRegistry keeps track of plugin identity and provides basic support for cross-plugin coordination. The `registrar.publish()` method makes your plugin instance available for lifecycle callbacks, but most plugins don't need this unless they require explicit cleanup notification.

**When to use `registrar.publish()`:**
- When you need `detachFromEngineForRegistrar:` to be called
- When your plugin needs explicit cleanup notification
- When managing long-lived resources that must be released

**Most plugins just use:**
```swift
registrar.addMethodCallDelegate(instance, channel: channel)
```

## 7. Specific Implementation Questions

**Should iOS plugins maintain static state or instance properties?**
- Use **instance properties** for plugin-specific state
- Avoid static state unless truly global across all plugin instances
- Each Flutter engine can have its own plugin instance

```swift
public class MyPlugin: NSObject, FlutterPlugin {
    // GOOD: Instance properties
    private var channel: FlutterMethodChannel?
    private var currentState: String = ""

    // AVOID: Static state (unless truly global)
    // static var sharedState: String = ""
}
```

**How do plugins handle multiple registrations?**
Each call to `register(with:)` creates a new plugin instance, so multiple engines = multiple instances.

**Error handling in detachFromEngine:**
```swift
public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar) {
    do {
        // Cleanup operations that might fail
        try performCleanup()
    } catch {
        // Log errors but don't throw - cleanup should be best-effort
        print("Error during plugin cleanup: \(error)")
    }

    // Always nil out references
    channel = nil
}
```

## 8. Complete Working Example

Here's a complete, production-ready plugin implementation:

```swift
import Flutter
import UIKit

public class BatteryPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var batteryLevelObserver: NSObjectProtocol?

    // REQUIRED: Static registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "samples.flutter.dev/battery",
            binaryMessenger: registrar.messenger()
        )

        let instance = BatteryPlugin()
        instance.channel = channel
        instance.setupBatteryMonitoring()

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Setup monitoring
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        batteryLevelObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sendBatteryLevelUpdate()
        }
    }

    // Handle method calls
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getBatteryLevel":
            let batteryLevel = getBatteryLevel()
            if batteryLevel == -1 {
                result(FlutterError(
                    code: "UNAVAILABLE",
                    message: "Battery level not available",
                    details: nil
                ))
            } else {
                result(batteryLevel)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getBatteryLevel() -> Int {
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            return -1
        }
        return Int(level * 100)
    }

    private func sendBatteryLevelUpdate() {
        let level = getBatteryLevel()
        channel?.invokeMethod("onBatteryChanged", arguments: level)
    }

    // OPTIONAL: Cleanup
    public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar) {
        // Remove observers
        if let observer = batteryLevelObserver {
            NotificationCenter.default.removeObserver(observer)
            batteryLevelObserver = nil
        }

        // Disable monitoring
        UIDevice.current.isBatteryMonitoringEnabled = false

        // Clear channel reference
        channel?.setMethodCallHandler(nil)
        channel = nil
    }

    deinit {
        // Fallback cleanup
        if let observer = batteryLevelObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
}
```

## 9. References and Sources

**Official Documentation:**
- Flutter iOS Embedder API: https://api.flutter.dev/ios-embedder/protocol_flutter_plugin-p.html
- Developing Packages & Plugins: https://docs.flutter.dev/packages-and-plugins/developing-packages

**GitHub Source Code:**
- Flutter Packages Repository: https://github.com/flutter/packages
- Example Plugin (esense_flutter): https://github.com/cph-cachet/flutter-plugins/blob/master/packages/esense_flutter/ios/Classes/SwiftEsenseFlutterPlugin.swift

**Tutorials:**
- Custom Plugin Tutorial: https://dartling.dev/how-to-create-a-custom-plugin-in-flutter-to-call-native-platform-code
- Create Flutter Plugin Step by Step: https://apparencekit.dev/blog/flutter-create-plugin/

## 10. Best Practices

**Recommended Patterns:**
1. **Always use instance properties** for state management
2. **Use weak self** in closures to prevent retain cycles
3. **Remove all observers** in detachFromEngine and deinit
4. **Set handlers to nil** when cleaning up
5. **Return FlutterMethodNotImplemented** for unhandled methods
6. **Use FlutterError** for platform-specific errors

**Common Pitfalls to Avoid:**
- ❌ Not removing NotificationCenter observers (memory leaks)
- ❌ Using static state that persists across engine restarts
- ❌ Forgetting to disable monitoring (battery, location, etc.)
- ❌ Not implementing proper error handling
- ❌ Retaining strong references in closures

**Performance Considerations:**
- Only enable monitoring when needed
- Use background queues for heavy operations
- Return results quickly on the platform thread
- Consider using EventChannels for streaming data

**Memory Management:**
```swift
// ✓ GOOD: Weak self in closures
NotificationCenter.default.addObserver(...) { [weak self] _ in
    self?.handleNotification()
}

// ✗ BAD: Strong reference cycle
NotificationCenter.default.addObserver(...) { _ in
    self.handleNotification() // Retains self
}
```

This comprehensive guide should give you everything you need to implement iOS Flutter plugins correctly with proper lifecycle management and resource cleanup!
