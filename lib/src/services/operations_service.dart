import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';

/// Class reponsible for handling operationa tasks
class OperationsService {
  final ConnectKitHostApi _hostApi;

  /// Constructor method
  OperationsService(this._hostApi);

  /// Retrieves the operating system version from the native platform (iOS/Android).
  ///
  /// Implements basic error handling for platform communication failures (Phase 9).
  Future<String> getPlatformVersion() async {
    try {
      // Call the generated Pigeon method.
      final String version = await _hostApi.getPlatformVersion();
      return version;
    } on PlatformException catch (e) {
      // Platform Communication Errors (Phase 9)
      if (kDebugMode) {
        debugPrint('PlatformException caught: ${e.message}');
      }
      rethrow;
    } catch (e) {
      // Initialization or other errors (Phase 9)
      if (kDebugMode) {
        debugPrint('General error caught: $e');
      }
      rethrow;
    }
  }
}
