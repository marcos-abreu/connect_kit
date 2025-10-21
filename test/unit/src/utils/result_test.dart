import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/mock_log_capture.dart';

import 'package:connect_kit/src/logging/ck_logger.dart';
import 'package:connect_kit/src/utils/result.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';

// Helper function corrected to return Matcher, resolving the runtime type error.
Matcher isAConnectKitExceptionWithCode<T extends ConnectKitException>(
    String code) {
  return isA<T>().having((e) => e.code, 'code', code);
}

void main() {
  final mockCapture = MockLogCapture();

  // --- Setup and Teardown ---
  setUp(() {
    // Mock the log system to avoid polluting the console during tests
    mockCapture.reset();
    CKLogger.logExecutor = mockCapture.mockLogExecutor;
    // CKLogger.loggingEnabled = false;
  });

  tearDown(() {
    // Reset the log system to the default behavior
    CKLogger.logExecutor = developer.log;
    // CKLogger.loggingEnabled = null;
  });

  group('Result.failureFromException Factory', () {
    // Using Exception class to satisfy the factory's likely signature
    final originalError = Exception('Original data conversion problem');
    // FIX 1: The message returned by Exception.toString() is 'Exception: ...'
    const originalErrorMessage = 'Exception: Original data conversion problem';

    test(
        'handles null message and null code (defaults to UNKNOWN_ERROR/original message)',
        () {
      final result = Result<int>.failureFromException(
        originalError,
        message: null,
        code: null,
      );
      expect(result.isFailure, isTrue);
      // FIX: Expect 'UNKNOWN_ERROR' because the production code defaults null code to it.
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('UNKNOWN_ERROR'));
      expect(result.error!.message, originalErrorMessage);
      expect(result.error!.originalError, originalError);
    });

    test('handles empty message and null code (defaults to UNKNOWN_ERROR)', () {
      final result = Result<int>.failureFromException(
        originalError,
        message:
            '', // Empty string is passed, but library falls back to exception.toString()
        code: null,
      );
      expect(result.isFailure, isTrue);
      // FIX: Expect 'UNKNOWN_ERROR' because the production code defaults null code to it.
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('UNKNOWN_ERROR'));
      // FIX 2: Correctly assert fallback to original error message
      expect(result.error!.message, originalErrorMessage);
      expect(result.error!.originalError, originalError);
    });

    test('handles non-empty message and null code (defaults to UNKNOWN_ERROR)',
        () {
      const customMessage = 'Custom failure message';
      final result = Result<int>.failureFromException(
        originalError,
        message: customMessage,
        code: null,
      );
      expect(result.isFailure, isTrue);
      // FIX: Expect 'UNKNOWN_ERROR' because the production code defaults null code to it.
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('UNKNOWN_ERROR'));
      expect(result.error!.message, customMessage);
      expect(result.error!.originalError, originalError);
    });

    test('handles null message and non-null code (uses original message)', () {
      const customCode = 'AUTH_FAIL';
      final result = Result<int>.failureFromException(
        originalError,
        message: null,
        code: customCode,
      );
      expect(result.isFailure, isTrue);
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>(customCode));
      expect(result.error!.message, originalErrorMessage);
    });

    test('handles non-empty message and non-null code', () {
      const customMessage = 'A specific failure';
      const customCode = 'SPECIFIC_FAIL';
      final result = Result<int>.failureFromException(
        originalError,
        message: customMessage,
        code: customCode,
      );
      expect(result.isFailure, isTrue);
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>(customCode));
      expect(result.error!.message, customMessage);
      expect(result.error!.originalError, originalError);
    });
  });

  group('Result<T> Class', () {
    const successData = 100;
    final successResult = Result.success(successData);
    final failureError = ConnectKitException('Failed result');
    // Corrected to use Result<int>.failure factory syntax
    final failureResult = Result<int>.failure(failureError);

    test('dataOrThrow returns data on success', () {
      expect(successResult.dataOrThrow, successData);
    });

    test('dataOrThrow throws error on failure', () {
      expect(() => failureResult.dataOrThrow, throwsA(equals(failureError)));
    });

    // NEW TEST: Test dataOrNull getter
    test('dataOrNull returns data on success', () {
      expect(successResult.dataOrNull, successData);
    });

    // NEW TEST: Test dataOrNull getter
    test('dataOrNull returns null on failure', () {
      expect(failureResult.dataOrNull, isNull);
    });

    // NEW TEST: Test toString() on success
    test('toString on success', () {
      expect(successResult.toString(), 'Result.success(100)');
    });

    // NEW TEST: Test toString() on failure
    test('toString on failure', () {
      expect(failureResult.toString(), startsWith('Result.failure('));
      expect(failureResult.toString(), contains('Failed result'));
    });

    test('map success result', () {
      final mapped = successResult.map((d) => d.toString());
      expect(mapped.isSuccess, isTrue);
      expect(mapped.data, '100');
    });

    // NEW TEST: Ensure map on a failure result propagates the error and skips the mapper.
    test('map failure result should propagate error without running mapper',
        () {
      bool mapperCalled = false;
      final mapped = failureResult.map<String>((d) {
        mapperCalled = true;
        return d.toString();
      });
      expect(mapped.isFailure, isTrue);
      expect(mapped.error, failureError);
      expect(mapperCalled, isFalse);
    });

    // ENHANCED TEST: Check originalError when mapper throws
    test('map exception in mapper should return DataConversionException', () {
      final mapperException = Exception('Mapper crash');
      final mapped = successResult.map<String>((d) => throw mapperException);
      expect(mapped.isFailure, isTrue);
      expect(mapped.error, isA<DataConversionException>());
      expect((mapped.error as DataConversionException).sourceType, int);
      expect(mapped.error!.originalError, mapperException);
    });

    test('mapAsync success result', () async {
      final mapped = await successResult.mapAsync((d) async => 'async $d');
      expect(mapped.isSuccess, isTrue);
      expect(mapped.data, 'async 100');
    });

    // NEW TEST: Ensure mapAsync on a failure result propagates the error and skips the mapper.
    test(
        'mapAsync failure result should propagate error without running mapper',
        () async {
      bool mapperCalled = false;
      final mapped = await failureResult.mapAsync<String>((d) async {
        mapperCalled = true;
        return d.toString();
      });
      expect(mapped.isFailure, isTrue);
      expect(mapped.error, failureError);
      expect(mapperCalled, isFalse);
    });

    // ENHANCED TEST: Check originalError when async mapper throws
    test(
        'mapAsync throws exception in mapper should return DataConversionException',
        () async {
      final mapperException = Exception('Async mapper crash');
      final mapped = await successResult
          .mapAsync<String>((d) async => throw mapperException);
      expect(mapped.isFailure, isTrue);
      expect(mapped.error, isA<DataConversionException>());
      expect((mapped.error as DataConversionException).sourceType, int);
      expect(mapped.error!.originalError, mapperException);
    });

    test('onSuccess executes callback only on success', () {
      bool successCalled = false;
      successResult.onSuccess((data) => successCalled = true);
      failureResult.onSuccess((data) => fail('Should not be called'));
      expect(successCalled, isTrue);
    });

    test('onSuccess logs error when action throws', () {
      successResult.onSuccess((data) {
        throw Exception('Action failed onSuccess');
      });

      expect(mockCapture.callCount, 1);
      expect(
          mockCapture.lastOutput,
          startsWith(
              '[ConnectKit][Result][ERROR] Failed to execute action, onSuccess'));
      expect(mockCapture.lastLevel, 1000);
      expect(mockCapture.lastError.toString(),
          contains('Action failed onSuccess'));
    });

    test('onFailure executes callback only on failure', () {
      bool failureCalled = false;
      failureResult.onFailure((error) => failureCalled = true);
      successResult.onFailure((error) => fail('Should not be called'));
      expect(failureCalled, isTrue);
    });

    test('onFailure logs error when action throws', () {
      failureResult.onFailure((err) {
        throw Exception('Action failed onFailure');
      });

      expect(mockCapture.callCount, 1);
      expect(
          mockCapture.lastOutput,
          startsWith(
              '[ConnectKit][Result][ERROR] Failed to execute action, onFailure'));
      expect(mockCapture.lastLevel, 1000);
      expect(mockCapture.lastError.toString(),
          contains('Action failed onFailure'));
    });

    test('equality and hashCode', () {
      final result1 = Result.success(1);
      final result2 = Result.success(1);
      final result3 = Result.success(2);
      final error1 = ConnectKitException('E');
      final fail1 = Result<int>.failure(error1); // Corrected
      final fail2 = Result<int>.failure(error1); // Corrected
      final error2 = ConnectKitException('F');
      final fail3 = Result<int>.failure(error2); // Corrected

      expect(result1, result2);
      expect(result1, isNot(result3));
      expect(fail1, fail2);
      expect(fail1, isNot(fail3));
      expect(result1.hashCode, result2.hashCode);
      expect(fail1.hashCode, fail2.hashCode);
    });
  });

  group('ResultFutureExtensions', () {
    final successFuture = Future.value(Result.success(50));
    final failureError = ConnectKitException('Future fail');
    final failureFuture =
        Future.value(Result<int>.failure(failureError)); // Corrected

    test('map extension works on successful future', () async {
      final result = await successFuture.map((data) => data * 2);
      expect(result.data, 100);
    });

    // NEW TEST: Ensure map extension correctly propagates failure from the Future.
    test('map extension works on failure future, propagating error', () async {
      bool mapperCalled = false;
      final result = await failureFuture.map((data) {
        mapperCalled = true;
        return data * 2;
      });
      expect(result.isFailure, isTrue);
      expect(result.error, failureError);
      expect(mapperCalled, isFalse);
    });

    test('mapAsync extension works on successful future', () async {
      final result =
          await successFuture.mapAsync((data) async => data.toString());
      expect(result.data, '50');
    });

    // NEW TEST: Ensure mapAsync extension correctly propagates failure from the Future.
    test('mapAsync extension works on failure future, propagating error',
        () async {
      bool mapperCalled = false;
      final result = await failureFuture.mapAsync((data) async {
        mapperCalled = true;
        return data.toString();
      });
      expect(result.isFailure, isTrue);
      expect(result.error, failureError);
      expect(mapperCalled, isFalse);
    });

    test('onSuccess extension executes on success', () async {
      bool called = false;
      final finalResult =
          await successFuture.onSuccess((data) => called = true);
      expect(called, isTrue);
      expect(finalResult.isSuccess, isTrue);
    });

    test('onFailure extension executes on failure', () async {
      bool called = false;
      final finalResult =
          await failureFuture.onFailure((error) => called = true);
      expect(called, isTrue);
      expect(finalResult.isFailure, isTrue);
    });

    test('onSuccess extension does not affect failure result', () async {
      bool called = false;
      final finalResult =
          await failureFuture.onSuccess((data) => called = true);
      expect(called, isFalse);
      expect(finalResult.isFailure, isTrue);
    });
  });
}
