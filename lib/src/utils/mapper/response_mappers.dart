/// TODO: add documentation
extension RawPigeonResponseMapping on Map<Object?, Object?>? {
  /// TODO: add documentation
  Map<String, Map<String, String>>? normalizeAsDataAccess() {
    final input = this as Map;

    // 1. Get the entries from the raw input map.
    // 2. Filter out entries where the outer key isn't a String or the value isn't a Map.
    final validEntries = input.entries
        .where((entry) => entry.key is String && entry.value is Map);

    // 3. Use Map.fromEntries() to build the final, materialized map in a single pass.
    return Map.fromEntries(
      validEntries.map((entry) {
        final outerKey = entry.key as String;
        final rawInnerMap = entry.value as Map;

        // 4. Transform the inner map's entries and eagerly materialize them
        //    into a new concrete Map<String, String>.
        final innerMapCasted = Map<String, String>.fromEntries(
          rawInnerMap.entries.map((innerEntry) {
            // Safely convert all inner keys and values to String
            return MapEntry(
              innerEntry.key.toString(),
              innerEntry.value.toString(),
            );
          }),
        );

        return MapEntry(outerKey, innerMapCasted);
      }),
    );
  }
}
