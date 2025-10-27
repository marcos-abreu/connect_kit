# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

[0.3.1] - 2025-10-27

  Fixed

  - CKAccessStatus Equality - Fixed equality and hashCode logic to ensure consistent comparison of permission status
  objects
  - Permission Service Testing - Enabled PermissionService dependency injection for improved testability
  - Test Infrastructure - Fixed mock setup and parameter matching in ConnectKit facade tests

  Added

  - Permission Service Tests - Added comprehensive test coverage for all PermissionService methods:
    - checkPermissions delegation and error handling
    - revokePermissions delegation and error handling
    - openHealthSettings delegation and error handling
  - ConnectKit Facade Tests - Complete test suite verifying proper delegation patterns between public API and service
  layer

  Changed

  - Record Schema Structure - Modified internal data model structure to support improved record handling
  - Test Architecture - Enhanced test infrastructure with proper Mocktail parameter matching and dependency injection

  Testing

  - Fixed all failing unit tests in ConnectKit facade
  - Implemented missing test cases for permission-related operations
  - Improved test reliability with proper mock setup and verification
  - All unit tests now pass successfully

[Unreleased]: https://github.com/marcos-abreu/connect_kit/compare/v0.3.1...HEAD

## [0.3.0] - 2025-10-26

### Added

- **Complete Permissions API Implementation** - Comprehensive permission management across all platforms:
  - **PermissionService** - Unified high-level API for permission operations
  - **requestPermissions()** - Request health data permissions with granular control
  - **checkPermissions()** - Check current permission status with detailed CKAccessStatus
  - **revokePermissions()** - Revoke all health data permissions
  - **openHealthSettings()** - Open platform health settings for user configuration

- **Enhanced Type System** - Robust data model for permission management:
  - **CKAccessStatus** - Comprehensive permission status container
  - **CKPermissionStatus** - Granular permission states (granted, denied, notDetermined, etc.)
  - **CKAccessType** - Read/write access type enumeration
  - **CKType** - Extended health data type system with auto-generation
  - **CKSDKStatus** - Platform SDK availability checking

- **Platform Implementation**:
  - **Android** - Full Health Connect integration with permission mapping
  - **iOS** - Complete HealthKit implementation with proper authorization flow
  - **Cross-platform** - Unified API surface with consistent behavior

- **Example App Overhaul** - Comprehensive permission demonstration:
  - **PermissionDemoScreen** - Interactive permission testing interface
  - **Visual feedback** - Color-coded results (green/red) for success/failure states
  - **Code snippets** - Real-time code generation for each permission operation
  - **Platform-specific guidance** - Contextual help for Android vs iOS behavior

- **Documentation & Research**:
  - **Extensive research docs** - Platform-specific implementation guides
  - **Type mapping analysis** - Comprehensive Health Connect ↔ HealthKit mapping
  - **Implementation patterns** - Best practices for health data handling

### Changed

- **Android Dependencies** - Added Health Connect as official dependency
- **Example App Configuration** - Updated platform setup for health permissions
- **Code Generation** - Enhanced CKType auto-generation tooling
- **Test Infrastructure** - Updated Pigeon generated test helpers

### Fixed

- **Version consistency** - Fixed plugin version configuration
- **Documentation formatting** - Improved README presentation and clarity

[Unreleased]: https://github.com/marcos-abreu/connect_kit/compare/v0.3.0...HEAD

## [0.2.0] - 2025-10-21

### Added

- Introduced a unified cross-platform logging system: CKLogger
  - Supports Dart, Android (Kotlin), and iOS (Swift) layers.
  - Provides consistent log levels: i (info), w (warning), and e (error).
  - Centralizes internal diagnostics for easier debugging and performance tracing.

- Added structured logs to:
  - Plugin lifecycle methods (onAttachedToEngine, onDetachedFromActivity, etc.)
  - Operation guards and result handling (OperationGuard, Result).

- Added privacy and contribution documentation:
    - docs/privacy.md – outlines what can and cannot be logged.

### Changed

- Replaced scattered Log.d / print / NSLog calls with CKLogger for consistency.
- Minor improvements to readability and error reporting across the plugin lifecycle.
- Updated CONTRIBUTING.md with logging best practices.

### Testing
- Introduced a mock_log_executor.dart helper to intercept logs during tests.
- Added unit tests for Result.onSuccess() and Result.onFailure() error branches.

### Notes

- The new logging system is developer-only and does not collect user or health data.
- Logging is disabled in production builds to preserve performance and privacy.


[0.2.0]: https://github.com/marcos-abreu/connect_kit/releases/tag/v0.2.0

## [0.1.0] - 2025-10-21

### Added

- Flutter Plugin: Added initial Flutter plugin setup
- CI/CD: Added GitHub Actions CI/CD pipeline.
- Core Architecture: Established the core plugin architecture (ConnectKitPlugin / CKHostApi) using Pigeon for type-safe cross-platform communication.
- Platform Identification: Implemented getPlatformVersion for Android and iOS.
- Documentation: Created initial README.md, CHANGELOG.md, and detailed PLATFORM_SETUP.md guides.
- Example: Set up a functioning example application to verify platform setup.
- Tests: implemented unit tests for the core plugin architecture.

[0.1.0]: https://github.com/marcos-abreu/connect_kit/releases/tag/v0.1.0
