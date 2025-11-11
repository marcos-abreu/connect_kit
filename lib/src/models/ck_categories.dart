/// Body temperature measurement location classification
enum CKBodyTemperatureMeasurementLocation {
  armpit,
  ear,
  finger,
  forehead,
  mouth,
  rectum,
  artery,
  toe,
  vagina,
  wrist,
  unknown,
}

/// Specimen source classification
enum CKSpecimenSource {
  capillaryBlood,
  interstitialFluid,
  plasma,
  serum,
  tears,
  blood,
  unknown,
}

/// Meal type classification
enum CKMealType {
  /// Breakfast meal
  breakfast,

  /// Lunch meal
  lunch,

  /// Dinner meal
  dinner,

  /// Snack between meals
  snack,

  /// Unknown or unspecified meal type
  unknown;
}

/// Relation to meal classification
enum CKRelationToMeal {
  afterMeal,
  beforeMeal,
  fasting,
  general,
  unknown,
}

/// Vo2Max measurement method classification
enum CKVo2MaxMeasurementMethod {
  cooperTest,
  rateRatio,
  metabolicCart,
  multistageFitnessTest,
  fitnessTest,
  other,
}

/// Skin temperature measurement location classification
enum CKSkinTemperatureMeasurementLocation {
  finger,
  toe,
  wrist,
  unknown,
}

/// Mindfulness session type classification
enum CKMindfulnessSessionType {
  breathing,
  meditation,
  movement,
  music,
  unguided,
  unknown,
}

/// Menstruation flow classification
enum CKMenstruationFlow {
  heavy,
  light,
  medium,
  unknown,
}

/// Cervical mucus appearance classification
enum CKCervicalMucusAppearance {
  dry,
  sticky,
  creamy,
  watery,
  eggWhite,
  unusual,
  unknown,
}

/// Cervical mucus sensation classification
enum CKCervicalMucusSensation {
  light,
  medium,
  heavy,
  unknown,
}

/// Ovulation test result classification
enum CKOvulationTestResult {
  high,
  negative,
  positive,
  inconclusive,
}

/// Sexual activity protection use classification
enum CKSexualActivityProtection {
  protected,
  unprotected,
  unknown,
}

/// Activity intensity type classification
enum CKActivityIntensityType {
  moderate,
  vigorous,
}
