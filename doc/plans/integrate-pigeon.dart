# Plan for Integrating Pigeon for Channel Communication

## Overview
We'll implement Pigeon to replace the standard MethodChannel approach with a type-safe, code-generated solution. We'll start with a basic implementation using `getPlatformVersion` as our test method.

## Step-by-Step Plan

### Phase 1: Pigeon Setup and Definition
- Add `pigeon` as a `dev_dependency`
- Create the input directory and file: `/pigeon/messages.dart`.
- Define the pigeon configuration and minimal API. No messages since the return is a String and the request doesn't have parameters.

```
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  // ...
))

@HostApi()
abstract class ConnectKitHostApi {
  String getPlatformVersion();
}
```

- *Dart output*: `lib/pigeon/connect_kit_messages.g.dart`
-  *Kotlin Output*: `android/src/main/kotlin/dev/luix/connect_kit/pigeon/ConnectKitMessages.g.kt`
- *Swift Output*: `ios/Classes/Pigeon/ConnectKitMessages.g.swift`


### Phase 2: Generation Script & CI

- Create a new shell script (e.g., `script/generate_code.sh`), with the right command to generate pigeon content (dart, ios, and android)
- Run the generation script to create the initial generated files.
- Update the CI pipeline, if required

### Phase 3: Dart and ConnectKit Integration

This will be the Dart structure:

```
lib/
├── connect_kit.dart          # Main entry point, exports everything
├── src/
│   ├── client_api.dart       # Implements the Pigeon API
│   ├── models/               # Data models
│   ├── pigeon/               # Folder containing auto generated pigeon files
│   │   └── connect_kit_messages.g.dart
│   ├── services/             # Business logic
│   └── utils/                # Utilities
```

**Reasons:**
1. **Better Organization**: As the plugin grows, separation of concerns makes the code more maintainable.
2. **Clear Public API**: The main `connect_kit.dart` file can export only what is needed, creating a clean public API surface.
3. **Easier Testing**: test individual components in isolation.
4. **Future Growth**: This structure scales better as the plugin adds more functionality.

**Implementation approach:**

- `lib/connect_kit.dart`: Refactor it as the main entry point, that exports what is needed
```
library connect_kit;

export 'src/client_api.dart';
// export 'src/models/models.dart'; // later
```

- `lib/src/client_api.dart`: Implements the Pigeon-generated API from `lib/src/pigeon/connect_kit_messages.g.dart`
- *Implement `getPlatformVersion`*: method in the ClientApi class using Pigeon to call the host api.

ps: The decision for how to expose the plugin: it will be a singleton

**Reasons:**

1. **Flexibility**: Allows future initialization with parameters if needed
2. **Testability**: Easier to mock than static methods
3. **Consistency**: Follows common Flutter plugin patterns
4. **Lazy Initialization**: Only creates when first accessed


ps: the applications that use this plugin should use the methods through ConnetKit, not though the ClientApi... so I don't know how this will work, but the app should use the siglenton (form ConnectKit) to get the instance and use it to access the methods
### Phase 4: Unit Tests

* Create mock implementation of the Pigeon-generated classes for testing. This will allow me to test your Dart code without needing to run on actual devices. Maybe there is a solution already in some lib, but lets explore what is available and useful. (maybe with dart **mockito**, if needed)
* *Update Tests* : if necessary update the unit test

### Phase 5: Platform Implementation (Android)

* Fix the application path current is `android/src/main/kotlin/dev/luix/connect_kit/connect_kit/` and instead it should be `android/src/main/kotlin/dev/luix/connect_kit/` - (this might be related to some configuration I did, because this wrong path was created automatically)
* Change anything that is required on the `android/src/main/kotlin/dev/luix/connect_kit/ConnectKitPlugin.kt` (plugin lifecycle, dependency injection, host api instantiation, pigeon communication setup)
* Implement the required generated Kotlin interface (`android/src/main/kotlin/dev/luix/connect_kit/HostApi.kt`)

### Phase 6: Platform Implementation (iOS)

- The Android was wrongly setup with a wrong path, I don't know if this impacts iOS, but if it does, we should fix... maybe the fix is in the plugin configuration and will fix both Android and iOS at the same time.
- Change anything that is required on the `ios/Classes/ConnectKitPlugin.swift` (plugin lifecycle, dependency injection, host api instantiation, pigeon communication setup)
- Implement the required generated Swift interface (`ios/Classes/HostApi.swift`

### Phase 7: Update Example App
- Modify the example app to test the new implementation
- Ensure it still displays the platform version correctly for both iOS and Android

### Phase 8: Update Documentation
- The README.md file doesn't need this kind of detail about Pigeon, but we need to make sure the file contents conforms with what Pigeon brings to the project
- Document the code generation process for contributors

### Phase 9: Error Handling
* Implement the basic error handling, as per Flutter best practices when using Pigeon.

1. **Initialization Errors**: What happens if Pigeon fails to initialize
2. **Platform Communication Errors**: What happens if the native code is unavailable
3. **Timeout Handling**: What happens if a call takes too long
