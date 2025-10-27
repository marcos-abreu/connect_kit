import 'package:connect_kit/src/utils/enum_helper.dart';

/// TODO: Add documentation
enum CKPermissionStatus {
  /// Permission has been granted by the user
  granted,

  /// Permission has been denied by the user
  denied,

  /// Permission has not been determined yet
  notDetermined,

  /// Type doesn't exist, or not supported by the plugin, or OS/SDK
  /// version doesn't support it, or (for write) the type is read-only.
  notSupported,

  /// Permission status is unknown
  unknown;

  /// Defaults to unknown for unknown values
  factory CKPermissionStatus.fromString(String inputString) =>
      enumFromStringOrDefault(
        CKPermissionStatus.values,
        inputString,
        CKPermissionStatus.unknown,
      );
}

/// Extension providing additional metadata for CKPermissionStatus
extension CKPermissionStatusExtension on CKPermissionStatus {
  /// Returns the display name for this status
  String get displayName {
    switch (this) {
      case CKPermissionStatus.granted:
        return 'Granted';
      case CKPermissionStatus.denied:
        return 'Denied';
      case CKPermissionStatus.notDetermined:
        return 'Not Determined';
      case CKPermissionStatus.notSupported:
        return 'Not Supported';
      case CKPermissionStatus.unknown:
        return 'Unknown';
    }
  }

  /// TODO: Add documentation
  bool get isGranted => this == CKPermissionStatus.granted;

  /// TODO: Add documentation
  bool get isDenied => this == CKPermissionStatus.denied;

  /// TODO: Add documentation
  bool get isNotDetermined => this == CKPermissionStatus.notDetermined;

  /// TODO: Add documentation
  bool get isNotSupported => this == CKPermissionStatus.notSupported;

  /// TODO: Add documentation
  bool get isUnknown => this == CKPermissionStatus.unknown;

  /// Returns the suggested action for this status
  String get suggestedAction {
    switch (this) {
      case CKPermissionStatus.granted:
        return 'You can proceed with health data operations';
      case CKPermissionStatus.denied:
        return 'User must grant permission in settings';
      case CKPermissionStatus.notDetermined:
        return 'Request permission from user';
      case CKPermissionStatus.notSupported:
        return 'You cannot proceed with health data operations';
      case CKPermissionStatus.unknown:
        return 'Attempt data operation to verify access';
    }
  }
}
