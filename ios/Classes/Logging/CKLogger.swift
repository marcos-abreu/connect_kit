import Dispatch
import Foundation
import os.log

/// A unified, compile-time-safe logging facade for the ConnectKit plugin.
///
/// This logger strictly mirrors the Dart/Kotlin CKLogger logic, using a LogExecutor
/// protocol to enable easy unit testing via dependency injection
public struct CKLogger {

    // --- The pluginTag is defined in the LogExecutor for encapsulation

    // --- Thread Safety Mechanism ---
    // Using a private concurrent queue with barrier locks ensures thread-safe reads
    // and exclusive writes to the static mutable state properties
    private static let stateQueue = DispatchQueue(
        label: "dev.luix.connect_kit.logstate", attributes: .concurrent)

    // --- Log Execution Delegation Property (The Injection Point) ---
    public static var executor: LogExecutorProtocol = OSLogExecutor()

    // --- Internal Control Flags (Mirroring Dart/Kotlin logic) ---

    // A nullable boolean used to implement the three-state logic:
    // - nil: Defer to preprocessor macro (Regular execution)
    // - true/false: Absolute override (Test control)
    private static var enableLogsForTests: Bool? = nil

    // Controls log output for (Critical Bypass)
    private static var forceCriticalLog: Bool = false

    /// Private function to determine if standard logging should occur.
    /// Logic: Use the override state if set, otherwise defer to preprocessor-based checks
    private static var shouldLog: Bool {
        // Read access needs to be sync'd to prevent race conditions during state read
        return stateQueue.sync {
            #if DEBUG
                return enableLogsForTests ?? true  // In DEBUG, default is true
            #else
                return enableLogsForTests ?? false  // In RELEASE, default is false
            #endif
        }
    }

    // --- Testability Setters (Analogous to Dart's static set properties) ---

    /// [FOR TESTING ONLY] Sets the logging override state.
    /// Set to `nil` to respect the build configuration. Set to `true` or `false` to override it
    public static func setLoggingEnabled(isEnabled: Bool?) {
        // Use a barrier for exclusive write access to ensure atomicity
        stateQueue.sync(flags: .barrier) {
            Self.enableLogsForTests = isEnabled
        }
    }

    /// [FOR TESTING ONLY] Sets whether the critical log bypass is active, simulating the runtime
    /// configuration override
    public static func setCriticalLogBypass(forceBypass: Bool) {
        // Use a barrier for exclusive write access to ensure atomicity
        stateQueue.sync(flags: .barrier) {
            Self.forceCriticalLog = forceBypass
        }
    }

    // --- Public Interface (Mirroring Dart d, i, w, e, f) ---

    /// Logs a [debug] message. Stripped at compile-time in Release builds
    public static func d(tag: String, message: String) {
        #if DEBUG
            if shouldLog {
                log(level: .DEBUG, tag: tag, message: message, error: nil)
            }
        #endif
    }

    /// Logs an [info] message. Stripped at compile-time in Release builds
    public static func i(tag: String, message: String) {
        #if DEBUG
            if shouldLog {
                log(level: .INFO, tag: tag, message: message, error: nil)
            }
        #endif
    }

    /// Logs a [warning] message. Stripped at compile-time in Release builds
    public static func w(tag: String, message: String, error: Error? = nil) {
        #if DEBUG
            if shouldLog {
                log(level: .WARN, tag: tag, message: message, error: error)
            }
        #endif
    }

    /// Logs an [error] message. Stripped at compile-time in Release builds
    public static func e(tag: String, message: String, error: Error? = nil) {
        #if DEBUG
            if shouldLog {
                log(level: .ERROR, tag: tag, message: message, error: error)
            }
        #endif
    }

    /// Logs a [fatal] error. Stripped at compile-time in Release builds
    public static func f(tag: String, message: String, error: Error? = nil) {
        #if DEBUG
            if shouldLog {
                log(level: .FATAL, tag: tag, message: message, error: error)
            }
        #endif
    }

    /// Logs a **critical** message that **bypasses** the standard debug stripping
    public static func critical(tag: String, message: String, error: Error? = nil) {
        // Read access to forceCriticalLog must be sync'd
        let shouldBypass = stateQueue.sync { Self.forceCriticalLog }

        // Logic: (shouldLog) OR if the critical bypass flag is explicitly set (shouldBypass)
        if shouldLog || shouldBypass {
            // Critical logs are treated as FATAL severity
            log(level: .FATAL, tag: tag, message: message, error: error)
        }
    }

    // --- Internal Execution ---

    /// Delegates the final log execution to the current LogExecutor instance
    private static func log(level: CKLogLevel, tag: String, message: String, error: Error?) {
        // The execute method of the LogExecutor takes care of log level and message formatting
        CKLogger.executor.execute(
            level: level,
            tag: tag,
            message: message,
            error: error
        )
    }
}
