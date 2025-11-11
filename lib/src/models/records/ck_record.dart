import 'package:connect_kit/src/logging/ck_logger.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';

/// Base class for all health records in ConnectKit
abstract class CKRecord {
  /// Unique identifier for this record (null before saving, set by platform)
  final String? id;

  /// Start time of the measurement/activity
  final DateTime startTime;

  /// End time of the measurement/activity
  /// For instantaneous measurements, equals startTime
  final DateTime endTime;

  /// NOTE on timezones:
  /// **Platform usage:**
  /// - Android: Required, used directly in Record (if not provided uses device timezone)
  /// - iOS: Not supported (HealthKit uses device timezone implicitly)

  /// Timezone offset at start time
  final Duration startZoneOffset;

  /// Timezone offset at end time
  /// Usually same as startZoneOffset unless you traveled during the measurement
  final Duration endZoneOffset;

  /// Data source information (recording method, sync IDs, device)
  final CKSource? source;

  /// TODO: add documentation
  const CKRecord({
    this.id,
    required this.startTime,
    required this.endTime,
    Duration? startZoneOffset,
    Duration? endZoneOffset,
    this.source,
  })  : startZoneOffset = startZoneOffset ?? Duration.zero,
        endZoneOffset = endZoneOffset ?? Duration.zero;

  /// Validate record before sending to platform
  void validate() {
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('endTime must be >= startTime');
    }

    // Android-specific validation happens in native layer
    // Dart layer provides basic structure validation only

    // Optional: Warn if source is missing but don't throw
    if (source == null) {
      CKLogger.w(
          'CKRecord',
          'No source provided. Android requires source with recording method. '
              'iOS allows but recommends device information.');
    }
  }

  /// TODO: add documentation
  bool get isInstantaneous => startTime == endTime;

  /// TODO: add documentation
  Duration get duration => endTime.difference(startTime);
}
