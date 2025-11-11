# ConnectKit Project Summary

## Project Overview
**ConnectKit** is a cross-platform Flutter plugin that unifies access to health and fitness data from **Apple HealthKit (iOS)** and **Google Health Connect (Android)**. It provides a clean, type-safe Dart API that abstracts platform differences, enabling developers to read, write, and manage health data without dealing with native complexities.

**Key Philosophy:** Never create synthetic data; only write/read what applications explicitly provide. Maintain data fidelity and transparency.

---

## Architecture

### High-Level Pattern
```
Flutter App
    ↓
ConnectKit (Dart Façade)
    ↓
Pigeon (Type-Safe Platform Channel)
    ↓
┌─────────────────┬─────────────────┐
│   iOS (Swift)   │ Android (Kotlin)│
│   HealthKit     │ Health Connect  │
└─────────────────┴─────────────────┘
```

### Dart Layer Architecture
```
lib/
├── src/
│   ├── logging/
│   │   ├── ck_log_level.dart           # Log level definition
│   │   └── ck_logger.dart              # Thin wrapper for structured logging interface
│   ├── mapper/
│   │   ├── request_mappers.dart        # Encode engine for channel data trasnfer
│   │   └── response_mappers.dart       # Decode engine for channel data trasnfer
│   ├── models/
│   │   ├── records/
│   │   │   ├── ck_audiogram.dart       # specialized record (iOS only)
│   │   │   ├── ck_blood_pressure.dart  # specialized record
│   │   │   ├── ck_data_record.dart     # quantity/category/series record
│   │   │   ├── ck_ecg.dart             # specialized record (iOS only)
│   │   │   ├── ck_nutrition.dart       # specialized record
│   │   │   ├── ck_sleep_session.dart   # specialized record
│   │   │   └── ck_workout.dart         # specialized record
│   │   ├── schema/
│   │   │   ├── ck_device.dart          # record - device schema
│   │   │   ├── ck_source.dart          # record - source schema
│   │   │   ├── ck_type.dart            # record - type schema
│   │   │   ├── ck_type.g.dart          # script-generated complement helper for types
│   │   │   ├── ck_units.dart           # record - unit list
│   │   │   └── ck_value.dart           # record - value schema
│   │   ├── ck_access_status.dart       # Check Permission result structure
│   │   ├── ck_access_type.dart         # Generic read/write data access type
│   │   ├── ck_permission_status.dart   # Possible data permission status
│   │   ├── ck_record.dart              # Base record model
│   │   ├── ck_sdk_status.dart          # Possible sdk availability status
│   │   ├── ck_write_result.dart        # Write records result structure
│   │   └── models.dart                 # public models centralized export
│   ├── operations/
│   │   ├── ck_operation_guard.dart     # Thread-safe operation protection
│   │   └── result.dart                 # Type-safe Result<T, E> for API result control
│   ├── pigeon/
│   │   └── connect_kit_messages.g.dart # Pigeon-generated api and utilities
│   ├── services/
│   │   ├── permission_operations.dart  # Permission operations
│   │   └── write_operations.dart       # Write data operations ← Current focus 
│   └── utils/
│       ├── ck_constants.dart           # Shared constants
│       ├── connect_kit_exception.dart  # Plugin exception interface and objects
│       ├── enum_helper.dart            # Enumeration utility helpers
│       └── string_manipulation.dart    # String utility helpers
└── connect_kit.dart                    # Plugin Singleton / Public Api (Main façade) & export
```

### Android Layer Architecture
```
android/src/main/kotlin/dev/luix/connect_kit/
├── logging/
│   ├── CKLogger.kt                     # Debug-only logging
│   └── CKLogLevel.kt                   # Log levels definition
├── mapper/
│   ├── RecordTypeMapper.kt             # String (CKType) → Android Record class mapping
│   ├── RecordMapper.kt                 # Record Map Encode/Decode Orchestrator
│   ├── RecordMapperException.kt        # Structured errors
│   ├── records/
│   │   ├── DataRecordMapper.kt         # Encode/Decode quantity/category/samples records
│   │   ├── WorkoutMapper.kt            # Encode/Decode Exercise sessions
│   │   ├── SleepSessionMapper.kt       # Encode/Decode Sleep Session with stages
│   │   ├── NutritionMapper.kt          # Encode/Decode Nutrition
│   │   └── BloodPressureMapper.kt      # Encode/Decode Systolic/diastolic correlation
│   └── pigeon/
│       └── connect_kit_messages.g.kt   # Pigeon-generated api and utilities
├── services/
│   ├── PermissionService.kt            # Permission CRUD operations
│   └── WriteService.kt                 # Record insertion ← Current focus
├── utils/
│   ├── RecordMapperUtils.kt            # Extraction, validation, conversions
│   └── CKConstants.kt                  # Shared constants
├── ConnectKitPlugin.kt                 # Composition root, lifecycle manager
└── CKHostApi.kt                        # Pigeon API implementation (façade)
```

### iOS Layer Architecture (To Be Implemented)
```
ios/Classes/
├── logging/
│   ├── CKLogger.swift                     # Debug-only logging
│   └── CKLogLevel.swift                   # Log levels definition
├── mapper/
│   ├── RecordTypeMapper.swift             # String (CKType) → Android Record class mapping
│   ├── RecordMapper.swift                 # Record Map Encode/Decode Orchestrator
│   ├── RecordMapperException.swift        # Structured errors
│   ├── records/
│   │   ├── DataRecordMapper.swift         # Encode/Decode quantity/category/samples records
│   │   ├── WorkoutMapper.swift            # Encode/Decode Exercise sessions
│   │   ├── SleepSessionMapper.swift       # Encode/Decode Sleep Session with stages
│   │   ├── NutritionMapper.swift          # Encode/Decode Nutrition
│   │   └── BloodPressureMapper.swift      # Encode/Decode Systolic/diastolic correlation
│   └── pigeon/
│       └── connect_kit_messages.g.swift   # Pigeon-generated api and utilities
├── services/
│   ├── PermissionService.swift            # Permission CRUD operations
│   └── WriteService.swift                 # Record insertion ← Current focus
├── utils/
│   ├── RecordMapperUtils.swift            # Extraction, validation, conversions
│   └── CKConstants.swift                  # Shared constants
├── ConnectKitPlugin.swift                 # Composition root, lifecycle manager
└── CKHostApi.swift                        # Pigeon API implementation (façade)
```

---

## Functional Specifications

### 1. Permission Management (✅ Complete)

#### `isSdkAvailable() → String`
- **Android:** Returns "available", "unavailable", or "updateRequired"
- **iOS:** Always returns "available" (HealthKit is built-in)

#### `requestPermissions({read, write, history, background}) → bool`
- Launches native permission UI
- Validates requested types against SDK/feature availability
- Returns `true` only if **ALL** requested permissions granted
- **Android:** Suspends until user returns from Health Connect UI
- **iOS:** Uses completion handler for HealthKit authorization

#### `checkPermissions({data, history, background}) → AccessStatus`
- Returns granular permission status per type and access level
- **Statuses:** "granted", "denied", "notSupported"
- **iOS-specific:** Also returns "notDetermined" (never asked)

#### `revokePermissions() → bool`
- **Android:** Revokes ALL permissions (no selective revocation)
- **iOS:** Not supported (HealthKit doesn't allow programmatic revocation)

#### `openHealthSettings() → bool`
- Opens native health settings UI
- **Android API 34+:** Direct to app's Health Connect permissions
- **Android API 33-:** General Health Connect settings
- **iOS:** Opens HealthKit in Settings app

---

### 2. Write Operations (🚧 Android Almost Complete, iOS Next)

#### `writeRecords(List<CKRecord>) → List<String>`
- Writes one or more health records
- Returns Health Connect/HealthKit assigned IDs
- Supports 5 record types via specialized mappers

**Supported Record Types:**
1. **Data Records** (quantity/category/samples types)
   - Steps, distance, heart rate, weight, height, etc.
   - 40+ types supported on Android
   - Handles both interval (time range) and instantaneous (point-in-time) records

2. **Workout Records** (exercise sessions)
   - Activity type (70+ types on Android)
   - Optional: title, totalDistance, totalEnergyBurned
   - Associated data: heart rate, distance, energy samples during workout
   - **Correlation:** Time-based only (no synthetic records created)

3. **Sleep Sessions**
   - Title, notes, time range
   - Sleep stages: inBed, asleep, awake, light, deep, REM, outOfBed
   - Stage validation disabled (trusts native SDK validation)

4. **Nutrition Records**
   - Name, meal type (breakfast, lunch, dinner, snack)
   - 30+ nutrient fields: energy, protein, carbs, fat, fiber, vitamins, minerals
   - All fields optional

5. **Blood Pressure Records**
   - Systolic/diastolic values (mmHg)
   - Validation: systolic > diastolic
   - Optional: body position, measurement location

**Upsert Behavior:**
- If `clientRecordId` + `clientRecordVersion` provided:
  - **UPDATE** if same ID exists and new version > existing version
  - **IGNORE** if new version ≤ existing version
  - **INSERT** if ID doesn't exist or different app owns it
- Without `clientRecordId`: Always INSERT as new record

---

### 3. Read Operations (📋 Not Yet Implemented)
- Query by type, time range, pagination
- Aggregate queries (sum, average, min, max)
- Will use same mapper architecture in reverse (Record → Map)

### 4. Delete Operations (📋 Not Yet Implemented)
- Delete by record ID
- Bulk delete by criteria

---

## Data Models

### Core Abstractions

#### **CKType** (Unified Health Data Types)
- 100+ supported types across platforms
- Examples: `steps`, `heartRate`, `bloodPressure.systolic`, `workout`, `sleepSession.deep`
- Platform-specific types marked clearly (e.g., `audiogram` iOS-only)

#### **CKValue** (Quantity with Unit)
- Value (double) + Unit (string)
- Examples: `150 kg`, `5000 steps`, `120 mmHg`
- Unit validation on native side (throws clear errors for invalid units)

#### **CKSource** (Data Provenance)
- Recording method: `manualEntry`, `activelyRecorded`, `automaticallyRecorded`, `unknown`
- Device info (optional): manufacturer, model, type, hardware/software versions
- Client record ID/version for upsert operations
- **Critical:** No custom metadata support (learned limitation from Health Connect)

#### **CKDevice** (Device Types)
- Types: phone, watch, scale, ring, chestStrap, fitnessBand, headMounted, unknown
- iOS-specific: Additional metadata fields (hardware/software versions)
- Android: Ignores hardware/software versions (not supported)

---

## Critical Architecture Decisions & Lessons Learned

### 1. **No Custom Metadata Storage**
**Problem:** Initially designed to store:
- Workout association IDs
- iOS-specific fields in Android (e.g., caffeine in nutrition)
- Custom app metadata

**Reality:** 
- **Android Health Connect:** Metadata is sealed, no custom fields
- **iOS HealthKit:** Limited metadata extensibility

**Solution:** Removed all custom metadata features. Data correlation relies on:
- Time-based queries (startTime/endTime overlap)
- Native platform capabilities only
- Applications responsible for maintaining external correlation databases if needed

### 2. **No Synthetic Records**
**Flutter `health` plugin problem:** Creates fake distance/energy records for workouts to maintain read/write consistency.

**ConnectKit approach:** 
- Only write what application provides
- Associated records written alongside workout (no synthesis)
- Read operations query by time range (natural correlation)
- **Benefit:** No data duplication, no incorrect aggregations

### 3. **Fail-Fast Unit Validation**
**Original approach:** Silent fallbacks (150 pounds → 150 grams)

**Current approach:** Throw exceptions immediately on invalid units
- Prevents data corruption
- Clear error messages listing valid units
- Applications must provide correct units upfront

### 4. **Client-Side Validation Strategy**
**Sleep stages:** Disabled overlap/bounds validation (trusts native SDK)
- **Reason:** Performance vs usability trade-off
- **Decision:** Monitor user feedback, re-enable if native errors are unclear

**Other validations:** Kept essential validations:
- Time order (endTime > startTime)
- Value ranges (e.g., body fat 0-100%, oxygen saturation 0-100%)
- Required field presence

---

## Current Implementation Status

### 🚧 Almost Completed (Android) <- Current Focus
1. **Permission Service** - Full CRUD for permissions
2. **Write Service** - Complete with 5 record type mappers
3. **Record Mapping Architecture** - Strategy pattern with specialized mappers
4. **Unit Conversions** - Mass, Energy, Length, Pressure, Volume, Temperature, Blood Glucose, Power
5. **Error Handling** - Structured exceptions with field-level details
6. **Logging** - Debug-only logging with 5 levels (debug, info, warn, error, fatal)
7. **Metadata Factory Methods** - Using Health Connect's official API
8. CKRecord model and extentials - improviments
9. Complete Android record mappers

### 🚧 **iOS Write Service Implementation**

**Goal:** Mirror Android architecture for iOS using HealthKit APIs

**Tasks:**
1. Create `WriteService.swift`
2. Implement `RecordMapper.swift` orchestrator
3. Create specialized mappers:
   - `DataRecordMapper.swift` (HKQuantitySample, HKCategorySample)
   - `WorkoutMapper.swift` (HKWorkout + associated samples)
   - `SleepSessionMapper.swift` (HKCategorySample with sleep stages)
   - `NutritionMapper.swift` (HKCorrelation for food items)
   - `BloodPressureMapper.swift` (HKCorrelation for systolic/diastolic)
4. Implement `RecordMapperUtils.swift` (extraction, validation, conversions)
5. Handle iOS-specific considerations:
   - HKQuantityType vs HKCategoryType
   - HKCorrelation for multi-value records
   - Permission granularity (HealthKit requires per-type authorization)
   - Metadata handling (HKMetadata dictionary)

**Key Differences iOS vs Android:**
| Aspect | Android Health Connect | iOS HealthKit |
|--------|----------------------|---------------|
| **Record Types** | Sealed classes (StepsRecord, WeightRecord) | HKQuantitySample, HKCategorySample |
| **Metadata** | Sealed properties only | HKMetadata dictionary (allows custom keys) |
| **Correlation** | Separate records (time-based linking) | HKCorrelation (native parent-child) |
| **Permissions** | Batch request | Per-type request |
| **Workout Associated Data** | Separate records | HKWorkout.workoutEvents + associated samples |
| **Units** | Unit classes (Mass.kilograms) | HKUnit (HKUnit.gramUnit()) |

---

## Edge Cases & Known Limitations

### 1. **Workout Associated Records**
- **Android:** Only time-based correlation (no parent-child relationship)
- **iOS:** Can use HKWorkout correlation, but ConnectKit uses time-based for consistency
- **Application responsibility:** Ensure associated record times fall within workout duration

### 2. **Cross-Platform Data Fidelity**
- **iOS → Android:** Loses hardware/software version from device
- **iOS → Android:** Loses custom metadata keys
- **Android → iOS:** No data loss (iOS is superset of Android capabilities)

### 3. **Blood Glucose Units**
- **US:** mg/dL (milligrams per deciliter)
- **International:** mmol/L (millimoles per liter)
- **ConnectKit:** Supports both, validates on write

### 4. **Temperature Units**
- Supports: Celsius, Fahrenheit, Kelvin
- Validates on write (prevents unit confusion)

### 5. **Upsert Behavior Differences**
- **Android:** Last-write-wins with version checking
- **iOS:** HealthKit doesn't have native upsert (simulate with delete + insert)

### 6. **Permission Revocation**
- **Android:** Can revoke all permissions programmatically
- **iOS:** Not supported (user must revoke in Settings)

---

## Testing Strategy

### Unit Tests
- Mapper logic (Dart record → Native record conversion)
- Validation helpers (time order, value ranges)
- Unit conversions (all 8 conversion types)

### Integration Tests
- Permission flows (request → grant → verify)
- Write operations (single record, batch, upsert)
- Error handling (invalid units, missing fields)

### Platform Tests
- Android: Robolectric for PermissionService, WriteService
- iOS: XCTest for service layer

---

## Dependencies

### Dart
- `flutter`: SDK
- `pigeon`: ^22.0.0 (type-safe platform channels)

### Android
- `androidx.health.connect:connect-client`: 1.1.0-alpha07
- Min SDK: API 34 (Android 14)
- Kotlin: 1.9.0

### iOS
- HealthKit framework (iOS 13+)
- Swift: 5.9+

---

## Development Commands

```bash
# Generate Pigeon platform channels
dart run pigeon --input pigeons/connect_kit_messages.dart

# Run Dart tests
flutter test

# Run Android tests
cd android && ./gradlew test

# Run iOS tests
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner
```

---

## Next Steps (Priority Order)

0. **Android WriteService** (Current Sprint)
   - finish implementation

1. **iOS WriteService**
   - Implement RecordMapper orchestrator
   - Create 5 specialized mappers
   - Handle HKQuantityType/HKCategoryType differences
   - Implement unit conversions for HealthKit units

2. **iOS Permission Service** (Dependencies for write testing)
   - Request permissions per type
   - Check authorization status
   - Handle "not determined" state

3. **Read Service** (Dart + Android + iOS)
   - Query by type and time range
   - Pagination support
   - Aggregate queries

4. **Delete Service** (Dart + Android + iOS)
   - Delete by ID
   - Bulk delete

5. **Documentation & Examples**
   - API reference
   - Platform setup guides
   - Example app with common use cases

---

## Contact Points for AI Assistant

**When resuming in new thread, the AI should know:**

1. **Architecture Pattern:** Strategy pattern with specialized mappers, no custom metadata storage
2. **Current Task:** Implementing iOS WriteService mirroring Android implementation
3. **Critical Constraint:** Never create synthetic records, only write what application provides
4. **Unit Validation:** Fail-fast with clear error messages on invalid units
5. **Permission Model:** Android batch requests, iOS per-type requests
6. **Error Handling:** Structured exceptions with field-level details (RecordMapperException pattern)
7. **Logging:** Debug-only with 5 levels, stripped in release builds
8. **Testing:** Unit tests for mappers, integration tests for services

**Key Files to Reference:**
- Android: `WriteService.kt`, `RecordMapper.kt`, `RecordMapperUtils.kt`
- Dart: `write_operations.dart`, `ck_*_record.dart` models
- Architecture decisions: No custom metadata, time-based workout correlation, fail-fast validation

