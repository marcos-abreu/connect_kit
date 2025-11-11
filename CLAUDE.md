# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ConnectKit is a cross-platform Flutter plugin that unifies access to health and fitness data from Apple HealthKit (iOS) and Google Health Connect (Android). It provides a type-safe Dart API that abstracts platform differences while maintaining performance and privacy.

## Key Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Format code (required before submitting PRs)
dart format .

# Generate platform channel code (Pigeon)
./script/generate_code.sh
```

### Example App Testing
```bash
# Navigate to example directory
cd example

# Install dependencies
flutter pub get

# Run the example app
flutter run
```

## Architecture

### Core Components

**Flutter/Dart Layer:**
- `lib/connect_kit.dart` - Main singleton entry point and public API
- `lib/src/services/` - Business logic and operation services
- `lib/src/pigeon/` - Auto-generated platform channel code (DO NOT EDIT)
- `lib/src/logging/` - Cross-platform logging wrapper (CKLogger)
- `lib/src/models/` - Data models for health information

**Platform Layers:**
- `ios/Classes/` - Swift implementation using HealthKit
- `android/src/main/kotlin/` - Kotlin implementation using Health Connect
- `pigeon/messages.dart` - Pigeon schema for type-safe platform channels

### Communication Flow

1. **Dart Layer**: Public API calls through `ConnectKit.instance`
2. **Operations Service**: Handles business logic and validation
3. **Pigeon Messages**: Type-safe serialization across platform boundary
4. **Native Implementation**: Platform-specific health data access

### Code Generation

The project uses **Pigeon** for type-safe platform channels. The schema is defined in `pigeon/messages.dart`. After modifying the schema, run:

```bash
./script/generate_code.sh
```

This regenerates code in:
- `lib/src/pigeon/connect_kit_messages.g.dart`
- `ios/Classes/Pigeon/`
- `android/src/main/kotlin/dev/luix/connect_kit/Pigeon/`

**IMPORTANT**: Never manually edit files in generated directories.

## Testing

### Test Structure
- `test/` - Unit tests for Dart code
- `example/` - Integration testing and manual testing app
- Platform-specific tests are in respective platform directories

### Running Tests
```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Logging

ConnectKit uses a structured logging system (`CKLogger`) that:
- Only logs in debug builds (automatically stripped in release)
- Provides different levels: debug, info, warning, error, fatal
- Uses tags for categorization (e.g., 'Permissions', 'HealthData')

**Usage:**
```dart
import 'package:connect_kit/src/logging/ck_logger.dart';

CKLogger.i('Permissions', 'Requested HealthKit access for steps');
CKLogger.e('DataSync', 'Failed to sync data', error: exception);
```

**NEVER** use `print()` or `debugPrint()` - always use `CKLogger`.
**NEVER** log health data or user identifiers.

## Platform-Specific Requirements

### iOS
- Requires HealthKit entitlements in Xcode
- Needs Info.plist permissions for health data access
- Uses Swift 5 and modern HealthKit APIs

### Android
- Requires Health Connect dependencies
- Needs AndroidManifest.xml configuration
- Uses Kotlin and Health Connect APIs

## Development Guidelines

### Code Style
- Follow official Dart style guide
- Use `dart format .` before committing
- Keep public API minimal and clean in `lib/connect_kit.dart`

### Adding New Health Data Types
1. Define models in `lib/src/models/`
2. Update Pigeon schema in `pigeon/messages.dart`
3. Implement native access in both iOS and Android
4. Add service methods in `lib/src/services/`
5. Expose through main API class

### Performance Considerations
- Minimize platform channel calls
- Batch operations where possible
- Use efficient data structures for large health datasets
- Consider async operations for heavy data processing

## Common Issues

### Code Generation
- If platform channel code fails to generate, ensure `flutter pub get` was run first
- Clean rebuild after Pigeon generation: `flutter clean && flutter pub get`

### Permissions
- iOS permissions are requested via HealthKit authorization dialogs
- Android permissions use Health Connect's permission flow
- Both platforms require user consent before accessing health data

### Testing Platform-Specific Code
- Use the example app for integration testing
- Mock platform channels for unit testing using `ConnectKit.forTesting()`
- Test on actual devices (health APIs not available in simulators)

## Code Agent Documentation System

### @.doc-agent/ Folder

The `@.doc-agent/` folder contains comprehensive documentation for AI code agents to understand and work with the project codebase effectively.

#### Structure and Purpose

- **@.doc-agent/README.md**: Main index file that provides an overview and navigation to all other documentation in the folder. Always start here when looking for specialized information.
- **@.doc-agent/product/**: Product documentation including:
  - Project structure and organization
  - Technology stack and dependencies
  - System design patterns and integration details
  - Data schemas and communication protocols
  - Among other overall architecture documents
- **@.doc-agent/guide/**: Guides and procedures for common development tasks
- **@.doc-agent/spec/**: Product Specification, Product Requirements Documents (PRDs) and implementation plans

#### Usage Guidelines

**Consuming Documentation:**
- Always reference `@.doc-agent/README.md` first to locate relevant specialized knowledge
- Use the categorized subfolders to find specific information about product, guide, or specification
- This documentation should be consulted during feature plan, implementation, debugging, and code reviews

**Updating Documentation:**
- **IMPORTANT**: Only the `/doc-agent` command should add or update information in the `@.doc-agent/` folder
- After implementing features, fixing complex bugs, or agreeing on requirements and implementation plans, invoke the `/doc-agent` command with the necessary information to keep documentation current
- The `/doc-agent` command has specialized knowledge about how to properly structure and organize documentation within this folder

#### When to Update Documentation

- After implementing new features or major changes
- When fixing complex bugs that required deep analysis
- After agreeing on feature requirements and implementation plans
- When architectural decisions are made or modified
- When development procedures or best practices change

#### When to Add Documentation

- After identifying a set of steps as a procedure or guide
- After being asked to plan or create a new project feture
- When learning a new way of performing possible repetitive actions in the project
- when a new technology is introduced

The documentation system ensures continuity and knowledge transfer across development sessions while maintaining consistency in how project information is organized and accessed.
