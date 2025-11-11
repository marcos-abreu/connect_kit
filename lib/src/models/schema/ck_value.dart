import 'package:connect_kit/src/models/schema/ck_unit.dart';

/// Base class for all health data values.
///
/// This sealed class hierarchy ensures type safety while supporting
/// different value patterns: quantity, category, samples, and complex values.
sealed class CKValue<T> {
  /// The underlying value of this health data measurement.
  final T value;

  /// The unit of measurement, or null for unitless values.
  final CKUnit? unit;

  /// Base class constructor
  const CKValue(this.value, this.unit);

  /// Performs pattern-matching on this [CKValue] to extract its concrete value type.
  ///
  /// This method lets you safely “unwrap” the underlying value without manually
  /// checking its runtime type (e.g. using `is CKQuantityValue`).
  ///
  /// Only the matching callback will be invoked — for example, if `this` is a
  /// [CKCategoryValue], only [onCategory] will be called.
  ///
  /// Each callback receives the strongly-typed instance of its respective value type.
  ///
  /// If no callback is provided for the current value type, `null` is returned.
  ///
  /// Example:
  /// ```dart
  /// final result = record.data.unwrap(
  ///   onQuantity: (q) => 'Quantity: ${q.value} ${q.unit}',
  ///   onCategory: (c) => 'Category: ${c.label}',
  /// );
  ///
  /// // Returns a String only if one of the provided callbacks matches,
  /// // otherwise null.
  /// print(result);
  /// ```
  ///
  /// Returns `null` if no matching callback is supplied.
  R? unwrap<R>({
    R Function(CKLabelValue value)? onLabel,
    R Function(CKQuantityValue value)? onQuantity,
    R Function(CKCategoryValue value)? onCategory,
    R Function(CKMultipleValue value)? onMultiple,
    R Function(CKSamplesValue value)? onSamples,
  }) {
    return switch (this) {
      CKLabelValue() => onLabel?.call(this as CKLabelValue),
      CKQuantityValue() => onQuantity?.call(this as CKQuantityValue),
      CKCategoryValue() => onCategory?.call(this as CKCategoryValue),
      CKMultipleValue() => onMultiple?.call(this as CKMultipleValue),
      CKSamplesValue() => onSamples?.call(this as CKSamplesValue),
    };
  }

  /// Performs pattern-matching on this [CKValue] and returns a result for all cases.
  ///
  /// Works like [unwrap], but **requires** a fallback handler ([orElse]) to be
  /// called when no specific callback is provided for the current value type.
  ///
  /// This is useful when you always want a non-nullable return value or want to
  /// ensure every case is handled.
  ///
  /// Example:
  /// ```dart
  /// final label = record.data.unwrapOrElse(
  ///   onQuantity: (q) => 'Quantity: ${q.value}',
  ///   onCategory: (c) => 'Category: ${c.label}',
  ///   orElse: (v) => 'Unsupported value type: ${v.runtimeType}',
  /// );
  ///
  /// print(label); // Always returns a String
  /// ```
  ///
  /// Returns the result of the matching callback, or the result of [orElse] if
  /// no specific handler is provided.
  R unwrapOrElse<R>({
    R Function(CKLabelValue value)? onLabel,
    R Function(CKQuantityValue value)? onQuantity,
    R Function(CKCategoryValue value)? onCategory,
    R Function(CKMultipleValue value)? onMultiple,
    R Function(CKSamplesValue value)? onSamples,
    required R Function(CKValue value) orElse,
  }) {
    return switch (this) {
      CKLabelValue() => onLabel?.call(this as CKLabelValue) ?? orElse(this),
      CKQuantityValue() =>
        onQuantity?.call(this as CKQuantityValue) ?? orElse(this),
      CKCategoryValue() =>
        onCategory?.call(this as CKCategoryValue) ?? orElse(this),
      CKMultipleValue() =>
        onMultiple?.call(this as CKMultipleValue) ?? orElse(this),
      CKSamplesValue() =>
        onSamples?.call(this as CKSamplesValue) ?? orElse(this),
    };
  }
}

/// Text health data value (unitless)
///
/// Represents a simple test such as notes or title
class CKLabelValue extends CKValue<String> {
  /// Creates a text value with the specified string value.
  ///
  /// Text are unitless, so no unit parameter is required.
  CKLabelValue(value) : super(value, null);
}

/// Numeric health data value with unit.
///
/// Represents measurements like weight (72.5 kg), heart rate (78 bpm),
/// or distance (5000 m).
class CKQuantityValue extends CKValue<num> {
  /// Creates a quantity value with the specified numeric value and unit.
  ///
  /// The unit must be compatible with the value type (e.g., mass units for weight).
  CKQuantityValue(super.value, CKUnit super.unit);
}

/// Categorical health data value (unitless).
///
/// Represents enum values such as menstrual flow (medium),
/// sleep stage (deep), or mindfulness type (meditation).
class CKCategoryValue extends CKValue<Enum> {
  /// Creates a category value with the specified enum value.
  ///
  /// Categories are unitless, so no unit parameter is required.
  CKCategoryValue(value) : super(value, null);
}

/// Health data value with multiple named fields.
///
/// Represents records that have multiple related measurements,
/// such as body temperature with measurement location
class CKMultipleValue extends CKValue<Map<String, CKValue<Object?>>> {
  /// Creates a multi-value record with the specified map of field names to values.
  ///
  /// Each value in the map should be one of the specific [CKValue] subtypes:
  /// [CKQuantityValue], [CKCategoryValue], [CKSamplesValue], or nested [CKMultipleValue].
  /// The multi-value record itself is unitless, but each contained value may have its own unit.
  CKMultipleValue(value) : super(value, null);

  /// Gets a quantity field by name, or null if not present or wrong type.
  CKQuantityValue? quantity(String key) => value[key] as CKQuantityValue?;

  /// Gets a category field by name, or null if not present or wrong type.
  CKCategoryValue? category(String key) => value[key] as CKCategoryValue?;

  /// Gets the numeric value of a quantity field, or null if not present or wrong type.
  num? numericValue(String key) => (value[key] as CKQuantityValue?)?.value;

  /// Gets the string value of a category field, or null if not present or wrong type.
  Enum? stringValue(String key) => (value[key] as CKCategoryValue?)?.value;
}

/// Time-series health data value with multiple samples.
///
/// Represents measurements that change over time, such as heart rate samples
/// during a workout or speed samples during a run.
class CKSamplesValue extends CKValue<List<CKSample>> {
  /// Creates a samples value with the specified list of time-series samples.
  ///
  /// All samples in the list should use the same unit type for consistency
  /// (e.g., all heart rate samples in beats per minute).
  CKSamplesValue(super.value, CKUnit super.unit);

  /// Gets all numeric values from the samples list.
  ///
  /// Returns a [List] of [num] values containing all samples that are quantity values.
  /// Samples that are not quantity values are filtered out.
  List<num> get numericValues => value
      .where((s) => s.value is CKQuantityValue)
      .map((s) => (s.value as CKQuantityValue).value)
      .toList();

  /// Gets the numeric sample at the specified index, or null if out of bounds or wrong type.
  ///
  /// Returns a [CKQuantityValue] if the index is valid and the sample contains a quantity value,
  /// otherwise returns null.
  CKQuantityValue? numericSampleAt(int index) {
    if (index >= 0 && index < value.length) {
      return value[index].value as CKQuantityValue?;
    }
    return null;
  }
}

/// A single time-point measurement in a time-series health record.
///
/// Samples are used within [CKSamplesValue] to represent measurements
/// that change over time, such as heart rate during a workout or
/// speed during a run.
class CKSample {
  /// The measured value at this time point.
  final num value;

  /// The time offset from the record's start time.
  ///
  /// For instantaneous records, this represents the absolute time.
  /// For interval records, this represents the time within the interval.
  final Duration time;

  /// Creates a sample with the specified time and value.
  CKSample(this.value, this.time);
}

final test = CKUnit.energy.joule;
final test2 = CKEnergyUnit.joule;
