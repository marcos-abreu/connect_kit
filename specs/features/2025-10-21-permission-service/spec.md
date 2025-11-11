# **🔐 Permission Service Specification**

## Overview

Create a unified permission service for ConnectKit that handles the complex, divergent privacy models of **Apple HealthKit** and **Android Health Connect** through a single, platform-agnostic Dart interface.

## I. Project Goals

1. **Dart Abstraction:** Shield developers from all platform-specific permission identifiers and request methods
2. **Explicit Documentation:** Clearly define limitations, especially the key privacy difference in **iOS Read Access**
3. **Cross-Platform Consistency:** Use unified data types to represent authorization status uniformly
4. **Platform-Aware Design:** Handle critical platform differences while maintaining consistent API surface

## II. Core API Methods

The Permission Service provides the following public interface methods:

| Method | Purpose | Key Platform Nuance |
| :--- | :--- | :--- |
| `isSdkAvailable()` | Check platform service availability | Maps Health Connect's `updateRequired` to a status |
| `requestPermissions()` | Initiate authorization prompts | Handles Android's optional `history`/`background` flags |
| `checkPermissions()` | Get the current access status | **Crucially** handles iOS returning `unknown` for read access |
| `openHealthSettings()` | Direct the user to manage settings | Handles Android deep link vs. iOS general app settings link |
| `revokePermissions()` | Programmatically remove access | **Supported on Android**; Not supported on iOS (user must manually revoke) |

## III. Data Types and Enums

### PermissionStatus Enum
```dart
/// The possible authorization states for a specific health data access type.
enum PermissionStatus {
  granted,         // Access is confirmed and reliable
  denied,          // Access is confirmed to be blocked
  notDetermined,   // Status is pending or initial
  unknown,         // Status cannot be known due to platform privacy rules (iOS Read Access)
}
```

### AccessType Enum
```dart
/// The different types of access that can be requested or checked.
enum AccessType {
  read,
  write,
}
```

### SdkStatus Enum
```dart
/// Platform SDK availability status
enum SdkStatus {
  available,       // SDK is ready for use
  notAvailable,    // Not supported on this device
  updateRequired,  // Health Connect needs update (Android only)
}
```

### Data Types
- **HealthType**: `typedef HealthType = String` (e.g., 'steps', 'heart_rate', 'weight')
- **Supported Data Types**: steps, distance, active_energy, heart_rate, weight, height

## IV. Detailed API Specifications

### isSdkAvailable()
```dart
Future<SdkStatus> isSdkAvailable();
```
- **Purpose**: Check if the platform's health SDK is available and ready
- **Returns**: `SdkStatus` enum indicating SDK state (`available`/`notAvailable`)
- **Platform Nuances**:
  - Android: Returns `updateRequired` if Health Connect needs updating

### requestPermissions()
```dart
Future<bool> requestPermissions({
  Set<HealthType>? readTypes,
  Set<HealthType>? writeTypes,
  bool? requestHistory = false,
  bool? requestBackground = false,
});
```
- **Purpose**: Initiate authorization prompts for specified data types
- **Parameters**:
  - `readTypes`: Data types to request read access
  - `writeTypes`: Data types to request write access
  - `requestHistory`: Android-only flag for historical data access
  - `requestBackground`: Android-only flag for background data access
- **Returns**: `bool` indicating if the permission prompt was successfully shown. It has no relation with the user decision to grant permission or not.
- **Platform Nuances**:
  - iOS: Returns `true` if prompt was shown, **not** if access was granted
  - Android: Returns `true` if permissions were successfully granted
  - `requestHistory`/`requestBackground` ignored on iOS

### checkPermissions()
```dart
Future<AccessStatus> checkPermissions({
  required Map<HealthType, Set<AccessType>>? permissionsToCheck,
  bool? checkBackground = false,
  bool? checkHistory = false,
});
```
- **Purpose**: Get current access status without triggering requests
- **Parameters**:
  - `permissionsToCheck`: Map of data types to access types to check
  - `checkBackground`: Include app-wide background permission status (Android only)
  - `checkHistory`: Include app-wide history permission status (Android only)
- **Returns**: `AccessStatus` with detailed access status information

### AccessStatus Structure
```dart
class AccessStatus {
  final Map<HealthType, Map<AccessType, PermissionStatus>> dataAccess;
  final PermissionStatus? backgroundAccess; // Android only
  final PermissionStatus? historyAccess; // Android only
}
```

### openHealthSettings()
```dart
Future<bool> openHealthSettings();
```
- **Purpose**: Direct user to platform-specific health settings
- **Returns**: `bool` indicating if settings were successfully opened
- **Platform Behavior**:
  - Android: Opens Health Connect app with deep link into the app health settings page
  - iOS: Opens general app settings (health permissions are managed there)

### revokePermissions()
```dart
Future<void> revokePermissions({
  required Set<HealthType> readTypes,
  required Set<HealthType> writeTypes,
});
```
- **Purpose**: Programmatically revoke specific permissions
- **Platform Support**:
  - Android: **Fully supported** - granular revocation available
  - iOS: **Not supported** - skip functionality, since iOS doesn't support this yet, and log info

## V. Platform-Specific Logic Mapping

### Critical Platform Differences

The permission service manages two critical areas where the platforms differ significantly:

#### A. Permission Request Behavior
| Aspect | iOS HealthKit | Android Health Connect |
| :--- | :--- | :--- |
| **Request Method** | Separate `requestAuthorizationToShare()` and `requestAuthorizationToRead()` | Single `requestPermissions()` with permission sets |
| **Return Value** | `true` only if prompt was shown (not if granted) | `true` if permissions were successfully granted |
| **History/Background** | Not applicable (implicit access) | Explicit flags for `requestHistory` and `requestBackground` |

#### B. Permission Status Checking
| Status | Platform Source | Condition | Developer Action |
| :--- | :--- | :--- | :--- |
| **`granted`** | Both | Access is confirmed and reliable | Proceed to read/write data |
| **`denied`** | Both | Access is confirmed to be blocked | Use `openHealthSettings()` to guide user |
| **`notDetermined`** | iOS only | Access cannot be determined | Call `requestPermissions()` |
| **`unknown`** | **iOS HealthKit (Read Only)** | HealthKit API reports status as "not determined to app" | **Must attempt to read data.** If query fails with permissions error, assume denial |

## VI. Implementation Architecture

### Dart Layer Responsibilities
- **Permission Service** (`lib/src/services/permission_service.dart`): Business logic and cross-platform unification
- **Public API** (`lib/connect_kit.dart`): Expose permission methods to app developers
- **Platform Abstraction**: Handle iOS `unknown` read status transparently
- **Error Handling**: Use existing `ConnectKitException` framework for permission errors
- **Logging**: Use `CKLogger` for permission events (never log health data)

### Platform Channel Communication
- **Pigeon Schema** (`pigeon/messages.dart`): Define type-safe method signatures and data structures
- **Code Generation**: Run `./script/generate_code.sh` after schema changes
- **Message Types**: Permission requests, responses, and platform-specific data

### Native Layer Responsibilities
- **iOS** (`ios/Classes/`):
  - HealthKit integration using `HKHealthStore`
  - Handle iOS privacy rules and `unknown` read status
  - Map HealthKit authorization states to unified enum
- **Android** (`android/src/main/kotlin/`):
  - Health Connect API integration using `HealthConnectClient`
  - Handle permission sets and app-wide permissions
  - Manage historical and background access flags

## VII. Error Handling

### Exception Types
- `SdkUnavailableException`: HealthKit/Health Connect not accessible
- `DataConversionException`: Invalid data type or parameters
- `PlatformNotSupportedException`: Operation not supported on current platform

### Critical Error Scenarios

#### iOS-Specific Errors
- **Missing HealthKit Entitlements**: App not properly configured for health data access
- **Restricted Access**: Parental controls or corporate policies blocking access

#### Android-Specific Errors
- **Health Connect Not Installed**: User must install from Play Store
- **Outdated Health Connect Version**: `updateRequired` status returned
- **Missing Manifest Permissions**: Required permissions not declared in AndroidManifest.xml

#### Cross-Platform Errors
- Invalid data type identifiers
- Network connectivity issues (Health Connect)
- Platform-specific permission restrictions

## VIII. Usage Example

### Complete Permission Flow
```dart
Future<void> handleHealthDataPermissions() async {
  // 1. Check SDK Availability
  final sdkStatus = await connectKit.isSdkAvailable();
  if (sdkStatus != HealthSdkStatus.available) {
    if (sdkStatus == HealthSdkStatus.updateRequired) {
      await connectKit.openHealthSettings();
      return;
    }
    // Handle unavailable SDK
    return;
  }

  // 2. Request Permissions
  final readTypes = {'steps', 'heart_rate'};

  final requestSuccessful = await connectKit.requestPermissions(
    readTypes: readTypes,
    writeTypes: writeTypes,
    requestHistory: true, // Android-specific
  );

  if (!requestSuccessful) {
    // something wrong with the permission dialog
    return;
  }

  // 3. Check Final Statuses
  final permissionsToCheck = {
    'steps': {AccessType.read, AccessType.write},
    'heart_rate': {AccessType.read},
  };

  final result = await connectKit.checkPermissions(
    permissionsToCheck: permissionsToCheck,
    checkBackground: true, // Android-specific
  );

  // Handle Android Background Status
  if (result.backgroundAccess == HealthPermissionStatus.granted) {
    print('App-Wide Background Access Granted (Android only).');
  }

  // Handle Per-Data Type Statuses
  for (final type in readTypes.union(writeTypes)) {
    final readStatus = result.dataAccess[type]?[AccessType.read];
    final writeStatus = result.dataAccess[type]?[AccessType.write];

    if (readStatus == HealthPermissionStatus.unknown) {
      // CRITICAL iOS Read state: Must attempt actual data read
      print('$type Read Status: Unknown (iOS Privacy Rule). Proceeding to confirm access.');
    } else if (readStatus == HealthPermissionStatus.granted) {
      print('$type Read Access Granted.');
    } else if (readStatus == HealthPermissionStatus.denied) {
      print('$type Read Access Denied. User must change in settings.');
      await connectKit.openHealthSettings();
    }
  }

  // 4. Example Revocation (Android only)
  if (Platform.isAndroid) {
    await connectKit.revokePermissions(
      readTypes: {},
      writeTypes: {'steps'},
    );
  } else {
    // iOS - guide user to manual settings
    await connectKit.openHealthSettings();
  }
}
```

## IX. Testing Strategy

### Unit Tests
- Permission service business logic and cross-platform unification
- iOS `unknown` read status handling
- Platform-specific error translation
- Data type validation and enum mapping
- Mock platform channel responses

### Integration Tests
- Platform channel communication with Pigeon messages
- Native permission handling on both platforms
- Cross-platform response consistency
- Error propagation from native to Dart layer

### Manual Testing (Physical Devices Required)
- iOS: HealthKit permission dialogs and iOS-specific privacy behavior
- Android: Health Connect permission flows and app-wide permissions
- Permission status checking accuracy
- Settings navigation functionality
- Error condition handling (entitlements missing, Health Connect not installed)

### Critical Test Scenarios
- iOS `unknown` read status confirmation via actual data read attempts
- Android historical and background permission flows
- Platform-specific revocation behavior
- Cross-platform API consistency verification

## X. Implementation Phases

### Phase 1: Core Framework and Data Models ✅
1. Create enums: `PermissionStatus`, `AccessType`, `SdkStatus`
2. Create `AccessStatus` data class
3. Define Pigeon message schema with all method signatures
4. Generate platform channel code using `./script/generate_code.sh`

### Phase 2: Dart Permission Service ✅
1. Create `lib/src/services/permission_service.dart` with business logic
2. Implement cross-platform unification logic
3. Handle iOS `unknown` read status in Dart layer
4. Add comprehensive error handling with existing exception framework
5. Integrate CKLogger for permission event logging

### Phase 3: Native Platform Implementation ✅
1. **iOS**: Implement HealthKit integration with `HKHealthStore`
   - Handle separate read/write authorization requests
   - Map HealthKit authorization states to unified enum
   - Implement iOS `unknown` read status detection
2. **Android**: Implement Health Connect integration with `HealthConnectClient`
   - Handle permission sets and app-wide permissions
   - Implement historical and background access flags
   - Add granular revocation support

### Phase 4: Public API Integration ✅
1. Expose permission methods in main `ConnectKit` class
2. Update platform configuration documentation
3. Create comprehensive example app demonstration
4. Add detailed API documentation with usage examples

### Phase 5: Testing and Validation ✅
1. Add comprehensive unit test suite
2. Test on physical devices (required for health APIs)
3. Validate cross-platform API consistency
4. Test critical iOS `unknown` read status scenarios
5. Performance optimization and error message refinement

## XI. Success Criteria

- [x] Successfully request permissions for all supported data types across platforms
- [x] Accurately check permission status with proper platform-specific handling
- [x] Handle iOS `unknown` read status transparently for developers
- [x] Support Android historical and background access permissions
- [x] Provide platform-appropriate settings navigation
- [x] Handle platform-specific revocation (Android programmatic, iOS guided)
- [x] Maintain privacy by never storing or logging health data
- [x] Enable developers to implement their own permission workflows
- [x] Pass comprehensive unit and integration test suites
- [x] Validate on physical devices for both iOS and Android

---

**Document Status**: ✅ **IMPLEMENTATION COMPLETE**
**Target Release**: v0.3.0
**Dependencies**: Pigeon code generation, native platform integration, physical device testing
**Last Updated**: 2025-10-21