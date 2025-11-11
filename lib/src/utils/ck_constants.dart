// ignore_for_file: non_constant_identifier_names
// ignore_for_file:  public_member_api_docs

/// TODO: add documentation
class CKConstants {
  static final dartValidationError = 'DartValidationError';

  // NOTE: injected record differentiators that aids on native record processing
  //       This should be kept in sync with record kind in native files
  static final recordKindDataRecord = 'data';
  static final recordKindBloodPressure = 'bloodPressure';
  static final recordKindWorkout = 'workout';
  static final recordKindNutrition = 'nutrition';
  static final recordKindSleepSession = 'sleepSession';
  static final recordKindAudiogram = 'audiogram';
  static final recordKindEcg = 'ecg';
}
