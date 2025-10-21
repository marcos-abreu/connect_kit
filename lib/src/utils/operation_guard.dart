import 'dart:async';
import 'package:flutter/services.dart';
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

/// Represents the outcome of an operation, either a success or a failure.
///
/// Use [data] to access the result on success, or [error] for failure details.
///
/// Example:
/// ```dart
/// final result = await OperationGuard.executeAsync(() => someAsyncCall());
/// if (result.isSuccess) print(result.data);
/// else print(result.error);
/// ```
class Result<T> {
  /// The successful data payload. Only non-null if [isSuccess] is true
  final T? data;

  /// The error payload. Only non-null if [isSuccess] is false
  final ConnectKitException? error;

  /// True if the operation succeeded, false otherwise
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create a successful result
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  /// Create a failure result
  factory Result.failure(ConnectKitException error) {
    // TODO: future log
    return Result._(error: error, isSuccess: false);
  }

  /// Create a failure result from a generic exception
  factory Result.failureFromException(
    Exception exception, {
    String? message,
    String? code,
  }) {
    final normalizedMessage =
        (message?.isNotEmpty ?? false) ? message! : exception.toString();

    final finalCode = code ?? 'UNKNOWN_ERROR';

    final connectKitException = ConnectKitException(
      normalizedMessage,
      code: finalCode,
      originalError: exception,
    );

    // TODO: future log
    return Result.failure(connectKitException);
  }

  /// Get data if successful, throw error if failed
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw error ?? const ConnectKitException('Unknown error occurred');
  }

  /// Get data if successful, null if failed
  T? get dataOrNull => isSuccess ? data : null;

  /// Check if result is successful
  bool get isFailure => !isSuccess;

  /// Map success result data to a different type
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return Result.success(mapper(data as T));
      } catch (e, stackTrace) {
        return Result.failure(
          DataConversionException(
            'Failed to map result',
            sourceType: T,
            targetType: R,
            originalError: e,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return Result.failure(error!);
  }

  /// Map success result data to a different type [R] asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    if (isSuccess && data != null) {
      try {
        final result = await mapper(data as T);
        return Result.success(result);
      } catch (e, stackTrace) {
        return Result.failure(
          DataConversionException(
            'Failed to map result asynchronously',
            sourceType: T,
            targetType: R,
            originalError: e,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return Result.failure(error!);
  }

  /// Executes [action] if the result is successful
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess && data != null) {
      try {
        action(data as T);
      } catch (e) {
        // TODO: future log
      }
    }
    return this;
  }

  /// Executes [action] if the result is a failure
  Result<T> onFailure(void Function(ConnectKitException error) action) {
    if (isFailure && error != null) {
      try {
        action(error!);
      } catch (e) {
        // TODO: future log
      }
    }
    return this;
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    } else {
      return 'Result.failure($error)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result<T> &&
        other.isSuccess == isSuccess &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isSuccess, data, error);
}

/// Extension wrapper for working with futures of [Result] objects
extension ResultFutureExtensions<T> on Future<Result<T>> {
  /// Maps the successful result of the future to a different type [R]
  Future<Result<R>> map<R>(R Function(T data) mapper) {
    return then((result) => result.map(mapper));
  }

  /// Maps the successful result of the future to a different type [R] asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) {
    return then((result) => result.mapAsync(mapper));
  }

  /// Executes [action] if the inner result is a success
  Future<Result<T>> onSuccess(void Function(T data) action) {
    return then((result) {
      result.onSuccess(action);
      return result;
    });
  }

  /// Executes [action] if the inner result is a failure
  Future<Result<T>> onFailure(void Function(ConnectKitException error) action) {
    return then((result) {
      result.onFailure(action);
      return result;
    });
  }
}
