part 'ck_unit.g.dart';

/// Base unit validation extension
///
/// @ck-base-unit: symbol:String
extension CKUnitValidation on CKUnit {
  /// Validates that the given [value] is valid for this unit.
  ///
  /// Throws [ArgumentError] if the value is invalid.
  ///
  /// This method should be overridden by specific unit classes to provide
  /// unit-specific validation logic.
  void validateValue(num value) {
    if (value <= 0) {
      throw ArgumentError('Unit value must be positive. Got: $value');
    }
  }
}

/// Mass unit validation extension
///
/// @ck-unit: kilogram:kg, gram:g, milligram:mg, pound:lb, ounces:oz
extension CKMassUnitValidation on CKMassUnit {}

/// Length unit validation extension
///
/// @ck-unit: kilometer:km, meter:m, mile:mi , foot:ft, inch:in
extension CKLengthUnitValidation on CKLengthUnit {}

/// Energy unit validation extension
///
/// @ck-unit: kilocalorie:kcal, calorie:cal, kilojoule:kJ, joule:J
extension CKEnergyUnitValidation on CKEnergyUnit {}

/// Power unit validation extension
///
/// @ck-unit: watt:W, kilocaloriesPerDay:kcal/day
extension CKPowerUnitValidation on CKPowerUnit {}

/// Pressure unit validation extension
///
/// @ck-unit: millimetersOfMercury:mmHg, decibelPressure:dBA
extension CKPressureUnitValidation on CKPressureUnit {}

/// Temperature unit validation extension
///
/// @ck-unit: celsius:C, fahrenheit:F
extension CKTemperatureUnitValidation on CKTemperatureUnit {}

/// Frequency unit validation extension
///
/// @ck-unit: hertz:Hz
extension CKFrequencyUnitValidation on CKFrequencyUnit {}

/// Velocity unit validation extension
///
/// @ck-unit: metersPerSecond:m/s, kilometersPerHour:kph, milesPerHour:mph
extension CKVelocityUnitValidation on CKVelocityUnit {}

/// Volume unit validation extension
///
/// @ck-unit: liter:L, milliliter:mL, fluidOunceUS:fl. oz
extension CKVolumeUnitValidation on CKVolumeUnit {}

/// Scalar unit validation extension
///
/// @ck-unit: count:count, percent:%
extension CKScalarUnitValidation on CKScalarUnit {}

/// Blood glucose unit validation extension
///
/// @ck-unit: millimolesPerLiter:mmol/L, milligramsPerDeciliter:mg/dL
extension CKBloodGlucoseUnitValidation on CKBloodGlucoseUnit {}

/// Time unit validation extension
///
/// @ck-unit: second:s, minute:m, hour:h, day:d
extension CKTimeUnitValidation on CKTimeUnit {}

/// Compound unit validation extension
///
/// @ck-unit: beatsPerMin:bpm
extension CKCompoundUnitValidation on CKCompoundUnit {}
