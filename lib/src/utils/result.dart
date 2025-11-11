import 'dart:async';
import 'package:connect_kit/src/logging/ck_logger.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';

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
  /// Static log TAG
  static const String logTag = 'Result';

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
    CKLogger.e(logTag, 'Creating failure result with error: $error');

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

    CKLogger.e(
      logTag,
      '$finalCode - Triggering failure for exception: $exception',
    );

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
      } catch (error, stackTrace) {
        CKLogger.e(
          logTag,
          'Failed to execute action, onSuccess, with exception: $error',
          error,
          stackTrace,
        );
      }
    }
    return this;
  }

  /// Executes [action] if the result is a failure
  Result<T> onFailure(void Function(ConnectKitException error) action) {
    if (isFailure && error != null) {
      try {
        action(error!);
      } catch (error, stackTrace) {
        CKLogger.e(
          logTag,
          'Failed to execute action, onFailure, with exception: $error',
          error,
          stackTrace,
        );
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
