// test/unit/src/models/ck_access_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/ck_access_status.dart';
import 'package:connect_kit/src/models/schema/ck_type.dart';
import 'package:connect_kit/src/models/ck_access_type.dart';
import 'package:connect_kit/src/models/ck_permission_status.dart';

void main() {
  group('CKAccessStatus', () {
    group('constructor', () {
      test('creates instance with required fields', () {
        final status = CKAccessStatus(
          dataAccess: {},
        );

        expect(status.dataAccess, isEmpty);
        expect(status.historyAccess, CKPermissionStatus.unknown);
        expect(status.backgroundAccess, CKPermissionStatus.unknown);
      });

      test('creates instance with all fields', () {
        final dataAccess = {
          CKType.steps: {
            CKAccessType.read: CKPermissionStatus.granted,
          },
        };

        final status = CKAccessStatus(
          dataAccess: dataAccess,
          historyAccess: CKPermissionStatus.granted,
          backgroundAccess: CKPermissionStatus.denied,
        );

        expect(status.dataAccess, equals(dataAccess));
        expect(status.historyAccess, CKPermissionStatus.granted);
        expect(status.backgroundAccess, CKPermissionStatus.denied);
      });
    });

    group('fromMessage', () {
      test('parses valid message with all fields', () {
        final dataAccessMap = {
          'steps': {'read': 'granted', 'write': 'denied'},
          'height': {'read': 'granted'},
        };

        final status = CKAccessStatus.fromMessage(
          dataAccessMap,
          historyAccessString: 'granted',
          backgroundAccessString: 'denied',
        );

        expect(status.dataAccess[CKType.steps]?[CKAccessType.read],
            CKPermissionStatus.granted);
        expect(status.dataAccess[CKType.steps]?[CKAccessType.write],
            CKPermissionStatus.denied);
        expect(status.dataAccess[CKType.height]?[CKAccessType.read],
            CKPermissionStatus.granted);
        expect(status.historyAccess, CKPermissionStatus.granted);
        expect(status.backgroundAccess, CKPermissionStatus.denied);
      });

      test('handles null dataAccessMap', () {
        final status = CKAccessStatus.fromMessage(null);

        expect(status.dataAccess, isEmpty);
        expect(status.historyAccess, CKPermissionStatus.unknown);
        expect(status.backgroundAccess, CKPermissionStatus.unknown);
      });

      test('handles empty dataAccessMap', () {
        final status = CKAccessStatus.fromMessage({});

        expect(status.dataAccess, isEmpty);
      });

      test('skips invalid health types', () {
        final dataAccessMap = {
          'steps': {'read': 'granted'},
          'invalidType': {'read': 'granted'},
          'height': {'write': 'denied'},
        };

        final status = CKAccessStatus.fromMessage(dataAccessMap);

        expect(status.dataAccess, hasLength(2));
        expect(status.dataAccess[CKType.steps], isNotNull);
        expect(status.dataAccess[CKType.height], isNotNull);
      });

      test('handles null history and background strings', () {
        final status = CKAccessStatus.fromMessage({});

        expect(status.historyAccess, CKPermissionStatus.unknown);
        expect(status.backgroundAccess, CKPermissionStatus.unknown);
      });

      test('parses composite types correctly', () {
        final dataAccessMap = {
          'bloodPressure.systolic': {'read': 'granted'},
          'bloodPressure.diastolic': {'write': 'denied'},
        };

        final status = CKAccessStatus.fromMessage(dataAccessMap);

        expect(
            status.dataAccess[CKType.bloodPressure.systolic]
                ?[CKAccessType.read],
            CKPermissionStatus.granted);
        expect(
            status.dataAccess[CKType.bloodPressure.diastolic]
                ?[CKAccessType.write],
            CKPermissionStatus.denied);
      });
    });

    group('getStatus', () {
      test('returns correct status for existing type and access', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {
              CKAccessType.read: CKPermissionStatus.granted,
            },
          },
        );

        expect(status.getStatus(CKType.steps, CKAccessType.read),
            CKPermissionStatus.granted);
      });

      test('returns notDetermined for non-existent type', () {
        final status = CKAccessStatus(dataAccess: {});

        expect(status.getStatus(CKType.steps, CKAccessType.read),
            CKPermissionStatus.notDetermined);
      });

      test('returns notDetermined for non-existent access type', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {
              CKAccessType.read: CKPermissionStatus.granted,
            },
          },
        );

        expect(status.getStatus(CKType.steps, CKAccessType.write),
            CKPermissionStatus.notDetermined);
      });
    });

    group('hasReadAccess', () {
      test('returns true when read is granted', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {
              CKAccessType.read: CKPermissionStatus.granted,
            },
          },
        );

        expect(status.hasReadAccess(CKType.steps), isTrue);
      });

      test('returns false when read is denied', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {
              CKAccessType.read: CKPermissionStatus.denied,
            },
          },
        );

        expect(status.hasReadAccess(CKType.steps), isFalse);
      });

      test('returns false for non-existent type', () {
        final status = CKAccessStatus(dataAccess: {});

        expect(status.hasReadAccess(CKType.steps), isFalse);
      });
    });

    group('hasWriteAccess', () {
      test('returns true when write is granted', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {
              CKAccessType.write: CKPermissionStatus.granted,
            },
          },
        );

        expect(status.hasWriteAccess(CKType.steps), isTrue);
      });

      test('returns false when write is denied', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {
              CKAccessType.write: CKPermissionStatus.denied,
            },
          },
        );

        expect(status.hasWriteAccess(CKType.steps), isFalse);
      });
    });

    group('hasHistoryAccess', () {
      test('returns true when history is granted', () {
        final status = CKAccessStatus(
          dataAccess: {},
          historyAccess: CKPermissionStatus.granted,
        );

        expect(status.hasHistoryAccess, isTrue);
      });

      test('returns false when history is not granted', () {
        final status = CKAccessStatus(
          dataAccess: {},
          historyAccess: CKPermissionStatus.denied,
        );

        expect(status.hasHistoryAccess, isFalse);
      });
    });

    group('hasBackgroundAccess', () {
      test('returns true when background is granted', () {
        final status = CKAccessStatus(
          dataAccess: {},
          backgroundAccess: CKPermissionStatus.granted,
        );

        expect(status.hasBackgroundAccess, isTrue);
      });

      test('returns false when background is not granted', () {
        final status = CKAccessStatus(
          dataAccess: {},
          backgroundAccess: CKPermissionStatus.denied,
        );

        expect(status.hasBackgroundAccess, isFalse);
      });
    });

    group('checkedTypes', () {
      test('returns list of all checked types', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.read: CKPermissionStatus.granted},
            CKType.height: {CKAccessType.write: CKPermissionStatus.denied},
          },
        );

        final types = status.checkedTypes;
        expect(types, hasLength(2));
        expect(types, contains(CKType.steps));
        expect(types, contains(CKType.height));
      });

      test('returns empty list when no types checked', () {
        final status = CKAccessStatus(dataAccess: {});

        expect(status.checkedTypes, isEmpty);
      });
    });

    group('getGrantedTypes', () {
      test('returns types granted for read', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.read: CKPermissionStatus.granted},
            CKType.height: {CKAccessType.read: CKPermissionStatus.denied},
            CKType.weight: {CKAccessType.read: CKPermissionStatus.granted},
          },
        );

        final granted = status.getGrantedTypes(CKAccessType.read);
        expect(granted, hasLength(2));
        expect(granted, contains(CKType.steps));
        expect(granted, contains(CKType.weight));
      });
    });

    group('getDeniedTypes', () {
      test('returns types denied for write', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.write: CKPermissionStatus.denied},
            CKType.height: {CKAccessType.write: CKPermissionStatus.granted},
            CKType.weight: {CKAccessType.write: CKPermissionStatus.denied},
          },
        );

        final denied = status.getDeniedTypes(CKAccessType.write);
        expect(denied, hasLength(2));
        expect(denied, contains(CKType.steps));
        expect(denied, contains(CKType.weight));
      });
    });

    group('getUnknownTypes', () {
      test('returns types with unknown status', () {
        final status = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.read: CKPermissionStatus.unknown},
            CKType.height: {CKAccessType.read: CKPermissionStatus.granted},
          },
        );

        final unknown = status.getUnknownTypes(CKAccessType.read);
        expect(unknown, hasLength(1));
        expect(unknown, contains(CKType.steps));
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        final status1 = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.read: CKPermissionStatus.granted},
          },
          historyAccess: CKPermissionStatus.granted,
        );

        final status2 = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.read: CKPermissionStatus.granted},
          },
          historyAccess: CKPermissionStatus.granted,
        );

        expect(status1, equals(status2));
        expect(status1.hashCode, equals(status2.hashCode));
      });

      test('different instances are not equal', () {
        final status1 = CKAccessStatus(
          dataAccess: {
            CKType.steps: {CKAccessType.read: CKPermissionStatus.granted},
          },
        );

        final status2 = CKAccessStatus(
          dataAccess: {
            CKType.height: {CKAccessType.read: CKPermissionStatus.granted},
          },
        );

        expect(status1, isNot(equals(status2)));
      });
    });

    group('toString', () {
      test('returns string representation', () {
        final status = CKAccessStatus(
          dataAccess: {},
          historyAccess: CKPermissionStatus.granted,
        );

        final str = status.toString();
        expect(str, contains('CKAccessStatus'));
        expect(str, contains('historyAccess'));
        expect(str, contains('granted'));
      });
    });
  });
}
