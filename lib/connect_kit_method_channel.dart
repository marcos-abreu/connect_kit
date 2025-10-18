import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'connect_kit_platform_interface.dart';

/// An implementation of [ConnectKitPlatform] that uses method channels.
class MethodChannelConnectKit extends ConnectKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('connect_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
