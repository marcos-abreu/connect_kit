
import 'connect_kit_platform_interface.dart';

class ConnectKit {
  Future<String?> getPlatformVersion() {
    return ConnectKitPlatform.instance.getPlatformVersion();
  }
}
