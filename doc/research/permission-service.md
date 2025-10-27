# Plugin Architecture: Permission Service

The **Permission Service** is the central component responsible for handling all user consent, authorization checks, and access management across both **Apple HealthKit** and **Android Health Connect**. It is designed to provide a unified, platform-agnostic Dart interface while managing the complex, divergent privacy models of the underlying SDKs.

-----

## 1\. Core Principles

The service operates on three core principles:

1.  **Dart Abstraction:** Shield the developer from all platform-specific permission identifiers and request methods.
2.  **Explicit Documentation:** Clearly define limitations, especially the key privacy difference in **iOS Read Access**.
3.  **Cross-Platform Consistency:** Use unified data types (`HealthType`, `AccessType`, `HealthPermissionStatus`) to represent authorization status uniformly.

-----

## 2\. Dart API Signatures

The following methods constitute the public interface of the Permission Service:

| Method | Role | Key Platform Nuance |
| :--- | :--- | :--- |
| `isSdkAvailable()` | Check platform service availability. | Maps Health Connect's `updateRequired` to a status. |
| `requestPermissions()` | Initiate authorization prompts. | Handles Android's optional `history`/`background` flags. |
| `checkPermissions()` | Get the current access status. | **Crucially** handles iOS returning `unknown` for read access. |
| `openHealthSettings()` | Direct the user to manage settings. | Handles Android deep link vs. iOS general app settings link. |
| `revokePermissions()` | Programmatically remove access. | **Supported on Android**; Not supported on iOS (user must manually revoke). |

### Supporting Data Types (Dart)

```dart
/// The possible authorization states for a specific health data access type.
enum HealthPermissionStatus {
  granted,
  denied,
  notDetermined, // Status is pending or initial (common for initial write/Android)
  unknown,       // Status cannot be known due to platform privacy rules (iOS Read Access)
}

/// The different types of access that can be requested or checked.
enum AccessType {
  read,
  write,
}

/// Placeholder for the specific data type identifiers (e.g., 'steps', 'heart_rate').
typedef HealthType = String;
```

-----

## 3\. Platform-Specific Logic Mapping

The permission service manages two critical areas where the platforms differ significantly: the permission request structure and the status checking mechanism.

### A. The `requestPermissions` Mapping

The Dart method separates `readTypes` and `writeTypes`, which the native code maps as follows:

| Dart Input | iOS/HealthKit Mapping | Android/Health Connect Mapping |
| :--- | :--- | :--- |
| `readTypes`, `writeTypes` | Standard `requestAuthorizationToShare()` and `requestAuthorizationToRead()`. | Used to build the `Set<String>` of permissions for the Health Connect API. |
| `requestHistory`, `requestBackground` | **Ignored.** | Mapped to the separate, app-wide manifest permissions (`READ_HEALTH_DATA_HISTORY`, `READ_HEALTH_DATA_IN_BACKGROUND`). |
| **Return Value (`Future<bool>`)** | Returns `true` only if the prompt was shown. **Does not imply access was granted.** | Returns `true` if all permissions were successfully granted in the user flow (status is usually reliable). |

### B. The `checkPermissions` Status Handling

The native implementation must map the raw platform status codes to the unified `HealthPermissionStatus` enum.

| Dart Status | Platform Source | Native Condition/Context | Developer Action |
| :--- | :--- | :--- | :--- |
| **`granted`** | Both | Access is confirmed and reliable. | Proceed to read/write data. |
| **`denied`** | Both | Access is confirmed to be blocked. | Use `openHealthSettings()` to guide user to re-enable. |
| **`notDetermined`** | Both | Request has not been initiated/completed. | Call `requestPermissions()`. |
| **`unknown`** | **iOS HealthKit (Read Only)** | HealthKit API reports status as "not determined to app". | **Must attempt to read data.** If the query fails with a permissions error, assume denial. |

-----

## Sample Application Permission Flow

This example demonstrates a user journey that checks the SDK status, requests necessary permissions, checks the final status, including how to handle the special iOS `unknown` state for read access. And even a revocation example.


### Dart Code Example

```dart
Future<void> handleHealthDataPermissions() async {
  print('--- 1. Checking SDK Availability ---');
  final sdkStatus = await connectKit.isSdkAvailable();

  if (sdkStatus != HealthSdkStatus.available) {
    if (sdkStatus == HealthSdkStatus.updateRequired) {
      print('Health Connect Update Required. Opening settings...');
      // Use the helper method to guide the user to the store
      await connectKit.openHealthSettings();
    } else {
      print('Health SDK not available or device not supported.');
    }
    return; // Cannot proceed without the SDK.
  }

  print('--- 2. Requesting Permissions ---');
  // Define the permissions needed for this feature
  final readTypes = {'steps', 'heart_rate'};
  final writeTypes = {'steps'};

  // Initiate the prompt, requesting Android History access
  final requestSuccessful = await connectKit.requestPermissions(
    readTypes: readTypes,
    writeTypes: writeTypes,
    requestHistory: true, // Android-specific: Ask for historical data access
  );

  if (!requestSuccessful) {
    print('Permission request failed or was interrupted by the system.');
    return;
  }

  print('--- 3. Checking Final Statuses ---');
  // 3a. Define the permissions we want to check
  final permissionsToCheck = {
    'steps': {AccessType.read, AccessType.write},
    'heart_rate': {AccessType.read},
  };

  // 3b. Check the statuses, including the app-wide History permission
  final result = await connectKit.checkPermissions(
    permissionsToCheck: permissionsToCheck,
    checkHistory: true, // Explicitly check the app-wide History status
  );

  // --- Handle Android History Status ---
  if (result.historyAccess == HealthPermissionStatus.granted) {
    print('✅ App-Wide History Access Granted (Android only).');
  } else if (result.historyAccess == HealthPermissionStatus.denied) {
    print('❌ App-Wide History Access Denied. Cannot read data older than 30 days.');
  }

  // --- Handle Per-Data Type Statuses ---
  for (final type in readTypes.union(writeTypes)) {
    final readStatus = result.dataAccess[type]?[AccessType.read];
    final writeStatus = result.dataAccess[type]?[AccessType.write];

    if (readStatus == HealthPermissionStatus.unknown) {
      // This is the CRITICAL iOS Read state: We can't know for sure.
      print('⚠️ $type Read Status: Unknown (iOS Privacy Rule). Proceeding to data read to confirm access.');
    } else if (readStatus == HealthPermissionStatus.granted) {
      print('✅ $type Read Access Granted.');
    } else if (readStatus == HealthPermissionStatus.denied) {
      print('❌ $type Read Access Denied. User must change in settings.');
      // Recommended step after denial: Guide the user
      // await connectKit.openHealthSettings();
    }

    if (writeStatus == HealthPermissionStatus.granted) {
      print('✅ $type Write Access Granted.');
    }
    // ... handle other write statuses (denied, notDetermined)
  }

  print('--- 4. Revoking a Permission (Example) ---');
  // Example: A user has disabled a feature, and we no longer need 'steps' write permission.

  // NOTE: We check the platform to handle the revocation difference.
  if (Platform.isAndroid) {
    // Android (Health Connect) supports programmatic, granular revocation.
    await permissionService.revokePermissions(
      readTypes: {},
      writeTypes: {'steps'},
    );
    print('✅ Revoked \'steps\' write permission on Android.');
  } else if (Platform.isIOS) {
    // iOS (HealthKit) requires manual revocation by the user.
    print('⚠️ iOS does not allow programmatic revocation. Guiding user to settings...');
    // We use the helper method to open the OS settings screen for the app.
    final settingsOpened = await permissionService.openHealthSettings();
    if (!settingsOpened) {
      print('Could not open settings. Open your phone settings to revoke health permissions.');
    }
  }
}
```
