/// Base class for all exceptions thrown by the ConnectKit plugin
///
/// Contains a human-readable [message], optional [code],
/// and references to the [originalError] and [stackTrace]
class ConnectKitException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  /// The original error that caused this exception
  final dynamic originalError;

  /// Stack trace when the error occurred
  final StackTrace? stackTrace;

  /// Creates a new ConnectKitException
  const ConnectKitException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (code != null) {
      buffer.write(' [code: $code]');
    }
    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }
    return buffer.toString();
  }
}

/// Thrown when the required native health platform (HealthKit or Health Connect)
/// is not available, or the plugin fails to communicate due to missing setup
class PlatformUnavailableException extends ConnectKitException {
  /// Creates an instance indicating that the platform service is unavailable
  PlatformUnavailableException(
    String? message, {
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          message ?? 'Native platform implementation is unavailable',
          code: 'PLATFORM_UNAVAILABLE',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// Thrown when a native operation exceeds the allotted time
class OperationTimeoutException extends ConnectKitException {
  /// The duration that was exceeded, if specified
  final Duration? timeout;

  /// Creates an instance indicating an operation timeout
  OperationTimeoutException(
    String? message, {
    this.timeout,
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          message ?? 'Operation timed out',
          code: 'OPERATION_TIMEOUT',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// Thrown when the communication channel between Flutter and the native side fails
/// for reasons other than unavailability or timeout (e.g., a serialization error)
class PlatformCommunicationException extends ConnectKitException {
  /// Creates an instance indicating a communication failure
  PlatformCommunicationException(
    String? message, {
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          message ?? 'Fluter <-> Platform communication failed',
          code: 'COMMUNICATION_FAILED',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when a feature is not implemented by the plugin or the native platform
class NotImplementedException extends ConnectKitException {
  /// Creates an instance indicating that a requested feature is not implemented
  NotImplementedException(
    String? message, {
    Object? error,
    StackTrace? stackTrace,
  }) : super(
          message ?? 'Feature not implemented',
          code: 'NOT_IMPLEMENTED',
          originalError: error,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when data conversion or mapping fails within the Dart layer
class DataConversionException extends ConnectKitException {
  /// The type of data being converted from
  final Type? sourceType;

  /// The type of data expected after conversion
  final Type? targetType;

  /// Creates an instance indicating a data conversion failure
  const DataConversionException(
    super.message, {
    super.code,
    this.sourceType,
    this.targetType,
    super.originalError,
    super.stackTrace,
  });
}
