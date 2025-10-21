import Foundation

/// Defines the log levels used consistently across Native platforms and Dart
///
/// These levels are used for structured logging and should be ordered
/// from least severe (debug) to most severe (fatal)
public enum CKLogLevel: String {
    /// Detailed information for tracing and debugging app flow. Stripped in release builds
    case DEBUG

    /// General operational information, state changes, and key milestones
    case INFO

    /// Potential issues that might lead to an error if not addressed
    case WARN

    /// Errors that are handled but indicate a failure in an operation
    case ERROR

    /// Very severe errors that lead to unrecoverable application state
    case FATAL
}
