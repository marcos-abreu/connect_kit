/// Defines the log levels used consistently across Dart and Native platforms.
///
/// These levels are used for structured logging (R3) and should be ordered
/// from least severe (debug) to most severe (fatal).
enum CKLogLevel {
  /// Detailed information for tracing and debugging app flow. Stripped in release builds.
  debug,

  /// General operational information, state changes, and key milestones.
  info,

  /// Potential issues that might lead to an error if not addressed.
  warn,

  /// Errors that are handled but indicate a failure in an operation.
  error,

  /// Very severe errors that lead to unrecoverable application state.
  fatal,
}
