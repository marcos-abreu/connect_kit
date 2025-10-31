# ConnectKit Sleep Session Record - Cross-Platform Research

## Document Purpose
Comprehensive research on sleep tracking capabilities across iOS HealthKit and Android Health Connect to design a unified `CKSleepSessionRecord` model.

---

## Executive Summary

**Key Findings:**

| Aspect | iOS HealthKit | Android Health Connect |
|--------|---------------|------------------------|
| **Structure** | Category samples per stage | Session with embedded stages |
| **Sleep Stages** | 8 stages (iOS 16+) | 8 stages |
| **Data Model** | Multiple `HKCategorySample` objects | Single `SleepSessionRecord` with `Stage` list |
| **Session Concept** | Implicit (inferred from overlapping samples) | Explicit `SleepSessionRecord` container |
| **Complexity** | Higher (manual aggregation needed) | Lower (built-in session structure) |

**Recommendation**: Create unified `CKSleepSession` model that abstracts both approaches.

---

## 1. iOS HealthKit Sleep Analysis

### Structure Overview

iOS uses `HKCategoryTypeIdentifierSleepAnalysis` with **category samples**, where each sample represents a continuous period in a specific sleep stage.

### Available Sleep Stages (iOS 16+)

```swift
public enum HKCategoryValueSleepAnalysis : Int {
    case inBed = 0          // User in bed, may or may not be asleep
    case asleep = 1         // Generic asleep (legacy, use specific stages)
    case awake = 2          // Awake during sleep session

    // Detailed sleep stages (iOS 16+)
    case asleepCore = 3     // NREM stages 1 & 2 (light sleep)
    case asleepDeep = 4     // NREM stage 3 (deep sleep)
    case asleepREM = 5      // REM sleep (rapid eye movement)

    // Additional states
    case asleepUnspecified = 6  // Asleep but stage unknown
}
```

###

 Historical Context

**Pre-iOS 16** (Legacy values):
- `inBed` (0): User in bed
- `asleep` (1): Generic asleep state
- `awake` (2): Awake

**iOS 16+** (WWDC 2022):
Apple introduced detailed sleep stages matching the American Academy of Sleep Medicine (AASM) scoring model:
- **asleepCore** → AASM stages 1 & 2
- **asleepDeep** → AASM stage 3
- **asleepREM** → REM stage

### Data Structure

**Single Sleep Stage Sample:**
```swift
let sample = HKCategorySample(
    type: HKCategoryType(.sleepAnalysis),
    value: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
    start: startDate,
    end: endDate,
    device: device,
    metadata: metadata
)
```

**Complete Sleep Session:**
A sleep session is represented by **multiple overlapping samples**:
```swift
// 1. Overall in-bed period
HKCategorySample(value: .inBed, start: 22:00, end: 07:00)

// 2. Individual sleep stage samples within the in-bed period
HKCategorySample(value: .awake, start: 22:00, end: 22:15)
HKCategorySample(value: .asleepCore, start: 22:15, end: 23:00)
HKCategorySample(value: .asleepDeep, start: 23:00, end: 01:00)
HKCategorySample(value: .asleepREM, start: 01:00, end: 02:30)
// ... more stages
```

### Querying Sleep Data

```swift
// Query for all sleep stages including unspecified
let predicate = HKQuery.predicateForSamples(
    withStart: startDate,
    end: endDate,
    options: .strictStartDate
)

// iOS 16+ - use .allAsleepValues for all stages
let categorySampleQuery = HKCategorySampleQuery(
    sampleType: .categoryType(forIdentifier: .sleepAnalysis)!,
    predicate: predicate,
    limit: HKObjectQueryNoLimit,
    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
) { query, samples, error in
    // Process samples - each is a continuous period in one stage
}
```

### Key Characteristics

1. **No Built-in Session Object**: Sleep sessions are implicit, inferred from overlapping samples
2. **Multiple Samples Per Night**: Typically 10-20+ category samples for one night's sleep
3. **Aggregation Required**: App must group and calculate totals per stage
4. **Overlap Handling**: In-bed sample overlaps with sleep stage samples
5. **Third-Party Data**: Apps like Oura Ring, AutoSleep can write their own samples

### Gotchas & Challenges

⚠️ **Challenge 1: Session Inference**
- No explicit "sleep session" concept
- Must use heuristics to group samples into sessions
- Common approach: 6pm-6pm window to capture overnight sleep

⚠️ **Challenge 2: Duplicate Data**
- Multiple apps can write sleep data for same period
- Need source filtering to avoid double-counting
- Check `sample.sourceRevision.source.bundleIdentifier`

⚠️ **Challenge 3: Legacy vs New Stages**
- Older devices write only `inBed`, `asleep`, `awake`
- Newer devices write detailed stages
- Must handle mixed data from different sources

⚠️ **Challenge 4: Timezone Handling**
- Sleep crosses midnight boundary
- Must handle inter-day calculations
- Timezone changes during travel complicate aggregation

### References
- [WWDC 2022 - What's New in HealthKit](https://developer.apple.com/videos/play/wwdc2022/10005/)
- [HKCategoryTypeIdentifierSleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifiersleepanalysis)
- [Tutorial: Sleep Analysis](https://www.appcoda.com/sleep-analysis-healthkit/)

---

## 2. Android Health Connect Sleep Sessions

### Structure Overview

Android uses `SleepSessionRecord` - an **explicit session object** containing a list of sleep stages as sub-records.

### Available Sleep Stages

```kotlin
object SleepSessionRecord {
    const val STAGE_TYPE_UNKNOWN = 0        // Unknown/unspecified
    const val STAGE_TYPE_AWAKE = 1          // Awake during session
    const val STAGE_TYPE_SLEEPING = 2       // Generic sleep (legacy)
    const val STAGE_TYPE_OUT_OF_BED = 3     // Not in bed
    const val STAGE_TYPE_LIGHT = 4          // Light sleep
    const val STAGE_TYPE_DEEP = 5           // Deep sleep
    const val STAGE_TYPE_REM = 6            // REM sleep
    const val STAGE_TYPE_AWAKE_IN_BED = 7   // Awake but still in bed
}
```

### Data Structure

**Complete Sleep Session:**
```kotlin
val stages = listOf(
    SleepSessionRecord.Stage(
        startTime = Instant.parse("2024-10-27T22:15:00Z"),
        endTime = Instant.parse("2024-10-27T23:00:00Z"),
        stage = SleepSessionRecord.STAGE_TYPE_LIGHT
    ),
    SleepSessionRecord.Stage(
        startTime = Instant.parse("2024-10-27T23:00:00Z"),
        endTime = Instant.parse("2024-10-28T01:00:00Z"),
        stage = SleepSessionRecord.STAGE_TYPE_DEEP
    ),
    SleepSessionRecord.Stage(
        startTime = Instant.parse("2024-10-28T01:00:00Z"),
        endTime = Instant.parse("2024-10-28T02:30:00Z"),
        stage = SleepSessionRecord.STAGE_TYPE_REM
    ),
    // ... more stages
)

val sleepSession = SleepSessionRecord(
    title = "Night Sleep",
    notes = "Good quality sleep",
    startTime = Instant.parse("2024-10-27T22:00:00Z"),
    endTime = Instant.parse("2024-10-28T07:00:00Z"),
    startZoneOffset = ZoneOffset.ofHours(-7),
    endZoneOffset = ZoneOffset.ofHours(-7),
    stages = stages,
    metadata = Metadata.autoRecorded(
        device = Device(type = Device.TYPE_WATCH)
    )
)
```

### Writing Sleep Data

```kotlin
suspend fun writeSleepSession(healthConnectClient: HealthConnectClient) {
    healthConnectClient.insertRecords(
        listOf(sleepSession)
    )
}
```

### Reading Sleep Data

```kotlin
suspend fun readSleepSessions(
    healthConnectClient: HealthConnectClient,
    startTime: Instant,
    endTime: Instant
): List<SleepSessionRecord> {
    val request = ReadRecordsRequest(
        recordType = SleepSessionRecord::class,
        timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
    )
    val response = healthConnectClient.readRecords(request)

    // Each record contains the full session with stages
    for (sleepRecord in response.records) {
        println("Session: ${sleepRecord.startTime} to ${sleepRecord.endTime}")

        // Access stages
        for (stage in sleepRecord.stages) {
            println("  Stage: ${stage.stage} from ${stage.startTime} to ${stage.endTime}")
        }
    }

    return response.records
}
```

### Key Characteristics

1. **Explicit Session Container**: One `SleepSessionRecord` per sleep session
2. **Embedded Stages**: All stages contained within single record
3. **Built-in Aggregation**: No manual grouping needed
4. **Title & Notes**: Optional descriptive fields
5. **Timezone Aware**: Explicit offsets for start and end

### Stage Rules

⚠️ **Critical Rules for Stage Data:**

1. **Sequential, Non-Overlapping**: Stage times must be sequential with no overlaps
2. **Gaps Allowed**: Stages don't need to be continuous
3. **Within Session Bounds**: All stages must fall within session start/end
4. **No UID**: Stages are sub-records, no separate identifiers

```kotlin
// ✅ VALID: Sequential with gap
Stage(start: 22:00, end: 23:00, stage: LIGHT)
Stage(start: 23:30, end: 01:00, stage: DEEP)  // 30 min gap is OK

// ❌ INVALID: Overlapping
Stage(start: 22:00, end: 23:00, stage: LIGHT)
Stage(start: 22:30, end: 23:30, stage: DEEP)  // Overlaps!

// ❌ INVALID: Outside session bounds
SleepSession(start: 22:00, end: 07:00, stages: [
    Stage(start: 21:00, end: 22:00, ...)  // Before session start!
])
```

### Gotchas & Challenges

⚠️ **Challenge 1: Session Boundaries**
- Must define clear start/end for entire session
- Stages must fit within these bounds
- Pre-sleep "in bed" time should be included in session

⚠️ **Challenge 2: Cross-Day Sessions**
- Sleep often crosses midnight
- Need careful handling of date boundaries
- Timezone changes during travel

⚠️ **Challenge 3: Stage Granularity**
- Apps may provide different levels of detail
- Some may only write `STAGE_TYPE_SLEEPING`
- Others provide detailed REM/Light/Deep breakdown

⚠️ **Challenge 4: Compatibility**
- Older apps may use deprecated `SleepStageRecord` (removed in newer SDK)
- Samsung Health compatibility requires specific stage names

### References
- [Track Sleep Sessions Guide](https://developer.android.com/health-and-fitness/guides/health-connect/develop/sleep-sessions)
- [SleepSessionRecord API](https://developer.android.com/reference/androidx/health/connect/client/records/SleepSessionRecord)
- [Samsung Health Integration](https://developer.samsung.com/health/blog/en/managing-sleep-data-with-samsung-health-and-health-connect)

---

## 3. Platform Comparison & Mapping

### Sleep Stage Mapping

| Stage Meaning | iOS HealthKit | Android Health Connect | ConnectKit Unified |
|---------------|---------------|------------------------|---------------------|
| In bed, may not be asleep | `inBed` (0) | `AWAKE_IN_BED` (7) | `inBed` |
| Out of bed | N/A | `OUT_OF_BED` (3) | `outOfBed` |
| Generic asleep (legacy) | `asleep` (1) | `SLEEPING` (2) | `sleeping` |
| Awake during session | `awake` (2) | `AWAKE` (1) | `awake` |
| Light sleep | `asleepCore` (3) | `LIGHT` (4) | `light` |
| Deep sleep | `asleepDeep` (4) | `DEEP` (5) | `deep` |
| REM sleep | `asleepREM` (5) | `REM` (6) | `rem` |
| Asleep, stage unknown | `asleepUnspecified` (6) | `UNKNOWN` (0) | `unknown` |

### Architectural Differences

| Aspect | iOS HealthKit | Android Health Connect |
|--------|---------------|------------------------|
| **Session Concept** | Implicit (inferred) | Explicit (`SleepSessionRecord`) |
| **Data Structure** | Multiple separate samples | Single record with embedded stages |
| **Querying** | Fetch all samples, filter, group | Direct session query |
| **Aggregation** | Manual (app responsibility) | Built-in (stages within record) |
| **Metadata** | Per-sample | Per-session |
| **Title/Notes** | Via metadata | Built-in properties |

### Unified Model Challenges

**Challenge 1: Session vs Samples**
- Android: One write = one session
- iOS: One write = one stage sample (need multiple writes)

**Challenge 2: Read Operations**
- Android: Returns complete sessions
- iOS: Returns individual samples (need grouping logic)

**Challenge 3: Update/Delete**
- Android: Update entire session
- iOS: Delete individual samples, write new ones

---

## 4. Proposed CKSleepSession Model

### Unified Schema Design

```dart
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

  const CKSleepSession({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    super.metadata,
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
          'Stage start time ${stage.startTime} is before session start $startTime'
        );
      }
      if (stage.endTime.isAfter(endTime)) {
        throw ArgumentError(
          'Stage end time ${stage.endTime} is after session end $endTime'
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
          throw ArgumentError(
            'Overlapping stages detected: '
            'Stage ending at ${current.endTime} overlaps with stage starting at ${next.startTime}'
          );
        }
      }
    }
  }

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'recordType': 'sleepSession',
    if (title != null) 'title': title,
    if (notes != null) 'notes': notes,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'startZoneOffsetSeconds': startZoneOffset.inSeconds,
    'endZoneOffsetSeconds': endZoneOffset.inSeconds,
    'stages': stages.map((s) => s.toMap()).toList(),
    if (source != null) 'source': source!.toMap(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Individual sleep stage within a session
class CKSleepStage {
  /// Start time of this stage
  final DateTime startTime;

  /// End time of this stage
  final DateTime endTime;

  /// The sleep stage type
  final CKSleepStageType stage;

  const CKSleepStage({
    required this.startTime,
    required this.endTime,
    required this.stage,
  });

  /// Duration of this stage
  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toMap() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'stage': stage.name,
  };
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
```

### Factory Constructors

```dart
extension CKSleepSessionFactories on CKSleepSession {
  /// Create a simple sleep session with one generic sleep stage
  factory CKSleepSession.simple({
    required DateTime startTime,
    required DateTime endTime,
    Duration? zoneOffset,
    required CKSource source,
    String? title,
    String? notes,
    Map<String, Object>? metadata,
  }) {
    return CKSleepSession(
      startTime: startTime,
      endTime: endTime,
      startZoneOffset: zoneOffset,
      endZoneOffset: zoneOffset,
      source: source,
      title: title,
      notes: notes,
      metadata: metadata,
      stages: [
        CKSleepStage(
          startTime: startTime,
          endTime: endTime,
          stage: CKSleepStageType.sleeping,
        ),
      ],
    );
  }

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
    Map<String, Object>? metadata,
  }) {
    return CKSleepSession(
      startTime: startTime,
      endTime: endTime,
      startZoneOffset: startZoneOffset,
      endZoneOffset: endZoneOffset,
      source: source,
      title: title,
      notes: notes,
      metadata: metadata,
      stages: stages,
    );
  }
}
```

### Convenience Methods

```dart
extension CKSleepSessionAnalysis on CKSleepSession {
  /// Total duration in bed
  Duration get totalDuration => endTime.difference(startTime);

  /// Total time asleep (excludes awake/in-bed stages)
  Duration get totalSleepTime {
    return stages
      .where((s) => s.stage != CKSleepStageType.awake &&
                    s.stage != CKSleepStageType.inBed &&
                    s.stage != CKSleepStageType.outOfBed)
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
```

---

## 5. Native Implementation Strategy

### Android Decoder (Kotlin)

```kotlin
class SleepRecordDecoder {
    fun decode(map: Map<String, Any>): SleepSessionRecord {
        val title = map["title"] as? String
        val notes = map["notes"] as? String

        val startTime = Instant.parse(map["startTime"] as String)
        val endTime = Instant.parse(map["endTime"] as String)
        val startOffset = ZoneOffset.ofTotalSeconds(map["startZoneOffsetSeconds"] as Int)
        val endOffset = ZoneOffset.ofTotalSeconds(map["endZoneOffsetSeconds"] as Int)

        // Decode stages
        val stagesList = (map["stages"] as List<Map<String, Any>>).map { stageMap ->
            val stageStart = Instant.parse(stageMap["startTime"] as String)
            val stageEnd = Instant.parse(stageMap["endTime"] as String)
            val stageType = mapSleepStage(stageMap["stage"] as String)

            SleepSessionRecord.Stage(
                startTime = stageStart,
                endTime = stageEnd,
                stage = stageType
            )
        }

        val source = map["source"] as? Map<String, Any>
        val metadata = buildMetadata(source)

        return SleepSessionRecord(
            title = title,
            notes = notes,
            startTime = startTime,
            endTime = endTime,
            startZoneOffset = startOffset,
            endZoneOffset = endOffset,
            stages = stagesList,
            metadata = metadata
        )
    }

    private fun mapSleepStage(stageName: String): Int {
        return when (stageName) {
            "inBed" -> SleepSessionRecord.STAGE_TYPE_AWAKE_IN_BED
            "outOfBed" -> SleepSessionRecord.STAGE_TYPE_OUT_OF_BED
            "sleeping" -> SleepSessionRecord.STAGE_TYPE_SLEEPING
            "awake" -> SleepSessionRecord.STAGE_TYPE_AWAKE
            "light" -> SleepSessionRecord.STAGE_TYPE_LIGHT
            "deep" -> SleepSessionRecord.STAGE_TYPE_DEEP
            "rem" -> SleepSessionRecord.STAGE_TYPE_REM
            "unknown" -> SleepSessionRecord.STAGE_TYPE_UNKNOWN
            else -> SleepSessionRecord.STAGE_TYPE_UNKNOWN
        }
    }
}
```

### iOS Decoder (Swift)

```swift
class SleepRecordDecoder {
    func decode(map: [String: Any]) throws -> [HKCategorySample] {
        guard let stagesList = map["stages"] as? [[String: Any]] else {
            throw DecoderError.missingStages
        }

        let source = map["source"] as? [String: Any]
        let device = try? buildDevice(from: source)

        // Build metadata
        var metadata: [String: Any] = [:]
        if let title = map["title"] as? String {
            metadata["title"] = title
        }
        if let notes = map["notes"] as? String {
            metadata["notes"] = notes
        }
        if let customMetadata = map["metadata"] as? [String: Any] {
            metadata.merge(customMetadata) { (_, new) in new }
        }

        let sleepType = HKCategoryType(.sleepAnalysis)

        // Create one HKCategorySample per stage
        var samples: [HKCategorySample] = []

        for stageMap in stagesList {
            guard let stageStart = ISO8601DateFormatter().date(from: stageMap["startTime"] as! String),
                  let stageEnd = ISO8601DateFormatter().date(from: stageMap["endTime"] as! String),
                  let stageName = stageMap["stage"] as? String else {
                continue
            }

            let stageValue = mapSleepStage(stageName)

            let sample = HKCategorySample(
                type: sleepType,
                value: stageValue,
                start: stageStart,
                end: stageEnd,
                device: device,
                metadata: metadata
            )

            samples.append(sample)
        }

        return samples
    }

    private func mapSleepStage(_ stageName: String) -> Int {
        switch stageName {
        case "inBed":
            return HKCategoryValueSleepAnalysis.inBed.rawValue
        case "sleeping":
            return HKCategoryValueSleepAnalysis.asleep.rawValue
        case "awake":
            return HKCategoryValueSleepAnalysis.awake.rawValue
        case "light":
            return HKCategoryValueSleepAnalysis.asleepCore.rawValue
        case "deep":
            return HKCategoryValueSleepAnalysis.asleepDeep.rawValue
        case "rem":
            return HKCategoryValueSleepAnalysis.asleepREM.rawValue
        case "unknown":
            return HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        case "outOfBed":
            // iOS doesn't have "out of bed" - map to awake
            return HKCategoryValueSleepAnalysis.awake.rawValue
        default:
            return HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        }
    }
}
```

---

## 6. Gotchas & Implementation Notes

### Critical Gotcha #1: iOS Session Concept

**Problem**: iOS has no "session" object.

**Solution**:
- **Write**: Create multiple `HKCategorySample` objects (one per stage)
- **Read**: Query category samples, use heuristics to group into sessions
- **Metadata**: Store session-level data (title, notes) in each sample's metadata

**Grouping Heuristic for Reads:**
```swift
// Common approach: Group samples within 4-hour gap
func groupIntoSessions(samples: [HKCategorySample]) -> [[HKCategorySample]] {
    let sorted = samples.sorted { $0.startDate < $1.startDate }
    var sessions: [[HKCategorySample]] = []
    var currentSession: [HKCategorySample] = []

    for sample in sorted {
        if currentSession.isEmpty {
            currentSession.append(sample)
        } else {
            let lastEnd = currentSession.last!.endDate
            let gap = sample.startDate.timeIntervalSince(lastEnd)

            if gap > 4 * 3600 { // 4 hours
                sessions.append(currentSession)
                currentSession = [sample]
            } else {
                currentSession.append(sample)
            }
        }
    }

    if !currentSession.isEmpty {
        sessions.append(currentSession)
    }

    return sessions
}
```

### Critical Gotcha #2: Stage Compatibility

**Problem**: Not all apps provide detailed stages.

**Solution**: Handle gracefully
```dart
// Accept sessions with only generic "sleeping" stage
final simpleSession = CKSleepSession.simple(
  startTime: DateTime(2024, 10, 27, 22, 0),
  endTime: DateTime(2024, 10, 28, 7, 0),
  source: CKSource.manualEntry(),
);

// Also accept detailed stages
final detailedSession = CKSleepSession.detailed(
  startTime: DateTime(2024, 10, 27, 22, 0),
  endTime: DateTime(2024, 10, 28, 7, 0),
  stages: [
    CKSleepStage(start: 22:00, end: 23:00, stage: light),
    CKSleepStage(start: 23:00, end: 01:00, stage: deep),
    // ...
  ],
  source: CKSource.automaticallyRecorded(device: watch),
);
```

### Critical Gotcha #3: Timezone Boundaries

**Problem**: Sleep crosses midnight and timezone boundaries.

**Example Scenario:**
```dart
// Flight from PST to EST during sleep
final session = CKSleepSession(
  startTime: DateTime.utc(2024, 10, 28, 5, 0), // 10pm PST
  endTime: DateTime.utc(2024, 10, 28, 14, 0),  // 10am EST
  startZoneOffset: Duration(hours: -8),        // PST
  endZoneOffset: Duration(hours: -5),          // EST
  // ...
);
```

**Best Practice**: Always use UTC for storage, offsets for display.

### Critical Gotcha #4: Android Stage Ordering

**Problem**: Android validates stage order strictly.

**Solution**: Sort stages before encoding
```kotlin
// In Android decoder, ensure stages are sorted
val sortedStages = stagesList.sortedBy {
    Instant.parse(it["startTime"] as String)
}
```

### Critical Gotcha #5: iOS "outOfBed" Limitation

**Problem**: iOS doesn't have `outOfBed` stage type.

**Solution**: Map to `awake` on iOS
```swift
case "outOfBed":
    return HKCategoryValueSleepAnalysis.awake.rawValue
```

**Documentation**: Clearly document this limitation for users.

---

## 7. Usage Examples

### Example 1: Simple Sleep Session (Manual Entry)

```dart
final session = CKSleepSession.simple(
  startTime: DateTime(2024, 10, 27, 22, 30),
  endTime: DateTime(2024, 10, 28, 6, 45),
  zoneOffset: DateTime.now().timeZoneOffset,
  source: CKSource.manualEntry(),
  title: "Night Sleep",
);

await ConnectKit.instance.writeRecords([session]);
```

### Example 2: Detailed Sleep from Wearable

```dart
final stages = [
  CKSleepStage(
    startTime: DateTime(2024, 10, 27, 22, 30),
    endTime: DateTime(2024, 10, 27, 22, 45),
    stage: CKSleepStageType.inBed,
  ),
  CKSleepStage(
    startTime: DateTime(2024, 10, 27, 22, 45),
    endTime: DateTime(2024, 10, 27, 23, 30),
    stage: CKSleepStageType.light,
  ),
  CKSleepStage(
    startTime: DateTime(2024, 10, 27, 23, 30),
    endTime: DateTime(2024, 10, 28, 1, 0),
    stage: CKSleepStageType.deep,
  ),
  CKSleepStage(
    startTime: DateTime(2024, 10, 28, 1, 0),
    endTime: DateTime(2024, 10, 28, 1, 15),
    stage: CKSleepStageType.awake,
  ),
  CKSleepStage(
    startTime: DateTime(2024, 10, 28, 1, 15),
    endTime: DateTime(2024, 10, 28, 3, 0),
    stage: CKSleepStageType.rem,
  ),
  CKSleepStage(
    startTime: DateTime(2024, 10, 28, 3, 0),
    endTime: DateTime(2024, 10, 28, 5, 30),
    stage: CKSleepStageType.deep,
  ),
  CKSleepStage(
    startTime: DateTime(2024, 10, 28, 5, 30),
    endTime: DateTime(2024, 10, 28, 6, 45),
    stage: CKSleepStageType.light,
  ),
];

final session = CKSleepSession.detailed(
  startTime: DateTime(2024, 10, 27, 22, 30),
  endTime: DateTime(2024, 10, 28, 6, 45),
  startZoneOffset: DateTime.now().timeZoneOffset,
  endZoneOffset: DateTime.now().timeZoneOffset,
  stages: stages,
  source: CKSource.automaticallyRecorded(
    device: CKDevice.watch(manufacturer: "Apple", model: "Watch Series 9"),
  ),
  title: "Night Sleep with Stages",
  notes: "Good quality sleep detected",
);

await ConnectKit.instance.writeRecords([session]);

// Analyze the session
print('Total sleep time: ${session.totalSleepTime}');
print('Sleep efficiency: ${(session.sleepEfficiency * 100).toStringAsFixed(1)}%');
print('Deep sleep: ${session.timeInStage(CKSleepStageType.deep)}');
print('REM sleep: ${session.timeInStage(CKSleepStageType.rem)}');
print('Awakenings: ${session.awakenings}');
```

### Example 3: Nap Session

```dart
final napSession = CKSleepSession.simple(
  startTime: DateTime(2024, 10, 27, 14, 0),
  endTime: DateTime(2024, 10, 27, 14, 30),
  zoneOffset: DateTime.now().timeZoneOffset,
  source: CKSource.manualEntry(),
  title: "Afternoon Nap",
  notes: "Quick power nap",
);

await ConnectKit.instance.writeRecords([napSession]);
```

---

## 8. Recommendations

### High Priority

1. ✅ **IMPLEMENT** `CKSleepSession` model as designed
2. ✅ **ADD** stage validation (sequential, non-overlapping, within bounds)
3. ✅ **INCLUDE** convenience analysis methods
4. ⚠️ **DOCUMENT** iOS-specific session grouping behavior for read operations

### Medium Priority

5. 📝 **ADD** factory for "in bed" session (start earlier than first sleep stage)
6. 📝 **CONSIDER** auto-generating "inBed" stage if not provided
7. 📝 **DOCUMENT** best practices for nap vs overnight sleep

### Low Priority

8. 🔄 **CONSIDER** helper for timezone handling during travel
9. 🔄 **ADD** validation warnings for unusual patterns (e.g., 16+ hour sessions)

---

## 9. Conclusion

### Model Quality: ✅ WELL-DESIGNED

The proposed `CKSleepSession` model successfully bridges the architectural differences between iOS and Android sleep tracking.

**Key Strengths:**
- ✅ Unified API despite different native structures
- ✅ Comprehensive stage coverage
- ✅ Built-in validation
- ✅ Convenience analysis methods
- ✅ Clear platform-specific documentation

**Implementation Strategy:**
- **Dart Layer**: Single unified model with validation
- **Android Layer**: Direct mapping to `SleepSessionRecord`
- **iOS Layer**: Split into multiple `HKCategorySample` objects
- **Read Operations**: Platform-specific aggregation logic

**Overall**: Ready for implementation with clear native decoder requirements.

---

*Research conducted: October 27, 2025*
*Document version: 1.0*
