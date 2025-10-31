# Write Service Research & Design - ConnectKit Plugin

## Table of Contents
1. [Platform Capabilities Overview](#platform-capabilities-overview)
2. [Update/Upsert Capabilities](#updateupsert-capabilities)
3. [Common Concepts & Key Differences](#common-concepts--key-differences)
4. [Unified Record Structure Design](#unified-record-structure-design)
5. [API Method Signature](#api-method-signature)
6. [Platform-Specific Implementation Strategy](#platform-specific-implementation-strategy)

---

## Platform Capabilities Overview

### iOS HealthKit - Write Capabilities

**Supported Sample Types:**
- `HKQuantitySample` - Numerical measurements (steps, heart rate, weight)
- `HKCategorySample` - Categorical data (sleep analysis, menstrual flow)
- `HKCorrelation` - Related samples grouped together (blood pressure)
- `HKWorkout` - Exercise sessions with optional route data

**Key Features:**
- Samples have `startDate` and `endDate` - instantaneous measurements use same value for both
- Optional metadata dictionary with predefined + custom keys
- Optional device information for data provenance
- Source app automatically tracked by system (bundle ID)
- All samples assigned UUID on save

**Writing Process:**
```swift
let sample = HKQuantitySample(
    type: quantityType,
    quantity: quantity,
    start: startDate,
    end: endDate,
    device: HKDevice.local(), // Optional
    metadata: ["key": "value"] // Optional
)

healthStore.save(sample) { success, error in
    // UUID available in sample.uuid
}
```

**Limitations:**
- Cannot write to characteristic types (dateOfBirth, biologicalSex)
- Cannot write to system-generated types (walkingHeartRateAverage)
- Cannot write to clinical records
- Correlation types require creating component samples

---

### Android Health Connect - Write Capabilities

**Supported Record Types:**
- All `Record` subclasses (Steps, HeartRate, Weight, Sleep, etc.)
- Exercise sessions with records that happened during session
- Nutrition records with detailed macros
- Vital signs (blood pressure, temperature, glucose)

**Key Features:**
- Metadata REQUIRED (as of SDK 1.1.0-beta) with recording method
- Automatic dataOrigin tracking (package name)
- Device information required for auto/actively recorded data
- Supports clientRecordId + clientRecordVersion for upsert
- All records require timezone offset information
- System assigns unique `id` on insert

**Writing Process:**
```kotlin
val record = StepsRecord(
    count = 120,
    startTime = startTime,
    endTime = endTime,
    startZoneOffset = ZoneOffset.UTC,
    endZoneOffset = ZoneOffset.UTC,
    metadata = Metadata.autoRecorded(
        device = Device(type = Device.TYPE_WATCH),
        clientRecordId = "optional-sync-id",
        clientRecordVersion = 1L
    )
)

healthConnectClient.insertRecords(listOf(record))
```

**Limitations:**
- No characteristic-type data (outside Health Connect)
- No clinical records (future feature)
- Requires explicit timezone information

---

## Update/Upsert Capabilities

### Android Health Connect - Full Upsert Support ✅

**Two Update Methods:**

1. **`updateRecords()` - Update by System ID**
   - Requires the Health Connect-assigned `id` from metadata
   - Updates existing record in place
   - Must provide complete updated record

2. **`insertRecords()` with clientRecordId - Upsert**
   - If data exists based on clientRecordId and clientRecordVersion is higher, it gets overwritten; otherwise written as new data
   - Recommended approach for sync scenarios
   - Automatic upsert behavior

**Example:**
```kotlin
// Upsert approach (recommended for sync)
val record = StepsRecord(
    count = 1000,
    startTime = startTime,
    endTime = endTime,
    startZoneOffset = ZoneOffset.UTC,
    endZoneOffset = ZoneOffset.UTC,
    metadata = Metadata.autoRecorded(
        device = Device(type = Device.TYPE_WATCH),
        clientRecordId = "steps-2024-01-15-morning", // Your sync ID
        clientRecordVersion = 2L // Increment to overwrite
    )
)

// If clientRecordId exists with lower version: UPDATES
// If clientRecordId doesn't exist: CREATES NEW
healthConnectClient.insertRecords(listOf(record))
```

### iOS HealthKit - No Update Support ❌

**Key Constraint:**
Samples in HealthKit are immutable. To modify a sample that was previously saved, your app should save a new sample with updated values and delete the old one

**Workaround Pattern:**
```swift
// 1. Query for existing sample by UUID
let query = HKSampleQuery(/*... predicate with UUID ...*/)

// 2. Delete old sample
healthStore.delete(oldSample) { success, error in
    // 3. Save new sample with updated data
    let newSample = HKQuantitySample(/* updated values */)
    healthStore.save(newSample) { success, error in
        // New UUID assigned
    }
}
```

**Implications:**
- Cannot preserve UUID across updates
- Cannot use clientRecordId for upsert
- Apps must track their own sync IDs in metadata if needed
- Delete + Save not atomic (can fail midway)

---

## Common Concepts & Key Differences

### Time Handling

| Aspect | iOS HealthKit | Android Health Connect |
|--------|---------------|------------------------|
| **Time Properties** | `startDate`, `endDate` (Date) | `startTime`, `endTime` (Instant) |
| **Timezone** | Implicit (device timezone) | Explicit (`ZoneOffset` required) |
| **Instantaneous** | startDate == endDate | Single `time` property |
| **Travel Scenarios** | Not supported | Different start/end offsets |

**Understanding Zone Offset (Android):**

A zone offset is the time difference between your local time and UTC (Coordinated Universal Time).

**Examples:**
- New York (EST): UTC-5:00 → `ZoneOffset.ofHours(-5)`
- London (GMT): UTC+0:00 → `ZoneOffset.UTC`
- Tokyo (JST): UTC+9:00 → `ZoneOffset.ofHours(9)`
- Los Angeles (PST): UTC-8:00 → `ZoneOffset.ofHours(-8)`

**Why it matters:**
- Health data timestamp = **absolute moment** + **where you were**
- Example: "I weighed 70kg at 8:00 AM in New York" vs "8:00 AM in Tokyo" are different times
- Enables accurate data interpretation across time zones

**Can we calculate it automatically?**
Yes! From Dart:
```dart
// Get device's current zone offset
final now = DateTime.now();
final offset = now.timeZoneOffset; // Duration
// offset.inSeconds gives you the offset for ZoneOffset
```

However, for historical data or data from other devices, you may need the offset from that specific time/place.

---

### Metadata Requirements

**iOS:**
- Metadata completely optional
- Free-form dictionary: `[String: Any]`
- No structured requirements

**Android:**
- Metadata REQUIRED (SDK 1.1.0-beta+)
- Must specify one of four recording methods:
  - `RECORDING_METHOD_MANUAL_ENTRY` - User typed it in
  - `RECORDING_METHOD_ACTIVELY_RECORDED` - User started a session (workout)
  - `RECORDING_METHOD_AUTOMATICALLY_RECORDED` - Background/passive (step counter)
  - `RECORDING_METHOD_UNKNOWN` - Legacy/uncertain
- Device REQUIRED for auto/actively recorded data

---

### Device Information

**iOS - Optional but Recommended:**
```swift
HKDevice(
    name: "Apple Watch",
    manufacturer: "Apple",
    model: "Watch6,1",
    hardwareVersion: "1.0",
    firmwareVersion: "8.0",
    softwareVersion: "8.0",
    localIdentifier: "UUID",
    udiDeviceIdentifier: nil
)
```

**Android - Required for Device/Sensor Data:**
```kotlin
Device(
    manufacturer: "Google",
    model: "Pixel Watch",
    type: Device.TYPE_WATCH // Required enum
)
```

---

## Unified Record Structure Design

### Base CKRecord Class

```dart
/// Base class for all health records in ConnectKit
abstract class CKRecord {
  /// Unique identifier for this record (null before saving, set by platform)
  final String? id;

  /// Start time of the measurement/activity
  final DateTime startTime;

  /// End time of the measurement/activity
  /// For instantaneous measurements, equals startTime
  final DateTime endTime;

  /// Timezone offset at start time
  ///
  /// **What is zone offset?**
  /// The time difference between your local time and UTC.
  /// Examples:
  /// - New York (EST): -5 hours → Duration(hours: -5)
  /// - London (GMT): 0 hours → Duration.zero
  /// - Tokyo (JST): +9 hours → Duration(hours: 9)
  ///
  /// **Why it matters:**
  /// Health data needs to know WHEN and WHERE you were.
  /// "8 AM in New York" is different from "8 AM in Tokyo".
  ///
  /// **Can it be calculated automatically?** Yes!
  ///
  /// final offset = DateTime.now().timeZoneOffset;
  ///
  ///
  /// **Platform usage:**
  /// - Android: Required, used directly in Record
  /// - iOS: Ignored (HealthKit uses device timezone implicitly)
  final Duration startZoneOffset;

  /// Timezone offset at end time
  /// Usually same as startZoneOffset unless you traveled during the measurement
  final Duration endZoneOffset;

  /// Data source information (recording method, sync IDs, device)
  final CKSource? source;

  /// Custom metadata key-value pairs
  /// Platform-agnostic additional information
  final Map<String, dynamic>? metadata;

  const CKRecord({
    this.id,
    required this.startTime,
    required this.endTime,
    Duration? startZoneOffset,
    Duration? endZoneOffset,
    this.source,
    this.metadata,
  }) :
    startZoneOffset = startZoneOffset ?? Duration.zero,
    endZoneOffset = endZoneOffset ?? Duration.zero;

  /// Validate record before sending to platform
  void validate() {
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('endTime must be >= startTime');
    }

    // Android requires source with recording method
    if (source == null || source!.recordingMethod == null) {
      throw ArgumentError(
        'source with recordingMethod required for Android. '
        'Use CKSource with appropriate CKRecordingMethod.'
      );
    }
  }

  /// Convert to map for platform channel (implemented by subclasses)
  /// Note: Platform will decode this, not Dart
  Map<String, dynamic> toMap();
}
```

### CKSource - Source & Sync Information

```dart
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
  final int? clientRecordVersion;

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
  }) => CKSource(
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
  }) => CKSource(
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
  }) => CKSource(
    recordingMethod: CKRecordingMethod.automaticallyRecorded,
    device: device,
    clientRecordId: clientRecordId,
    clientRecordVersion: clientRecordVersion,
  );

  Map<String, dynamic> toMap() => {
    'recordingMethod': recordingMethod.name,
    if (device != null) 'device': device!.toMap(),
    if (clientRecordId != null) 'clientRecordId': clientRecordId,
    if (clientRecordVersion != null) 'clientRecordVersion': clientRecordVersion,
  };
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
```

### CKDevice - Device Information

```dart
/// Device information for data provenance
class CKDevice {
  /// Device manufacturer (e.g., "Apple", "Google", "Fitbit")
  final String? manufacturer;

  /// Device model (e.g., "iPhone 14 Pro", "Pixel Watch")
  final String? model;

  /// Device type category
  final CKDeviceType type;

  /// Hardware version (iOS only - ignored on Android)
  final String? hardwareVersion;

  /// Software/firmware version (iOS only - ignored on Android)
  final String? softwareVersion;

  const CKDevice({
    this.manufacturer,
    this.model,
    required this.type,
    this.hardwareVersion,
    this.softwareVersion,
  });

  /// Create device representing current phone
  factory CKDevice.phone({
    String? manufacturer,
    String? model,
  }) => CKDevice(
    manufacturer: manufacturer,
    model: model,
    type: CKDeviceType.phone,
  );

  /// Create device representing a wearable
  factory CKDevice.watch({
    String? manufacturer,
    String? model,
  }) => CKDevice(
    manufacturer: manufacturer,
    model: model,
    type: CKDeviceType.watch,
  );

  /// Create device representing a scale
  factory CKDevice.scale({
    String? manufacturer,
    String? model,
  }) => CKDevice(
    manufacturer: manufacturer,
    model: model,
    type: CKDeviceType.scale,
  );

  Map<String, dynamic> toMap() => {
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (model != null) 'model': model,
    'type': type.name,
    if (hardwareVersion != null) 'hardwareVersion': hardwareVersion,
    if (softwareVersion != null) 'softwareVersion': softwareVersion,
  };
}

/// Device type categories
enum CKDeviceType {
  unknown,
  phone,
  watch,
  scale,
  ring,
  chestStrap,
  fitnessBand,
  headMounted,
}
```

### Unified Data Record (Replaces Quantity + Category)

```dart
/// Universal health data record with type, value, and unit
///
/// Handles both quantity data (steps, weight, heart rate) and
/// category data (sleep stage, menstrual flow) in a unified model.
///
/// **Design Philosophy:**
/// - Dart: Single unified model (simpler API)
/// - Native: Split to HKQuantitySample/HKCategorySample (iOS) or
///           appropriate Record class (Android) during encoding
class CKDataRecord extends CKRecord {
  /// Health data type identifier (e.g., "steps", "weight", "sleepAnalysis")
  final String type;

  /// The measurement or category value
  final CKValue value;

  const CKDataRecord({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    super.metadata,
    required this.type,
    required this.value,
  });

  /// Create instantaneous data record (weight, heart rate snapshot)
  factory CKDataRecord.instantaneous({
    required String type,
    required CKValue value,
    required DateTime time,
    Duration? zoneOffset,
    required CKSource source,
    Map<String, dynamic>? metadata,
  }) => CKDataRecord(
    type: type,
    value: value,
    startTime: time,
    endTime: time,
    startZoneOffset: zoneOffset,
    endZoneOffset: zoneOffset,
    source: source,
    metadata: metadata,
  );

  /// Create interval data record (steps over 15 minutes)
  factory CKDataRecord.interval({
    required String type,
    required CKValue value,
    required DateTime startTime,
    required DateTime endTime,
    Duration? startZoneOffset,
    Duration? endZoneOffset,
    required CKSource source,
    Map<String, dynamic>? metadata,
  }) => CKDataRecord(
    type: type,
    value: value,
    startTime: startTime,
    endTime: endTime,
    startZoneOffset: startZoneOffset,
    endZoneOffset: endZoneOffset,
    source: source,
    metadata: metadata,
  );

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'recordType': 'data', // Discriminator for native decoder
    'type': type,
    'value': value.toMap(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'startZoneOffsetSeconds': startZoneOffset.inSeconds,
    'endZoneOffsetSeconds': endZoneOffset.inSeconds,
    if (source != null) 'source': source!.toMap(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Value with optional unit
///
/// Unifies numerical values (with units) and categorical values (no units)
class CKValue {
  /// The numeric or categorical value
  final dynamic value; // double for quantity, int/String for category

  /// Unit of measurement (null for categories)
  final String? unit;

  const CKValue(this.value, [this.unit]);

  /// Create quantity value (e.g., 70.5 kg, 150 bpm)
  factory CKValue.quantity(double value, String unit) => CKValue(value, unit);

  /// Create category value (e.g., sleep stage = "deep", menstrual flow = 2)
  factory CKValue.category(dynamic value) => CKValue(value, null);

  bool get isQuantity => unit != null;
  bool get isCategory => unit == null;

  Map<String, dynamic> toMap() => {
    'value': value,
    if (unit != null) 'unit': unit,
  };
}
```

### Specialized Records (When Truly Different)

```dart
/// Workout/Exercise session record
///
/// Specialized because it has unique properties (activity type, aggregated metrics)
/// that don't fit the standard data record model
class CKWorkoutRecord extends CKRecord {
  /// Workout activity type (running, cycling, swimming, etc.)
  final CKWorkoutActivityType activityType;

  /// Optional workout title
  final String? title;

  /// Total distance covered (if applicable)
  final CKValue? totalDistance;

  /// Total energy burned
  final CKValue? totalEnergyBurned;

  /// Data records recorded during workout session
  /// (heart rate samples, step intervals, etc.)
  final List<CKDataRecord>? duringSession;

  const CKWorkoutRecord({
    super.id,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    super.metadata,
    required this.activityType,
    this.title,
    this.totalDistance,
    this.totalEnergyBurned,
    this.duringSession,
  });

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'recordType': 'workout', // Discriminator
    'activityType': activityType.name,
    if (title != null) 'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'startZoneOffsetSeconds': startZoneOffset.inSeconds,
    'endZoneOffsetSeconds': endZoneOffset.inSeconds,
    if (totalDistance != null) 'totalDistance': totalDistance!.toMap(),
    if (totalEnergyBurned != null) 'totalEnergyBurned': totalEnergyBurned!.toMap(),
    if (source != null) 'source': source!.toMap(),
    if (metadata != null) 'metadata': metadata,
    if (duringSession != null)
      'duringSession': duringSession!.map((r) => r.toMap()).toList(),
  };
}

enum CKWorkoutActivityType {
  running,
  walking,
  cycling,
  swimming,
  yoga,
  hiking,
  // ... many more
}
```

---

## API Method Signature

### Unified writeRecords Method

```dart
/// Writes one or more health records to the native health platform.
///
/// **Platforms:**
/// - iOS: Writes to HealthKit as HKSample instances
/// - Android: Writes to Health Connect as Record instances
///
/// **Single vs Batch:**
/// Pass a list of one record or many. Batching is more efficient for:
/// - Bulk imports
/// - Workout sessions with records that happened during session
/// - Sync operations with multiple records
///
/// **Update Behavior:**
/// - **Android:** Supports upsert via `source.clientRecordId`
///   - If record exists with same ID and higher version: UPDATES
///   - If record doesn't exist: CREATES NEW
/// - **iOS:** No upsert support (samples are immutable)
///   - Always creates NEW record
///   - To "update": Query old sample → Delete → Save new
///
/// **Returns:** List of platform-assigned IDs (UUIDs on iOS, IDs on Android)
///
/// **Throws:**
/// - `PermissionDeniedException`: No write permission for data type(s)
/// - `UnsupportedTypeException`: Data type not supported on platform/OS version
/// - `ValidationException`: Record data invalid
/// - `PlatformException`: Native platform error
///
/// **Example - Single Record:**
///
/// final record = CKDataRecord.instantaneous(
///   type: 'weight',
///   value: CKValue.quantity(70.5, 'kg'),
///   time: DateTime.now(),
///   source: CKSource.manualEntry(
///     device: CKDevice.scale(manufacturer: 'Withings'),
///   ),
/// );
///
/// final ids = await ConnectKit.instance.writeRecords([record]);
/// print('Saved with ID: ${ids.first}');
///
///
/// **Example - Batch with Upsert (Android):**
///
/// final records = [
///   CKDataRecord.interval(
///     type: 'steps',
///     value: CKValue.quantity(1000, 'count'),
///     startTime: start,
///     endTime: end,
///     source: CKSource.automaticallyRecorded(
///       device: CKDevice.watch(),
///       clientRecordId: 'steps-2024-01-15-morning',
///       clientRecordVersion: 1, // Increment to update
///     ),
///   ),
///   // ... more records
/// ];
///
/// final ids = await ConnectKit.instance.writeRecords(records);
/// // Android: May update existing or create new based on clientRecordId
/// // iOS: Always creates new records
///
///
// **Example - Workout with Records that happened during session :**

// final workout = CKWorkoutRecord(
//   activityType: CKWorkoutActivityType.running,
//   startTime: start,
//   endTime: end,
//   totalDistance: CKValue.quantity(5.0, 'km'),
//   totalEnergyBurned: CKValue.quantity(300, 'kcal'),
//   source: CKSource.activelyRecorded(
//     device: CKDevice.watch(),
//   ),
//   duringSession: [
//     CKDataRecord.instantaneous(
//       type: 'heartRate',
//       value: CKValue.quantity(150, 'bpm'),
//       time: midpoint,
//       source: CKSource.activelyRecorded(
//         device: CKDevice.watch(),
//       ),
//     ),
//   ],
// );

// final writeResult = await ConnectKit.instance.writeRecords([workout]);
///
Future<List<String>> writeRecords(List<CKRecord> records) async {
  // Validate all records
  for (final record in records) {
    record.validate();
  }

  // Send to native platform
  // Note: Native side decodes and processes the records
  final result = await _channel.invokeMethod<List>(
    'writeRecords',
    {'records': records.map((r) => r.toMap()).toList()},
  );

  return List<String>.from(result ?? []);
}


**Why Single Method:**
1. **Simpler API** - One method for all scenarios
2. **Batching encouraged** - Performance benefit without extra method
3. **Consistent behavior** - Same flow for 1 or 100 records
4. **Future-proof** - Easy to add parameters without breaking changes

---

## Platform-Specific Implementation Strategy

### Key Principle: Native Decoding

**Dart responsibilities:**
- Define clean, typed record models
- Simple validation (dates, required fields)
- Convert to basic Map structure

**Native responsibilities:**
- Decode map to platform-specific types
- Complex validation (type support, feature availability)
- Handle platform-specific quirks
- Maximum performance for encoding/decoding

### Android Implementation Structure

```kotlin
class WriteService(
    private val healthConnectClient: HealthConnectClient
) {
    private val recordDecoder = RecordDecoder()

    suspend fun writeRecords(recordMaps: List<Map<String, Any>>): List<String> {
        // 1. Decode maps to Health Connect Record objects
        val records = recordMaps.map { map ->
            recordDecoder.decode(map)
        }

        // 2. Insert/upsert to Health Connect
        val response = healthConnectClient.insertRecords(records)

        // 3. Return assigned IDs
        return response.recordIdsList
    }
}

class RecordDecoder {
    fun decode(map: Map<String, Any>): Record {
        val recordType = map["recordType"] as String

        return when (recordType) {
            "data" -> decodeDataRecord(map)
            "workout" -> decodeWorkoutRecord(map)
            else -> throw IllegalArgumentException("Unknown record type: $recordType")
        }
    }

    private fun decodeDataRecord(map: Map<String, Any>): Record {
        val type = map["type"] as String
        val valueMap = map["value"] as Map<String, Any>
        val value = valueMap["value"]
        val unit = valueMap["unit"] as String?

        // Get timestamps
        val startTime = Instant.parse(map["startTime"] as String)
        val endTime = Instant.parse(map["endTime"] as String)
        val startOffset = ZoneOffset.ofTotalSeconds(map["startZoneOffsetSeconds"] as Int)
        val endOffset = ZoneOffset.ofTotalSeconds(map["endZoneOffsetSeconds"] as Int)

        // Decode source
        val source = map["source"] as? Map<String, Any>
        val metadata = buildMetadata(source)

        // Map to appropriate Record type
        return when (type) {
            "steps" -> StepsRecord(
                count = (value as Number).toLong(),
                startTime = startTime,
                endTime = endTime,
                startZoneOffset = startOffset,
                endZoneOffset = endOffset,
                metadata = metadata
            )
            "weight" -> WeightRecord(
                weight = Mass.kilograms((value as Number).toDouble()),
                time = startTime,
                zoneOffset = startOffset,
                metadata = metadata
            )
            // ... more types
            else -> throw IllegalArgumentException("Unsupported type: $type")
        }
    }

    private fun buildMetadata(sourceMap: Map<String, Any>?): Metadata {
        if (sourceMap == null) {
            return Metadata.unknownRecordingMethod()
        }

        val recordingMethod = sourceMap["recordingMethod"] as String
        val clientRecordId = sourceMap["clientRecordId"] as? String
        val clientRecordVersion = (sourceMap["clientRecordVersion"] as? Number)?.toLong() ?: 0L
        val deviceMap = sourceMap["device"] as? Map<String, Any>

        val device = if (deviceMap != null) {
            Device(
                manufacturer = deviceMap["manufacturer"] as? String,
                model = deviceMap["model"] as? String,
                type = parseDeviceType(deviceMap["type"] as String)
            )
        } else null

        return when (recordingMethod) {
            "manualEntry" -> Metadata.manuallyEntered(
                clientRecordId = clientRecordId,
                clientRecordVersion = clientRecordVersion
            )
            "activelyRecorded" -> Metadata.activelyRecorded(
                device = device ?: throw IllegalArgumentException("Device required for activelyRecorded"),
                clientRecordId = clientRecordId,
                clientRecordVersion = clientRecordVersion
            )
            "automaticallyRecorded" -> Metadata.autoRecorded(
                device = device ?: throw IllegalArgumentException("Device required for automaticallyRecorded"),
                clientRecordId = clientRecordId,
                clientRecordVersion = clientRecordVersion
            )
            else -> Metadata.unknownRecordingMethod(
                clientRecordId = clientRecordId,
                clientRecordVersion = clientRecordVersion
            )
        }
    }

    private fun parseDeviceType(typeString: String): Int {
        return when (typeString) {
            "phone" -> Device.TYPE_PHONE
            "watch" -> Device.TYPE_WATCH
            "scale" -> Device.TYPE_SCALE
            "ring" -> Device.TYPE_RING
            "chestStrap" -> Device.TYPE_CHEST_STRAP
            "fitnessBand" -> Device.TYPE_FITNESS_BAND
            "headMounted" -> Device.TYPE_HEAD_MOUNTED
            else -> Device.TYPE_UNKNOWN
        }
    }

    private fun decodeWorkoutRecord(map: Map<String, Any>): ExerciseSessionRecord {
        val activityType = parseWorkoutActivityType(map["activityType"] as String)
        val title = map["title"] as? String

        val startTime = Instant.parse(map["startTime"] as String)
        val endTime = Instant.parse(map["endTime"] as String)
        val startOffset = ZoneOffset.ofTotalSeconds(map["startZoneOffsetSeconds"] as Int)
        val endOffset = ZoneOffset.ofTotalSeconds(map["endZoneOffsetSeconds"] as Int)

        val source = map["source"] as? Map<String, Any>
        val metadata = buildMetadata(source)

        // Optional aggregated metrics
        val totalDistanceMap = map["totalDistance"] as? Map<String, Any>
        val totalDistance = if (totalDistanceMap != null) {
            val value = (totalDistanceMap["value"] as Number).toDouble()
            val unit = totalDistanceMap["unit"] as String
            Length.meters(convertDistanceToMeters(value, unit))
        } else null
        val totalEnergyMap = map["totalEnergyBurned"] as? Map<String, Any>
        val totalEnergy = if (totalEnergyMap != null) {
            val value = (totalEnergyMap["value"] as Number).toDouble()
            val unit = totalEnergyMap["unit"] as String
            Energy.kilocalories(convertEnergyToKcal(value, unit))
        } else null

        return ExerciseSessionRecord(
            exerciseType = activityType,
            title = title,
            startTime = startTime,
            endTime = endTime,
            startZoneOffset = startOffset,
            endZoneOffset = endOffset,
            metadata = metadata
        )
        // Note: duringSession data would be saved separately in Health Connect
    }

    private fun parseWorkoutActivityType(type: String): Int {
        return when (type) {
            "running" -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING
            "walking" -> ExerciseSessionRecord.EXERCISE_TYPE_WALKING
            "cycling" -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING
            "swimming" -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL
            "yoga" -> ExerciseSessionRecord.EXERCISE_TYPE_YOGA
            // ... more mappings
            else -> ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT
        }
    }

    private fun convertDistanceToMeters(value: Double, unit: String): Double {
        return when (unit.lowercase()) {
            "m", "meter", "meters" -> value
            "km", "kilometer", "kilometers" -> value * 1000
            "mi", "mile", "miles" -> value * 1609.34
            "ft", "foot", "feet" -> value * 0.3048
            else -> value // Assume meters as default
        }
    }

    private fun convertEnergyToKcal(value: Double, unit: String): Double {
        return when (unit.lowercase()) {
            "kcal", "kilocalorie", "kilocalories" -> value
            "cal", "calorie", "calories" -> value / 1000
            "kj", "kilojoule", "kilojoules" -> value * 0.239006
            else -> value // Assume kcal as default
        }
    }
}


**Key Android Features:**
1. **RecordDecoder** handles all map → Record conversion
2. **Type mapping** from generic types to specific Record classes
3. **Unit conversion** handled natively for performance
4. **Metadata builder** enforces Android's metadata requirements

5. **Automatic upsert** via clientRecordId + clientRecordVersion

---

### iOS Implementation Structure

```swift
class WriteService {
    private let healthStore: HKHealthStore
    private let recordDecoder = RecordDecoder()
    private static let TAG = "WriteService"

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    /// Writes multiple health records to HealthKit
    func writeRecords(recordMaps: [[String: Any]]) async throws -> [String] {
        var savedIds: [String] = []

        for map in recordMaps {
            // 1. Decode map to HKSample
            let sample = try recordDecoder.decode(map: map)

            // 2. Save to HealthKit
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.save(sample) { success, error in
                    if let error = error {
                        CKLogger.e(
                            tag: WriteService.TAG,
                            message: "Failed to save sample: \(error.localizedDescription)"
                        )
                        continuation.resume(throwing: error)
                    } else {
                        CKLogger.i(
                            tag: WriteService.TAG,
                            message: "Successfully saved sample"
                        )
                        continuation.resume()
                    }
                }
            }

            // 3. Collect UUID
            savedIds.append(sample.uuid.uuidString)
        }

        return savedIds
    }
}

class RecordDecoder {
    func decode(map: [String: Any]) throws -> HKSample {
        guard let recordType = map["recordType"] as? String else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Missing recordType"]
            )
        }

        switch recordType {
        case "data":
            return try decodeDataRecord(map: map)
        case "workout":
            return try decodeWorkoutRecord(map: map)
        default:
            throw NSError(
                domain: "RecordDecoder",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Unknown recordType: \(recordType)"]
            )
        }
    }

    private func decodeDataRecord(map: [String: Any]) throws -> HKSample {
        // Extract common fields
        guard let type = map["type"] as? String,
              let valueMap = map["value"] as? [String: Any],
              let value = valueMap["value"],
              let startTimeString = map["startTime"] as? String,
              let endTimeString = map["endTime"] as? String,
              let startDate = ISO8601DateFormatter().date(from: startTimeString),
              let endDate = ISO8601DateFormatter().date(from: endTimeString) else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Invalid data record format"]
            )
        }

        // Build metadata
        var metadata: [String: Any] = [:]
        if let customMetadata = map["metadata"] as? [String: Any] {
            metadata.merge(customMetadata) { (_, new) in new }
        }

        // Add clientRecordId to metadata if present (for app's own tracking)
        if let sourceMap = map["source"] as? [String: Any],
           let clientRecordId = sourceMap["clientRecordId"] as? String {
            metadata["clientRecordId"] = clientRecordId
        }

        // Build device
        let device = try? buildDevice(from: map["source"] as? [String: Any])

        // Determine if quantity or category based on unit presence
        if let unit = valueMap["unit"] as? String {
            // Quantity sample
            return try createQuantitySample(
                typeString: type,
                value: value,
                unit: unit,
                startDate: startDate,
                endDate: endDate,
                device: device,
                metadata: metadata
            )
        } else {
            // Category sample
            return try createCategorySample(
                typeString: type,
                value: value,
                startDate: startDate,
                endDate: endDate,
                device: device,
                metadata: metadata
            )
        }
    }

    private func createQuantitySample(
        typeString: String,
        value: Any,
        unit: String,
        startDate: Date,
        endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]
    ) throws -> HKQuantitySample {
        // Get quantity type using RecordTypeMapper
        guard let quantityType = RecordTypeMapper.getObjectType(
            recordType: typeString,
            accessType: .write
        ) as? HKQuantityType else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "Invalid quantity type: \(typeString)"]
            )
        }

        // Convert value to double
        let doubleValue: Double
        if let double = value as? Double {
            doubleValue = double
        } else if let int = value as? Int {
            doubleValue = Double(int)
        } else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1005,
                userInfo: [NSLocalizedDescriptionKey: "Invalid numeric value"]
            )
        }

        // Parse unit
        let hkUnit = HKUnit(from: unit)
        let quantity = HKQuantity(unit: hkUnit, doubleValue: doubleValue)

        return HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    private func createCategorySample(
        typeString: String,
        value: Any,
        startDate: Date,
        endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]
    ) throws -> HKCategorySample {
        guard let categoryType = RecordTypeMapper.getObjectType(
            recordType: typeString,
            accessType: .write
        ) as? HKCategoryType else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1006,
                userInfo: [NSLocalizedDescriptionKey: "Invalid category type: \(typeString)"]
            )
        }

        // Convert value to int
        let intValue: Int
        if let int = value as? Int {
            intValue = int
        } else if let string = value as? String, let int = Int(string) {
            intValue = int
        } else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1007,
                userInfo: [NSLocalizedDescriptionKey: "Invalid category value"]
            )
        }

        return HKCategorySample(
            type: categoryType,
            value: intValue,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    private func decodeWorkoutRecord(map: [String: Any]) throws -> HKWorkout {
        guard let activityTypeString = map["activityType"] as? String,
              let activityType = parseWorkoutActivityType(activityTypeString),
              let startTimeString = map["startTime"] as? String,
              let endTimeString = map["endTime"] as? String,
              let startDate = ISO8601DateFormatter().date(from: startTimeString),
              let endDate = ISO8601DateFormatter().date(from: endTimeString) else {
            throw NSError(
                domain: "RecordDecoder",
                code: 1008,
                userInfo: [NSLocalizedDescriptionKey: "Invalid workout format"]
            )
        }

        let duration = endDate.timeIntervalSince(startDate)

        // Optional metrics
        var totalEnergyBurned: HKQuantity? = nil
        if let energyMap = map["totalEnergyBurned"] as? [String: Any],
           let energyValue = energyMap["value"] as? Double,
           let energyUnit = energyMap["unit"] as? String {
            totalEnergyBurned = HKQuantity(
                unit: HKUnit(from: energyUnit),
                doubleValue: energyValue
            )
        }

        var totalDistance: HKQuantity? = nil
        if let distanceMap = map["totalDistance"] as? [String: Any],
           let distanceValue = distanceMap["value"] as? Double,
           let distanceUnit = distanceMap["unit"] as? String {
            totalDistance = HKQuantity(
                unit: HKUnit(from: distanceUnit),
                doubleValue: distanceValue
            )
        }

        // Build metadata
        var metadata: [String: Any] = [:]
        if let customMetadata = map["metadata"] as? [String: Any] {
            metadata.merge(customMetadata) { (_, new) in new }
        }
        if let title = map["title"] as? String {
            metadata[HKMetadataKeyWorkoutBrandName] = title
        }

        // Build device
        let device = try? buildDevice(from: map["source"] as? [String: Any])

        return HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            device: device,
            metadata: metadata
        )
    }

    private func buildDevice(from sourceMap: [String: Any]?) throws -> HKDevice? {
        guard let sourceMap = sourceMap,
              let deviceMap = sourceMap["device"] as? [String: Any] else {
            return nil
        }

        let manufacturer = deviceMap["manufacturer"] as? String
        let model = deviceMap["model"] as? String
        let hardwareVersion = deviceMap["hardwareVersion"] as? String
        let softwareVersion = deviceMap["softwareVersion"] as? String

        return HKDevice(
            name: model,
            manufacturer: manufacturer,
            model: model,
            hardwareVersion: hardwareVersion,
            firmwareVersion: nil,
            softwareVersion: softwareVersion,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    private func parseWorkoutActivityType(_ type: String) -> HKWorkoutActivityType? {
        switch type {
        case "running": return .running
        case "walking": return .walking
        case "cycling": return .cycling
        case "swimming": return .swimming
        case "yoga": return .yoga
        case "hiking": return .hiking
        // ... more mappings
        default: return .other
        }
    }
}
```

**Key iOS Features:**
1. **RecordDecoder** handles all map → HKSample conversion
2. **Automatic quantity vs category detection** based on unit presence
3. **Metadata preservation** including clientRecordId for app tracking
4. **Device information** optional but recommended
5. **UUID returned** for each saved sample

---

### Host API Implementation (Android)

```kotlin
// In ConnectKitHostApiImpl.kt
override fun writeRecords(
    records: List<Map<String, Any>>,
    callback: (Result<List<String>>) -> Unit
) {
    scope.launch {
        try {
            val ids = writeService.writeRecords(records)
            callback(Result.success(ids))
        } catch (e: Exception) {
            CKLogger.e(
                tag = TAG,
                message = "Failed to write records: ${e.message}",
                error = e
            )
            callback(Result.failure(e))
        }
    }
}
```

### Host API Implementation (iOS)

```swift
// In CKHostApi.swift
func writeRecords(
    records: [[String: Any]],
    completion: @escaping (Result<[String], Error>) -> Void
) {
    Task {
        do {
            let ids = try await writeService.writeRecords(recordMaps: records)
            completion(.success(ids))
        } catch {
            CKLogger.e(
                tag: "CKHostApi",
                message: "Failed to write records: \(error.localizedDescription)",
                error: error
            )
            completion(.failure(error))
        }
    }
}
```

---

## Summary

### Design Decisions

1. **Unified `CKDataRecord`** - Combines quantity + category for simpler Dart API
2. **Native splitting** - Platform decoders split to HKQuantitySample/HKCategorySample as needed
3. **Specialized records** - Only when truly different (Workout, future: ECG, Nutrition)
4. **CKSource model** - Encapsulates recording method, device, sync IDs
5. **CKValue model** - Value + optional unit in single object
6. **Single `writeRecords` method** - Handles 1 or many records
7. **Native decoding** - Heavy processing on native side for performance
8. **Automatic zone offset** - Can be calculated from DateTime, documented for clarity

### Platform Parity

| Feature | Android | iOS | Plugin Behavior |
|---------|---------|-----|-----------------|
| **Write data** | ✅ Full support | ✅ Full support | Both platforms supported |
| **Upsert/Update** | ✅ Via clientRecordId | ❌ Immutable samples | Android: automatic upsert<br>iOS: always creates new |
| **Batch write** | ✅ Native support | ✅ Sequential saves | Both use `writeRecords([])` |
| **Metadata** | ✅ Required | ✅ Optional | Dart requires source, iOS ignores recording method |
| **Device info** | ✅ Conditionally required | ✅ Optional | Both support, Android enforces for auto/active |
| **Timezone** | ✅ Required explicit | ✅ Implicit device | Android uses provided offset, iOS ignores |

### Performance Considerations

1. **Native decoding** - Parsing happens in Kotlin/Swift (faster than Dart)
2. **Batch operations** - Single platform call for multiple records
3. **Type validation** - Happens at native layer using existing mappers
4. **Unit conversion** - Native code for precision and speed

This design provides a **clean, type-safe Dart API** while leveraging **native performance and platform-specific optimizations**! 🎯
