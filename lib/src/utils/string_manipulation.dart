/// Converts a camelCase string (e.g., 'basalMetabolicRate') into
/// a Title Case display name (e.g., 'Basal Metabolic Rate').
String camelCaseToTitleCase(String name) {
  // Insert spaces: 'basalMetabolicRate' -> 'basal metabolic rate'
  final String spacedName = name.replaceAllMapped(
    RegExp(r'(?<=[a-z])(?=[A-Z])'),
    (Match m) => ' ',
  );

  // Title Case: Split the words, capitalize each one, and join them back.
  return spacedName.split(' ').map((word) => capitalizeWord(word)).join(' ');
}

/// Converts a single word to start with a capital letter.
String capitalizeWord(String word) {
  if (word.isEmpty) return '';
  // Capitalizes the first character and ensures the rest are lowercase
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}
