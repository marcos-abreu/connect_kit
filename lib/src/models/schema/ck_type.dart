// IMPORTANT NOTE: This file is also the input file for some generated code
// - `ck_types.g.dart` - type registration to avoid code repetition
// - `ck_record_builder.g.dart` - factory methods for easy record creation
//
// Note: Changes here might trigger auto generated code.

// ignore_for_file: public_member_api_docs
import 'package:connect_kit/src/utils/string_manipulation.dart';

// TODO: document the custom auto generated code here
part 'ck_type.g.dart';

/// Main CKType definition with hierarchical type system
/// NOTE: If chaning anything make sure to sync with mappers (dart/native)
class CKType {
  final String _name;
  final CKValuePattern _pattern;
  final CKTimePattern _timePattern;

  const CKType._(this._name, this._pattern, this._timePattern);

  String get name => _name;
  CKValuePattern get pattern => _pattern;
  CKTimePattern get timePattern => _timePattern;

// === Activity ===
  /// @ck-type-prop: energy:quantity:CKEnergyUnit required
  static const activeEnergy = CKType._(
    'activeEnergy',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // iOS: activeEnergyBurned, Android: ActiveCaloriesBurnedRecord

  /// @ck-type-prop: energy:quantity:CKEnergyUnit required
  static const restingEnergy = CKType._(
    'restingEnergy',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Android: BasalMetabolicRateRecord, iOS: basalEnergyBurned

  /// @ck-type-prop: energy:quantity:CKEnergyUnit required
  static const totalEnergy = CKType._(
    'totalEnergy',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // Sum of resting + active, Android: TotalCaloriesBurnedRecord

  /// @ck-type-prop: speedSamples:samples:CKVelocityUnit required
  static const speed = CKType._(
    'speed',
    CKValuePattern.samples,
    CKTimePattern.interval,
  ); // Both platforms

  /// @ck-type-prop: count:quantity:CKScalarUnit.count required
  static const steps = CKType._(
    'steps',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // Both platforms

  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const distance = CKType._(
    'distance',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // iOS: distanceWalkingRunning, Android: DistanceRecord

  /// @ck-type-prop: count:quantity:CKScalarUnit.count required
  static const floorsClimbed = CKType._(
    'floorsClimbed',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // iOS: flightsClimbed, Android: FloorsClimbedRecord

  /// @ck-type-prop: powerSamples:samples:CKPowerUnit required
  static const runningPower = CKType._(
    'runningPower',
    CKValuePattern.samples,
    CKTimePattern.interval,
  ); // Android: PowerRecords

  /// @ck-type-prop: powerSamples:samples:CKPowerUnit required
  static const cyclingPower = CKType._(
    'cyclingPower',
    CKValuePattern.samples,
    CKTimePattern.interval,
  ); // Android: PowerRecord

  static const workout = _WorkoutType._();

  // Android only
  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const elevation = CKType._(
    'elevation',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // Android: ElevationGainedRecord

  /// @ck-type-prop: powerSamples:samples:CKPowerUnit required
  static const power = CKType._(
    'power',
    CKValuePattern.samples,
    CKTimePattern.interval,
  ); // for many activities

  /// @ck-type-prop: cadenceSamples:samples:CKScalarUnit.count required
  static const cyclingPedalingCadence = CKType._(
    'cyclingPedalingCadence',
    CKValuePattern.samples,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: count:quantity:CKScalarUnit.count required
  static const wheelchairPushes = CKType._(
    'wheelchairPushes',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: intensity:category:CKActivityIntensityType required
  static const activityIntensity = CKType._(
    'activityIntensity',
    CKValuePattern.category,
    CKTimePattern.interval,
  );

  // iOS only
  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const distanceCycling = CKType._(
    'distanceCycling',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const distanceWheelchair = CKType._(
    'distanceWheelchair',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const distanceSwimming = CKType._(
    'distanceSwimming',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const distanceDownhillSnowSports = CKType._(
    'distanceDownhillSnowSports',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: count:quantity:CKScalarUnit.count required
  static const pushCount = CKType._(
    'pushCount',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // Wheelchair pushes

  /// @ck-type-prop: count:quantity:CKScalarUnit.count required
  static const swimmingStrokeCount = CKType._(
    'swimmingStrokeCount',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: speedSamples:samples:CKVelocityUnit required
  static const walkingSpeed = CKType._(
    'walkingSpeed',
    CKValuePattern.samples,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const walkingStepLength = CKType._(
    'walkingStepLength',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const walkingAsymmetry = CKType._(
    'walkingAsymmetry',
    CKValuePattern.multiple,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: percentage:quantity:CKScalarUnit.percent required
  static const walkingDoubleSupportPercentage = CKType._(
    'walkingDoubleSupportPercentage',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  );

  /// @ck-type-prop: speedSamples:samples:CKVelocityUnit required
  static const stairSpeed = CKType._(
    'stairSpeed',
    CKValuePattern.samples,
    CKTimePattern.interval,
  );

  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const sixMinuteWalkDistance = CKType._(
    'sixMinuteWalkDistance',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

// === Body Measurement ===
  /// @ck-type-prop: length:quantity:CKLengthUnit required
  static const height = CKType._(
    'height',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: weight:quantity:CKMassUnit required
  static const weight = CKType._(
    'weight',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: percentage:quantity:CKScalarUnit.percent required
  static const bodyFat = CKType._(
    'bodyFat',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: mass:quantity:CKMassUnit required
  static const leanBodyMass = CKType._(
    'leanBodyMass',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms

  // Android only
  /// @ck-type-prop: mass:quantity:CKMassUnit required
  static const bodyWaterMass = CKType._(
    'bodyWaterMass',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  );

  /// @ck-type-prop: mass:quantity:CKMassUnit required
  static const boneMass = CKType._(
    'boneMass',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  );

  // iOS only (none additional)

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const bodyMassIndex = CKType._(
    'bodyMassIndex',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  ); // iOS: native, Android: would have to be calculated

// === Characteristics ===
  // Android only (none - characteristics not in Health Connect)

  // iOS only

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const biologicalSex = CKType._(
    'biologicalSex',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const bloodType = CKType._(
    'bloodType',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const dateOfBirth = CKType._(
    'dateOfBirth',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const fitzpatrickSkinType = CKType._(
    'fitzpatrickSkinType',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

// === Cycle Tracking ===
  /// @ck-type-prop: flow:category:CKMenstruationFlow required
  static const menstrualFlow = CKType._(
    'menstrualFlow',
    CKValuePattern.category,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: appearance:category:CKCervicalMucusAppearance optional
  /// @ck-type-prop: sensation:category:CKCervicalMucusSensation optional
  static const cervicalMucus = CKType._(
    'cervicalMucus',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  ); // iOS: cervicalMucusQuality

  /// @ck-type-prop: result:category:CKOvulationTestResult required
  static const ovulationTest = CKType._(
    'ovulationTest',
    CKValuePattern.category,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: activity:category:CKSexualActivityProtection required
  static const sexualActivity = CKType._(
    'sexualActivity',
    CKValuePattern.category,
    CKTimePattern.instantaneous,
  ); // Both platforms

  // NOTE: No data properties accepted - value will be ignored by SDK
  /// @ck-type-prop: none:none:none required
  static const intermenstrualBleeding = CKType._(
    'intermenstrualBleeding',
    CKValuePattern.none,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: temperature:quantity:CKTemperatureUnit required
  /// @ck-type-prop: measurementLocation:category:CKBodyTemperatureMeasurementLocation optional
  static const basalBodyTemperature = CKType._(
    'basalBodyTemperature',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // Android only

  // NOTE: No data properties accepted - value will be ignored by SDK
  /// @ck-type-prop: none:none:none required
  static const menstruationPeriod = CKType._(
    'menstruationPeriod',
    CKValuePattern.none,
    CKTimePattern.interval,
  ); // MenstruationPeriodRecord

  // iOS only

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const contraceptive = CKType._(
    'contraceptive',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const lactation = CKType._(
    'lactation',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const pregnancy = CKType._(
    'pregnancy',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const progesteroneTest = CKType._(
    'progesteroneTest',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

// === Vitals ===
  /// @ck-type-prop: rateSamples:samples:CKScalarUnit.count required
  static const heartRate = CKType._(
    'heartRate',
    CKValuePattern.samples,
    CKTimePattern.interval,
  ); // Both platforms

  /// @ck-type-prop: rate:quantity:CKScalarUnit.count required
  static const restingHeartRate = CKType._(
    'restingHeartRate',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms (iOS 11+)

  /// @ck-type-prop: level:quantity:CKBloodGlucoseUnit required
  /// @ck-type-prop: specimenSource:category:CKSpecimenSource optional
  /// @ck-type-prop: mealType:category:CKMealType optional
  /// @ck-type-prop: relationToMeal:category:CKRelationToMeal optional
  static const bloodGlucose = CKType._(
    'bloodGlucose',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: temperature:quantity:CKTemperatureUnit required
  /// @ck-type-prop: measurementLocation:category:CKBodyTemperatureMeasurementLocation optional
  static const bodyTemperature = CKType._(
    'bodyTemperature',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: percentage:quantity:CKScalarUnit.percent required
  static const oxygenSaturation = CKType._(
    'oxygenSaturation',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// @ck-type-prop: rate:quantity:CKScalarUnit.count required
  static const respiratoryRate = CKType._(
    'respiratoryRate',
    CKValuePattern.quantity,
    CKTimePattern.instantaneous,
  ); // Both platforms

  /// TODO: rename the categories field names
  /// @ck-type-prop: vo2Max:quantity:CKScalarUnit.count required
  /// @ck-type-prop: measurementMethod:category:CKVo2MaxMeasurementMethod optional
  static const vo2Max = CKType._(
    'vo2Max',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  ); // Both platforms

  static const bloodPressure = _BloodPressureType._();

  // Android only
  /// @ck-type-prop: deltaSamples:samples:CKTemperatureUnit required
  /// @ck-type-prop: baseline:quantity:CKTemperatureUnit optional
  /// @ck-type-prop: measurementLocation:category:CKSkinTemperatureMeasurementLocation optional
  static const skinTemperature = CKType._(
    'skinTemperature',
    CKValuePattern.multiple,
    CKTimePattern.interval,
  ); // FEATURE_SKIN_TEMPERATURE

  // iOS only

  // static const electrocardiogram = TODO e._('electrocardiogram');

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const heartRateVariability = CKType._(
    'heartRateVariability',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  ); // HRV SDNN

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const peripheralPerfusionIndex = CKType._(
    'peripheralPerfusionIndex',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

// === Nutrition ===
  static const nutrition = _NutritionType._();

  /// @ck-type-prop: volume:quantity:CKVolumeUnit required
  static const waterIntake = CKType._(
    'waterIntake',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  ); // iOS: dietaryWater, Android: HydrationRecord

  // Android only

  // iOS only

  /// @ck-type-prop: count:quantity:CKScalarUnit.count required
  static const numberOfAlcoholicBeverages = CKType._(
    'numberOfAlcoholicBeverages',
    CKValuePattern.quantity,
    CKTimePattern.interval,
  );

// === Sleep ===
  static const sleepSession = _SleepType._();

  // Android only (none - sleep handled by composite)

  // iOS only (none - sleep handled by composite)

// === Wellness ===
  /// @ck-type-prop: mindfulnessSessionType:category:CKMindfulnessSessionType required
  /// @ck-type-prop: notes:label:String optional
  /// @ck-type-prop: title:label:String optional
  static const mindfulSession = CKType._(
    'mindfulSession',
    CKValuePattern.multiple,
    CKTimePattern.interval,
  ); // Both platforms (FEATURE_MINDFULNESS_SESSION)

  // Android only (none additional)

  // iOS only

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const uvExposure = CKType._(
    'uvExposure',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const timeInDaylight = CKType._(
    'timeInDaylight',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

// === Hearing ===
  // Android only (none)

  // iOS only

  // static const audiogram = TODO

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const environmentalAudioExposure = CKType._(
    'environmentalAudioExposure',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

  // TODO: included only notes before checking iOS type
  /// @ck-type-prop: notes:label:String optional
  static const headphoneAudioExposure = CKType._(
    'headphoneAudioExposure',
    CKValuePattern.multiple,
    CKTimePattern.instantaneous,
  );

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

// ============================================================================
// COMPOSITE TYPES
// ============================================================================

/// Workout composite type
class _WorkoutType extends CKType {
  const _WorkoutType._()
      : super._('workout', CKValuePattern.multiple, CKTimePattern.interval);

  // === Workout Records that happened duringSession ===
  // NOTE: If chaning anything make sure to sync with mappers (dart/native)

  CKType get energy => CKType._('workout.energy', CKValuePattern.quantity,
      CKTimePattern.interval); // Energy burned

  CKType get distance => CKType._('workout.distance', CKValuePattern.quantity,
      CKTimePattern.interval); // Distance covered

  CKType get heartRate => CKType._('workout.heartRate', CKValuePattern.samples,
      CKTimePattern.interval); // Heart rate during workout

  CKType get speed => CKType._(
        'workout.speed',
        CKValuePattern.samples,
        CKTimePattern.interval,
      ); // Speed during workout

  CKType get power => CKType._(
        'workout.power',
        CKValuePattern.samples,
        CKTimePattern.interval,
      ); // Power output (cycling/running)
  // CKType get route =>
  //      TODO ._('workout.route', CKValuePattern.quantity); // GPS route

  // Default components for permission requests
  @override
  Set<CKType> get defaultComponents => {this, energy, distance};
}

/// Blood pressure composite type
class _BloodPressureType extends CKType {
  const _BloodPressureType._()
      : super._('bloodPressure', CKValuePattern.multiple,
            CKTimePattern.instantaneous);

  // === BloodPressure ===
  // NOTE: If chaning anything make sure to sync with mappers (dart/native)

  // Component types as instance getters
  CKType get systolic => CKType._('bloodPressure.systolic',
      CKValuePattern.quantity, CKTimePattern.instantaneous);

  CKType get diastolic => CKType._('bloodPressure.diastolic',
      CKValuePattern.quantity, CKTimePattern.instantaneous);

  // Default components for permission requests
  @override
  Set<CKType> get defaultComponents => {systolic, diastolic};
}

/// Sleep composite type
class _SleepType extends CKType {
  const _SleepType._()
      : super._(
            'sleepSession', CKValuePattern.multiple, CKTimePattern.interval);

  // === Sleep Stages ===
  // NOTE: If chaning anything make sure to sync with mappers (dart/native)

  CKType get inBed => CKType._('sleepSession.inBed', CKValuePattern.quantity,
      CKTimePattern.interval); // In bed but may not be asleep

  CKType get asleep => CKType._('sleepSession.asleep', CKValuePattern.quantity,
      CKTimePattern.interval); // Generic asleep (legacy)

  CKType get awake => CKType._('sleepSession.awake', CKValuePattern.quantity,
      CKTimePattern.interval); // Awake during session

  CKType get light => CKType._('sleepSession.light', CKValuePattern.quantity,
      CKTimePattern.interval); // Light sleep

  CKType get deep => CKType._('sleepSession.deep', CKValuePattern.quantity,
      CKTimePattern.interval); // Deep sleep

  CKType get rem => CKType._('sleepSession.rem', CKValuePattern.quantity,
      CKTimePattern.interval); // REM sleep

  CKType get outOfBed => CKType._(
      'sleepSession.outOfBed',
      CKValuePattern.quantity,
      CKTimePattern.interval); // Out of bed (Android only)

  Set<CKType> get all => {inBed, asleep, awake, light, deep, rem, outOfBed};

  // Default components for permission requests (just the session)
  @override
  Set<CKType> get defaultComponents => all;
}

/// Nutrition composite type
class _NutritionType extends CKType {
  const _NutritionType._()
      : super._('nutrition', CKValuePattern.multiple, CKTimePattern.interval);

  // === Nutrition ===
  // NOTE: If chaning anything make sure to sync with mappers (dart/native)

  /// Energy content (calories/kilojoules)
  CKType get energy => CKType._(
      'nutrition.energy', CKValuePattern.quantity, CKTimePattern.interval);

  // === Macro Nutrients ===
  CKType get protein => CKType._(
      'nutrition.protein', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get carbs => CKType._('nutrition.carbs', CKValuePattern.quantity,
      CKTimePattern.interval); // Total carbohydrates

  CKType get fat => CKType._('nutrition.fat', CKValuePattern.quantity,
      CKTimePattern.interval); // Total fat

  CKType get fiber => CKType._('nutrition.fiber', CKValuePattern.quantity,
      CKTimePattern.interval); // Dietary fiber

  CKType get sugar => CKType._('nutrition.sugar', CKValuePattern.quantity,
      CKTimePattern.interval); // Total sugars

  // === Fat Breakdown ===
  CKType get saturatedFat => CKType._('nutrition.saturatedFat',
      CKValuePattern.quantity, CKTimePattern.interval);

  CKType get unsaturatedFat => CKType._('nutrition.unsaturatedFat',
      CKValuePattern.quantity, CKTimePattern.interval);

  CKType get monounsaturatedFat => CKType._('nutrition.monounsaturatedFat',
      CKValuePattern.quantity, CKTimePattern.interval);

  CKType get polyunsaturatedFat => CKType._('nutrition.polyunsaturatedFat',
      CKValuePattern.quantity, CKTimePattern.interval);

  CKType get transFat => CKType._(
      'nutrition.transFat', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get cholesterol => CKType._(
      'nutrition.cholesterol', CKValuePattern.quantity, CKTimePattern.interval);

  // === Minerals ===
  CKType get calcium => CKType._(
      'nutrition.calcium', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get chloride => CKType._(
      'nutrition.chloride', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get chromium => CKType._(
      'nutrition.chromium', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get copper => CKType._(
      'nutrition.copper', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get iodine => CKType._(
      'nutrition.iodine', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get iron => CKType._(
      'nutrition.iron', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get magnesium => CKType._(
      'nutrition.magnesium', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get manganese => CKType._(
      'nutrition.manganese', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get molybdenum => CKType._(
      'nutrition.molybdenum', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get phosphorus => CKType._(
      'nutrition.phosphorus', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get potassium => CKType._(
      'nutrition.potassium', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get selenium => CKType._(
      'nutrition.selenium', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get sodium => CKType._(
      'nutrition.sodium', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get zinc => CKType._(
      'nutrition.zinc', CKValuePattern.quantity, CKTimePattern.interval);

  // === Vitamins ===
  CKType get vitaminA => CKType._(
      'nutrition.vitaminA', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get vitaminB6 => CKType._(
      'nutrition.vitaminB6', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get vitaminB12 => CKType._(
      'nutrition.vitaminB12', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get vitaminC => CKType._(
      'nutrition.vitaminC', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get vitaminD => CKType._(
      'nutrition.vitaminD', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get vitaminE => CKType._(
      'nutrition.vitaminE', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get vitaminK => CKType._(
      'nutrition.vitaminK', CKValuePattern.quantity, CKTimePattern.interval);

  CKType get thiamin => CKType._('nutrition.thiamin', CKValuePattern.quantity,
      CKTimePattern.interval); // B1

  CKType get riboflavin => CKType._('nutrition.riboflavin',
      CKValuePattern.quantity, CKTimePattern.interval); // B2

  CKType get niacin => CKType._('nutrition.niacin', CKValuePattern.quantity,
      CKTimePattern.interval); // B3

  CKType get folate => CKType._('nutrition.folate', CKValuePattern.quantity,
      CKTimePattern.interval); // B9

  CKType get biotin => CKType._('nutrition.biotin', CKValuePattern.quantity,
      CKTimePattern.interval); // B7

  CKType get pantothenicAcid => CKType._('nutrition.pantothenicAcid',
      CKValuePattern.quantity, CKTimePattern.interval); // B5

  // === Others ===
  CKType get caffeine => CKType._('nutrition.caffeine', CKValuePattern.quantity,
      CKTimePattern.interval); // iOS only

  // Default components for permission requests (energy & macros)
  @override
  Set<CKType> get defaultComponents => {
        energy,
        protein,
        carbs,
        fat,
        fiber,
        sugar,
      };
}

/// Time pattern for health records
enum CKTimePattern {
  instantaneous, // Single time point (e.g., weight measurement)
  interval, // Time range (e.g., steps over a day)
}

/// Value pattern for health data
enum CKValuePattern {
  quantity, // Single numeric value with unit (e.g., steps count)
  samples, // List of samples with unit (e.g., heart rate over time)
  category, // Enum value (unitless) (e.g., biological sex)
  multiple, // Map of properties with different patterns (e.g., blood pressure)
  label, // String or custom type value (e.g., notes, title)
  none, // No value accepted (e.g., intermenstrual bleeding)
}
