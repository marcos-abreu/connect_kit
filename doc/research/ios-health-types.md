# HealthKit Data Types & Permissions - Complete Reference Guide

## Table of Contents
1. [Overview](#overview)
2. [Data Type Hierarchy](#data-type-hierarchy)
3. [Permission System](#permission-system)
4. [Characteristic Types](#characteristic-types)
5. [Quantity Types](#quantity-types)
6. [Category Types](#category-types)
7. [Correlation Types](#correlation-types)
8. [Clinical & Document Types](#clinical--document-types)
9. [Workout Types](#workout-types)
10. [Permission Patterns & Best Practices](#permission-patterns--best-practices)
11. [Code Examples](#code-examples)

---

## Overview

HealthKit is Apple's centralized repository for health and fitness data, introduced in iOS 8.0. It provides a unified API for apps to read and write health-related information with user permission.

### Key Concepts

- **Available Since:** iOS 8.0
- **Not Available On:** iPad (any iOS version)
- **Permissions:** Fine-grained, per-data-type user control
- **Privacy:** Read permissions cannot be determined (privacy protection)
- **Data Ownership:** Data saved to HealthKit doesn't belong to your app

---

## Data Type Hierarchy

All HealthKit data types inherit from `HKObjectType`:

```
HKObjectType (Abstract Base Class)
├── HKCharacteristicType (Static user characteristics)
├── HKSampleType (Time-based data - Abstract)
│   ├── HKQuantityType (Numerical measurements)
│   ├── HKCategoryType (Categorical data)
│   ├── HKCorrelationType (Complex samples with multiple components)
│   ├── HKWorkoutType (Exercise sessions)
│   ├── HKDocumentType (CDA documents)
│   └── HKClinicalType (Clinical records - iOS 12+)
├── HKActivitySummaryType (Activity rings data - iOS 9.3+)
├── HKAudiogramSampleType (Hearing health - iOS 13+)
└── HKWorkoutRouteType (GPS workout routes - iOS 11+)
```

---

## Permission System

### How Permissions Work

HealthKit uses two types of permissions:
- **Read Permission:** Request to query existing data
- **Write/Share Permission:** Request to save new data

### Critical Permission Rules

1. **Characteristic Types:**
   - ✅ Can request READ permission
   - ❌ CANNOT request WRITE permission (read-only)
   - Users must edit via Health app

2. **Quantity Types:**
   - ✅ Can request READ permission
   - ✅ Can request WRITE permission

3. **Category Types:**
   - ✅ Can request READ permission
   - ✅ Can request WRITE permission

4. **Correlation Types:**
   - ❌ DO NOT request permission for correlation types directly
   - ✅ Request permissions for the individual components instead
   - Example: For blood pressure, request `.bloodPressureSystolic` and `.bloodPressureDiastolic`

5. **Workout Types:**
   - ✅ Can request READ permission
   - ✅ Can request WRITE permission
   - Use `HKObjectType.workoutType()` (no identifier needed)

6. **Clinical Types:**
   - ✅ Can request READ permission
   - ❌ CANNOT request WRITE permission (system-only)

### Permission Request Pattern

```swift
// CORRECT: Request permission for quantity types
let typesToShare: Set<HKSampleType> = [
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .bodyMass)!
]

let typesToRead: Set<HKObjectType> = [
    HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .heartRate)!
]

healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
    (success, error) in
    // Handle result
}
```

```swift
// WRONG: DO NOT request permission for correlation type
let bloodPressure = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)
// This will cause issues!

// CORRECT: Request individual components
let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
```

### Checking Permission Status

**For Write Permission (works):**
```swift
let status = healthStore.authorizationStatus(for: quantityType)
switch status {
case .notDetermined:
    // Permission not yet requested
case .sharingDenied:
    // User explicitly denied write access
case .sharingAuthorized:
    // User granted write access
@unknown default:
    break
}
```

**For Read Permission (doesn't work for privacy):**
- You CANNOT determine if user granted read permission
- If denied, queries return only data your app wrote
- This prevents apps from inferring health conditions

---

## Characteristic Types

Characteristic types represent data that doesn't typically change over time.

### Permission Rules
- ✅ **READ:** Yes - can request
- ❌ **WRITE:** No - read-only (users edit via Health app)

### Available Identifiers

| Identifier | iOS Version | Type | Description |
|------------|-------------|------|-------------|
| `biologicalSex` | 8.0 | Enum | Male, Female, Other, Not Set |
| `bloodType` | 8.0 | Enum | A+, A-, B+, B-, AB+, AB-, O+, O-, Not Set |
| `dateOfBirth` | 8.0 | Date | User's birth date |
| `fitzpatrickSkinType` | 9.0 | Enum | Skin type I-VI (UV sensitivity) |
| `wheelchairUse` | 10.0 | Enum | Yes, No, Not Set |
| `activityMoveMode` | 14.0 | Enum | Active energy or move time |

### Usage Example

```swift
// Request READ permission for characteristics
let readTypes: Set<HKObjectType> = [
    HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
    HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!,
    HKCharacteristicType.characteristicType(forIdentifier: .bloodType)!
]

healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
    // DO NOT add characteristics to toShare - this will cause an error:
    // "Authorization to share the following types is disallowed"
}

// Reading characteristic data (no query needed)
do {
    let biologicalSex = try healthStore.biologicalSex()
    let dateOfBirth = try healthStore.dateOfBirthComponents() // iOS 10+
    let bloodType = try healthStore.bloodType()
} catch {
    // Handle error (Code 5: Authorization not determined)
}
```

### Important Notes
- Cannot create queries for characteristic types
- Access directly via `HKHealthStore` methods
- Must handle authorization errors (don't use `try!`)
- Cannot determine if permission was granted

---

## Quantity Types

Quantity types represent numerical measurements with units.

### Permission Rules
- ✅ **READ:** Yes - can request
- ✅ **WRITE:** Yes - can request

### Categories

#### Body Measurements (iOS 8.0+)
| Identifier | Unit | Discrete/Cumulative | Description |
|------------|------|---------------------|-------------|
| `bodyMassIndex` | Scalar (Count) | Discrete | BMI calculation |
| `bodyFatPercentage` | Scalar (0.0-1.0) | Discrete | Body fat % |
| `height` | Length | Discrete | Body height |
| `bodyMass` | Mass | Discrete | Body weight |
| `leanBodyMass` | Mass | Discrete | Lean body mass |
| `waistCircumference` | Length | Discrete | Waist measurement (iOS 11+) |

#### Fitness (iOS 8.0+)
| Identifier | Unit | Discrete/Cumulative | Description |
|------------|------|---------------------|-------------|
| `stepCount` | Count | Cumulative | Number of steps |
| `distanceWalkingRunning` | Length | Cumulative | Walking/running distance |
| `distanceCycling` | Length | Cumulative | Cycling distance |
| `distanceWheelchair` | Length | Cumulative | Wheelchair distance (iOS 10+) |
| `basalEnergyBurned` | Energy | Cumulative | Resting energy |
| `activeEnergyBurned` | Energy | Cumulative | Active energy burned |
| `flightsClimbed` | Count | Cumulative | Stairs climbed |
| `nikeFuel` | Count | Cumulative | Nike Fuel points |
| `appleExerciseTime` | Time | Cumulative | Exercise minutes |
| `pushCount` | Count | Cumulative | Wheelchair pushes (iOS 10+) |
| `distanceSwimming` | Length | Cumulative | Swimming distance (iOS 10+) |
| `swimmingStrokeCount` | Count | Cumulative | Swim strokes (iOS 10+) |
| `vo2Max` | ml/(kg·min) | Discrete | VO2 max (iOS 11+) |
| `distanceDownhillSnowSports` | Length | Cumulative | Downhill skiing (iOS 11.2+) |

#### Vitals (iOS 8.0+)
| Identifier | Unit | Discrete/Cumulative | Description |
|------------|------|---------------------|-------------|
| `heartRate` | Count/Time | Discrete | Heart rate (bpm) |
| `bodyTemperature` | Temperature | Discrete | Body temperature |
| `basalBodyTemperature` | Temperature | Discrete | Basal temperature (iOS 9+) |
| `bloodPressureSystolic` | Pressure | Discrete | Systolic pressure |
| `bloodPressureDiastolic` | Pressure | Discrete | Diastolic pressure |
| `respiratoryRate` | Count/Time | Discrete | Breaths per minute |
| `restingHeartRate` | Count/Time | Discrete | Resting HR (iOS 11+) |
| `walkingHeartRateAverage` | Count/Time | Discrete | Walking HR (iOS 11+) |
| `heartRateVariabilitySDNN` | Time (ms) | Discrete | HRV (iOS 11+) |
| `oxygenSaturation` | Scalar (0.0-1.0) | Discrete | Blood O2 saturation (iOS 8.0+) |
| `peripheralPerfusionIndex` | Scalar (0.0-1.0) | Discrete | Perfusion index (iOS 8.0+) |
| `bloodGlucose` | Mass/Volume | Discrete | Blood glucose |
| `numberOfTimesFallen` | Count | Cumulative | Fall count (iOS 8.0+) |
| `electrodermalActivity` | Conductance | Discrete | Skin conductance (iOS 8.0+) |
| `inhalerUsage` | Count | Cumulative | Inhaler uses (iOS 8.0+) |
| `insulinDelivery` | Pharmacology | Cumulative | Insulin units (iOS 11+) |
| `bloodAlcoholContent` | Scalar (0.0-1.0) | Discrete | BAC (iOS 8.0+) |
| `forcedVitalCapacity` | Volume | Discrete | Lung capacity (iOS 8.0+) |
| `forcedExpiratoryVolume1` | Volume | Discrete | FEV1 (iOS 8.0+) |
| `peakExpiratoryFlowRate` | Volume/Time | Discrete | Peak flow (iOS 8.0+) |
| `environmentalAudioExposure` | Pressure | Discrete | Audio exposure (iOS 13+) |
| `headphoneAudioExposure` | Pressure | Discrete | Headphone audio (iOS 13+) |

#### Nutrition (iOS 8.0+)
All nutrition types use:
- Mass units (g, mg, mcg)
- Cumulative samples
- Available since iOS 8.0

| Identifier | Description |
|------------|-------------|
| `dietaryFatTotal` | Total fat |
| `dietaryFatPolyunsaturated` | Polyunsaturated fat |
| `dietaryFatMonounsaturated` | Monounsaturated fat |
| `dietaryFatSaturated` | Saturated fat |
| `dietaryCholesterol` | Cholesterol |
| `dietarySodium` | Sodium |
| `dietaryCarbohydrates` | Total carbs |
| `dietaryFiber` | Fiber |
| `dietarySugar` | Sugar |
| `dietaryEnergyConsumed` | Calories consumed |
| `dietaryProtein` | Protein |
| `dietaryVitaminA` | Vitamin A |
| `dietaryVitaminB6` | Vitamin B6 |
| `dietaryVitaminB12` | Vitamin B12 |
| `dietaryVitaminC` | Vitamin C |
| `dietaryVitaminD` | Vitamin D |
| `dietaryVitaminE` | Vitamin E |
| `dietaryVitaminK` | Vitamin K |
| `dietaryCalcium` | Calcium |
| `dietaryIron` | Iron |
| `dietaryThiamin` | Thiamin (B1) |
| `dietaryRiboflavin` | Riboflavin (B2) |
| `dietaryNiacin` | Niacin (B3) |
| `dietaryFolate` | Folate |
| `dietaryBiotin` | Biotin |
| `dietaryPantothenicAcid` | Pantothenic acid |
| `dietaryPhosphorus` | Phosphorus |
| `dietaryIodine` | Iodine |
| `dietaryMagnesium` | Magnesium |
| `dietaryZinc` | Zinc |
| `dietarySelenium` | Selenium |
| `dietaryCopper` | Copper |
| `dietaryManganese` | Manganese |
| `dietaryChromium` | Chromium |
| `dietaryMolybdenum` | Molybdenum |
| `dietaryChloride` | Chloride |
| `dietaryPotassium` | Potassium |
| `dietaryCaffeine` | Caffeine |
| `dietaryWater` | Water intake |

#### UV Exposure (iOS 9.0+)
| Identifier | Unit | Description |
|------------|------|-------------|
| `uvExposure` | Count (0-12) | UV index exposure |

### Usage Example

```swift
// Request permissions for quantity types
let typesToWrite: Set<HKSampleType> = [
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
    HKQuantityType.quantityType(forIdentifier: .heartRate)!
]

let typesToRead: Set<HKObjectType> = [
    HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
    HKQuantityType.quantityType(forIdentifier: .heartRate)!,
    HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
]

healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
    success, error in
    // Permission dialog shown to user
}

// Saving a quantity sample
let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: 1000)
let sample = HKQuantitySample(type: type, quantity: quantity,
                              start: Date(), end: Date())

healthStore.save(sample) { success, error in
    // Check success
}
```

### Important Notes
- **Cumulative vs Discrete:**
  - Cumulative: Values add up over time (steps, distance)
  - Discrete: Snapshot values (height, heart rate)
- For cumulative types, set different start/end dates
- For discrete types, typically use same start/end date
- Always check authorization before saving

---

## Category Types

Category types represent data in predefined categories rather than numerical values.

### Permission Rules
- ✅ **READ:** Yes - can request
- ✅ **WRITE:** Yes - can request

### Available Identifiers

| Identifier | iOS Version | Values | Description |
|------------|-------------|--------|-------------|
| `sleepAnalysis` | 8.0 | InBed, Asleep, Awake, Core, Deep, REM | Sleep stages |
| `appleStandHour` | 9.0 | Stood, Idle | Stand activity |
| `cervicalMucusQuality` | 9.0 | Dry, Sticky, Creamy, Watery, EggWhite | Fertility tracking |
| `ovulationTestResult` | 9.0 | Negative, Positive, Indeterminate | LH surge test |
| `menstrualFlow` | 9.0 | Unspecified, Light, Medium, Heavy, None | Period tracking |
| `intermenstrualBleeding` | 9.0 | NotPresent, Present | Spotting |
| `sexualActivity` | 9.0 | NotPresent, Present | Sexual activity log |
| `mindfulSession` | 10.0 | NotApplicable | Mindfulness minutes |
| `highHeartRateEvent` | 12.2 | NotApplicable | High HR notification |
| `lowHeartRateEvent` | 12.2 | NotApplicable | Low HR notification |
| `irregularHeartRhythmEvent` | 12.2 | NotApplicable | Irregular rhythm |
| `audioExposureEvent` | 13.0 | LoudEnvironment | Loud sound exposure |
| `toothbrushingEvent` | 13.0 | NotApplicable | Brushing activity |
| `pregnancyTestResult` | 15.0 | Negative, Positive, Indeterminate | Pregnancy test |
| `progesteroneTestResult` | 15.0 | Negative, Positive, Indeterminate | Progesterone test |
| `contraceptive` | 14.3 | Multiple values | Birth control type |
| `lactation` | 14.3 | NotPresent, Present | Breastfeeding |
| `menstrualFlowIsStartOfCycle` | 16.0 | NotPresent, Present | Cycle start |
| `headphoneAudioExposureEvent` | 14.0 | Loud environment | Headphone warning |
| `environmentalAudioExposureEvent` | 14.0 | Momentary limit | Environment warning |
| `handwashingEvent` | 14.0 | NotApplicable | Handwashing log |
| `lowCardioFitnessEvent` | 14.3 | NotApplicable | Low fitness alert |
| `appleWalkingSteadinessEvent` | 15.0 | Multiple values | Walking stability |

### Usage Example

```swift
// Request permissions for category types
let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!

let typesToWrite: Set<HKSampleType> = [sleepType, mindfulType]
let typesToRead: Set<HKObjectType> = [sleepType, mindfulType]

healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
    success, error in
    // Handle result
}

// Saving a category sample
let sleepSample = HKCategorySample(
    type: sleepType,
    value: HKCategoryValueSleepAnalysis.asleep.rawValue,
    start: Date().addingTimeInterval(-3600 * 8), // 8 hours ago
    end: Date()
)

healthStore.save(sleepSample) { success, error in
    // Check success
}
```

---

## Correlation Types

Correlation types group multiple related quantity types together.

### Permission Rules
- ❌ **DO NOT request permission for correlation types directly**
- ✅ **Request permissions for individual component types instead**
- Reason: HealthKit doesn't require authorization for correlation types

### Available Identifiers

| Identifier | iOS Version | Components | Description |
|------------|-------------|------------|-------------|
| `bloodPressure` | 8.0 | Systolic + Diastolic | Blood pressure reading |
| `food` | 8.0 | Nutrition types | Food/meal entry |

### Correct Permission Pattern

```swift
// WRONG - DO NOT DO THIS:
// let bloodPressureType = HKCorrelationType.correlationType(
//     forIdentifier: .bloodPressure
// )
// healthStore.requestAuthorization(toShare: [bloodPressureType], ...) // ❌

// CORRECT - Request component permissions:
let systolicType = HKQuantityType.quantityType(
    forIdentifier: .bloodPressureSystolic
)!
let diastolicType = HKQuantityType.quantityType(
    forIdentifier: .bloodPressureDiastolic
)!

let typesToWrite: Set<HKSampleType> = [systolicType, diastolicType]
let typesToRead: Set<HKObjectType> = [systolicType, diastolicType]

healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
    success, error in
    // Now you can work with correlations
}
```

### Creating Correlations

```swift
// Create blood pressure correlation
let systolic = HKQuantitySample(
    type: systolicType,
    quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 120),
    start: Date(),
    end: Date()
)

let diastolic = HKQuantitySample(
    type: diastolicType,
    quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: 80),
    start: Date(),
    end: Date()
)

let correlation = HKCorrelation(
    type: HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!,
    start: Date(),
    end: Date(),
    objects: Set([systolic, diastolic])
)

healthStore.save(correlation) { success, error in
    // Check success
}
```

### Querying Correlations

```swift
// You can only query for correlations with member objects you're authorized to read
let bloodPressureType = HKCorrelationType.correlationType(
    forIdentifier: .bloodPressure
)!

let query = HKSampleQuery(
    sampleType: bloodPressureType,
    predicate: nil,
    limit: HKObjectQueryNoLimit,
    sortDescriptors: nil
) { query, samples, error in
    guard let correlations = samples as? [HKCorrelation] else { return }

    for correlation in correlations {
        if let systolic = correlation.objects(
            for: systolicType
        ).first as? HKQuantitySample {
            // Process systolic reading
        }
    }
}

healthStore.execute(query)
```

---

## Clinical & Document Types

### Clinical Types (iOS 12.0+)

Clinical types represent health records from medical institutions.

#### Permission Rules
- ✅ **READ:** Yes - can request
- ❌ **WRITE:** No - system-only (populated by Health Records feature)

#### Available Identifiers

| Identifier | iOS Version | Description |
|------------|-------------|-------------|
| `allergyRecord` | 12.0 | Allergy records |
| `conditionRecord` | 12.0 | Medical conditions |
| `immunizationRecord` | 12.0 | Vaccination records |
| `labResultRecord` | 12.0 | Lab test results |
| `medicationRecord` | 12.0 | Medication information |
| `procedureRecord` | 12.0 | Medical procedures |
| `vitalSignRecord` | 12.0 | Vital signs from medical records |
| `coverageRecord` | 14.0 | Insurance coverage |
| `clinicalNoteRecord` | 16.0 | Clinical notes |

#### Usage Example

```swift
// Request READ permission for clinical types (iOS 12+)
if #available(iOS 12.0, *) {
    let allergyType = HKClinicalType.clinicalType(
        forIdentifier: .allergyRecord
    )!
    let medicationType = HKClinicalType.clinicalType(
        forIdentifier: .medicationRecord
    )!

    let typesToRead: Set<HKObjectType> = [allergyType, medicationType]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
        success, error in
        // Cannot write to clinical types
    }
}
```

### Document Types (iOS 10.0+)

#### Permission Rules
- ✅ **READ:** Yes - can request
- ✅ **WRITE:** Yes - can request (CDA documents)

#### Available Identifiers

| Identifier | iOS Version | Description |
|------------|-------------|-------------|
| `CDA` | 10.0 | Clinical Document Architecture (HL7 CDA) |

#### Usage Example

```swift
// CDA documents (iOS 10+)
if #available(iOS 10.0, *) {
    let cdaType = HKDocumentType.documentType(
        forIdentifier: .CDA
    )!

    let typesToWrite: Set<HKSampleType> = [cdaType]
    let typesToRead: Set<HKObjectType> = [cdaType]

    healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
        success, error in
        // Handle result
    }
}
```

---

## Workout Types

Workout types represent exercise sessions.

### Permission Rules
- ✅ **READ:** Yes - can request
- ✅ **WRITE:** Yes - can request

### Usage Pattern

```swift
// No identifier needed - workoutType() method
let workoutType = HKObjectType.workoutType()

let typesToWrite: Set<HKSampleType> = [workoutType]
let typesToRead: Set<HKObjectType> = [workoutType]

healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
    success, error in
    // Handle result
}

// Creating a workout
let workout = HKWorkout(
    activityType: .running,
    start: Date().addingTimeInterval(-3600),
    end: Date(),
    duration: 3600,
    totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 300),
    totalDistance: HKQuantity(unit: .mile(), doubleValue: 3.1),
    metadata: nil
)

healthStore.save(workout) { success, error in
    // Check success
}
```

### Workout Route (iOS 11.0+)

```swift
if #available(iOS 11.0, *) {
    let routeType = HKSeriesType.workoutRoute()

    let typesToRead: Set<HKObjectType> = [routeType]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
        success, error in
        // Handle result
    }
}
```

### Activity Summary (iOS 9.3+)

```swift
if #available(iOS 9.3, *) {
    let activitySummaryType = HKObjectType.activitySummaryType()

    let typesToRead: Set<HKObjectType> = [activitySummaryType]

    healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
        success, error in
        // Activity rings data
    }
}
```

---

## Permission Patterns & Best Practices

### 1. Always Check Availability

```swift
// Check if HealthKit is available
guard HKHealthStore.isHealthDataAvailable() else {
    // Not available (iPad, old iOS)
    return
}
```

### 2. Handle Permission Requests Properly

```swift
func requestHealthKitAuthorization(completion: @escaping (Bool, Error?) -> Void) {
    // 1. Check availability
    guard HKHealthStore.isHealthDataAvailable() else {
        completion(false, HealthKitError.notAvailable)
        return
    }

    // 2. Prepare data types
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
          let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
          let dobType = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)
    else {
        completion(false, HealthKitError.dataTypeUnavailable)
        return
    }

    // 3. Separate read and write types
    let typesToShare: Set<HKSampleType> = [stepType, weightType]
    let typesToRead: Set<HKObjectType> = [stepType, weightType, dobType]

    // 4. Request authorization
    let healthStore = HKHealthStore()
    healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
        success, error in
        // Note: success means dialog was shown, NOT that user granted all permissions
        completion(success, error)
    }
}
```

### 3. Understanding the Success Flag

```swift
healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
    success, error in

    // IMPORTANT: success == true means:
    // - Authorization dialog was successfully shown
    // - NOT that user granted all permissions
    // - NOT that user granted any permissions

    // You CANNOT determine read permissions (privacy)
    // You CAN check write permissions:
    let writeStatus = healthStore.authorizationStatus(for: stepType)
    switch writeStatus {
    case .notDetermined:
        // Never requested or user hasn't decided yet
        break
    case .sharingDenied:
        // User explicitly denied write access
        break
    case .sharingAuthorized:
        // User granted write access
        break
    @unknown default:
        break
    }
}
```

### 4. Group Related Permissions

```swift
// Group by functionality for better UX
struct HealthKitPermissions {
    static let fitness: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]

    static let vitals: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
    ]

    static let body: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKQuantityType.quantityType(forIdentifier: .height)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
    ]

    static let profile: Set<HKObjectType> = [
        HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!,
        HKCharacteristicType.characteristicType(forIdentifier: .bloodType)!
    ]
}

// Request permissions by group
func requestFitnessPermissions(completion: @escaping (Bool, Error?) -> Void) {
    let writeTypes = HealthKitPermissions.fitness.filter { $0 is HKSampleType } as! Set<HKSampleType>
    healthStore.requestAuthorization(toShare: writeTypes, read: HealthKitPermissions.fitness, completion: completion)
}
```

### 5. Handle iOS Version Availability

```swift
func getSupportedHealthTypes() -> Set<HKObjectType> {
    var types: Set<HKObjectType> = []

    // Always available (iOS 8.0+)
    if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
        types.insert(stepCount)
    }

    // iOS 10.0+
    if #available(iOS 10.0, *),
       let wheelchairUse = HKCharacteristicType.characteristicType(forIdentifier: .wheelchairUse) {
        types.insert(wheelchairUse)
    }

    // iOS 11.0+
    if #available(iOS 11.0, *),
       let vo2Max = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
        types.insert(vo2Max)
    }

    // iOS 12.0+
    if #available(iOS 12.0, *),
       let allergyRecord = HKClinicalType.clinicalType(forIdentifier: .allergyRecord) {
        types.insert(allergyRecord)
    }

    // iOS 13.0+
    if #available(iOS 13.0, *),
       let audioExposure = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) {
        types.insert(audioExposure)
    }

    // iOS 14.0+
    if #available(iOS 14.0, *),
       let activityMoveMode = HKCharacteristicType.characteristicType(forIdentifier: .activityMoveMode) {
        types.insert(activityMoveMode)
    }

    return types
}
```

### 6. Error Handling

```swift
enum HealthKitError: Error {
    case notAvailable
    case dataTypeUnavailable
    case authorizationDenied
    case authorizationNotDetermined
    case characteristicReadError
    case invalidDataType

    var localizedDescription: String {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .dataTypeUnavailable:
            return "The requested health data type is not available"
        case .authorizationDenied:
            return "Authorization has been denied for this health data type"
        case .authorizationNotDetermined:
            return "Authorization has not been requested for this health data type"
        case .characteristicReadError:
            return "Unable to read characteristic data"
        case .invalidDataType:
            return "Invalid health data type"
        }
    }
}

// Using error handling
func readBiologicalSex() throws -> HKBiologicalSex {
    do {
        let biologicalSex = try healthStore.biologicalSex()
        return biologicalSex.biologicalSex
    } catch let error as NSError {
        if error.code == HKError.errorAuthorizationNotDetermined.rawValue {
            throw HealthKitError.authorizationNotDetermined
        } else if error.code == HKError.errorAuthorizationDenied.rawValue {
            throw HealthKitError.authorizationDenied
        }
        throw HealthKitError.characteristicReadError
    }
}
```

### 7. Don't Request Unnecessary Permissions

```swift
// BAD: Requesting everything at once
let allTypes: Set<HKObjectType> = [
    // 50+ different data types
]
healthStore.requestAuthorization(toShare: allTypes as? Set<HKSampleType>, read: allTypes) { _, _ in }

// GOOD: Request only what you need, when you need it
func requestStepCountPermission(completion: @escaping (Bool, Error?) -> Void) {
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
        completion(false, HealthKitError.dataTypeUnavailable)
        return
    }

    healthStore.requestAuthorization(
        toShare: [stepType],
        read: [stepType],
        completion: completion
    )
}
```

### 8. Handle Correlation Types Correctly

```swift
// CORRECT: Blood Pressure Permission Pattern
func requestBloodPressurePermissions(completion: @escaping (Bool, Error?) -> Void) {
    // Get component types
    guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
          let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
    else {
        completion(false, HealthKitError.dataTypeUnavailable)
        return
    }

    // Request permissions for COMPONENTS, not correlation
    let typesToShare: Set<HKSampleType> = [systolicType, diastolicType]
    let typesToRead: Set<HKObjectType> = [systolicType, diastolicType]

    healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
        // Now you can work with blood pressure correlations
        completion(success, error)
    }
}

// CORRECT: Food Permission Pattern
func requestFoodPermissions(completion: @escaping (Bool, Error?) -> Void) {
    // Get nutrition component types
    guard let energyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
          let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
          let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
          let fatType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)
    else {
        completion(false, HealthKitError.dataTypeUnavailable)
        return
    }

    // Request permissions for nutrition types you'll use
    let typesToShare: Set<HKSampleType> = [energyType, proteinType, carbsType, fatType]
    let typesToRead: Set<HKObjectType> = [energyType, proteinType, carbsType, fatType]

    healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
}
```

### 9. Permission Request Timing

```swift
// BAD: Request on app launch
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    requestAllHealthKitPermissions() // User hasn't seen your app yet!
}

// GOOD: Request when user needs the feature
func onFitnessTrackingButtonTapped() {
    // Show explanation first
    showPermissionExplanation {
        self.requestFitnessPermissions { success, error in
            // Handle result
        }
    }
}

// BETTER: Progressive permission requests
class HealthKitManager {
    private var permissionsRequested: Set<HKObjectType> = []

    func ensurePermission(for type: HKObjectType, completion: @escaping (Bool) -> Void) {
        // Check if already requested
        guard !permissionsRequested.contains(type) else {
            completion(true)
            return
        }

        // Request this specific permission
        let sampleType = type as? HKSampleType
        let shareTypes = sampleType != nil ? [sampleType!] : nil

        healthStore.requestAuthorization(toShare: Set(shareTypes ?? []), read: [type]) {
            success, _ in
            if success {
                self.permissionsRequested.insert(type)
            }
            completion(success)
        }
    }
}
```

### 10. Testing Permission States

```swift
class HealthKitPermissionTester {
    let healthStore = HKHealthStore()

    func testWritePermission(for type: HKSampleType) -> (status: String, canWrite: Bool) {
        let status = healthStore.authorizationStatus(for: type)

        switch status {
        case .notDetermined:
            return ("Not Determined", false)
        case .sharingDenied:
            return ("Denied", false)
        case .sharingAuthorized:
            return ("Authorized", true)
        @unknown default:
            return ("Unknown", false)
        }
    }

    func testReadPermission(for type: HKObjectType) -> String {
        // Cannot determine read permission (privacy protection)
        // Instead, try to read and see if you get results
        return "Unknown (Privacy Protected)"
    }

    func testCharacteristicPermission(for identifier: HKCharacteristicTypeIdentifier) -> Bool {
        guard let type = HKCharacteristicType.characteristicType(forIdentifier: identifier) else {
            return false
        }

        do {
            switch identifier {
            case .dateOfBirth:
                _ = try healthStore.dateOfBirthComponents()
            case .biologicalSex:
                _ = try healthStore.biologicalSex()
            case .bloodType:
                _ = try healthStore.bloodType()
            case .fitzpatrickSkinType:
                _ = try healthStore.fitzpatrickSkinType()
            case .wheelchairUse:
                if #available(iOS 10.0, *) {
                    _ = try healthStore.wheelchairUse()
                }
            case .activityMoveMode:
                if #available(iOS 14.0, *) {
                    _ = try healthStore.activityMoveMode()
                }
            default:
                return false
            }
            return true
        } catch {
            return false
        }
    }
}
```

---

## Code Examples

### Complete Plugin Permission Manager

```swift
import HealthKit

class HealthKitPermissionManager {
    private let healthStore = HKHealthStore()

    // MARK: - Availability Check

    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Permission Requests

    func requestQuantityTypePermissions(
        identifiers: [HKQuantityTypeIdentifier],
        read: Bool,
        write: Bool,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isHealthKitAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        var readTypes: Set<HKObjectType> = []
        var writeTypes: Set<HKSampleType> = []

        for identifier in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                continue
            }

            if read {
                readTypes.insert(type)
            }
            if write {
                writeTypes.insert(type)
            }
        }

        healthStore.requestAuthorization(
            toShare: write ? writeTypes : nil,
            read: read ? readTypes : nil,
            completion: completion
        )
    }

    func requestCategoryTypePermissions(
        identifiers: [HKCategoryTypeIdentifier],
        read: Bool,
        write: Bool,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isHealthKitAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        var readTypes: Set<HKObjectType> = []
        var writeTypes: Set<HKSampleType> = []

        for identifier in identifiers {
            guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else {
                continue
            }

            if read {
                readTypes.insert(type)
            }
            if write {
                writeTypes.insert(type)
            }
        }

        healthStore.requestAuthorization(
            toShare: write ? writeTypes : nil,
            read: read ? readTypes : nil,
            completion: completion
        )
    }

    func requestCharacteristicTypePermissions(
        identifiers: [HKCharacteristicTypeIdentifier],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isHealthKitAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        var readTypes: Set<HKObjectType> = []

        for identifier in identifiers {
            guard let type = HKCharacteristicType.characteristicType(forIdentifier: identifier) else {
                continue
            }
            readTypes.insert(type)
        }

        // Characteristics are READ-ONLY
        healthStore.requestAuthorization(
            toShare: nil,
            read: readTypes,
            completion: completion
        )
    }

    func requestWorkoutPermissions(
        read: Bool,
        write: Bool,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isHealthKitAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        let workoutType = HKObjectType.workoutType()

        healthStore.requestAuthorization(
            toShare: write ? [workoutType] : nil,
            read: read ? [workoutType] : nil,
            completion: completion
        )
    }

    @available(iOS 12.0, *)
    func requestClinicalTypePermissions(
        identifiers: [HKClinicalTypeIdentifier],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isHealthKitAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        var readTypes: Set<HKObjectType> = []

        for identifier in identifiers {
            guard let type = HKClinicalType.clinicalType(forIdentifier: identifier) else {
                continue
            }
            readTypes.insert(type)
        }

        // Clinical types are READ-ONLY
        healthStore.requestAuthorization(
            toShare: nil,
            read: readTypes,
            completion: completion
        )
    }

    // MARK: - Blood Pressure (Correlation)

    func requestBloodPressurePermissions(
        read: Bool,
        write: Bool,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard isHealthKitAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)
        else {
            completion(false, HealthKitError.dataTypeUnavailable)
            return
        }

        var readTypes: Set<HKObjectType> = []
        var writeTypes: Set<HKSampleType> = []

        if read {
            readTypes.insert(systolicType)
            readTypes.insert(diastolicType)
        }

        if write {
            writeTypes.insert(systolicType)
            writeTypes.insert(diastolicType)
        }

        healthStore.requestAuthorization(
            toShare: write ? writeTypes : nil,
            read: read ? readTypes : nil,
            completion: completion
        )
    }

    // MARK: - Authorization Status

    func getAuthorizationStatus(for type: HKSampleType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    func canWriteType(_ type: HKSampleType) -> Bool {
        let status = healthStore.authorizationStatus(for: type)
        return status == .sharingAuthorized
    }

    // MARK: - Read Characteristics

    func readDateOfBirth() throws -> DateComponents {
        return try healthStore.dateOfBirthComponents()
    }

    func readBiologicalSex() throws -> HKBiologicalSex {
        return try healthStore.biologicalSex().biologicalSex
    }

    func readBloodType() throws -> HKBloodType {
        return try healthStore.bloodType().bloodType
    }

    @available(iOS 9.0, *)
    func readFitzpatrickSkinType() throws -> HKFitzpatrickSkinType {
        return try healthStore.fitzpatrickSkinType().skinType
    }

    @available(iOS 10.0, *)
    func readWheelchairUse() throws -> HKWheelchairUse {
        return try healthStore.wheelchairUse().wheelchairUse
    }

    @available(iOS 14.0, *)
    func readActivityMoveMode() throws -> HKActivityMoveMode {
        return try healthStore.activityMoveMode().activityMoveMode
    }
}
```

### Flutter Plugin Bridge Example

```swift
// Flutter iOS Plugin for HealthKit Permissions
import Flutter
import HealthKit

public class HealthKitPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private let permissionManager = HealthKitPermissionManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "healthkit_permissions",
            binaryMessenger: registrar.messenger()
        )

        let instance = HealthKitPlugin()
        instance.channel = channel

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(permissionManager.isHealthKitAvailable())

        case "requestQuantityPermissions":
            handleRequestQuantityPermissions(call, result: result)

        case "requestCategoryPermissions":
            handleRequestCategoryPermissions(call, result: result)

        case "requestCharacteristicPermissions":
            handleRequestCharacteristicPermissions(call, result: result)

        case "requestWorkoutPermissions":
            handleRequestWorkoutPermissions(call, result: result)

        case "requestBloodPressurePermissions":
            handleRequestBloodPressurePermissions(call, result: result)

        case "readCharacteristic":
            handleReadCharacteristic(call, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleRequestQuantityPermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let identifierStrings = args["identifiers"] as? [String],
              let read = args["read"] as? Bool,
              let write = args["write"] as? Bool
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            return
        }

        let identifiers = identifierStrings.compactMap {
            HKQuantityTypeIdentifier(rawValue: $0)
        }

        permissionManager.requestQuantityTypePermissions(
            identifiers: identifiers,
            read: read,
            write: write
        ) { success, error in
            if let error = error {
                result(FlutterError(
                    code: "PERMISSION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                result(success)
            }
        }
    }

    private func handleRequestCategoryPermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let identifierStrings = args["identifiers"] as? [String],
              let read = args["read"] as? Bool,
              let write = args["write"] as? Bool
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            return
        }

        let identifiers = identifierStrings.compactMap {
            HKCategoryTypeIdentifier(rawValue: $0)
        }

        permissionManager.requestCategoryTypePermissions(
            identifiers: identifiers,
            read: read,
            write: write
        ) { success, error in
            if let error = error {
                result(FlutterError(
                    code: "PERMISSION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                result(success)
            }
        }
    }

    private func handleRequestCharacteristicPermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let identifierStrings = args["identifiers"] as? [String]
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            return
        }

        let identifiers = identifierStrings.compactMap {
            HKCharacteristicTypeIdentifier(rawValue: $0)
        }

        permissionManager.requestCharacteristicTypePermissions(identifiers: identifiers) {
            success, error in
            if let error = error {
                result(FlutterError(
                    code: "PERMISSION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                result(success)
            }
        }
    }

    private func handleRequestWorkoutPermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let read = args["read"] as? Bool,
              let write = args["write"] as? Bool
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            return
        }

        permissionManager.requestWorkoutPermissions(read: read, write: write) {
            success, error in
            if let error = error {
                result(FlutterError(
                    code: "PERMISSION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                result(success)
            }
        }
    }

    private func handleRequestBloodPressurePermissions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let read = args["read"] as? Bool,
              let write = args["write"] as? Bool
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            return
        }

        permissionManager.requestBloodPressurePermissions(read: read, write: write) {
            success, error in
            if let error = error {
                result(FlutterError(
                    code: "PERMISSION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                result(success)
            }
        }
    }

    private func handleReadCharacteristic(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let identifierString = args["identifier"] as? String,
              let identifier = HKCharacteristicTypeIdentifier(rawValue: identifierString)
        else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: nil, details: nil))
            return
        }

        do {
            switch identifier {
            case .dateOfBirth:
                let dob = try permissionManager.readDateOfBirth()
                result([
                    "year": dob.year as Any,
                    "month": dob.month as Any,
                    "day": dob.day as Any
                ])

            case .biologicalSex:
                let sex = try permissionManager.readBiologicalSex()
                result(sex.rawValue)

            case .bloodType:
                let bloodType = try permissionManager.readBloodType()
                result(bloodType.rawValue)

            default:
                result(FlutterError(
                    code: "UNSUPPORTED_TYPE",
                    message: "Characteristic type not supported",
                    details: nil
                ))
            }
        } catch {
            result(FlutterError(
                code: "READ_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    public func detachFromEngineForRegistrar(_ registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
    }
}
```

---

## Quick Reference Tables

### Permission Matrix

| Data Type | Read Permission | Write Permission | Notes |
|-----------|----------------|------------------|-------|
| **Characteristic** | ✅ Yes | ❌ No | Read-only, edit via Health app |
| **Quantity** | ✅ Yes | ✅ Yes | Most common type |
| **Category** | ✅ Yes | ✅ Yes | Categorical values |
| **Correlation** | ❌ No (use components) | ❌ No (use components) | Request component permissions |
| **Workout** | ✅ Yes | ✅ Yes | Use `workoutType()` |
| **Clinical** | ✅ Yes (iOS 12+) | ❌ No | System-populated only |
| **Document (CDA)** | ✅ Yes (iOS 10+) | ✅ Yes (iOS 10+) | Clinical documents |
| **Activity Summary** | ✅ Yes (iOS 9.3+) | ❌ No | Activity rings data |
| **Workout Route** | ✅ Yes (iOS 11+) | ✅ Yes (iOS 11+) | GPS workout data |

### iOS Version Requirements

| iOS Version | Major Features Added |
|-------------|---------------------|
| 8.0 | HealthKit introduced, basic quantity/category/characteristic types |
| 9.0 | Reproductive health, UV exposure, Fitzpatrick skin type |
| 9.3 | Activity summary type |
| 10.0 | Wheelchair use, swimming metrics, mindful sessions |
| 11.0 | VO2 max, HRV, resting/walking HR, insulin delivery, workout routes |
| 11.2 | Downhill snow sports distance |
| 12.0 | Clinical records (allergies, medications, lab results, etc.) |
| 12.2 | Heart rate events (high, low, irregular) |
| 13.0 | Audio exposure, toothbrushing, audiogram samples |
| 14.0 | Activity move mode, headphone audio, handwashing, ECG |
| 14.3 | Low cardio fitness, contraceptive, lactation |
| 15.0 | Walking steadiness, pregnancy test, Apple Walking Steadiness |
| 16.0 | Menstrual cycle start marker, clinical notes |

---

## Common Pitfalls & Solutions

### Pitfall 1: Requesting Correlation Type Permissions

❌ **Wrong:**
```swift
let bloodPressure = HKCorrelationType.correlationType(forIdentifier: .bloodPressure)!
healthStore.requestAuthorization(toShare: [bloodPressure], read: [bloodPressure])
```

✅ **Correct:**
```swift
let systolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
let diastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
healthStore.requestAuthorization(toShare: [systolic, diastolic], read: [systolic, diastolic])
```

### Pitfall 2: Trying to Write Characteristic Types

❌ **Wrong:**
```swift
let dob = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!
healthStore.requestAuthorization(toShare: [dob], read: [dob]) // Error!
```

✅ **Correct:**
```swift
let dob = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!
healthStore.requestAuthorization(toShare: nil, read: [dob]) // Only read
```

### Pitfall 3: Assuming Success Means Permission Granted

❌ **Wrong:**
```swift
healthStore.requestAuthorization(toShare: types, read: types) { success, error in
    if success {
        // User granted all permissions! (WRONG ASSUMPTION)
        self.startReadingData()
    }
}
```

✅ **Correct:**
```swift
healthStore.requestAuthorization(toShare: types, read: types) { success, error in
    if success {
        // Dialog was shown successfully
        // For write permissions, check individual types:
        let canWrite = self.healthStore.authorizationStatus(for: stepType) == .sharingAuthorized

        // For read permissions: Cannot check, just try to read
        // If denied, you'll only get data your app wrote
        self.attemptDataRead()
    }
}
```

### Pitfall 4: Not Checking iOS Availability

❌ **Wrong:**
```swift
let vo2Max = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
// Crashes on iOS 10 and below
```

✅ **Correct:**
```swift
if #available(iOS 11.0, *) {
    if let vo2Max = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
        // Safe to use
    }
} else {
    // Handle older iOS version
}
```

### Pitfall 5: Not Handling iPad

❌ **Wrong:**
```swift
func setupHealthKit() {
    let healthStore = HKHealthStore()
    healthStore.requestAuthorization(...) // Crashes on iPad
}
```

✅ **Correct:**
```swift
func setupHealthKit() {
    guard HKHealthStore.isHealthDataAvailable() else {
        // HealthKit not available (iPad or region restriction)
        return
    }

    let healthStore = HKHealthStore()
    healthStore.requestAuthorization(...)
}
```

### Pitfall 6: Requesting Too Many Permissions at Once

❌ **Wrong:**
```swift
// Request 50+ data types on app launch
let allTypes: Set<HKObjectType> = [/* massive list */]
healthStore.requestAuthorization(...)
// User sees overwhelming permission dialog and denies everything
```

✅ **Correct:**
```swift
// Request permissions progressively as features are used
func startStepTracking() {
    requestPermission(for: .stepCount) {
        // Start tracking
    }
}

func startHeartRateMonitoring() {
    requestPermission(for: .heartRate) {
        // Start monitoring
    }
}
```

### Pitfall 7: Using Force Unwrap on Optional Types

❌ **Wrong:**
```swift
let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
// Could crash if identifier is invalid or unavailable
```

✅ **Correct:**
```swift
guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
    // Handle error gracefully
    return
}
```

### Pitfall 8: Not Removing Observers

❌ **Wrong:**
```swift
class HealthDataObserver {
    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(healthDataChanged),
            name: .HKHealthStoreDataChanged,
            object: nil
        )
    }
    // No cleanup - memory leak!
}
```

✅ **Correct:**
```swift
class HealthDataObserver {
    private var observer: NSObjectProtocol?

    func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: .HKHealthStoreDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.healthDataChanged()
        }
    }

    func stopObserving() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    deinit {
        stopObserving()
    }
}
```

---

## Advanced Permission Patterns

### Pattern 1: Batch Permission Requests with Validation

```swift
class HealthKitPermissionValidator {
    func requestPermissions(
        quantityTypes: [HKQuantityTypeIdentifier] = [],
        categoryTypes: [HKCategoryTypeIdentifier] = [],
        characteristicTypes: [HKCharacteristicTypeIdentifier] = [],
        includeWorkouts: Bool = false,
        read: Bool = true,
        write: Bool = false,
        completion: @escaping (Result<PermissionResult, Error>) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(HealthKitError.notAvailable))
            return
        }

        var readTypes: Set<HKObjectType> = []
        var writeTypes: Set<HKSampleType> = []
        var unavailableTypes: [String] = []

        // Quantity types
        for identifier in quantityTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                unavailableTypes.append(identifier.rawValue)
                continue
            }
            if read { readTypes.insert(type) }
            if write { writeTypes.insert(type) }
        }

        // Category types
        for identifier in categoryTypes {
            guard let type = HKCategoryType.categoryType(forIdentifier: identifier) else {
                unavailableTypes.append(identifier.rawValue)
                continue
            }
            if read { readTypes.insert(type) }
            if write { writeTypes.insert(type) }
        }

        // Characteristic types (read-only)
        for identifier in characteristicTypes {
            guard let type = HKCharacteristicType.characteristicType(forIdentifier: identifier) else {
                unavailableTypes.append(identifier.rawValue)
                continue
            }
            if read { readTypes.insert(type) }
        }

        // Workout type
        if includeWorkouts {
            let workoutType = HKObjectType.workoutType()
            if read { readTypes.insert(workoutType) }
            if write { writeTypes.insert(workoutType) }
        }

        // Check if any types are available
        guard !readTypes.isEmpty || !writeTypes.isEmpty else {
            completion(.failure(HealthKitError.dataTypeUnavailable))
            return
        }

        // Request authorization
        let healthStore = HKHealthStore()
        healthStore.requestAuthorization(
            toShare: write ? writeTypes : nil,
            read: read ? readTypes : nil
        ) { success, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let result = PermissionResult(
                dialogShown: success,
                requestedReadTypes: readTypes.count,
                requestedWriteTypes: writeTypes.count,
                unavailableTypes: unavailableTypes
            )

            completion(.success(result))
        }
    }
}

struct PermissionResult {
    let dialogShown: Bool
    let requestedReadTypes: Int
    let requestedWriteTypes: Int
    let unavailableTypes: [String]

    var hasUnavailableTypes: Bool {
        return !unavailableTypes.isEmpty
    }
}
```

### Pattern 2: Permission Status Checker

```swift
class HealthKitAuthorizationChecker {
    private let healthStore = HKHealthStore()

    func checkWriteAuthorization(for identifiers: [HKQuantityTypeIdentifier]) -> [String: HKAuthorizationStatus] {
        var results: [String: HKAuthorizationStatus] = [:]

        for identifier in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                continue
            }

            let status = healthStore.authorizationStatus(for: type)
            results[identifier.rawValue] = status
        }

        return results
    }

    func canWriteAllTypes(_ identifiers: [HKQuantityTypeIdentifier]) -> Bool {
        for identifier in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                return false
            }

            let status = healthStore.authorizationStatus(for: type)
            if status != .sharingAuthorized {
                return false
            }
        }

        return true
    }

    func canWriteAnyType(_ identifiers: [HKQuantityTypeIdentifier]) -> Bool {
        for identifier in identifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                continue
            }

            let status = healthStore.authorizationStatus(for: type)
            if status == .sharingAuthorized {
                return true
            }
        }

        return false
    }

    func getAuthorizedWriteTypes(from identifiers: [HKQuantityTypeIdentifier]) -> [HKQuantityTypeIdentifier] {
        return identifiers.filter { identifier in
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                return false
            }
            return healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
    }
}
```

### Pattern 3: Smart Permission Request Strategy

```swift
class SmartPermissionManager {
    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard
    private let requestedPermissionsKey = "healthkit.requested.permissions"

    func shouldRequestPermission(for identifier: HKQuantityTypeIdentifier) -> Bool {
        // Check if already requested
        var requestedPermissions = userDefaults.stringArray(forKey: requestedPermissionsKey) ?? []

        if requestedPermissions.contains(identifier.rawValue) {
            // Already requested - check current status
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
                return false
            }

            let status = healthStore.authorizationStatus(for: type)
            // Only re-request if not determined
            return status == .notDetermined
        }

        return true
    }

    func requestPermissionWithTracking(
        for identifier: HKQuantityTypeIdentifier,
        read: Bool,
        write: Bool,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard shouldRequestPermission(for: identifier) else {
            completion(false, HealthKitError.authorizationNotDetermined)
            return
        }

        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(false, HealthKitError.dataTypeUnavailable)
            return
        }

        healthStore.requestAuthorization(
            toShare: write ? [type] : nil,
            read: read ? [type] : nil
        ) { success, error in
            if success {
                // Mark as requested
                var requestedPermissions = self.userDefaults.stringArray(
                    forKey: self.requestedPermissionsKey
                ) ?? []
                if !requestedPermissions.contains(identifier.rawValue) {
                    requestedPermissions.append(identifier.rawValue)
                    self.userDefaults.set(requestedPermissions, forKey: self.requestedPermissionsKey)
                }
            }

            completion(success, error)
        }
    }

    func resetRequestHistory() {
        userDefaults.removeObject(forKey: requestedPermissionsKey)
    }
}
```

### Pattern 4: Permission Request with User Education

```swift
class EducationalPermissionManager {
    private let healthStore = HKHealthStore()

    struct PermissionRequest {
        let identifier: HKQuantityTypeIdentifier
        let title: String
        let description: String
        let icon: String
        let read: Bool
        let write: Bool
    }

    func requestPermissionsWithEducation(
        requests: [PermissionRequest],
        presentingViewController: UIViewController,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // Show educational UI first
        showEducationalDialog(requests: requests, from: presentingViewController) { userAccepted in
            guard userAccepted else {
                completion(false, nil)
                return
            }

            // User understands and agreed - now request actual permissions
            self.requestHealthKitPermissions(requests: requests, completion: completion)
        }
    }

    private func showEducationalDialog(
        requests: [PermissionRequest],
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: "Health Data Access",
            message: self.buildEducationalMessage(for: requests),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            completion(true)
        })

        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel) { _ in
            completion(false)
        })

        viewController.present(alert, animated: true)
    }

    private func buildEducationalMessage(for requests: [PermissionRequest]) -> String {
        var message = "This app needs access to the following health data:\n\n"

        for request in requests {
            message += "• \(request.title): \(request.description)\n"
        }

        message += "\nYour health data is private and secure. You control what we can access."

        return message
    }

    private func requestHealthKitPermissions(
        requests: [PermissionRequest],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        var readTypes: Set<HKObjectType> = []
        var writeTypes: Set<HKSampleType> = []

        for request in requests {
            guard let type = HKQuantityType.quantityType(forIdentifier: request.identifier) else {
                continue
            }

            if request.read { readTypes.insert(type) }
            if request.write { writeTypes.insert(type) }
        }

        healthStore.requestAuthorization(
            toShare: writeTypes.isEmpty ? nil : writeTypes,
            read: readTypes.isEmpty ? nil : readTypes,
            completion: completion
        )
    }
}
```

---

## Info.plist Configuration

Don't forget to add the required privacy descriptions to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We need to read your health data to provide personalized fitness insights.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>We need to save your workout data to HealthKit to track your progress.</string>

<!-- For clinical records (iOS 12+) -->
<key>NSHealthClinicalHealthRecordsShareUsageDescription</key>
<string>We need to read your clinical records to provide comprehensive health analysis.</string>
```

**Important Notes:**
- Both descriptions are required even if you only need read or write access
- Apps are rejected if these are missing
- Be specific about why you need access
- Don't use generic descriptions

---

## Testing Checklist

### Pre-Release Testing

- [ ] Test on physical device (HealthKit unavailable in simulator for most features)
- [ ] Test permission request dialogs appear correctly
- [ ] Test handling of permission denial
- [ ] Test handling of partial permission grants
- [ ] Test on iPad (should gracefully handle unavailability)
- [ ] Test with no Health app data
- [ ] Test with existing Health app data
- [ ] Test background data reading/writing
- [ ] Test app behavior after iOS update
- [ ] Verify Info.plist descriptions are present and appropriate

### Permission Scenarios to Test

1. **First Launch (Not Determined)**
   - Request permissions
   - Verify dialog shows
   - Grant some, deny others
   - Check app behavior

2. **Permission Denied**
   - Open Settings → Privacy → Health
   - Disable specific permissions
   - Relaunch app
   - Verify graceful handling

3. **Permission Later Granted**
   - Initially deny permissions
   - Later grant via Settings
   - Verify app detects and uses new permissions

4. **Multiple Permission Requests**
   - Request permissions for different data types over time
   - Verify no permission dialogs shown twice for same type
   - Test that previously denied permissions aren't re-requested

5. **Characteristic Types**
   - Request characteristic permissions
   - Verify read-only behavior
   - Test error handling when not authorized

6. **Correlation Types**
   - Request blood pressure permissions (components)
   - Verify both systolic and diastolic work
   - Test correlation creation and reading

---

## Performance Optimization

### 1. Batch Queries

```swift
// BAD: Multiple individual queries
for identifier in identifiers {
    let type = HKQuantityType.quantityType(forIdentifier: identifier)!
    let query = HKSampleQuery(sampleType: type, ...) { ... }
    healthStore.execute(query)
}

// GOOD: Single query with predicate
let types = identifiers.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
// Use HKStatisticsCollectionQuery for multiple types
```

### 2. Use Background Delivery

```swift
// Enable background delivery for high-priority types
let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

healthStore.enableBackgroundDelivery(
    for: stepType,
    frequency: .hourly
) { success, error in
    if success {
        // Set up observer query
    }
}
```

### 3. Limit Query Results

```swift
// Use limit parameter
let query = HKSampleQuery(
    sampleType: type,
    predicate: predicate,
    limit: 100, // Don't fetch thousands of samples
    sortDescriptors: [sortDescriptor]
) { query, samples, error in
    // Process limited results
}
```

### 4. Cache Permission Status

```swift
class PermissionCache {
    private var cache: [String: (status: HKAuthorizationStatus, timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes

    func getCachedStatus(for type: HKSampleType, healthStore: HKHealthStore) -> HKAuthorizationStatus {
        let key = type.identifier

        if let cached = cache[key],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            return cached.status
        }

        let status = healthStore.authorizationStatus(for: type)
        cache[key] = (status, Date())
        return status
    }

    func invalidateCache() {
        cache.removeAll()
    }
}
```

---

## Summary & Key Takeaways

### Critical Rules for HealthKit Permissions

1. **Always check availability** with `HKHealthStore.isHealthDataAvailable()`
2. **Characteristic types are READ-ONLY** - never request write permission
3. **Correlation types** - request permissions for components, not the correlation itself
4. **Clinical types are READ-ONLY** - system-populated via Health Records
5. **Success flag ≠ permission granted** - it only means dialog was shown
6. **Read permissions are private** - you cannot determine if they were granted
7. **Request progressively** - don't overwhelm users with 50+ permissions at once
8. **Add Info.plist descriptions** - required for App Store approval
9. **Handle iOS version availability** - use `@available` checks
10. **Test on physical device** - simulator has limited HealthKit functionality

### Permission Request Template

```swift
// 1. Check availability
guard HKHealthStore.isHealthDataAvailable() else { return }

// 2. Create types with nil checks
guard let type1 = HKQuantityType.quantityType(forIdentifier: .stepCount),
      let type2 = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
      let type3 = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)
else { return }

// 3. Separate read and write
let writeTypes: Set<HKSampleType> = [type1, type2] // No characteristics!
let readTypes: Set<HKObjectType> = [type1, type2, type3]

// 4. Request with error handling
healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
    if let error = error {
        // Handle error
        return
    }

    if success {
        // Dialog shown - proceed with feature
    }
}
```

### For Flutter Plugin Development

When building a Flutter plugin for HealthKit permissions:

1. **Create comprehensive type mappings** between Dart enums and iOS identifiers
2. **Validate iOS availability** before creating HKObjectType instances
3. **Separate permission request methods** by data category (quantity, category, etc.)
4. **Handle correlation types specially** - decompose to components
5. **Return detailed results** including which types are unavailable on current iOS
6. **Cache permission states** to minimize native bridge calls
7. **Provide clear error messages** back to Dart layer
8. **Document iOS version requirements** for each data type
9. **Test extensively** on multiple iOS versions
10. **Handle background/foreground** state transitions properly

---

## Additional Resources

### Official Apple Documentation
- [HealthKit Framework Reference](https://developer.apple.com/documentation/healthkit)
- [Protecting User Privacy](https://developer.apple.com/documentation/healthkit/protecting_user_privacy)
- [HKHealthStore Authorization](https://developer.apple.com/documentation/healthkit/hkhealthstore/1614152-requestauthorization)
- [Data Types Overview](https://developer.apple.com/documentation/healthkit/data-types)

### WWDC Sessions
- WWDC 2020: "What's New in HealthKit"
- WWDC 2019: "Exploring New Data Representations in HealthKit"
- WWDC 2018: "New Ways to Work with Workouts"

### Community Resources
- [HealthKit Tutorial](https://www.raywenderlich.com/459-healthkit-tutorial-with-swift-getting-started)
- [HealthKit Best Practices](https://www.hackingwithswift.com/example-code/healthkit)

---

## Revision History

- **Version 1.0** - Initial documentation covering iOS 8.0 - iOS 16.0 data types
- Covers all data type categories and permission patterns
- Includes complete code examples for Flutter plugin development
- Last updated: October 2025

---

**End of Documentation**
