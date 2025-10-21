/// A mock implementation of the LogExecutor to capture logging calls
/// and verify their contents and execution
class MockLogCapture {
  int callCount = 0;
  String? lastOutput;
  int? lastLevel;
  Object? lastError;
  StackTrace? lastStackTrace;

  /// Resets the internal state for the next test run.
  void reset() {
    callCount = 0;
    lastOutput = null;
    lastLevel = null;
    lastError = null;
    lastStackTrace = null;
  }

  /// The mock function that replaces dart:developer.log in tests.
  void mockLogExecutor(
    String message, {
    int? level,
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    callCount++;
    lastOutput = message;
    lastLevel = level;
    lastError = error;
    lastStackTrace = stackTrace;
  }
}
