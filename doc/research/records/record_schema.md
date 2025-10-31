# ConnectKit Record Schema Validation Research

## Document Purpose
This document validates the unified record schema for ConnectKit's write operations, ensuring it can accurately represent health data for both iOS HealthKit and Android Health Connect platforms.

---

## Executive Summary

**Overall Assessment: ✅ SOLID WITH MINOR RECOMMENDATIONS**

The current `CKRecord` schema is well-designed and capable of handling both platforms. Key findings:

- ✅ **Time handling**: Properly accounts for both platforms
- ✅ **Metadata structure**: Correctly unified through `CKSource`
- ✅ **Device information**: Appropriately modeled in `CKDevice`
- ⚠️ **Validation logic**: Needs platform-specific adjustments
- ⚠️ **Timezone handling**: iOS ignores it (documented), but implementation correct

---

## 1. Platform Core Requirements Comparison

### iOS HealthKit - HKSample Structure

**Required Properties:**
```swift
HKSample(
    type: HKSampleType,           // The health data type
    startDate: Date,              // Start time (required)
    endDate: Date,                // End time (required)
    device: HKDevice?,            // Optional but recommended
    metadata: [String: Any]?      // Optional dictionary
)
```

**Key Characteristics:**
- **Timezone**: Implicit (uses device timezone) - no explicit timezone parameter
- **Metadata**: Completely optional, free-form dictionary
- **Device**: Optional but recommended for data provenance
- **Source**: Automatically tracked via bundle ID
- **UUID**: Assigned automatically by HealthKit upon save
- **Immutability**: Samples cannot be updated once saved

**References:**
- [HKSample Documentation](https://developer.apple.com/documentation/healthkit/hksample)
- [HKObject Documentation](https://developer.apple.com/documentation/healthkit/hkobject)
- [Metadata Keys](https://developer.apple.com/documentation/healthkit/samples/metadata_keys)

### Android Health Connect - Record Structure

**Required Properties:**
```kotlin
Record(
    startTime: Instant,                    // Required
    endTime: Instant,                      // Required
    startZoneOffset: ZoneOffset,           // Required*
    endZoneOffset: ZoneOffset,             // Required*
    metadata: Metadata                     // Required (as of SDK 1.1.0-beta)
)
```

**Metadata Required Structure (SDK 1.1.0-beta+):**
```kotlin
Metadata.recordingMethod(
    device: Device?,                       // Required for auto/active recording
    clientRecordId: String?,               // Optional sync ID
    clientRecordVersion: Long              // Optional version for upsert
)
```

**Key Characteristics:**
- **Timezone**: **REQUIRED** - explicit `ZoneOffset` for both start and end
- **Metadata**: **REQUIRED** with one of four recording methods
- **Device**: **REQUIRED** for automatically/actively recorded data
- **Data Origin**: Automatically tracked via package name
- **ID**: System-assigned unique identifier
- **Upsert Support**: Via `clientRecordId` + `clientRecordVersion`

**References:**
- [Write Data Guide](https://developer.android.com/health-and-fitness/guides/health-connect/develop/write-data)
- [Metadata Requirements](https://developer.android.com/health-and-fitness/guides/health-connect/develop/metadata)
- [Data Format](https://developer.android.com/health-and-fitness/guides/health-connect/data-format)

---

## 2. CKRecord Schema Validation

### Current Implementation Analysis

```dart
abstract class CKRecord {
  final String? id;                    // ✅ Maps to UUID (iOS) / ID (Android)
  final DateTime startTime;            // ✅ Required on both
  final DateTime endTime;              // ✅ Required on both
  final Duration startZoneOffset;      // ✅ Android required, iOS ignores
  final Duration endZoneOffset;        // ✅ Android required, iOS ignores
  final CKSource? source;              // ✅ Unifies both platform requirements
  final Map<String, Object>? metadata; // ✅ Additional custom data
}
```

### Validation Results

| Property | iOS HealthKit | Android Health Connect | Status |
|----------|---------------|------------------------|--------|
| **id** | UUID (auto-generated) | ID (auto-generated) | ✅ Correct |
| **startTime** | Required `Date` | Required `Instant` | ✅ Correct |
| **endTime** | Required `Date` | Required `Instant` | ✅ Correct |
| **startZoneOffset** | Not used (implicit) | **Required** `ZoneOffset` | ✅ Correct |
| **endZoneOffset** | Not used (implicit) | **Required** `ZoneOffset` | ✅ Correct |
| **source** | Maps to device + metadata | Maps to metadata.recordingMethod + device | ✅ Correct |
| **metadata** | Optional custom data | Additional to required metadata | ✅ Correct |

---

## 3. CKSource Schema Validation

### Current Implementation

```dart
class CKSource {
  final CKRecordingMethod recordingMethod;  // Android required
  final CKDevice? device;                   // Conditional required
  final String? clientRecordId;             // Android sync/upsert
  final int? clientRecordVersion;           // Android sync/upsert
}
```

### Platform Mapping

**Android Health Connect:**
```kotlin
// CKSource maps to:
Metadata.recordingMethod(
    device: Device(
        manufacturer: source.device?.manufacturer,
        model: source.device?.model,
        type: mapDeviceType(source.device.type)
    ),
    clientRecordId: source.clientRecordId,
    clientRecordVersion: source.clientRecordVersion
)
```

**iOS HealthKit:**
```swift
// CKSource maps to:
HKDevice(
    name: source.device?.model,
    manufacturer: source.device?.manufacturer,
    model: source.device?.model,
    hardwareVersion: source.device?.hardwareVersion,
    softwareVersion: source.device?.softwareVersion
    // recordingMethod: stored in metadata dictionary
    // clientRecordId: stored in metadata dictionary
)
```

### Validation Result: ✅ EXCELLENT

The `CKSource` model elegantly unifies both platforms:
- **Recording method**: Required for Android, stored in metadata for iOS
- **Device info**: Optional for iOS, conditionally required for Android
- **Sync IDs**: Enables Android upsert, can be stored in iOS metadata for app tracking
- **Clean separation**: Platform-specific logic stays in native decoders

---

## 4. CKDevice Schema Validation

### Current Implementation

```dart
class CKDevice {
  final String? manufacturer;
  final String? model;
  final CKDeviceType type;              // Required enum
  final String? hardwareVersion;        // iOS only
  final String? softwareVersion;        // iOS only
}
```

### Platform Mapping

| Property | iOS HealthKit | Android Health Connect | Status |
|----------|---------------|------------------------|--------|
| **manufacturer** | Optional | Optional | ✅ Correct |
| **model** | Optional | Optional | ✅ Correct |
| **type** | No direct equivalent | **Required** enum | ✅ Correct |
| **hardwareVersion** | Optional | Ignored | ✅ Documented |
| **softwareVersion** | Optional | Ignored | ✅ Documented |

### Device Type Mapping

**CKDeviceType → Android Device Types:**
```kotlin
CKDeviceType.phone       → Device.TYPE_PHONE
CKDeviceType.watch       → Device.TYPE_WATCH
CKDeviceType.scale       → Device.TYPE_SCALE
CKDeviceType.ring        → Device.TYPE_RING (extended)
CKDeviceType.chestStrap  → Device.TYPE_CHEST_STRAP (extended)
CKDeviceType.fitnessBand → Device.TYPE_FITNESS_BAND (extended)
CKDeviceType.headMounted → Device.TYPE_HEAD_MOUNTED (extended)
CKDeviceType.unknown     → Device.TYPE_UNKNOWN
```

**Extended Device Types Note:**
Some types require Health Connect feature check:
```kotlin
if (healthConnectClient.features.getFeature(Features.FEATURE_EXTENDED_DEVICE_TYPES)) {
    // Use extended types (ring, chestStrap, etc.)
} else {
    // Fall back to Device.TYPE_UNKNOWN
}
```

### Validation Result: ✅ SOLID

---

## 5. Timezone Handling Deep Dive

### Why Timezones Matter

Health data is **time-and-place sensitive**:
- "I weighed 70kg at 8:00 AM in New York" ≠ "8:00 AM in Tokyo"
- Sleep sessions cross timezone boundaries during travel
- Data interpretation requires knowing WHERE measurement occurred

### Platform Approaches

**iOS HealthKit:**
- Uses **implicit timezone** (device's current timezone)
- No `ZoneOffset` parameter in HK Sample APIs
- Timezone embedded in `Date` object
- **Assumption**: Device timezone = measurement timezone

**Android Health Connect:**
- Uses **explicit timezone** (required `ZoneOffset`)
- Separate `startZoneOffset` and `endZoneOffset`
- Enables accurate cross-timezone tracking
- **Flexibility**: Different offsets for start/end (travel scenarios)

### ConnectKit Implementation

```dart
final Duration startZoneOffset;  // Default: Duration.zero
final Duration endZoneOffset;    // Default: Duration.zero
```

**Auto-calculation from Dart:**
```dart
final now = DateTime.now();
final offset = now.timeZoneOffset; // Duration
// offset.inSeconds gives seconds for ZoneOffset
```

### Validation Result: ✅ CORRECT

- Android: Uses provided offset (required)
- iOS: Ignores offset (uses device timezone)
- **Well-documented** in code comments
- Auto-calculation example provided

---

## 6. Validation Logic Review

### Current Validation

```dart
void validate() {
  if (endTime.isBefore(startTime)) {
    throw ArgumentError('endTime must be >= startTime');
  }

  if (source == null) {
    throw ArgumentError('source with recordingMethod required for Android');
  }
}
```

### Issues Identified

⚠️ **Problem**: Validation is too Android-centric

**Issue 1**: iOS doesn't strictly require source
- iOS can save samples without device or metadata
- Current validation forces source requirement for iOS too

**Issue 2**: Device requirement not validated
- Android requires device for auto/active recording
- No validation for this conditional requirement

### Recommended Fix

```dart
void validate() {
  // Universal validation
  if (endTime.isBefore(startTime)) {
    throw ArgumentError('endTime must be >= startTime');
  }

  // Android-specific validation happens in native layer
  // Dart layer provides basic structure validation only

  // Optional: Warn if source is missing but don't throw
  if (source == null) {
    CKLogger.w(
      'CKRecord',
      'No source provided. Android requires metadata with recording method. '
      'iOS allows but recommends device information.'
    );
  }
}
```

**Rationale:**
- **Dart layer**: Basic structural validation
- **Native layer**: Platform-specific validation
- **Separation of concerns**: Complex platform rules handled natively
- **Flexibility**: Allows platform-specific workflows

---

## 7. CKValue Schema Validation

### Current Implementation

```dart
class CKValue {
  final dynamic value;      // double for quantity, int/String for category
  final String? unit;       // null for categories
}
```

### Platform Mapping

**iOS HealthKit:**
```swift
// Quantity types
HKQuantitySample(
    type: quantityType,
    quantity: HKQuantity(
        unit: HKUnit(from: ckValue.unit),
        doubleValue: ckValue.value
    ),
    ...
)

// Category types
HKCategorySample(
    type: categoryType,
    value: Int(ckValue.value),  // Integer category value
    ...
)
```

**Android Health Connect:**
```kotlin
// Quantity types
StepsRecord(
    count: ckValue.value.toLong(),
    ...
)

WeightRecord(
    weight: Mass.kilograms(ckValue.value.toDouble()),
    ...
)

// No direct "category" concept in Health Connect
// All data is strongly typed
```

### Validation Result: ✅ SOLID

- Unifies quantity and category data
- Platform decoders split into appropriate types
- Unit handling delegated to native (correct approach)

---

## 8. Recommendations

### High Priority

1. **✅ KEEP** current schema - it's well-designed
2. **⚠️ ADJUST** validation logic to be less strict
3. **⚠️ ENHANCE** documentation on platform differences

### Medium Priority

4. **📝 ADD** factory methods for common scenarios:
```dart
factory CKRecord.fromDevice({
  required DateTime time,
  required CKDevice device,
  // ... other params
}) => CKRecord(
  startTime: time,
  endTime: time,
  source: CKSource.automaticallyRecorded(device: device),
  // Auto-calculate timezone
  startZoneOffset: DateTime.now().timeZoneOffset,
);
```

5. **📝 DOCUMENT** extended device type handling for Android

### Low Priority

6. **🔄 CONSIDER** adding convenience getters:
```dart
bool get isInstantaneous => startTime == endTime;
Duration get duration => endTime.difference(startTime);
```

---

## 9. Conclusion

### Schema Quality: ✅ EXCELLENT (9/10)

The `CKRecord` schema successfully unifies iOS HealthKit and Android Health Connect requirements while maintaining clean abstraction.

**Strengths:**
- ✅ Comprehensive coverage of both platforms
- ✅ Clean separation of concerns
- ✅ Well-documented platform differences
- ✅ Flexible enough for future extensions

**Minor Improvements Needed:**
- ⚠️ Validation logic adjustment
- ⚠️ Extended device type feature detection (Android)

**Overall**: The schema is production-ready with minor validation adjustments recommended.

---

## References

### iOS HealthKit
- [HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [HKSample Class](https://developer.apple.com/documentation/healthkit/hksample)
- [WWDC 2020 - Getting Started with HealthKit](https://developer.apple.com/videos/play/wwdc2020/10664/)

### Android Health Connect
- [Health Connect Overview](https://developer.android.com/health-and-fitness/guides/health-connect)
- [Write Data Guide](https://developer.android.com/health-and-fitness/guides/health-connect/develop/write-data)
- [Metadata Requirements](https://developer.android.com/health-and-fitness/guides/health-connect/develop/metadata)
- [Android Developers Blog - SDK Beta](https://android-developers.googleblog.com/2025/03/health-connect-jetpack-sdk-now-in-beta.html)

---

*Research conducted: October 27, 2025*
*Document version: 1.0*
