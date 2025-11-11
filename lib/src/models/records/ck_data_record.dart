import 'package:connect_kit/src/models/records/ck_record.dart';
import 'package:connect_kit/src/models/schema/ck_source.dart';
import 'package:connect_kit/src/models/schema/ck_value.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/schema/ck_unit.dart';

/// Universal health data record with type, value, and unit
///
/// Handles both quantity data (steps, weight, heart rate) and
/// category data (sleep stage, menstrual flow) in a unified model.
///
/// **Design Philosophy:**
/// - Dart: Single unified model (simpler API)
/// - Native: Split to HKQuantitySample/HKCategorySample (iOS) or
///           appropriate Record class (Android) during encoding
class CKDataRecord extends CKRecord {
  /// Health data type identifier (e.g., "steps", "weight", "sleepAnalysis")
  final CKType type;

  /// The measurement, category or samples data
  final CKValue data;

  /// Creates a universal health data record with type, value, and temporal information.
  ///
  /// Validates that the [value] is compatible with the [type]'s pattern, temporal
  /// constraints, data integrity and value against its unit
  CKDataRecord({
    required this.type,
    required this.data,
    required super.startTime,
    required super.endTime,
    super.startZoneOffset,
    super.endZoneOffset,
    super.source,
    super.id,
  })  : assert(startTime.isUtc, 'startTime must be UTC'),
        assert(endTime.isUtc, 'endTime must be UTC'),
        assert(
          !startTime.isAfter(endTime),
          'startTime cannot be after endTime',
        ) {
    // Validate data compatibility with type pattern
    switch (type.pattern) {
      case CKValuePattern.quantity:
        if (data is! CKQuantityValue) {
          throw ArgumentError(
              'Type "${type.name}" has quantity pattern and requires CKQuantityValue, '
              'but received ${data.runtimeType}.');
        }
        break;

      case CKValuePattern.label || CKValuePattern.none:
        if (data is! CKLabelValue) {
          throw ArgumentError(
              'Type "${type.name}" has label/none pattern and requires CKLabelValue, '
              'but received ${data.runtimeType}.');
        }
        break;

      case CKValuePattern.samples:
        if (data is! CKQuantityValue && data is! CKSamplesValue) {
          throw ArgumentError(
              'Type "${type.name}" has samples pattern and requires CKQuantityValue '
              'or CKSamplesValue, but received ${data.runtimeType}.');
        }
        break;

      case CKValuePattern.category:
        if (data is! CKCategoryValue) {
          throw ArgumentError(
              'Type "${type.name}" has category pattern and requires CKCategoryValue, '
              'but received ${data.runtimeType}.');
        }
        break;

      case CKValuePattern.multiple:
        if (data is! CKMultipleValue) {
          throw ArgumentError(
              'Type "${type.name}" has multiple pattern and requires CKMultipleValue, '
              'but received ${data.runtimeType}.');
        }
        break;
    }

    // Additional validation for samples values
    if (data is CKSamplesValue) {
      if (data.value.isEmpty) {
        throw ArgumentError('CKSamplesValue cannot be empty');
      }
      // Validate all samples have the same unit as the parent
      final parentUnit = data.unit;
      for (final sample in data.value) {
        if (sample.value.unit != parentUnit) {
          throw ArgumentError(
            'All samples must have the same unit as the parent CKSamplesValue',
          );
        }
      }
    }

    // Validate instantaneous records have same start/end time
    if (startTime == endTime) {
      // Instantaneous record validation could go here if needed
    }

    // Validate unit-specific value constraints
    _validateCKValueUnits(data);
  }

  /// Create instantaneous data record (weight, heart rate snapshot)
  factory CKDataRecord.instantaneous({
    required CKType type,
    required CKValue data,
    required DateTime time,
    Duration? zoneOffset,
    required CKSource source,
  }) =>
      CKDataRecord(
        type: type,
        data: data,
        startTime: time,
        endTime: time,
        startZoneOffset: zoneOffset,
        endZoneOffset: zoneOffset,
        source: source,
      );

  /// Create interval data record (steps over 15 minutes)
  factory CKDataRecord.interval({
    required CKType type,
    required CKValue data,
    required DateTime startTime,
    required DateTime endTime,
    Duration? startZoneOffset,
    Duration? endZoneOffset,
    required CKSource source,
  }) =>
      CKDataRecord(
        type: type,
        data: data,
        startTime: startTime,
        endTime: endTime,
        startZoneOffset: startZoneOffset,
        endZoneOffset: endZoneOffset,
        source: source,
      );
}

/// Gets the quantity value from a record with [CKValuePattern.quantity] pattern.
///
/// Returns the [CKValue] if the record has a quantity pattern and contains
/// a valid [CKQuantityValue], otherwise returns null.
///
/// Use this for cumulative metrics like steps, weight, calories, distance, etc.
CKValue? getQuantityValue(CKRecord record) {
  if (record is! CKDataRecord) return null;
  if (record.type.pattern != CKValuePattern.quantity) return null;
  return record.data;
}

/// Gets the samples value from a record with [CKValuePattern.samples] pattern.
///
/// Returns the [CKValue] if the record has a samples pattern and contains
/// either a [CKQuantityValue] (single measurement) or [CKSamplesValue] (time series),
/// otherwise returns null.
///
/// Use this for time-series metrics like heart rate, speed, power, etc.
CKValue? getSamplesValue(CKRecord record) {
  if (record is! CKDataRecord) return null;
  if (record.type.pattern != CKValuePattern.samples) return null;
  return record.data;
}

/// Gets the category value from a record with [CKValuePattern.category] pattern.
///
/// Returns the [CKValue] if the record has a category pattern and contains
/// a valid [CKCategoryValue], otherwise returns null.
///
/// Use this for text/enum metrics like sleep stage, menstrual flow, etc.
CKValue? getCategoryValue(CKRecord record) {
  if (record is! CKDataRecord) return null;
  if (record.type.pattern != CKValuePattern.category) return null;
  return record.data;
}

/// Gets the multiple value from a record with [CKValuePattern.multiple] pattern.
///
/// Returns the [CKValue] if the record has a multiple pattern and contains
/// a valid [CKMultipleValue], otherwise returns null.
///
/// Use this for complex metrics like blood pressure, nutrition, workout, etc.
CKValue? getMultipleValue(CKRecord record) {
  if (record is! CKDataRecord) return null;
  if (record.type.pattern != CKValuePattern.multiple) return null;
  return record.data;
}

// -- Helpers --

/// Recursively validates all unit values in a CKValue structure.
void _validateCKValueUnits(CKValue value) {
  if (value is CKQuantityValue) {
    value.unit?.validateValue(value.value);
  } else if (value is CKSamplesValue) {
    final unit = value.unit;
    if (unit != null) {
      for (final sample in value.value) {
        unit.validateValue(sample.value);
      }
    }
  } else if (value is CKMultipleValue) {
    for (final entry in value.value.values) {
      _validateCKValueUnits(entry);
    }
  }
  // CKCategoryValue has no unit, so no validation needed
}
