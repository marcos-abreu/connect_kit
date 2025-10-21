import 'package:flutter_test/flutter_test.dart';

// Assuming the CKLogger and CKLogLevel files are structured as below in a typical project
import 'package:connect_kit/src/logging/ck_logger.dart';
import '../../../helpers/mock_log_capture.dart';

void main() {
  final mockCapture = MockLogCapture();

  const defaultTag = 'TestTag';
  const defaultMessage = 'A simple test message.';
  final defaultError = Exception('Test error!');
  final defaultStackTrace = StackTrace.current;

  // --- Setup and Teardown ---
  setUp(() {
    // 1. Reset the mock capture state
    mockCapture.reset();

    // 2. Reset the control flags to the desired release-mode baseline (suppressed)
    // CRITICAL FIX: Set logging state to 'null' (defer to kDebugMode).
    // In the flutter test runner, kDebugMode is always TRUE, so this effectively
    // sets the logger to ENABLED by default for most tests.
    CKLogger.loggingEnabled = null;
    CKLogger.criticalLogBypass = false;

    // 3. Set the logger to use our content-checking mock for positive tests.
    CKLogger.logExecutor = mockCapture.mockLogExecutor;
  });

  // --- Test Suites ---

  group('CKLogger Execution & Content (kDebugMode Enabled)', () {
    test('Debug (d) logs correctly and is executed', () {
      // Act
      CKLogger.d(defaultTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 1, reason: 'd() should execute the log.');
      expect(mockCapture.lastOutput,
          '[ConnectKit][$defaultTag][DEBUG] $defaultMessage',
          reason: 'd() output format is incorrect.');
      expect(mockCapture.lastLevel, 500);
      expect(mockCapture.lastError, isNull);
    });

    test('Info (i) logs correctly and is executed', () {
      // Act
      CKLogger.i(defaultTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 1);
      expect(mockCapture.lastOutput,
          '[ConnectKit][$defaultTag][INFO] $defaultMessage',
          reason: 'i() output format is incorrect.');
      expect(mockCapture.lastLevel, 800);
    });

    test('Warning (w) logs with optional error/stackTrace', () {
      // Act
      CKLogger.w(defaultTag, defaultMessage, defaultError, defaultStackTrace);

      // Assert
      expect(mockCapture.callCount, 1);
      expect(mockCapture.lastOutput,
          startsWith('[ConnectKit][$defaultTag][WARN]'));
      expect(mockCapture.lastLevel, 900);
      expect(mockCapture.lastError, defaultError);
      expect(mockCapture.lastStackTrace, defaultStackTrace);
    });

    test('Error (e) logs with optional error/stackTrace', () {
      // Act
      CKLogger.e(defaultTag, defaultMessage, defaultError, defaultStackTrace);

      // Assert
      expect(mockCapture.callCount, 1);
      expect(mockCapture.lastOutput,
          startsWith('[ConnectKit][$defaultTag][ERROR]'));
      expect(mockCapture.lastLevel, 1000);
      expect(mockCapture.lastError, defaultError);
    });

    test('Fatal (f) logs with optional error/stackTrace', () {
      // Act
      CKLogger.f(defaultTag, defaultMessage, defaultError, defaultStackTrace);

      // Assert
      expect(mockCapture.callCount, 1);
      expect(mockCapture.lastOutput,
          startsWith('[ConnectKit][$defaultTag][FATAL]'));
      expect(mockCapture.lastLevel, 1200);
      expect(mockCapture.lastError, defaultError);
    });
  });

  group('CKLogger Control Logic (bool? _enableLogsForTests)', () {
    test(
        'Logging is ENABLED when setLoggingEnabled is null (Defers to kDebugMode=true)',
        () {
      // Arrange (Default state from setUp: loggingEnabled = null)

      // Act (Since kDebugMode is true in test runner, this should execute)
      CKLogger.d(defaultTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 1,
          reason: 'Null state should defer to kDebugMode and log.');
      expect(mockCapture.lastOutput, isNotNull);
    });

    test(
        'Logging is DISABLED when setLoggingEnabled is false (Absolute Override)',
        () {
      // Arrange
      CKLogger.loggingEnabled = false;

      // Act (Should be suppressed despite kDebugMode=true)
      CKLogger.d(defaultTag, defaultMessage);
      CKLogger.i(defaultTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 0,
          reason: 'False state should absolutely override kDebugMode.');
    });

    test(
        'Logging is ENABLED when setLoggingEnabled is true (Absolute Override)',
        () {
      // Arrange
      CKLogger.loggingEnabled = true;

      // Act (Should log, which is the same as default behavior, but explicitly tested)
      CKLogger.d(defaultTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 1, reason: 'True state should log.');
    });
  });

  group('CKLogger Critical Bypass (R5) Logic', () {
    const criticalTag = 'CriticalInit';

    test(
        'Critical log executes when kDebugMode is true (default test environment)',
        () {
      // Arrange: Logging state is null/default (effectively kDebugMode=true)

      // Act
      CKLogger.critical(criticalTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 1,
          reason: 'kDebugMode=true should allow critical log.');
      expect(mockCapture.lastLevel, 1200);
    });

    test(
        'Critical log executes when bypass is true, despite logging disabled (Simulated Release)',
        () {
      // Arrange: Simulate a release build where standard logs are suppressed,
      // but the critical override is active.
      CKLogger.loggingEnabled = false; // Simulates standard logs suppressd
      CKLogger.criticalLogBypass = true; // R5 override active

      // Act
      CKLogger.critical(criticalTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 1,
          reason: 'Bypass flag should force critical log.');
      expect(mockCapture.lastOutput,
          contains('[FATAL]')); // Critical always logs as FATAL
    });

    test(
        'Critical log is suppressed when bypass is false AND logging is disabled',
        () {
      // Arrange: Force disable both standard logging and the critical bypass.
      CKLogger.loggingEnabled = false;
      CKLogger.criticalLogBypass =
          false; // false by default, but set for clarity

      // Act
      CKLogger.critical(criticalTag, defaultMessage);

      // Assert
      expect(mockCapture.callCount, 0,
          reason: 'Critical log should be suppressed if all flags are false.');
    });

    test(
        'Standard log is suppressed when standard logging is disabled, even if Critical Bypass is true',
        () {
      // Arrange: Critical bypass is true, but standard logging is false.
      CKLogger.loggingEnabled = false;
      CKLogger.criticalLogBypass = true;

      // Act
      CKLogger.d(defaultTag, defaultMessage); // Standard log

      // Assert
      expect(mockCapture.callCount, 0,
          reason: 'Critical bypass only affects critical(), not d().');
    });
  });

  group('CKLogLevel Mapping', () {
    test('Log levels map to correct integer values', () {
      // We can't directly call the private _levelToDeveloperInt, but we can verify
      // the known integer values via log execution.

      // Arrange (Already set to enabled in setUp)

      // Act & Assert
      CKLogger.d('T', 'd');
      expect(mockCapture.lastLevel, 500);
      CKLogger.i('T', 'i');
      expect(mockCapture.lastLevel, 800);
      CKLogger.w('T', 'w');
      expect(mockCapture.lastLevel, 900);
      CKLogger.e('T', 'e');
      expect(mockCapture.lastLevel, 1000);
      CKLogger.f('T', 'f');
      expect(mockCapture.lastLevel, 1200);
    });
  });
}
