import 'package:pigeon/pigeon.dart';

// The configuration for the Pigeon tool, specifying all input and output files,
// as well as platform class names for the generated code.
//
// INFO: To regenerate files, run:
// flutter pub run pigeon --input pigeon/messages.dart
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/connect_kit_messages.g.dart',
    dartOptions: DartOptions(),
    dartTestOut: 'test/pigeon/connect_kit_test_api.g.dart',
    kotlinOut: 'android/src/main/kotlin/dev/luix/connect_kit/pigeon/ConnectKitMessages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'dev.luix.connect_kit.pigeon',
      // errorClassName: 'ConnectKitError',
    ),
    swiftOut: 'ios/Classes/Pigeon/ConnectKitMessages.g.swift',
    swiftOptions: SwiftOptions(
      // errorClassName: 'ConnectKitError',
    ),

    // INFO: Leaving the following commented our to test, since some references attest
    //       that is needed, while other says it is not
    //
    // // REQUIRED: Objective-C output paths for Swift/Flutter bridging
    // objcHeaderOut: 'ios/Classes/Pigeon/connect_kit_messages.h',
    // objcSourceOut: 'ios/Classes/Pigeon/connect_kit_messages.m',
    // objcOptions: ObjcOptions(
    //   prefix: 'ConnectKit', // Use a clear prefix to avoid naming collisions
    // ),

    copyrightHeader: 'Copyright(c) 2025-present ConnectKit. All rights reserved.',
  ),
)

@HostApi()
abstract class ConnectKitHostApi {
  @async
  String getPlatformVersion();
}
