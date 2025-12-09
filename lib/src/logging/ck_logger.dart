import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:connect_kit/src/logging/ck_log_level.dart';

/// Defines the function signature for dart:developer.log
/// This is the function that is executed during logging
typedef LogExecutor = void Function(
  String message, {
  int level,
  String name,
  Object? error,
  StackTrace? stackTrace,
});

/// A unified, compile-time-safe logging facade for the ConnectKit plugin
///
/// This logger is designed for zero overhead in release builds
/// and uses platform-native logging systems for superior developer experience.
class CKLogger {
  // Static identifier used for structured output
  static const String _pluginTag = '[ConnectKit]';

  // --- Internal Control Flags ---

  /// A nullable boolean is used to implement the three-state logic:
  /// - `null`: Defer to kDebugMode (Regular execution)
  /// - `true`/`false`: Absolute override of kDebugMode (Test control)
  static bool? _enableLogsForTests;

  /// Controls log output for (Critical Bypass). Can be used to log
  /// core initialization errors even in release builds if necessary
  static bool _forceCriticalLog = false;

  // Injectable Log Execution Point
  // By default, it points to the real dart:developer.log function
  static LogExecutor _logExecutor = developer.log;

  /// [MOSTLY, IF NOT ONLY FOR TESTING] Sets the logging override state
  // Public setter for core log executoion override
  @visibleForTesting
  static set logExecutor(LogExecutor executor) => _logExecutor = executor;

  /// [FOR TESTING ONLY] Sets the logging override state
  /// Set to `null` to respect kDebugMode. Set to `true` or `false` to override it
  @visibleForTesting
  static set loggingEnabled(bool? isEnabled) => _enableLogsForTests = isEnabled;

  /// [FOR TESTING ONLY] Sets whether the critical log bypass is active, simulating
  /// the runtime configuration override
  @visibleForTesting
  static set criticalLogBypass(bool forceBypass) =>
      _forceCriticalLog = forceBypass;

  /// Private function to determine if logging should occur
  /// Logic: Use the override state if set, otherwise use kDebugMode
  static bool get _shouldLog => _enableLogsForTests ?? kDebugMode;

  // --- Public Interface ---

  /// Logs a [debug] message. Stripped in release builds
  static void d(String tag, String message) {
    if (_shouldLog) {
      _log(CKLogLevel.debug, tag, message);
    }
  }

  /// Logs an [info] message. Stripped in release builds
  static void i(String tag, String message) {
    if (_shouldLog) {
      _log(CKLogLevel.info, tag, message);
    }
  }

  /// Logs a [warning] message. Stripped in release builds
  static void w(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_shouldLog) {
      _log(CKLogLevel.warn, tag, message, error, stackTrace);
    }
  }

  /// Logs an [error] message. Stripped in release builds
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_shouldLog) {
      _log(CKLogLevel.error, tag, message, error, stackTrace);
    }
  }

  /// Logs a [fatal] error. Stripped in release builds
  static void f(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_shouldLog) {
      _log(CKLogLevel.fatal, tag, message, error, stackTrace);
    }
  }

  /// Logs a **critical** message that **bypasses** the standard debug stripping
  ///
  /// This should be used extremely sparingly, typically for unrecoverable
  /// initialization failures that must be visible even in profile/release builds
  /// where the developer has enabled logging for debugging the build variant
  static void critical(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // (_shouldLog) OR if the critical bypass flag is explicitly set (_forceCriticalLog)
    // This respects the setter 'loggingEnabled(false)' test override
    if (_shouldLog || _forceCriticalLog) {
      _log(CKLogLevel.fatal, tag, message, error, stackTrace);
    }
  }

  /// The internal logging execution function
  static void _log(
    CKLogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Structured Format
    final output = '$_pluginTag[$tag][${level.name.toUpperCase()}] $message';

    // Using _logExecutor as an interface which by default points to dart:developer.log
    // for zero-dependency structured logging
    _logExecutor(
      output,
      name:
          'connect_kit_log', // Logger name for filtering in the Dart observatory/IDE
      level: _levelToDeveloperInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Converts the enum level to a numerical level recognized by `dart:developer`
  /// This helps with filtering in tools like the Dart Observatory
  static int _levelToDeveloperInt(CKLogLevel level) {
    switch (level) {
      case CKLogLevel.debug:
        return 500;
      case CKLogLevel.info:
        return 800;
      case CKLogLevel.warn:
        return 900;
      case CKLogLevel.error:
        return 1000;
      case CKLogLevel.fatal:
        return 1200; // Use a level higher than 1000 for FATAL
    }
  }
}
