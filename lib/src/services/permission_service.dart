import 'package:connect_kit/src/pigeon/connect_kit_messages.g.dart';
import 'package:connect_kit/src/utils/operation_guard.dart';
import 'package:connect_kit/src/mapper/request_mappers.dart';
import 'package:connect_kit/src/mapper/response_mappers.dart';

import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/ck_sdk_status.dart';
import 'package:connect_kit/src/models/ck_access_status.dart';

/// TODO: add proper documentation
///  Service for handling SDK availability and permission management
class PermissionService {
  /// Static log TAG
  static const String logTag = 'PermissionService';

  final ConnectKitHostApi _hostApi;

  /// TODO: Add documentation
  PermissionService(this._hostApi);

  /// Check if health SDK is available on the current platform
  Future<CKSdkStatus> isSdkAvailable() async {
    final result = await OperationGuard.executeAsync(
      () async {
        final result = await _hostApi.isSdkAvailable();

        // parse response
        return CKSdkStatus.fromString(result);
      },
      operationName: 'Check SDK availability',
    );

    return result.dataOrThrow;
  }

  /// TODO: add proper documentation
  ///  Request permissions for health record types
  /// - History permission requires an accompanying data-type read permission to trigger the dialog
  //; - Background permission triggers with any accompanying data-type read or write permission
  Future<bool> requestPermissions({
    Set<CKType>? readTypes,
    Set<CKType>? writeTypes,
    bool? forHistory,
    bool? forBackground,
  }) async {
    final result = await OperationGuard.executeAsync(
      () async {
        final reqReadTypes = readTypes?.expandCompositeTypes().mapToRequest();
        final reqWriteTypes = writeTypes?.expandCompositeTypes().mapToRequest();

        return await _hostApi.requestPermissions(
          reqReadTypes,
          reqWriteTypes,
          forHistory,
          forBackground,
        );
      },
      operationName: 'Request permissions',
      parameters: {
        'readTypes': readTypes
            ?.expandCompositeTypes()
            .mapToRequest(), // shallow copy of parameter
        'writeTypes': writeTypes
            ?.expandCompositeTypes()
            .mapToRequest(), // shallow copy of parameter
        'forHistory': forHistory,
        'forBackground': forBackground,
      },
    );

    return result.dataOrThrow;
  }

  ///TODO: add proper documentation
  /// Check permissions for health record access
  Future<CKAccessStatus> checkPermissions({
    Map<CKType, Set<CKAccessType>>? forData,
    bool? forHistory,
    bool? forBackground,
  }) async {
    final result = await OperationGuard.executeAsync(
      () async {
        final reqDataToCheck = forData?.mapToRequest();

        final response = await _hostApi.checkPermissions(
          reqDataToCheck,
          forHistory,
          forBackground,
        );

        // parse response
        return CKAccessStatus.fromMessage(
          // NOTE: required normalization to extract inner object of `Map<String?, Object?>``
          response.dataAccess.normalizeAsDataAccess(),
          historyAccessString: response.historyAccess,
          backgroundAccessString: response.backgroundAccess,
        );
      },
      operationName: 'Check permissions',
      parameters: {
        'forData': forData?.mapToRequest(), // shallow copy of parameter
        'forHistory': forHistory,
        'forBackground': forBackground,
      },
    );

    return result.dataOrThrow;
  }

  /// TODO: add propper documention
  /// Revoke permissions (Android Health Connect only)
  Future<bool> revokePermissions() async {
    final result = await OperationGuard.executeAsync(
      () async {
        return await _hostApi.revokePermissions();
      },
      operationName: 'Revoke permissions',
    );

    return result.dataOrThrow;
  }

  /// Add propper documnetation
  /// Open health settings for the current platform
  Future<bool> openHealthSettings() async {
    final result = await OperationGuard.executeAsync(
      () async {
        return await _hostApi.openHealthSettings();
      },
      operationName: 'Open health settings',
    );

    return result.dataOrThrow;
  }
}
