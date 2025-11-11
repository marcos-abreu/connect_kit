import 'package:connect_kit/src/models/records/ck_data_record.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';

/// Workout/Exercise session record
///
/// Specialized because it has unique properties (activity type, aggregated metrics)
/// that don't fit the standard data record model
class CKWorkout extends CKRecord {
  /// Workout activity type (running, cycling, swimming, etc.)
  final CKWorkoutActivityType activityType;

  /// Optional workout title
  final String? title;

  // TODO: add notes // Android-only property

  // TODO: Add activities or segments (iOS: HKWorkoutActivity / Android: ExerciseSegment)
  // ref: https://developer.android.com/reference/kotlin/androidx/health/connect/client/records/ExerciseSegment?hl=en
  // ref: https://developer.apple.com/documentation/healthkit/hkworkoutactivity

  // TODO: Add routes (iOS: HKWorkoutRoute / Android: ExerciseRoute)

  /// data points recorded during workout session
  /// (heart rate samples, step intervals, etc.)
  final List<CKDataRecord>? duringSession;

  /// TODO: add documentation
  const CKWorkout({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    required this.activityType,
    this.title,
    this.duringSession,
  });
}

/// TODO: add documentation
enum CKWorkoutActivityType {
  /// TODO: add documentation
  running,

  /// TODO: add documentation
  walking,

  /// TODO: add documentation
  cycling,

  /// TODO: add documentation
  swimming,

  /// TODO: add documentation
  yoga,

  /// TODO: add documentation
  hiking,
  // ... many more
}
