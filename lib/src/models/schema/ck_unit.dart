part 'ck_unit.g.dart';

/// TODO: add documentation
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

/// TODO: add documentation
/// @ck-unit: kilogram:kg, gram:g, milligram:mg, pound:lb, ounces:oz
extension CKMassUnitValidation on CKMassUnit {}

/// TODO: add documentation
/// @ck-unit: kilometer:km, meter:m, mile:mi , foot:ft, inch:in
extension CKLengthUnitValidation on CKLengthUnit {}

/// TODO: add documentation
/// @ck-unit: kilocalorie:kcal, calorie:cal, kilojoule:kJ, joule:J
extension CKEnergyUnitValidation on CKEnergyUnit {}

/// TODO: add documentation
/// @ck-unit: watt:W, kilocaloriesPerDay:kcal/day
extension CKPowerUnitValidation on CKPowerUnit {}

/// TODO: add documentation
/// @ck-unit: millimetersOfMercury:mmHg
extension CKPressureUnitValidation on CKPressureUnit {}

/// TODO: add documentation
/// @ck-unit: celsius:C, fahrenheit:F
extension CKTemperatureUnitValidation on CKTemperatureUnit {}

/// TODO: add documentation
/// @ck-unit: hertz:Hz
extension CKFrequencyUnitValidation on CKFrequencyUnit {}

/// TODO: add documentation
/// @ck-unit: metersPerSecond:m/s, kilometersPerHour:kph, milesPerHour:mph
extension CKVelocityUnitValidation on CKVelocityUnit {}

/// TODO: add documentation
/// @ck-unit: liter:L, milliliter:mL, fluidOunceUS:fl. oz
extension CKVolumeUnitValidation on CKVolumeUnit {}

/// TODO: add documentation
/// @ck-unit: count:count, percent:%
extension CKScalarUnitValidation on CKScalarUnit {}

/// TODO: add documentation
/// @ck-unit: millimolesPerLiter:mmol/L, milligramsPerDeciliter:mg/dL
extension CKBloodGlucoseUnitValidation on CKBloodGlucoseUnit {}
