package dev.luix.connect_kit.logging

/// Defines the log levels used consistently across Native platforms and Dart
///
/// These levels are used for structured logging  and should be ordered
/// from least severe (debug) to most severe (fatal)
enum class CKLogLevel {
    /// Detailed information for tracing and debugging app flow. Stripped in release builds
    DEBUG,

    /// General operational information, state changes, and key milestones
    INFO,

    /// Potential issues that might lead to an error if not addressed
    WARN,

    /// Errors that are handled but indicate a failure in an operation
    ERROR,

    /// Very severe errors that lead to unrecoverable application state
    FATAL
}
