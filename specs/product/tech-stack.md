# Technology Stack

ConnectKit uses modern, well-supported technologies to ensure reliability and performance across platforms.

## Core Technologies

### Flutter/Dart
- **Flutter**: >=3.7.0 - UI framework and plugin system
- **Dart SDK**: >=3.0.0 <4.0.0 - Programming language
- **Pigeon**: ^26.0.2 - Type-safe platform channel code generation

### Android Platform
- **Kotlin**: Primary development language
- **Health Connect**: Google's modern health data platform
- **Android API Level**: Targeting modern Android versions with Health Connect support
- **Build System**: Gradle with standard Android plugin configuration

### iOS Platform
- **Swift**: Primary development language (Swift 5+)
- **HealthKit**: Apple's health data framework
- **iOS Version**: Supporting versions with modern HealthKit APIs
- **Xcode**: Standard iOS development toolchain

## Development Dependencies

### Code Quality
- **flutter_lints**: ^5.0.0 - Dart style guide enforcement
- **mocktail**: ^1.0.4 - Testing framework for mocks

### Testing
- **flutter_test**: Flutter's testing framework
- **Robolectric**: Android unit testing framework
- **XCTest**: iOS unit testing framework

## Build and Deployment

### Code Generation
- **Pigeon**: Generates type-safe platform channel code
- **Build Runner**: For future code generation needs

### Continuous Integration
- **GitHub Actions**: Automated testing and validation
- **Multi-platform**: Tests on both iOS and Android environments

## Platform-Specific Requirements

### Android
- **Health Connect Library**: Google's official Health Connect SDK
- **Permissions**: AndroidManifest.xml configuration for health data access
- **Gradle**: Standard Android build configuration

### iOS
- **HealthKit Framework**: Native iOS health data access
- **Entitlements**: HealthKit capabilities in Xcode project
- **Info.plist**: Health data usage descriptions

## Development Tools

### Essential Scripts
- **generate_code.sh**: Regenerates Pigeon platform channel code
- **Standard Flutter commands**: test, build, format, analyze

### IDE Support
- **Zed / VS Code / IntelliJ**: Dart/Flutter plugin support
- **Xcode**: iOS development and debugging
- **Android Studio**: Android development and debugging
