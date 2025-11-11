library;

import 'package:flutter/foundation.dart'; // Required for @visibleForTesting
// import 'package:flutter/services.dart';

// The auto-generated Pigeon code lives here.
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/services/operations_service.dart';
import 'package:connect_kit/src/services/permission_service.dart';
import 'package:connect_kit/src/services/write_service.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/ck_access_status.dart';
import 'package:connect_kit/src/models/ck_sdk_status.dart';
import 'package:connect_kit/src/models/ck_write_result.dart';

// Exports for public models/enums - keeping the public interface clean
export 'package:connect_kit/src/models/models.dart';

/// Primary interface for the ConnectKit plugin
///
/// This class is implemented as a **singleton** using a lazy getter
/// to ensure internal services are initialized automatically upon first access
class ConnectKit {
  // --- Singleton Implementation ---

  /// **FOR TESTING ONLY.**
  /// Returns a new instance of [ConnectKit] with injected dependencies.
  /// Used to mock services and test the public API façade in isolation.
  @visibleForTesting
  ConnectKit.forTesting({
    ConnectKitHostApi? hostApi,
    OperationsService? operationsService,
    PermissionService? permissionService,
    WriteService? writeService,
  }) {
    _initialize(
      injectedHostApi: hostApi,
      injectedOperationsService: operationsService,
      injectedPermissionService: permissionService,
      injectedWriteService: writeService,
    ); // Initialize immediately on construction
  }

  /// Static log TAG
  static const String logTag = 'ConnectKit';

  /// Private constructor to enforce the singleton pattern
  ConnectKit._internal() {
    _initialize(); // Initialize immediately on construction
  }

  // A static final variable is initialized the first time it is accessed
  // Initialization is atomic and happens at most once
  static final ConnectKit _instance =
      ConnectKit._internal(); // ← final, non-nullable

  late final ConnectKitHostApi _hostApi;
  late final OperationsService _operationsService;
  late final PermissionService _permissionService;
  late final WriteService _writeService;

  /// The getter returns as single instance of the [ConnectKit] plugin
  static ConnectKit get instance => _instance;

  /// Initialization (idempotent)
  /// It allows optional dependency injection for testing purposes
  bool _initialized = false;
  void _initialize({
    ConnectKitHostApi? injectedHostApi,
    OperationsService? injectedOperationsService,
    PermissionService? injectedPermissionService,
    WriteService? injectedWriteService,
  }) {
    if (_initialized) return;
    _initialized = true;

    _hostApi = injectedHostApi ?? ConnectKitHostApi();
    _operationsService =
        injectedOperationsService ?? OperationsService(_hostApi);
    _permissionService =
        injectedPermissionService ?? PermissionService(_hostApi);
    _writeService = injectedWriteService ?? WriteService(_hostApi);
  }

  // --- Public API ---

  /// Retrieves the operating system version from the native platform
  ///
  /// Delegates the call to the internal Pigeon communication client
  Future<String> getPlatformVersion() {
    return _operationsService.getPlatformVersion();
  }

  /// Checks if the underlying health and fitness SDK is available and ready on the device.
  ///
  /// This method should be called before any other health data operations to ensure
  /// the platform's health service is accessible.
  ///
  /// **Platform Specifics:**
  /// - **iOS/HealthKit:** This check determines if HealthKit is supported on the current
  ///   device. It will return either [HealthCKSdkStatus.available] or [HealthCKSdkStatus.unavailable].
  /// - **Android/Health Connect:** This check verifies the installation and version status
  ///   of the Health Connect SDK. It can return [HealthCKSdkStatus.available],
  ///   [HealthCKSdkStatus.unavailable], or [HealthCKSdkStatus.updateRequired] if a newer
  ///   version of Health Connect must be downloaded from the Play Store.
  ///
  /// **Returns:**
  /// A Future that completes with a [HealthCKSdkStatus] enum indicating the availability
  /// and status of the native health SDK.
  Future<CKSdkStatus> isSdkAvailable() async {
    return await _permissionService.isSdkAvailable();
  }

  /// Initiates the platform-specific authorization request flow.
  ///
  /// **IMPORTANT:** The 'true' return value only indicates the request prompt
  /// was successfully shown/processed. It **does NOT** guarantee the user granted access,
  /// especially on **iOS/HealthKit**. You must call [checkPermissions] immediately afterward.
  ///
  /// For **Android/Health Connect**, a 'true' return generally means the request succeeded
  /// and the statuses are usually reliable.
  ///
  /// **Parameters:**
  /// - [readTypes]: The specific health data types to request **read** access for.
  /// - [writeTypes]: The specific health data types to request **write** access for.
  /// - [requestHistory] (Android only): Requests the app-wide permission to read all
  ///   available historical data (beyond 30 days). Ignored on iOS.
  /// - [requestBackground] (Android only): Requests the app-wide permission to read data in the
  ///   background. Ignored on iOS.
  ///
  /// **Returns:**
  /// A Future that completes with `true` if the system processed the request
  /// successfully, or `false` if a system error occurred (e.g., Health service unavailable).
  Future<bool> requestPermissions({
    required Set<CKType> readTypes,
    required Set<CKType> writeTypes,
    bool forHistory = false,
    bool forBackground = false,
  }) async {
    return await _permissionService.requestPermissions(
      readTypes: readTypes,
      writeTypes: writeTypes,
      forHistory: forHistory,
      forBackground: forBackground,
    );
  }

  // Assuming PermissionCheckResult is now a class/structure, as suggested previously:
  // class PermissionCheckResult { ... }

  /// Checks the current authorization status for a set of data types and access types.
  ///
  /// **iOS/HealthKit Specifics:**
  /// - **Read Access:** The status is always reported as [HealthPermissionStatus.unknown].
  ///   Your app must attempt to query data to infer if access was granted/denied.
  /// - **Write Access:** The status is reliable (granted, denied, notDetermined).
  ///
  /// **Android/Health Connect Specifics:**
  /// - **All Types:** The status is reliable for all access types (read, write, history, background).
  ///
  /// **Parameters:**
  /// - [permissionsToCheck]: A map where the key is the health type and the value is a Set
  ///   of access types ([read, write]) whose status should be checked.
  /// - [checkHistory] (Android only): Flag to explicitly check the app-wide HISTORY permission status.
  /// - [checkBackground] (Android only): Flag to explicitly check the app-wide BACKGROUND permission status.
  ///
  /// **Returns:**
  /// A Future that completes with a [CKAccessStatus] object detailing the status
  /// for each requested data type and the app-wide history/background statuses.
  Future<CKAccessStatus> checkPermissions({
    required Map<CKType, Set<CKAccessType>> forData, // permissionsToCheck,
    bool forHistory = false, // bool checkHistory = false,
    bool forBackground = false, // bool checkBackground = false,
  }) async {
    return await _permissionService.checkPermissions(
      forData: forData,
      forHistory: forHistory,
      forBackground: forBackground,
    );
  }

  /// Revokes the specified read and/or write permissions for the application.
  ///
  /// **Platform Specifics:**
  /// - **iOS/HealthKit:** HealthKit does not allow an application to programmatically revoke its
  ///   *own* permissions. This method will fail or have no effect on iOS. The user must manually
  ///   revoke permissions via the iOS Settings app.
  /// - **Android/Health Connect:** This method is fully supported. It revokes the requested
  ///   [readTypes] and [writeTypes] access for your application immediately.
  ///
  /// **Parameters:**
  /// - [readTypes]: The specific health data types to revoke **read** access for.
  /// - [writeTypes]: The specific health data types to revoke **write** access for.
  ///
  /// **Returns:**
  /// A Future that completes with `true` if the revocation was successful (always `true` on Android
  /// if the platform service is available), or `false` if the system failed to process the request.
  /// On iOS, this will typically return `false` or throw an error, as the operation is not supported.
  Future<bool> revokePermissions() async {
    return await _permissionService.revokePermissions();
  }

  /// Opens platform-specific settings for managing health permissions.
  ///
  /// **Android Priority Order (most specific → least specific):**
  /// 1. **Android 14+:** Direct to your app's Health Connect permission screen
  /// 2. **Android 13-:** General Health Connect settings (user navigates to app)
  /// 3. **Fallback:** App's system settings page
  ///
  /// **iOS:**
  /// - Opens your app's settings page
  /// - User must navigate: Health → Data Access & Devices → [Your App]
  /// - iOS does not support deep linking to HealthKit settings
  ///
  /// **Common Use Cases:**
  /// - User wants to revoke permissions manually
  /// - Permission request blocked after 3 denials (Android)
  /// - User wants to grant additional permissions
  /// - Troubleshooting permission issues
  ///
  /// **Returns:**
  /// A Future that completes with `true` if the system successfully opened the settings
  /// screen, or `false` if the operation failed.
  Future<bool> openHealthSettings() async {
    return await _permissionService.openHealthSettings();
  }

  /// Writes one or more health records to the native health platform.
  ///
  /// **Platforms:**
  /// - iOS: Writes to HealthKit as HKSample instances
  /// - Android: Writes to Health Connect as Record instances
  ///
  /// **Single vs Batch:**
  /// Pass a list of one record or many. Batching is more efficient for:
  /// - Bulk imports
  /// - Workout sessions with records that happened during session
  /// - Sync operations with multiple records
  ///
  /// **Update Behavior:**
  /// - **Android:** Supports upsert via `source.clientRecordId`
  ///   - If record exists with same ID and higher version: UPDATES
  ///   - If record doesn't exist: CREATES NEW
  /// - **iOS:** No upsert support (samples are immutable)
  ///   - Always creates NEW record
  ///   - To "update": Query old sample → Delete → Save new
  ///
  /// **Returns:** List of platform-assigned IDs (UUIDs on iOS, IDs on Android)
  ///
  /// **Throws:**
  /// - `PermissionDeniedException`: No write permission for data type(s)
  /// - `UnsupportedTypeException`: Data type not supported on platform/OS version
  /// - `ValidationException`: Record data invalid
  /// - `PlatformException`: Native platform error
  ///
  Future<CKWriteResult> writeRecords(List<CKRecord> records) async {
    return await _writeService.writeRecords(records);
  }

  // Future public methods will be added here, delegating to other services or clients
}
