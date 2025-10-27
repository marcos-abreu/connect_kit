/// Safely converts a string to an enum value
///  Returns the corresponding enum value, with fallback to provided default value (or last value)
///
///
/// [values] is the list of all enum values (e.g., `HealthSdkStatus.values`)
/// [name] is the string representation of the enum value to find
/// [defaultValue] is the value returned if [name] does not match any enum value
/// If [defaultValue] is omitted, the **last** item in the [values] list is returned
///
/// Returns the corresponding enum value, or the calculated default value if the name is not found
T enumFromStringOrDefault<T extends Enum>(List<T> values, String name,
    [T? defaultValue]) {
  final effectiveDefault =
      defaultValue ?? values.last; // Use the provided default, or the last item

  try {
    return values.firstWhere(
      (v) => v.name == name,
      orElse: () => effectiveDefault,
    );
  } catch (e) {
    return effectiveDefault;
  }
}

/// Safely converts a string to an enum value
///
/// [values] is the list of all enum values (e.g., `HealthType.values`)
/// [name] is the string representation of the enum value to find
/// Returns the corresponding enum value, or throws an [ArgumentError] if not found
T enumFromString<T extends Enum>(
  List<T> values,
  String name,
) {
  try {
    return values.firstWhere((v) => v.name == name);
  } catch (e) {
    throw ArgumentError('No enum value found for name: $name');
  }
}

/// Safely converts a string to an enum value, returning null if not found
///
/// [values] is the list of all enum values (e.g., `HealthType.values`)
/// [name] is the string representation of the enum value to find
/// Returns the corresponding enum value, or null if not found
T? enumFromStringOrNull<T extends Enum>(
  List<T> values,
  String name,
) {
  try {
    return values.firstWhere((v) => v.name == name);
  } catch (e) {
    return null;
  }
}
