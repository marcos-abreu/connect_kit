import 'dart:async';
import 'package:flutter/services.dart';
import 'package:connect_kit/src/utils/result.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';

/// Utility class that guards the execution of an operation by providing
/// centralized logging, execution timing, and error handling
///
/// It ensures that all executed operations, synchronous or asynchronous,
/// always return a [Result] object, converting any thrown exceptions
/// into a [ConnectKitException] within the failure Result
class OperationGuard {
  /// Execute a synchronous operation, wrapping the outcome in a [Result]
  static Result<T> execute<T>(
    T Function() operation, {
    String? operationName,
    Map<String, dynamic>? parameters,
  }) {
    final stopwatch = Stopwatch()..start();
    T? result; // INFO: keeping as nullable to use in the catch block when logs are implemented
    try {
      result = operation();

      stopwatch.stop();
      // TODO: future log

      return Result.success(result as T);
    } catch (error, stackTrace) {
      stopwatch.stop();

      // TODO: future log
      final exception = error is PlatformException
          ? OperationGuard._mapPlatformException(error, stackTrace)
          : ConnectKitException(
              error is Exception
                  ? error.toString()
                  : 'Unexpected error: $error',
              code: 'UNKNOWN_ERROR',
              originalError: error,
              stackTrace: stackTrace,
            );
      return Result.failure(exception);
    }
  }

  /// Execute an asynchronous operation, wrapping the outcome in a [Result]
  ///
  /// Optionally accepts a [timeout] duration
  static Future<Result<T>> executeAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    Map<String, dynamic>? parameters,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = timeout == null
          ? await operation()
          : await operation().timeout(timeout);
      stopwatch.stop();

      // TODO: future log

      return Result.success(result);
    } on MissingPluginException catch (e, stackTrace) {
      stopwatch.stop();

      // MissingPluginException is often used to indicate that a feature is not implemented
      // on the current platform
      return Result.failure(
        NotImplementedException(
          'Feature not implemented on this platform',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    } on TimeoutException catch (e, stackTrace) {
      stopwatch.stop();

      return Result.failure(
        OperationTimeoutException(
          '${operationName ?? 'Operation'} timed out after ${timeout?.inSeconds ?? 'unknown'} seconds',
          timeout: timeout,
          error: e,
          stackTrace: stackTrace,
        ),
      );
    } on PlatformException catch (e, stackTrace) {
      stopwatch.stop();

      return Result.failure(
        OperationGuard._mapPlatformException(e, stackTrace),
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      // TODO: future log

      return Result.failure(
        ConnectKitException(
          error is Exception ? error.toString() : 'Unexpected error: $error',
          code: 'UNKNOWN_ERROR',
          originalError: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // Helper function to map PlatformException codes to more specialized exceptions
  static ConnectKitException _mapPlatformException(
    PlatformException error,
    StackTrace? stackTrace,
  ) {
    switch (error.code) {
      case 'PLATFORM_UNAVAILABLE':
        return PlatformUnavailableException(
          error.message,
          error: error,
          stackTrace: stackTrace,
        );
      case 'COMMUNICATION_FAILED':
        return PlatformCommunicationException(
          error.message,
          error: error,
          stackTrace: stackTrace,
        );
      case _:
        return ConnectKitException(
          error.message ?? 'Platform error',
          code: error.code,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }
}
