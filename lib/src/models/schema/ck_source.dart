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
  /// Used for sync and upsert operations (Android only)
  ///
  /// **Android:** Enables upsert - if record with this ID exists and version
  /// is higher, it gets updated; otherwise new record created
  ///
  /// **iOS:** Can be stored in metadata for your own tracking,
  /// but iOS doesn't support upsert natively
  final String? clientRecordId;

  /// Version number for this record (Android only)
  /// Increment to overwrite existing record with same clientRecordId
  ///
  /// **iOS:** Can be stored in metadata for your own tracking, but only
  ///          if it has been written by this plugin
  final int? clientRecordVersion;

  /// TODO: add documentation
  const CKSource({
    required this.recordingMethod,
    this.device,
    this.clientRecordId,
    this.clientRecordVersion,
  });

  /// Create source for manually entered data
  factory CKSource.manualEntry({
    CKDevice? device,
    String? clientRecordId,
    int? clientRecordVersion,
  }) =>
      CKSource(
        recordingMethod: CKRecordingMethod.manualEntry,
        device: device,
        clientRecordId: clientRecordId,
        clientRecordVersion: clientRecordVersion,
      );

  /// Create source for user-initiated recording (e.g., workout)
  factory CKSource.activelyRecorded({
    required CKDevice device, // Required for Android
    String? clientRecordId,
    int? clientRecordVersion,
  }) =>
      CKSource(
        recordingMethod: CKRecordingMethod.activelyRecorded,
        device: device,
        clientRecordId: clientRecordId,
        clientRecordVersion: clientRecordVersion,
      );

  /// Create source for automatic/passive recording (e.g., step counter)
  factory CKSource.automaticallyRecorded({
    required CKDevice device, // Required for Android
    String? clientRecordId,
    int? clientRecordVersion,
  }) =>
      CKSource(
        recordingMethod: CKRecordingMethod.automaticallyRecorded,
        device: device,
        clientRecordId: clientRecordId,
        clientRecordVersion: clientRecordVersion,
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
