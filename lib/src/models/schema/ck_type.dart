// INFO: ignoring public member docs since this would make this file really hard to consume and maintain
// ignore_for_file: public_member_api_docs

import 'package:connect_kit/src/utils/string_manipulation.dart';

part 'ck_type.g.dart';

/// Main CKType definition with hierarchical type system
class CKType {
  final String _name;

  const CKType._(this._name);

  static const distance = CKType._('distance'); // iOS is distanceWalkingRunning
  static const workout = _WorkoutType._();
  static const floorsClimbed = CKType._('floorsClimbed'); // iOS flightsClimbed
  static const restingCalories = CKType._('restingCalories');
  static const steps = CKType._('steps');

  // Android only
  static const activeCalories = CKType._('activeCalories'); // (no BMR)
  //(FEATURE_ACTIVITY_INTENSITY)
  static const activityIntensity = CKType._('activityIntensity');
  static const totalCalories = CKType._('totalCalories'); // (includes BMR)
  static const wheelchairPushes = CKType._('wheelchairPushes');

  // iOS only
  static const distanceCycling = CKType._('distanceCycling');
  static const distanceWheelchair = CKType._('distanceWheelchair');
  static const distanceSwimming = CKType._('distanceSwimming');

// --- Body Measurement
  static const bodyFat = CKType._('bodyFat');
  static const height = CKType._('height');
  static const leanBodyMass = CKType._('leanBodyMass');
  static const weight = CKType._('weight');

  // Android only
  static const basalMetabolicRate = CKType._('basalMetabolicRate');
  static const bodyWaterMass = CKType._('bodyWaterMass');
  static const boneMass = CKType._('boneMass');

  // iOS only
  static const bodyMassIndex = CKType._('bodyMassIndex');

// --- Characteristics

  // Android only

  // iOS only
  static const biologicalSex = CKType._('biologicalSex');
  static const bloodType = CKType._('bloodType');
  static const dateOfBirth = CKType._('dateOfBirth');

// --- Cycle Tracking
  static const menstrualFlow = CKType._('menstrualFlow');

  // Android only
  // iOS only

// --- Nutrition
  static const nutrition = _NutritionType._();
  static const waterIntake = CKType._('waterIntake');

  // Android only
  // iOS only

// --- Sleep
  static const sleepAnalysis = CKType._('sleepAnalysis');

  // Android only
  // iOS only

// --- Vitals
  static const bloodGlucose = CKType._('bloodGlucose');
  static const bloodPressure = _BloodPressureType._();
  static const bodyTemperature = CKType._('bodyTemperature');
  static const heartRate = CKType._('heartRate');
  static const oxygenSaturation = CKType._('oxygenSaturation');
  static const respiratoryRate = CKType._('respiratoryRate');

  // Android only
  static const restingHeartRate = CKType._('restingHeartRate');
  // FEATURE_SKIN_TEMPERATURE
  static const skinTemperature = CKType._('skinTemperature');

  // iOS only
  static const electrocardiogram = CKType._('electrocardiogram');

// --- Wellness
// FEATURE_MINDFULNESS_SESSION
  static const mindfulSession = CKType._('mindfulSession');

  // Android only
  // iOS only

  /// Get the display name for the health type
  String get displayName => camelCaseToTitleCase(_name);

  /// String representation
  @override
  String toString() => _name;

  /// Make objects with same string equal (fixes equality issue)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CKType &&
          runtimeType == other.runtimeType &&
          _name == other._name;

  @override
  int get hashCode => _name.hashCode;

  /// Validates and returns type from string, throws if invalid
  static CKType fromString(String inputString) {
    return _$CKTypeRegistry.fromString(inputString);
  }

  /// Safe version that returns null instead of throwing
  static CKType? fromStringOrNull(String inputString) {
    return _$CKTypeRegistry.fromStringOrNull(inputString);
  }

  /// Check if a type string is valid
  static bool isValid(String inputString) {
    return _$CKTypeRegistry.isValid(inputString);
  }

  /// Get all registered types
  static List<CKType> get allTypes {
    return _$CKTypeRegistry.allTypes;
  }

  /// Get all registered type names (for debugging)
  static List<String> get allTypeNames {
    return _$CKTypeRegistry.allTypeNames;
  }

  /// Default components for this type
  /// Empty for simple types, overridden by composite types
  Set<CKType> get defaultComponents => {};
}

/// Workout composite type
class _WorkoutType extends CKType {
  const _WorkoutType._() : super._('workout');

  // Component types as instance getters
  CKType get distance => CKType._('workout.distance');
  CKType get heartRate => CKType._('workout.heartRate');
  CKType get calories => CKType._('workout.calories');

  // Default components for this composite type
  @override
  Set<CKType> get defaultComponents => {this, distance};
}

/// Blood pressure composite type
class _BloodPressureType extends CKType {
  const _BloodPressureType._() : super._('bloodPressure');

  // Component types as instance getters
  CKType get systolic => CKType._('bloodPressure.systolic');
  CKType get diastolic => CKType._('bloodPressure.diastolic');

  // Default components for this composite type
  @override
  Set<CKType> get defaultComponents => {systolic, diastolic};
}

/// Nutrition composite type
class _NutritionType extends CKType {
  const _NutritionType._() : super._('nutrition');

  // Component types as instance getters
  CKType get calories => CKType._('nutrition.calories');
  CKType get protein => CKType._('nutrition.protein');
  CKType get carbs => CKType._('nutrition.carbs');
  CKType get fat => CKType._('nutrition.fat');

  // Default components for this composite type
  @override
  Set<CKType> get defaultComponents => {calories, protein, carbs, fat};
}
