# ConnectKit Blood Pressure Record - Cross-Platform Research

## Document Purpose
Comprehensive research on blood pressure tracking capabilities across iOS HealthKit and Android Health Connect to design unified `CKBloodPressure` model.

---

## Executive Summary

**Key Findings:**

| Aspect | iOS HealthKit | Android Health Connect |
|--------|---------------|------------------------|
| **Structure** | Correlation (2 separate samples) | Single InstantaneousRecord |
| **Components** | Systolic + Diastolic (separate) | Systolic + Diastolic (single record) |
| **Complexity** | High (manual correlation creation) | Low (single record with fields) |
| **Permissions** | Separate (systolic & diastolic) | Single (BloodPressureRecord) |

**Recommendation**: Create unified `CKBloodPressure` model that abstracts both approaches.

---

## iOS HealthKit Blood Pressure

### Structure Overview

<cite index="22-1,25-1">iOS uses `HKCorrelationType` for blood pressure, combining systolic and diastolic samples into a single reading</cite>. Each reading consists of:

1. **Systolic Sample**: `HKQuantityType(.bloodPressureSystolic)`
2. **Diastolic Sample**: `HKQuantityType(.bloodPressureDiastolic)`
3. **Correlation Container**: `HKCorrelationType(.bloodPressure)`

### Data Structure

**Creating a Blood Pressure Reading:**
```swift
func saveBloodPressure(systolic: Double, diastolic: Double) {
    // 1. Create unit
    let unit = HKUnit.millimeterOfMercury()
    let date = Date()

    // 2. Create systolic sample
    let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    let systolicQuantity = HKQuantity(unit: unit, doubleValue: systolic)
    let systolicSample = HKQuantitySample(
        type: systolicType,
        quantity: systolicQuantity,
        start: date,
        end: date
    )

    // 3. Create diastolic sample
    let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    let diastolicQuantity = HKQuantity(unit: unit, doubleValue: diastolic)
    let diastolicSample = HKQuantitySample(
        type: diastolicType,
        quantity: diastolicQuantity,
        start: date,
        end: date
    )

    // 4. Create correlation
    let bpType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
    let correlation = HKCorrelation(
        type: bpType,
        start: date,
        end: date,
        objects: Set([systolicSample, diastolicSample])
    )

    // 5. Save to HealthKit
    healthStore.save(correlation) { success, error in
        // Handle completion
    }
}
```

### Reading Blood Pressure Data

```swift
func readBloodPressure() {
    let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    let bpType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!

    let query = HKCorrelationQuery(
        type: bpType,
        predicate: nil,
        samplePredicates: nil
    ) { query, correlations, error in
        for correlation in correlations ?? [] {
            // Extract samples from correlation
            let systolicSample = correlation.objects(for: systolicType).first as? HKQuantitySample
            let diastolicSample = correlation.objects(for: diastolicType).first as? HKQuantitySample

            let systolicValue = systolicSample?.quantity.doubleValue(for: .millimeterOfMercury())
            let diastolicValue = diastolicSample?.quantity.doubleValue(for: .millimeterOfMercury())

            print("\(systolicValue ?? 0) / \(diastolicValue ?? 0) mmHg")
        }
    }

    healthStore.execute(query)
}
```

### Key Characteristics

1. **Two-Step Creation**: Must create individual samples first, then correlate them
2. **Separate Permissions**: Need permission for both `.bloodPressureSystolic` AND `.bloodPressureDiastolic`
3. **Atomic Save**: Correlation saves both samples together
4. **Standard Unit**: Always millimeters of mercury (mmHg)
5. **Instantaneous**: start and end dates are always the same

### Gotchas

⚠️ **Gotcha #1: Permission Requirements**
- Cannot request permission on `.bloodPressure` correlation type
- Must request on `.bloodPressureSystolic` and `.bloodPressureDiastolic` separately

⚠️ **Gotcha #2: Query Complexity**
- Must use `HKCorrelationQuery`, not `HKSampleQuery`
- Must extract individual samples from correlation
- Need to handle optional values carefully

⚠️ **Gotcha #3: Incomplete Data**
- If only systolic or diastolic is missing, can't create correlation
- Must have both values to save

---

## Android Health Connect Blood Pressure

### Structure Overview

Android uses `BloodPressureRecord` - a single instantaneous record with both systolic and diastolic values as fields.

### Data Structure

**Creating a Blood Pressure Reading:**
```kotlin
val bloodPressure = BloodPressureRecord(
    time = Instant.now(),
    zoneOffset = ZoneOffset.systemDefault(),
    systolic = Pressure.millimetersOfMercury(120.0),
    diastolic = Pressure.millimetersOfMercury(80.0),
    bodyPosition = BloodPressureRecord.BODY_POSITION_SITTING,  // Optional
    measurementLocation = BloodPressureRecord.MEASUREMENT_LOCATION_LEFT_WRIST,  // Optional
    metadata = Metadata.autoRecorded(
        device = Device(type = Device.TYPE_UNKNOWN)
    )
)

healthConnectClient.insertRecords(listOf(bloodPressure))
```

### Available Constants

**Body Positions:**
```kotlin
BloodPressureRecord.BODY_POSITION_STANDING_UP
BloodPressureRecord.BODY_POSITION_SITTING_DOWN
BloodPressureRecord.BODY_POSITION_LYING_DOWN
BloodPressureRecord.BODY_POSITION_RECLINING
```

**Measurement Locations:**
```kotlin
BloodPressureRecord.MEASUREMENT_LOCATION_LEFT_WRIST
BloodPressureRecord.MEASUREMENT_LOCATION_RIGHT_WRIST
BloodPressureRecord.MEASUREMENT_LOCATION_LEFT_UPPER_ARM
BloodPressureRecord.MEASUREMENT_LOCATION_RIGHT_UPPER_ARM
```

### Reading Blood Pressure Data

```kotlin
suspend fun readBloodPressure(
    healthConnectClient: HealthConnectClient,
    startTime: Instant,
    endTime: Instant
): List<BloodPressureRecord> {
    val request = ReadRecordsRequest(
        recordType = BloodPressureRecord::class,
        timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
    )

    val response = healthConnectClient.readRecords(request)

    for (record in response.records) {
        val systolic = record.systolic.inMillimetersOfMercury
        val diastolic = record.diastolic.inMillimetersOfMercury
        println("$systolic / $diastolic mmHg at ${record.time}")

        // Optional fields
        record.bodyPosition?.let { println("Position: $it") }
        record.measurementLocation?.let { println("Location: $it") }
    }

    return response.records
}
```

### Key Characteristics

1. **Single Record**: One object contains both values
2. **Single Permission**: Only need `BloodPressureRecord` permission
3. **Strongly Typed**: Uses `Pressure` type with unit safety
4. **Optional Context**: Body position and measurement location
5. **Instantaneous**: Only has `time`, not start/end
6. **Timezone Required**: Explicit `ZoneOffset` required

### Gotchas

⚠️ **Gotcha #1: Optional Context Fields**
- iOS has no equivalent for body position or measurement location
- Must store in metadata if needed on iOS

⚠️ **Gotcha #2: Pressure Type**
- Android uses `Pressure` type, not raw doubles
- Must convert: `Pressure.millimetersOfMercury(value)`

---

## Proposed CKBloodPressure Model

```dart
/// Blood pressure reading (systolic/diastolic)
///
/// **Platform Behavior:**
/// - **Android**: Maps to `BloodPressureRecord`
/// - **iOS**: Maps to `HKCorrelation` containing systolic + diastolic samples
class CKBloodPressure extends CKRecord {
  /// Systolic pressure value (upper number)
  final CKValue systolic;

  /// Diastolic pressure value (lower number)
  final CKValue diastolic;

  /// Body position during measurement (optional)
  /// Android-specific, stored in metadata on iOS
  final CKBodyPosition? bodyPosition;

  /// Measurement location (optional)
  /// Android-specific, stored in metadata on iOS
  final CKMeasurementLocation? measurementLocation;

  const CKBloodPressure({
    super.id,
    required DateTime time,
    Duration? zoneOffset,
    super.source,
    super.metadata,
    required this.systolic,
    required this.diastolic,
    this.bodyPosition,
    this.measurementLocation,
  }) : super(
    startTime: time,
    endTime: time,
    startZoneOffset: zoneOffset,
    endZoneOffset: zoneOffset,
  );

  /// Create blood pressure with values in mmHg
  factory CKBloodPressure.mmHg({
    required double systolic,
    required double diastolic,
    required DateTime time,
    Duration? zoneOffset,
    required CKSource source,
    CKBodyPosition? bodyPosition,
    CKMeasurementLocation? measurementLocation,
    Map<String, Object>? metadata,
  }) {
    return CKBloodPressure(
      time: time,
      zoneOffset: zoneOffset,
      source: source,
      systolic: CKValue.quantity(systolic, 'mmHg'),
      diastolic: CKValue.quantity(diastolic, 'mmHg'),
      bodyPosition: bodyPosition,
      measurementLocation: measurementLocation,
      metadata: metadata,
    );
  }

  @override
  void validate() {
    super.validate();

    // Validate both values are present and use same unit
    if (systolic.unit != diastolic.unit) {
      throw ArgumentError(
        'Systolic and diastolic must use same unit: '
        'systolic=${systolic.unit}, diastolic=${diastolic.unit}'
      );
    }

    // Validate reasonable ranges (optional warning)
    final sysValue = systolic.value as double;
    final diaValue = diastolic.value as double;

    if (sysValue < diaValue) {
      throw ArgumentError(
        'Systolic ($sysValue) cannot be less than diastolic ($diaValue)'
      );
    }
  }

  @override
  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'recordType': 'bloodPressure',
    'systolic': systolic.toMap(),
    'diastolic': diastolic.toMap(),
    'time': startTime.toIso8601String(),
    'zoneOffsetSeconds': startZoneOffset.inSeconds,
    if (bodyPosition != null) 'bodyPosition': bodyPosition!.name,
    if (measurementLocation != null) 'measurementLocation': measurementLocation!.name,
    if (source != null) 'source': source!.toMap(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Body position during blood pressure measurement
enum CKBodyPosition {
  /// Standing upright
  standingUp,

  /// Sitting down
  sittingDown,

  /// Lying down flat
  lyingDown,

  /// Reclining (partially reclined)
  reclining;
}

/// Measurement location for blood pressure
enum CKMeasurementLocation {
  /// Left wrist
  leftWrist,

  /// Right wrist
  rightWrist,

  /// Left upper arm
  leftUpperArm,

  /// Right upper arm
  rightUpperArm;
}
```

## Native Implementation - Blood Pressure

**Android Decoder:**
```kotlin
fun decodeBloodPressure(map: Map<String, Any>): BloodPressureRecord {
    val time = Instant.parse(map["time"] as String)
    val offset = ZoneOffset.ofTotalSeconds(map["zoneOffsetSeconds"] as Int)

    val systolicMap = map["systolic"] as Map<String, Any>
    val diastolicMap = map["diastolic"] as Map<String, Any>

    val systolic = Pressure.millimetersOfMercury(
        (systolicMap["value"] as Number).toDouble()
    )
    val diastolic = Pressure.millimetersOfMercury(
        (diastolicMap["value"] as Number).toDouble()
    )

    val bodyPosition = (map["bodyPosition"] as? String)?.let { mapBodyPosition(it) }
    val measurementLocation = (map["measurementLocation"] as? String)?.let {
        mapMeasurementLocation(it)
    }

    val source = map["source"] as? Map<String, Any>
    val metadata = buildMetadata(source)

    return BloodPressureRecord(
        time = time,
        zoneOffset = offset,
        systolic = systolic,
        diastolic = diastolic,
        bodyPosition = bodyPosition,
        measurementLocation = measurementLocation,
        metadata = metadata
    )
}

private fun mapBodyPosition(position: String): Int {
    return when (position) {
        "standingUp" -> BloodPressureRecord.BODY_POSITION_STANDING_UP
        "sittingDown" -> BloodPressureRecord.BODY_POSITION_SITTING_DOWN
        "lyingDown" -> BloodPressureRecord.BODY_POSITION_LYING_DOWN
        "reclining" -> BloodPressureRecord.BODY_POSITION_RECLINING
        else -> throw IllegalArgumentException("Unknown body position: $position")
    }
}

private fun mapMeasurementLocation(location: String): Int {
    return when (location) {
        "leftWrist" -> BloodPressureRecord.MEASUREMENT_LOCATION_LEFT_WRIST
        "rightWrist" -> BloodPressureRecord.MEASUREMENT_LOCATION_RIGHT_WRIST
        "leftUpperArm" -> BloodPressureRecord.MEASUREMENT_LOCATION_LEFT_UPPER_ARM
        "rightUpperArm" -> BloodPressureRecord.MEASUREMENT_LOCATION_RIGHT_UPPER_ARM
        else -> throw IllegalArgumentException("Unknown measurement location: $location")
    }
}
```

**iOS Decoder:**
```swift
func decodeBloodPressure(map: [String: Any]) throws -> HKCorrelation {
    guard let time = ISO8601DateFormatter().date(from: map["time"] as! String),
          let systolicMap = map["systolic"] as? [String: Any],
          let diastolicMap = map["diastolic"] as? [String: Any] else {
        throw DecoderError.invalidFormat
    }

    let unit = HKUnit.millimeterOfMercury()

    // Create systolic sample
    let systolicValue = (systolicMap["value"] as! NSNumber).doubleValue
    let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
    let systolicQuantity = HKQuantity(unit: unit, doubleValue: systolicValue)
    let systolicSample = HKQuantitySample(
        type: systolicType,
        quantity: systolicQuantity,
        start: time,
        end: time
    )

    // Create diastolic sample
    let diastolicValue = (diastolicMap["value"] as! NSNumber).doubleValue
    let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    let diastolicQuantity = HKQuantity(unit: unit, doubleValue: diastolicValue)
    let diastolicSample = HKQuantitySample(
        type: diastolicType,
        quantity: diastolicQuantity,
        start: time,
        end: time
    )

    // Build metadata (include Android-specific fields)
    var metadata: [String: Any] = [:]
    if let bodyPosition = map["bodyPosition"] as? String {
        metadata["bodyPosition"] = bodyPosition
    }
    if let measurementLocation = map["measurementLocation"] as? String {
        metadata["measurementLocation"] = measurementLocation
    }
    if let customMetadata = map["metadata"] as? [String: Any] {
        metadata.merge(customMetadata) { (_, new) in new }
    }

    let source = map["source"] as? [String: Any]
    let device = try? buildDevice(from: source)

    // Create correlation
    let bpType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
    return HKCorrelation(
        type: bpType,
        start: time,
        end: time,
        objects: Set([systolicSample, diastolicSample]),
        device: device,
        metadata: metadata
    )
}
```

---

## Conclusion

### Blood Pressure Model: ✅ SOLID

The `CKBloodPressure` model successfully unifies iOS correlation-based and Android field-based approaches.

**Key Success Factors:**
- Single unified API for both platforms
- Proper validation (systolic > diastolic)
- Android-specific fields preserved in metadata on iOS
- Clear documentation of platform differences

---

*Research conducted: October 27, 2025*
*Document version: 1.0*
