import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'connect_kit_method_channel.dart';

abstract class ConnectKitPlatform extends PlatformInterface {
  /// Constructs a ConnectKitPlatform.
  ConnectKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static ConnectKitPlatform _instance = MethodChannelConnectKit();

  /// The default instance of [ConnectKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelConnectKit].
  static ConnectKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ConnectKitPlatform] when
  /// they register themselves.
  static set instance(ConnectKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
