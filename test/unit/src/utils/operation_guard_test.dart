import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:connect_kit/src/utils/result.dart';
import 'package:connect_kit/src/utils/connect_kit_exception.dart';
import 'package:connect_kit/src/utils/operation_guard.dart';

// Helper function corrected to return Matcher, resolving the runtime type error.
Matcher isAConnectKitExceptionWithCode<T extends ConnectKitException>(
    String code) {
  return isA<T>().having((e) => e.code, 'code', code);
}

void main() {
  group('OperationGuard.execute (Synchronous)', () {
    test('Success path should return Result.success', () {
      final result = OperationGuard.execute(() => 42);
      expect(result.isSuccess, isTrue);
      expect(result.data, 42);
    });

    test('Failure path (Generic Exception) should map to ConnectKitException',
        () {
      final exception = Exception('Sync failure');
      final result = OperationGuard.execute<int>(() => throw exception);
      expect(result.isFailure, isTrue);
      // Using the corrected helper that returns a Matcher
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('UNKNOWN_ERROR'));
      expect(result.error!.originalError, exception);
    });

    // NEW TEST: Ensure non-Exception objects thrown are mapped correctly.
    test(
        'Failure path (Non-Exception Object) should map to ConnectKitException',
        () {
      final nonExceptionError = 'A random error object';
      final result = OperationGuard.execute<int>(() => throw nonExceptionError);
      expect(result.isFailure, isTrue);
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('UNKNOWN_ERROR'));
      expect(result.error!.originalError, nonExceptionError);
    });

    test(
        'Failure path (PlatformException) should map via _mapPlatformException',
        () {
      final platformError = PlatformException(
          code: 'TEST_SYNC', message: 'Platform sync failure');
      final result = OperationGuard.execute<int>(() => throw platformError);
      expect(result.isFailure, isTrue);
      // Using the corrected helper
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('TEST_SYNC'));
    });
  });

  group('OperationGuard.executeAsync (Asynchronous)', () {
    const testTimeout = Duration(milliseconds: 10);

    test('Success path should return Result.success', () async {
      final result =
          await OperationGuard.executeAsync(() async => 'Async Data');
      expect(result.isSuccess, isTrue);
      expect(result.data, 'Async Data');
    });

    test('Success path with timeout but completes quickly should succeed',
        () async {
      final result = await OperationGuard.executeAsync(
        () async => 'Quick data',
        timeout: const Duration(seconds: 1),
      );
      expect(result.isSuccess, isTrue);
      expect(result.data, 'Quick data');
    });

    test(
        'Failure path (TimeoutException) should map to OperationTimeoutException',
        () async {
      final operation = () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 0;
      };
      final result = await OperationGuard.executeAsync(
        operation,
        operationName: 'LongOp',
        timeout: testTimeout,
      );
      expect(result.isFailure, isTrue);
      expect(result.error, isA<OperationTimeoutException>());
      expect(result.error!.code, 'OPERATION_TIMEOUT');
      expect(
          result.error!.message, contains('LongOp timed out after 0 seconds'));
    });

    // NEW TEST: Ensure generic exceptions map to UNKNOWN_ERROR
    test(
        'Failure path (Generic Exception) should map to ConnectKitException (UNKNOWN_ERROR)',
        () async {
      final genericError = StateError('Async generic failure');
      final result =
          await OperationGuard.executeAsync(() async => throw genericError);
      expect(result.isFailure, isTrue);
      // Using the corrected helper
      expect(result.error,
          isAConnectKitExceptionWithCode<ConnectKitException>('UNKNOWN_ERROR'));
      expect(result.error!.originalError, genericError);
    });

    test(
        'Failure path (MissingPluginException) should map to NotImplementedException',
        () async {
      final exception = MissingPluginException('No channel found');
      final result =
          await OperationGuard.executeAsync(() async => throw exception);
      expect(result.isFailure, isTrue);
      // Using the corrected helper
      expect(
          result.error,
          isAConnectKitExceptionWithCode<NotImplementedException>(
              'NOT_IMPLEMENTED'));
      expect(result.error!.originalError, exception);
    });

    group('PlatformException Mapping', () {
      Future<Result<int>> runAsyncWithError(String code, String message) async {
        final error = PlatformException(code: code, message: message);
        return OperationGuard.executeAsync(() async => throw error);
      }

      test('PLATFORM_UNAVAILABLE maps correctly', () async {
        final result = await runAsyncWithError(
            'PLATFORM_UNAVAILABLE', 'Native is missing');
        expect(result.isFailure, isTrue);
        // Using the corrected helper
        expect(
            result.error,
            isAConnectKitExceptionWithCode<PlatformUnavailableException>(
                'PLATFORM_UNAVAILABLE'));
      });

      test('COMMUNICATION_FAILED maps correctly', () async {
        final result = await runAsyncWithError(
            'COMMUNICATION_FAILED', 'Bad serialization');
        expect(result.isFailure, isTrue);
        // Using the corrected helper
        expect(
            result.error,
            isAConnectKitExceptionWithCode<PlatformCommunicationException>(
                'COMMUNICATION_FAILED'));
      });

      test('Unmapped code maps to base ConnectKitException', () async {
        final result =
            await runAsyncWithError('CUSTOM_ERROR', 'A custom failure');
        expect(result.isFailure, isTrue);
        // Using the corrected helper
        expect(
            result.error,
            isAConnectKitExceptionWithCode<ConnectKitException>(
                'CUSTOM_ERROR'));
      });
    });
  });
}
