import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/connect_kit.dart';
import 'package:connect_kit/connect_kit_platform_interface.dart';
import 'package:connect_kit/connect_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockConnectKitPlatform
    with MockPlatformInterfaceMixin
    implements ConnectKitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ConnectKitPlatform initialPlatform = ConnectKitPlatform.instance;

  test('$MethodChannelConnectKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelConnectKit>());
  });

  test('getPlatformVersion', () async {
    ConnectKit connectKitPlugin = ConnectKit();
    MockConnectKitPlatform fakePlatform = MockConnectKitPlatform();
    ConnectKitPlatform.instance = fakePlatform;

    expect(await connectKitPlugin.getPlatformVersion(), '42');
  });
}
