import Foundation
import os.log

/// The protocol that defines the logging execution contract
///
/// This protocol acts as the Dependency Injection point for testing the CKLogger.
/// During unit tests, the production executor is swapped with a mock that captures log payloads
public protocol LogExecutorProtocol {
    /// The function responsible for mapping the structured log data to the native system.
    /// The signature has been simplified to only include log content data.
    func execute(level: CKLogLevel, tag: String, message: String, error: Error?)
}

/// The production implementation of the LogExecutor, which calls the optimized os_log
public struct OSLogExecutor: LogExecutorProtocol {

    private static let subsystem = "dev.luix.connect_kit"

    // The OSLog object is created once, outside the execution function
    private static let osLog = OSLog(subsystem: OSLogExecutor.subsystem, category: "Logger")

    // Static identifier used for structured output prefixing
    private static let pluginTag = "[ConnectKit]"

    public init() {}

    // Updated signature: Removed the unused 'log: OSLog' parameter
    public func execute(level: CKLogLevel, tag: String, message: String, error: Error?) {
        let osLogType: OSLogType

        // Map CKLogLevel to OSLogType (Error/Fatal get the highest visibility)
        switch level {
        case .DEBUG: osLogType = .debug
        case .INFO: osLogType = .info
        case .WARN: osLogType = .default
        case .ERROR: osLogType = .error
        case .FATAL: osLogType = .fault
        }

        // Prepare structured message prefix
        var output = "\(OSLogExecutor.pluginTag)[\(tag)][\(level.rawValue)] \(message)"

        // Append error details if available
        if let error = error {
            output += " | Error: \(error.localizedDescription)"
        }

        // Using safe format specifier for logging Swift Strings with OSLog
        os_log("%{public}@", log: OSLogExecutor.osLog, type: osLogType, output)
    }
}
