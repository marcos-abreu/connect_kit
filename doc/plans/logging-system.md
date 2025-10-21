# **🎯 Feature Plan: High-Performance, Debug-Only Logging System**

## **I. Project Goals**

Create a unified, minimal-overhead logging system for ConnectKit that:

1. **Achieve Zero Log Overhead:** Ensure all standard logging code is removed from the compiled application binary in release mode, resulting in zero runtime cost and maintaining user privacy.
2. **Maximize Developer Experience (DX):** Provide a single, consistent, and structured logging interface (CKLogger) that works identically across Dart, Android, and iOS code.
3. **Utilize Native Tooling:** Leverage platform-optimized log systems (os\_log and android.util.Log) for high-speed, native debugging context.

## **II. Key Requirements**

| Requirement | Description | Stripping Mechanism |
| :---- | :---- | :---- |
| **R1. Uniform Interface** | A single CKLogger class with static methods: d(), i(), w(), e(), f() (fatal). | Wrapper/Facade Pattern |
| **R2. Compile-Time Stripping** | Standard log methods (R1) must only execute in debug/profile builds. | kDebugMode (Dart), BuildConfig.DEBUG (Android), \#if DEBUG (iOS) |
| **R3. Log Levels** | Define a Dart enum for log levels: debug, info, warn, error, fatal. | Shared Enum (Internal) |
| **R4. Structured Format** | Output must follow the structure: \[ConnectKit\] \[TAG\] \[LEVEL\] message. | Handled by platform wrappers. |
| **R5. Critical Bypass** | Implement a CKLogger.critical(tag, message) method that **bypasses** the stripping mechanism. This should only be used for core initialization or unrecoverable error reporting. | Internal boolean flag check. |
| **R6. Testability** | Introduce an internal flag (\_enableLogsForTests) accessible via a setter to enable logs during unit testing where kDebugMode is false. | Internal boolean flag check. |
| **R7. Platform Implementation** | iOS must use os\_log and Android must use android.util.Log. | Native Wrapper Implementation |
| **R8. Dart Implementation** | Dart must use `developer.log` for zero-overhead | Dart Wrapper Implementation |
| R9. Tagging Convention | Each log call should specify a tag representing a developer-provided scope (e.g., [Auth], [Network], [BLE]). Default tag: [Core]. | Optional tag parameter in CKLogger methods |

## **III. Task Breakdown**

### **Task 1: Dart Core and Interface Definition**

**Goal:** Establish the main entry point, log levels, debug-mode gates, and testability control for the entire system.

* **Sub-Tasks:**
  1. Create lib/src/ck\_log\_level.dart with the CKLogLevel enum.
  2. Create lib/src/ck\_logger.dart implementing the static CKLogger interface.
  3. Implement the if (kDebugMode) gate for all standard methods (d, i, w, e, f).
  4. Implement the logic for CKLogger.critical() and the internal setter to handle testing mode (\_enableLogsForTests).

### **Task 2: Android Native Wrapper Implementation**

**Goal:** Create a simple Kotlin wrapper to enforce BuildConfig.DEBUG stripping and structure log output using android.util.Log.

* **Sub-Tasks:**
  1. Create a Kotlin CKLogger class (or object) in the Android source set.
  2. Implement methods (d, i, w, e, f) that map to Log.d, Log.i, etc.
  3. Wrap all log execution code in if (BuildConfig.DEBUG) to ensure compile-time stripping.
  4. Implement the formatting logic to prefix the message with \[ConnectKit\]\[TAG\]\[LEVEL\].

### **Task 3: iOS Native Wrapper Implementation**

**Goal:** Create a simple Swift wrapper to enforce \#if DEBUG stripping and structure log output using the optimized os\_log.

* **Sub-Tasks:**
  1. Create a Swift CKLogger class (or struct) in the iOS source set.
  2. Implement methods (d, i, w, e, f) that map to the appropriate os\_log call (e.g., .debug, .info, .error).
  3. Wrap the log calls using the \#if DEBUG preprocessor macro to ensure compile-time stripping.
  4. Implement the formatting logic to prepare the message payload for os\_log.

### **Task 4: Replace current logs and todos with new CKLogger in all Platforms**

**Goal:** Use the new CKLogger to replace all current logs and todos in all platforms.

* **Sub-Tasks:**
  1. Replace all current logs and todos with new CKLogger on Dart
  2. Replace all current logs and todos with new CKLogger on Android
  3. Replace all current logs and todos with new CKLogger on iOS

### **Task 5: Documentation and Testing**

**Goal:** Document the new CKLogger and provide unit tests to ensure it works as expected.

* **Sub-Tasks:**
  1. Document the new CKLogger in the README and in the API reference.
  2. Clear guidelines on what can/cannot be logged (not health data, sensitive data, etc.).
  3. Add unit tests to ensure the CKLogger works as expected.

## Kotlin Build Notes

Rationale for Omitting LogExecutor in Kotlin CKLogger

The Dart/Flutter implementation of the CKLogger required a LogExecutor interface to abstract the actual logging mechanism (developer.log). This was necessary primarily for two reasons:

Testability: To allow mocking the logging function during unit tests to verify that Log.d, Log.e, etc., were called with the correct parameters.

Pollution Control: To prevent excessive console output (log pollution) during test execution, as Dart's unit test environment does not automatically strip log calls.

In the Kotlin/Android environment, this abstraction is considered redundant due to native testing solutions:

1. Testability (Verifying Calls)

Because the underlying logging utility, android.util.Log, is a static class from the Android framework, it cannot be mocked with standard JVM unit testing tools (like Mockito).

Instead, we rely on the Robolectric testing framework. Robolectric provides a "shadow" implementation of the core Android classes, specifically ShadowLog.

ShadowLog automatically intercepts all static calls to android.util.Log.

During testing, we can use ShadowLog.getLogs() to retrieve a list of every log entry made by the code under test.

This mechanism allows us to precisely verify the tag, level (D, E, W), and message content of every logging call without introducing a dependency injection facade (LogExecutor) into the production code.

2. Pollution Control (Preventing Output)

Log pollution is naturally handled by the Android build system and the testing environment:

Release Builds: Logging calls are typically wrapped in an if (BuildConfig.DEBUG) block. When building for release or running release-side tests, the compiler performs dead code elimination  and strips these log calls entirely, guaranteeing zero pollution.

Robolectric: When running unit tests via Robolectric, even in debug mode, the calls are diverted to the in-memory ShadowLog list, not the console or the device's logcat, thus preventing noisy output.
