// INFO: ignoring public member docs since this would make this file really hard to consume and maintain
// ignore_for_file: public_member_api_docs

import 'package:connect_kit/src/utils/enum_helper.dart';
import 'package:connect_kit/src/utils/string_manipulation.dart';

// INFO: Android Ref: https://developer.android.com/health-and-fitness/guides/health-connect/plan/data-types?jetpack=alpha10plus

/// Enum representing different health data types supported by ConnectKit
enum CKType {
// --- Activities
  distance, // iOS is distanceWalkingRunning // 'DistanceRecord'
  workout, // Android 'ExerciseSessionRecord' (*_EXERCISE & *_EXERCISE_ROUTE)
  floorsClimbed, // || iOS flightsClimbed // 'FloorsClimbedRecord'
  restingCalories, // iOS basalEnergyBurned // Android BasalMetabolicRateRecord
  steps, // 'StepsRecord' & 'StepsCadenceRecord'

  // Android only
  activeCalories, // Android 'ActiveCaloriesBurnedRecord' (no BMR)
  activityIntensity, // (FEATURE_ACTIVITY_INTENSITY)	'ActivityIntensityRecord'
  totalCalories, //	Android 'TotalCaloriesBurnedRecord' (includes BMR)
  wheelchairPushes, // Android 'WheelchairPushesRecord'

  // iOS only
  distanceCycling,
  distanceWheelchair,
  distanceSwimming,

// --- Body Measurement
  bodyFat, // iOS bodyFatPercentage //	Android 'BodyFatRecord'
  height, //Android 'HeightRecord'
  leanBodyMass, // Android 'LeanBodyMassRecord'
  weight, // Android 'WeightRecord'

  // Android only
  basalMetabolicRate, // Android 'BasalMetabolicRateRecord'
  bodyWaterMass, // Android 'BodyWaterMassRecord'
  boneMass, // Android 'BoneMassRecord'

  // iOS only
  bodyMassIndex, // iOS only

// --- Characteristics

  // Android only

  // iOS only
  biologicalSex, // iOS only (read only)
  bloodType, // iOS only (read only)
  dateOfBirth, // iOS only (read only)

// --- Cycle Tracking
  menstrualFlow, // Android MenstruationFlowRecord

  // Android only
  // iOS only

// --- Nutrition
  nutrition, // || iOS food // Android 'NutritionRecord'
  waterIntake, // iOS dietaryWater // Android 'HydrationRecord'

  // Android only
  // iOS only

// --- Sleep
  sleepAnalysis, // Android 'SleepSessionRession'

  // Android only
  // iOS only

// --- Vitals
  bloodGlucose, // Android 'BloodGlucoseRecord'
  bloodPressure, // 'BloodPressureRecord'
  bodyTemperature, // 'BodyTemperatureRecord'
  heartRate, // Android 'HeartRateRecord'
  oxygenSaturation, // Android 'OxygenSaturationRecord'
  respiratoryRate, // Android 'RespiratoryRateRecord'

  // Android only
  restingHeartRate, // Android 'RestingHeartRateRecord'
  skinTemperature, // Android 'SkinTemperatureRecord' (FEATURE_SKIN_TEMPERATURE)

  // iOS only
  bloodPressureDiastolic,
  bloodPressureSystolic,
  electrocardiogram,

// --- Wellness
  mindfulSession; // Android calls it mindfulness, (FEATURE_MINDFULNESS_SESSION) 'MindfulnessSessionRecord'

  // Android only
  // iOS only

  /// CKType factory method (throws on invalid)
  factory CKType.fromString(String inputString) =>
      enumFromString(CKType.values, inputString);
}

/// Extension for CKType enum
extension CKTypeExtension on CKType {
  /// Get the display name for the health type
  String get displayName {
    switch (this) {
      // TODO: add exceptions here
      default:
        return camelCaseToTitleCase(name);
    }
  }

  /// Check if this health type is read-only
  bool get isReadOnly {
    switch (this) {
      case CKType.biologicalSex:
      case CKType.bloodType:
      case CKType.dateOfBirth:
      case CKType.electrocardiogram:
        return true;
      default:
        return false;
    }
  }

  /// Check if this health type is supported on iOS
  bool get isOnlyIOS {
    switch (this) {
      // TODO:  add iOS-specific types
      default:
        return false;
    }
  }

  /// Check if this health type is supported on Android
  bool get isOnlyAndroid {
    switch (this) {
      // TODO:  add Android-specific types
      default:
        return true;
    }
  }
}
