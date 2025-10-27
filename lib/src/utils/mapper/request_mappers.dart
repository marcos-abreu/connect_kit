import 'package:connect_kit/src/models/ck_record/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';

/// Utility extensions for converting ConnectKit types to platform channel representations.
///
/// These extensions handle the conversion from Dart types to their string representations
/// that can be sent across the platform channel boundary to native iOS and Android code.
extension CKTypeMapping on Set<CKType> {
  /// Expands composite types to their default component types.
  ///
  /// This method handles the hierarchical CKType system by converting parent composite types
  /// (like `CKType.nutrition`, `CKType.bloodPressure`) into their constituent component types.
  ///
  /// **Use case**: This should be called before `mapToRequest()` when preparing types for
  /// permission requests to native platforms.
  Set<CKType> expandCompositeTypes() {
    final expanded = <CKType>{};

    for (final type in this) {
      // Try to get default components - this works for both composite and simple types
      final defaultComponents = type.defaultComponents;

      if (defaultComponents.isNotEmpty) {
        // This is a composite parent type (e.g., CKType.nutrition) - expand it
        expanded.addAll(defaultComponents);
      } else {
        // Simple type (CKType.height) or component type (CKType.nutrition.calories) - Keep as-is
        expanded.add(type);
      }
    }

    return expanded;
  }

  /// Converts a Set of CKType objects to a List of strings for platform channel communication.
  ///
  /// Returns a List of strings that can be sent through Pigeon messages to native iOS/Android code.
  List<String> mapToRequest() {
    return map((type) => type.toString()).toList();
  }
}

/// Utility extensions for converting ConnectKit AccessStatus to platform channel representations.
///
/// These extensions handle the conversion from Dart types to their string representations
/// that can be sent across the platform channel boundary to native iOS and Android code.
extension DataAccessStatus on Map<CKType, Set<CKAccessType>> {
  /// Converts a Map of CKType to CKAccessType mappings to string representation for platform channels.
  ///
  /// This method prepares AccessStatus structure for transmission to native code.
  /// Each CKType is expanded and converted to its string representation, and each CKAccessType is
  /// converted to its name string.
  ///
  /// The resulting structure can be sent through Pigeon messages to native iOS/Android code
  /// for permission status checking.
  ///
  /// Returns a Map where:
  /// - Keys: String representations of CKType objects (e.g., 'nutrition.calories')
  /// - Values: Lists of access type names (e.g., ['read', 'write'])
  Map<String, List<String>> mapToRequest() {
    final result = <String, List<String>>{};

    for (final entry in entries) {
      final typeSet = {entry.key};
      final expandedTypes = typeSet.expandCompositeTypes();
      final accessTypeStrings = entry.value.map((t) => t.name).toList();

      for (final expandedType in expandedTypes) {
        result[expandedType.toString()] = accessTypeStrings;
      }
    }

    return result;
  }
}
