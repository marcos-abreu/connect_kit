# ConnectKit
**Cross-platform health data bridge for Flutter — seamlessly integrating Apple HealthKit and Google Health Connect.**
> The robust, modern, and type-safe connection layer for health and fitness data across iOS and Android.

![Pub Version](https://img.shields.io/pub/v/connect_kit.svg)
![CI](https://github.com/marcos-abreu/connect_kit/actions/workflows/ci.yml/badge.svg)
![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20Android-blue.svg)
![License](https://img.shields.io/github/license/marcos-abreu/connect_kit.svg)

---

## 2. What is ConnectKit?

**ConnectKit** is a cross-platform Flutter plugin that unifies access to health and fitness data from **Apple HealthKit** (iOS) and **Google Health Connect** (Android).

It simplifies complex native integrations behind a clean, type-safe Dart API — helping you focus on your app experience, not platform differences.

---

## 3. Core Features

📶 **Extensive Health Metric Coverage** - Supports a wide and growing variety of common and specialized data types, including workout, sleep, nutrition, biometrics, and characteristics types.

🔗 **Unified Platform API** - Combines all core operations—permission management, data reading, writing, and deletion—into a single, intuitive interface.

🔀 **Platform-Agnostic Data Schema** - Provides a single, unified Dart data model for all health metrics, completely abstracting the disparate HealthKit and Health Connect platform schemas.

🛡️ **Robust and Maintainable Core** - Built on a modern, layered architecture with comprehensive test coverage, guaranteeing stability and contribution clarity for long-term project viability.

⚡ **Optimized Architecture** - Engineered for speed and resource efficiency, this architecture features minimal runtime overhead, ensuring rapid data processing in production applications.

---

## 4. Installation

Add `connect_kit` to your Flutter project:

```bash
flutter pub add connect_kit
```

> ⚙️ **Platform Setup Required:**
> **iOS** requires HealthKit entitlements and Info.plist permissions.
> **Android** requires Health Connect configuration in your AndroidManifest.xml.
>
> See our [Platform Setup Guide](doc/Platform_Setup.md) for full details.

---

## 5. Quick Usage

Here’s a simple example to get started:

```dart
import 'package:connect_kit/connect_kit.dart';

void main() async {
  // Get the singleton instance
  final connectKit = ConnectKit.instance;

  // Request read permissions for step count
  await connectKit.requestPermissions(readTypes: [CKTypes.steps]);

  // Retrieve step data
  final steps = await connectKit.read(
    types: [CKTypes.steps],
    from: DateTime.now().subtract(Duration(days: 1)),
    to: DateTime.now(),
  );

  // Use the data
  print('Total steps: ${steps.length}');
}
```

That’s all you need to start reading health data from both, iOS and Android, platforms.

---

## 6. Documentation & Support

📘 **API Reference:** [View on pub.dev](https://pub.dev/packages/connect_kit)

🧭 **Full Documentation:** [Platform setup, advanced usage, and architecture overview →](doc/Architecture.md)

🐛 **Issue Tracker:** [GitHub Issues](https://github.com/marcos-abreu/connect_kit/issues)


*Need help or found a bug? Open an [issue](https://github.com/marcos-abreu/connect_kit/issues) — your feedback drives improvements.*

---

## 7. Contributing

> Contributions are what make the open-source community an incredible place to learn, inspire, and build.
> Whether you're fixing a bug, improving documentation, or proposing a new feature — we welcome your help!

**➡️ Get Started:**
See the [Contributor Documentation Guide](CONTRIBUTING.md) for details on:

* Setting up your local environment
* Understanding the plugin’s architecture
* Running tests and submitting pull requests

[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 8. License (MIT)

This project is licensed under the [MIT License](LICENSE).
