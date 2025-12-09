import 'package:connect_kit/src/models/schema/ck_device.dart';

/// Source information for health data records
///
/// Combines recording method, device info, and sync identifiers
/// into a single model representing data provenance.
class CKSource {
  /// How this data was recorded (required for Android)
  final CKRecordingMethod recordingMethod;

  /// Device that recorded the data (optional for manual, required for auto/active)
  final CKDevice? device;

  /// Your app's unique identifier for this record
  /// Use this ID to uniquely identify objects in your application
  ///
  /// This lets you maintain your own refrence to a record, for server syncs
  /// and later manipulations
  final String? appRecordUUID;

  /// Health SDK (Health Connect / HealthKit) unique id for this record
  /// When reading: the Health SDK will give you the id
  /// When writing: add this with incremented sdkVersion to upsert (update)
  ///               for new items don't inform
  ///
  /// **Android:** Enables upsert - if record with this ID exists and version
  ///              is higher, it gets updated; otherwise new record created
  /// **iOS:**     Can be stored in metadata for your own tracking,
  ///              but need to confirm if iOS support upsert natively
  final String? sdkRecordId;

  /// Health SDK (Health Connect / HealthKit) version number for this record
  /// When reading: the Health SDK will give you the latest version
  /// When writing: increment to overwrite existing record with same sdkRecordId
  ///               for new items don't inform
  final int? sdkRecordVersion;

  /// Source constructor
  /// parameters:
  /// - recordingMethod: How this data was recorded (required for Android)
  /// - device: Device that recorded the data (optional for manual, required for auto/active)
  /// - appRecordUUID: Your app's unique identifier for this record
  /// - sdkRecordId: Health SDK (Health Connect / HealthKit) unique id for this record
  /// - sdkRecordVersion: Health SDK (Health Connect / HealthKit) version number for this record
  const CKSource({
    required this.recordingMethod,
    this.device,
    this.appRecordUUID,
    this.sdkRecordId,
    this.sdkRecordVersion,
  });

  /// Create source for manually entered data
  factory CKSource.manualEntry({
    CKDevice? device,
    String? appRecordUUID,
    String? sdkRecordId,
    int? sdkRecordVersion,
  }) =>
      CKSource(
        recordingMethod: CKRecordingMethod.manualEntry,
        device: device,
        appRecordUUID: appRecordUUID,
        sdkRecordId: sdkRecordId,
        sdkRecordVersion: sdkRecordVersion,
      );

  /// Create source for user-initiated recording (e.g., workout)
  factory CKSource.activelyRecorded({
    required CKDevice device, // Required for Android
    String? appRecordUUID,
    String? sdkRecordId,
    int? sdkRecordVersion,
  }) =>
      CKSource(
        recordingMethod: CKRecordingMethod.activelyRecorded,
        device: device,
        appRecordUUID: appRecordUUID,
        sdkRecordId: sdkRecordId,
        sdkRecordVersion: sdkRecordVersion,
      );

  /// Create source for automatic/passive recording (e.g., step counter)
  factory CKSource.automaticallyRecorded({
    required CKDevice device, // Required for Android
    String? appRecordUUID,
    String? sdkRecordId,
    int? sdkRecordVersion,
  }) =>
      CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        device: device,
        appRecordUUID: appRecordUUID,
        sdkRecordId: sdkRecordId,
        sdkRecordVersion: sdkRecordVersion,
      );
}

/// How the health data was recorded
enum CKRecordingMethod {
  /// User manually entered the data
  manualEntry,

  /// User initiated a recording session (e.g., started workout)
  activelyRecorded,

  /// App automatically/passively recorded (e.g., background steps)
  automaticallyRecorded,

  /// Recording method unknown or legacy data
  unknown;
}
