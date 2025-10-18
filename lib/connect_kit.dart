/// A cross-platform bridge for Apple HealthKit and Google Health Connect.
library;

import 'dart:async';
import 'package:flutter/services.dart';

/// Main entry point for ConnectKit.
///
/// All methods are static — no instantiation required.
class ConnectKit {
  ConnectKit._(); // Private constructor

  /// Returns the platform version (for example app only).
  static Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Private method channel for platform communication.
  static const MethodChannel _channel = MethodChannel('connect_kit');
}
