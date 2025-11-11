import 'package:connect_kit/src/models/records/ck_record.dart';

/// Audiogram (hearing test) record
///
/// **Platform Support:**
/// - **iOS**: ✅ Supported (`HKAudiogramSample`)
/// - **Android**: ❌ NOT SUPPORTED (Health Connect has no audiogram type)
///
/// **Note for Android**: Calling writeRecords() with CKAudiogram on Android
/// will throw `UnsupportedTypeException`. Read operations will return empty results.
class CKAudiogram extends CKRecord {
  /// List of hearing sensitivity measurements at different frequencies
  final List<CKAudiogramPoint> sensitivityPoints;

  /// TODO: add documentation
  const CKAudiogram({
    super.id,
    required DateTime time,
    Duration? zoneOffset,
    super.source,
    required this.sensitivityPoints,
  }) : super(
          startTime: time,
          endTime: time,
          startZoneOffset: zoneOffset,
          endZoneOffset: zoneOffset,
        );

  @override
  void validate() {
    super.validate();

    if (sensitivityPoints.isEmpty) {
      throw ArgumentError('Audiogram must have at least one sensitivity point');
    }

    // Validate reasonable frequency ranges
    for (final point in sensitivityPoints) {
      if (point.frequency < 125 || point.frequency > 16000) {
        throw ArgumentError(
          'Frequency ${point.frequency} Hz is outside typical range (125-16000 Hz)',
        );
      }
    }
  }

  /// Get all left ear points
  List<CKAudiogramPoint> get leftEarPoints {
    return sensitivityPoints
        .where((p) => p.leftEarSensitivity != null)
        .toList();
  }

  /// Get all right ear points
  List<CKAudiogramPoint> get rightEarPoints {
    return sensitivityPoints
        .where((p) => p.rightEarSensitivity != null)
        .toList();
  }

  /// Get average hearing threshold for left ear
  double? get leftEarAverageThreshold {
    final points = leftEarPoints;
    if (points.isEmpty) return null;

    final sum = points.fold<double>(0, (sum, p) => sum + p.leftEarSensitivity!);
    return sum / points.length;
  }

  /// Get average hearing threshold for right ear
  double? get rightEarAverageThreshold {
    final points = rightEarPoints;
    if (points.isEmpty) return null;

    final sum =
        points.fold<double>(0, (sum, p) => sum + p.rightEarSensitivity!);
    return sum / points.length;
  }
}

/// Single frequency measurement point in an audiogram
class CKAudiogramPoint {
  /// Frequency tested in Hertz (Hz)
  final double frequency;

  /// Left ear sensitivity threshold in decibels Hearing Level (dBHL)
  /// Null if not tested for left ear
  final double? leftEarSensitivity;

  /// Right ear sensitivity threshold in decibels Hearing Level (dBHL)
  /// Null if not tested for right ear
  final double? rightEarSensitivity;

  /// TODO: add documentaiton
  const CKAudiogramPoint({
    required this.frequency,
    this.leftEarSensitivity,
    this.rightEarSensitivity,
  });

  /// Create point for left ear only
  factory CKAudiogramPoint.leftEar({
    required double frequency,
    required double sensitivity,
  }) {
    return CKAudiogramPoint(
      frequency: frequency,
      leftEarSensitivity: sensitivity,
    );
  }

  /// Create point for right ear only
  factory CKAudiogramPoint.rightEar({
    required double frequency,
    required double sensitivity,
  }) {
    return CKAudiogramPoint(
      frequency: frequency,
      rightEarSensitivity: sensitivity,
    );
  }

  /// Create point for both ears
  factory CKAudiogramPoint.bothEars({
    required double frequency,
    required double leftSensitivity,
    required double rightSensitivity,
  }) {
    return CKAudiogramPoint(
      frequency: frequency,
      leftEarSensitivity: leftSensitivity,
      rightEarSensitivity: rightSensitivity,
    );
  }
}

/// Standard audiogram test frequencies
class CKAudiogramFrequencies {
  /// Standard 6-frequency test: 250, 500, 1000, 2000, 4000, 8000 Hz
  static const standard = [250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0];

  /// Extended 9-frequency test
  static const extended = [
    125.0,
    250.0,
    500.0,
    1000.0,
    2000.0,
    3000.0,
    4000.0,
    6000.0,
    8000.0,
  ];

  /// Speech frequencies (most important for understanding speech)
  static const speech = [500.0, 1000.0, 2000.0, 4000.0];
}
