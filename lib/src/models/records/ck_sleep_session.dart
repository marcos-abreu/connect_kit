import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/records/ck_record.dart';

/// Sleep session record with stages
///
/// **Platform Behavior:**
/// - **Android**: Maps to single `SleepSessionRecord` with embedded stages
/// - **iOS**: Maps to multiple `HKCategorySample` objects (one per stage)
class CKSleepSession extends CKRecord {
  /// Optional title for the sleep session
  final String? title;

  /// Optional notes about the sleep session
  final String? notes;

  /// List of sleep stages during this session
  /// Must be sequential and non-overlapping
  final List<CKSleepStage> stages;

  /// TODO: add documentation
  const CKSleepSession({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    this.title,
    this.notes,
    required this.stages,
  });

  @override
  void validate() {
    super.validate();

    // Validate stages are within session bounds
    for (final stage in stages) {
      if (stage.startTime.isBefore(startTime)) {
        throw ArgumentError(
          'Stage start time ${stage.startTime} is before session start $startTime',
        );
      }
      if (stage.endTime.isAfter(endTime)) {
        throw ArgumentError(
          'Stage end time ${stage.endTime} is after session end $endTime',
        );
      }
    }

    // Validate stages are sequential and non-overlapping
    if (stages.length > 1) {
      final sortedStages = List<CKSleepStage>.from(stages)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      for (int i = 0; i < sortedStages.length - 1; i++) {
        final current = sortedStages[i];
        final next = sortedStages[i + 1];

        if (current.endTime.isAfter(next.startTime)) {
          throw ArgumentError('Overlapping stages detected: '
              'Stage ending at ${current.endTime} overlaps with stage starting at ${next.startTime}');
        }
      }
    }
  }

  // TODO: strange that this doesnn't accept id
  // TODO: strange that this is really similar to the default constructor
  /// Create a simple sleep session with one generic sleep stage
  factory CKSleepSession.simple({
    required DateTime startTime,
    required DateTime endTime,
    Duration? zoneOffset,
    required CKSource source,
    String? title,
    String? notes,
  }) {
    return CKSleepSession(
      startTime: startTime,
      endTime: endTime,
      startZoneOffset: zoneOffset,
      endZoneOffset: zoneOffset,
      source: source,
      title: title,
      notes: notes,
      stages: [
        CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.sleeping,
        ),
      ],
    );
  }

  // TODO: strange that this doesnn't accept id
  // TODO: strange that this is really similar to the default constructor
  /// Create a detailed sleep session with multiple stages
  factory CKSleepSession.detailed({
    required DateTime startTime,
    required DateTime endTime,
    Duration? startZoneOffset,
    Duration? endZoneOffset,
    required List<CKSleepStage> stages,
    required CKSource source,
    String? title,
    String? notes,
  }) {
    return CKSleepSession(
      startTime: startTime,
      endTime: endTime,
      startZoneOffset: startZoneOffset,
      endZoneOffset: endZoneOffset,
      source: source,
      title: title,
      notes: notes,
      stages: stages,
    );
  }
}

/// TODO: add documentation
extension CKSleepSessionAnalysis on CKSleepSession {
  /// Total duration in bed
  Duration get totalDuration => endTime.difference(startTime);

  /// Total time asleep (excludes awake/in-bed stages)
  Duration get totalSleepTime {
    return stages
        .where(
          (s) =>
              s.stage != CKSleepStageType.awake &&
              s.stage != CKSleepStageType.inBed &&
              s.stage != CKSleepStageType.outOfBed,
        )
        .fold(Duration.zero, (sum, stage) => sum + stage.duration);
  }

  /// Time spent in specific stage
  Duration timeInStage(CKSleepStageType stageType) {
    return stages
        .where((s) => s.stage == stageType)
        .fold(Duration.zero, (sum, stage) => sum + stage.duration);
  }

  /// Sleep efficiency (sleep time / time in bed)
  double get sleepEfficiency {
    final total = totalDuration.inMinutes;
    if (total == 0) return 0.0;
    return totalSleepTime.inMinutes / total;
  }

  /// Number of awakenings during sleep
  int get awakenings {
    return stages.where((s) => s.stage == CKSleepStageType.awake).length;
  }
}

/// Individual sleep stage within a session
class CKSleepStage {
  /// Start time of this stage
  final DateTime startTime;

  /// End time of this stage
  final DateTime endTime;

  /// The sleep stage type
  final CKSleepStageType stage;

  /// TODO: add documentation
  const CKSleepStage({
    required this.startTime,
    required this.endTime,
    required this.stage,
  });

  /// Duration of this stage
  Duration get duration => endTime.difference(startTime);
}

/// Sleep stage types unified across platforms
enum CKSleepStageType {
  /// In bed but may not be asleep yet
  /// iOS: inBed (0) | Android: AWAKE_IN_BED (7)
  inBed,

  /// Out of bed during session
  /// iOS: N/A (not available) | Android: OUT_OF_BED (3)
  outOfBed,

  /// Generic sleeping state (legacy/fallback)
  /// iOS: asleep (1) | Android: SLEEPING (2)
  sleeping,

  /// Awake during the sleep session
  /// iOS: awake (2) | Android: AWAKE (1)
  awake,

  /// Light sleep (NREM stages 1-2)
  /// iOS: asleepCore (3) | Android: LIGHT (4)
  light,

  /// Deep sleep (NREM stage 3)
  /// iOS: asleepDeep (4) | Android: DEEP (5)
  deep,

  /// REM sleep (rapid eye movement)
  /// iOS: asleepREM (5) | Android: REM (6)
  rem,

  /// Asleep but stage unknown/unspecified
  /// iOS: asleepUnspecified (6) | Android: UNKNOWN (0)
  unknown;
}
