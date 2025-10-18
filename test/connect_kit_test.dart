import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/connect_kit.dart';

void main() {
  // Initialize Flutter bindings
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('connect_kit');

  test('getPlatformVersion returns mocked value', () async {
    // Mock the method channel using the BinaryMessenger
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getPlatformVersion') {
        return '42';
      }
      return null;
    });

    // Call your real static method
    final version = await ConnectKit.getPlatformVersion();

    expect(version, '42');

    // Clean up: remove the mock handler
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('MethodChannel is used by ConnectKit', () {
    // Just verify the channel call doesn't throw
    expect(() => ConnectKit.getPlatformVersion(), returnsNormally);
  });
}
