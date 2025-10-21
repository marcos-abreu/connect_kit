# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

[Unreleased]: https://github.com/marcos-abreu/connect_kit/compare/v0.2.0...HEAD

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
