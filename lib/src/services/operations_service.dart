import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/utils/operation_guard.dart';

/// Class reponsible for handling operational tasks
class OperationsService {
  /// Static log TAG
  static const String logTag = 'WriteService';

  final ConnectKitHostApi _hostApi;

  /// Constructor method
  OperationsService(this._hostApi);

  /// Retrieves the operating system version from the native platform (iOS/Android).
  ///
  /// Implements basic error handling for platform communication failures (Phase 9).
  Future<String> getPlatformVersion() async {
    final result = await OperationGuard.executeAsync(
      () async {
        return await _hostApi.getPlatformVersion();
      },
      operationName: 'Check SDK availability',
    );

    return result.dataOrThrow;
  }
}
