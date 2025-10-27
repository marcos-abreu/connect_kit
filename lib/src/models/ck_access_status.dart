import 'package:connect_kit/src/logging/ck_logger.dart';
import 'package:connect_kit/src/models/ck_record/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/ck_permission_status.dart';

/// The structure returned by [checkPermissions].
/// Note: 'history' and 'background' statuses are app-wide, not per-data type
class CKAccessStatus {
  /// Use static const and SCREAMING_SNAKE_CASE
  static const String logTag = 'CK_ACCESS_STATUS';

  /// App-wide status for accessing historical data (Android only)
  final CKPermissionStatus historyAccess;

  /// App-wide status for accessing data in the background (Android only)
  final CKPermissionStatus backgroundAccess;

  /// The per-data type and per-access type statuses
  final Map<CKType, Map<CKAccessType, CKPermissionStatus>> dataAccess;

  /// Creates a new CKAccessStatus instance
  CKAccessStatus({
    required this.dataAccess,
    this.historyAccess = CKPermissionStatus.unknown,
    this.backgroundAccess = CKPermissionStatus.unknown,
  });

  /// Creates a CKAccessStatus from a message returned by the native platform
  // factory CKAccessStatus.fromMessage(
  //   Map<String, Map<String, String>>? dataAccessMap, {
  //   String? historyAccessString,
  //   String? backgroundAccessString,
  // }) {
  //   // Parse history access status (Android only)
  //   final historyAccess = historyAccessString != null
  //       ? CKPermissionStatus.fromString(historyAccessString)
  //       : CKPermissionStatus.unknown;

  //   // Parse background access status (Android only)
  //   final backgroundAccess = backgroundAccessString != null
  //       ? CKPermissionStatus.fromString(backgroundAccessString)
  //       : CKPermissionStatus.unknown;

  //   // Convert data access map from strings to enums
  //   final Map<CKType, Map<CKAccessType, CKPermissionStatus>> dataAccess = {};

  //   if (dataAccessMap != null) {
  //     for (final entry in dataAccessMap.entries) {
  //       try {
  //         // Parse the health type from string key
  //         final healthType = CKType.fromString(entry.key);

  //         // Parse the access types and their statuses
  //         final Map<CKAccessType, CKPermissionStatus> accessTypes = {};
  //         for (final accessEntry in entry.value.entries) {
  //           final accessType = CKAccessType.fromString(accessEntry.key);
  //           final permissionStatus =
  //               CKPermissionStatus.fromString(accessEntry.value);
  //           accessTypes[accessType] = permissionStatus;
  //         }

  //         dataAccess[healthType] = accessTypes;
  //       } catch (e) {
  //         // Skip invalid health types but continue processing others
  //         continue;
  //       }
  //     }
  //   }

  //   return CKAccessStatus(
  //     dataAccess: dataAccess,
  //     historyAccess: historyAccess,
  //     backgroundAccess: backgroundAccess,
  //   );
  // }

  factory CKAccessStatus.fromMessage(
    Map<String, Map<String, String>>? dataAccessMap, {
    String? historyAccessString,
    String? backgroundAccessString,
  }) {
    // Parse history access status
    final historyAccess = historyAccessString != null
        ? CKPermissionStatus.fromString(historyAccessString)
        : CKPermissionStatus.unknown;

    final backgroundAccess = backgroundAccessString != null
        ? CKPermissionStatus.fromString(backgroundAccessString)
        : CKPermissionStatus.unknown;

    // Convert data access map from strings to enums
    final dataAccess = dataAccessMap == null
        ? <CKType,
            Map<CKAccessType,
                CKPermissionStatus>>{} // Return empty map if input is null
        : Map.fromEntries(
            // Create the final map in one operation
            dataAccessMap.entries.map((outerEntry) {
              try {
                // 1. Parse the health type from string key (throws if invalid)
                final healthType = CKType.fromString(outerEntry.key);

                // 2. Parse the inner map using a functional approach
                final innerMap = Map.fromEntries(
                  outerEntry.value.entries.map((innerEntry) {
                    final accessType = CKAccessType.fromString(innerEntry.key);
                    final permissionStatus =
                        CKPermissionStatus.fromString(innerEntry.value);
                    return MapEntry(accessType, permissionStatus);
                  }),
                );

                // 3. Return the successfully created entry
                return MapEntry(healthType, innerMap);
              } catch (error) {
                CKLogger.w(
                  CKAccessStatus.logTag,
                  'Skipping Data Access Item. Parsing failed for entry '
                  'key: ${outerEntry.key} and value: ${outerEntry.value}. '
                  'Error Type: ${error.runtimeType}',
                  error,
                );

                return null; // to skip in final filter
              }
            }).whereType<
                MapEntry<
                    CKType,
                    Map<CKAccessType,
                        CKPermissionStatus>>>(), // Filter out nulls
          );

    return CKAccessStatus(
      dataAccess: dataAccess,
      historyAccess: historyAccess,
      backgroundAccess: backgroundAccess,
    );
  }

  /// Gets the permission status for a specific health type and access type
  CKPermissionStatus getStatus(CKType type, CKAccessType accessType) {
    return dataAccess[type]?[accessType] ?? CKPermissionStatus.notDetermined;
  }

  /// Checks if a specific health type has read access
  bool hasReadAccess(CKType type) {
    return getStatus(type, CKAccessType.read).isGranted;
  }

  /// Checks if a specific health type has write access
  bool hasWriteAccess(CKType type) {
    return getStatus(type, CKAccessType.write).isGranted;
  }

  /// Checks if the app has historical data access (Android only)
  bool get hasHistoryAccess => historyAccess.isGranted;

  /// Checks if the app has background data access (Android only)
  bool get hasBackgroundAccess => backgroundAccess.isGranted;

  /// Returns a list of all health types that have been checked
  List<CKType> get checkedTypes => dataAccess.keys.toList();

  /// Returns a list of health types that are granted for a specific access type
  List<CKType> getGrantedTypes(CKAccessType accessType) {
    return dataAccess.entries
        .where((entry) => entry.value[accessType]?.isGranted ?? false)
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns a list of health types that are denied for a specific access type
  List<CKType> getDeniedTypes(CKAccessType accessType) {
    return dataAccess.entries
        .where((entry) => entry.value[accessType]?.isDenied ?? false)
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns a list of health types that have unknown status for a specific access type
  List<CKType> getUnknownTypes(CKAccessType accessType) {
    return dataAccess.entries
        .where((entry) => entry.value[accessType]?.isUnknown ?? false)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'CKAccessStatus('
        'historyAccess: $historyAccess, '
        'backgroundAccess: $backgroundAccess, '
        'dataAccess: $dataAccess)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CKAccessStatus &&
        other.historyAccess == historyAccess &&
        other.backgroundAccess == backgroundAccess &&
        _mapEquals(other.dataAccess, dataAccess);
  }

  @override
  int get hashCode {
    return historyAccess.hashCode ^
        backgroundAccess.hashCode ^
        dataAccess.hashCode;
  }

  /// Helper method to compare maps for equality
  bool _mapEquals<T, U>(Map<T, U> a, Map<T, U> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}
