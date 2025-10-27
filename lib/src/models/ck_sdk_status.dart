import 'package:connect_kit/src/utils/enum_helper.dart';

/// Enum representing the availability status of health SDKs
/// Maps to both Apple HealthKit and Google Health Connect availability states
enum CKSdkStatus {
  /// Health SDK is available and ready to use
  /// iOS: HealthKit is available
  /// Android: Health Connect SDK_AVAILABLE
  available,

  /// Health SDK is not available
  /// iOS: HealthKit is not available
  /// Android: Health Connect SDK_UNAVAILABLE
  unavailable,

  /// Health SDK requires an update
  /// iOS: Not applicable (always maps to unavailable)
  /// Android: Health Connect SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED
  updateRequired;

  /// Parse a string value to HealthCKSdkStatus enum
  /// Defaults to unavailable for unknown values
  factory CKSdkStatus.fromString(String statusString) {
    return enumFromStringOrDefault(
      CKSdkStatus.values, // Pass the specific enum values
      statusString,
      CKSdkStatus.unavailable, // Use a specific default
    );
  }
}

/// Extension providing additional metadata for HealthCKSdkStatus
extension CKSdkStatusExtension on CKSdkStatus {
  /// Returns the display name for this status
  String get displayName {
    switch (this) {
      case CKSdkStatus.available:
        return 'Available';
      case CKSdkStatus.unavailable:
        return 'Unavailable';
      case CKSdkStatus.updateRequired:
        return 'Update Required';
    }
  }
}
