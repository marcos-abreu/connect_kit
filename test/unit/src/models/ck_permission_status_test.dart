// test/unit/src/models/ck_permission_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connect_kit/src/models/ck_permission_status.dart';

void main() {
  group('CKPermissionStatus', () {
    test('has correct enum values', () {
      expect(CKPermissionStatus.values, hasLength(5));
      expect(CKPermissionStatus.values, contains(CKPermissionStatus.granted));
      expect(CKPermissionStatus.values, contains(CKPermissionStatus.denied));
      expect(CKPermissionStatus.values,
          contains(CKPermissionStatus.notDetermined));
      expect(
          CKPermissionStatus.values, contains(CKPermissionStatus.notSupported));
      expect(CKPermissionStatus.values, contains(CKPermissionStatus.unknown));
    });

    group('fromString', () {
      test('returns correct enum for valid strings', () {
        expect(CKPermissionStatus.fromString('granted'),
            CKPermissionStatus.granted);
        expect(
            CKPermissionStatus.fromString('denied'), CKPermissionStatus.denied);
        expect(CKPermissionStatus.fromString('notDetermined'),
            CKPermissionStatus.notDetermined);
        expect(CKPermissionStatus.fromString('notSupported'),
            CKPermissionStatus.notSupported);
        expect(CKPermissionStatus.fromString('unknown'),
            CKPermissionStatus.unknown);
      });

      test('returns unknown for invalid strings', () {
        expect(CKPermissionStatus.fromString('invalid'),
            CKPermissionStatus.unknown);
        expect(CKPermissionStatus.fromString(''), CKPermissionStatus.unknown);
      });
    });

    group('extension properties', () {
      test('displayName returns correct values', () {
        expect(CKPermissionStatus.granted.displayName, 'Granted');
        expect(CKPermissionStatus.denied.displayName, 'Denied');
        expect(CKPermissionStatus.notDetermined.displayName, 'Not Determined');
        expect(CKPermissionStatus.notSupported.displayName, 'Not Supported');
        expect(CKPermissionStatus.unknown.displayName, 'Unknown');
      });

      test('isGranted returns true only for granted', () {
        expect(CKPermissionStatus.granted.isGranted, isTrue);
        expect(CKPermissionStatus.denied.isGranted, isFalse);
        expect(CKPermissionStatus.notDetermined.isGranted, isFalse);
        expect(CKPermissionStatus.notSupported.isGranted, isFalse);
        expect(CKPermissionStatus.unknown.isGranted, isFalse);
      });

      test('isDenied returns true only for denied', () {
        expect(CKPermissionStatus.denied.isDenied, isTrue);
        expect(CKPermissionStatus.granted.isDenied, isFalse);
        expect(CKPermissionStatus.notDetermined.isDenied, isFalse);
        expect(CKPermissionStatus.notSupported.isDenied, isFalse);
        expect(CKPermissionStatus.unknown.isDenied, isFalse);
      });

      test('isNotDetermined returns true only for notDetermined', () {
        expect(CKPermissionStatus.notDetermined.isNotDetermined, isTrue);
        expect(CKPermissionStatus.granted.isNotDetermined, isFalse);
        expect(CKPermissionStatus.denied.isNotDetermined, isFalse);
      });

      test('isNotSupported returns true only for notSupported', () {
        expect(CKPermissionStatus.notSupported.isNotSupported, isTrue);
        expect(CKPermissionStatus.granted.isNotSupported, isFalse);
        expect(CKPermissionStatus.denied.isNotSupported, isFalse);
      });

      test('isUnknown returns true only for unknown', () {
        expect(CKPermissionStatus.unknown.isUnknown, isTrue);
        expect(CKPermissionStatus.granted.isUnknown, isFalse);
        expect(CKPermissionStatus.denied.isUnknown, isFalse);
      });

      test('suggestedAction returns appropriate messages', () {
        expect(CKPermissionStatus.granted.suggestedAction, contains('proceed'));
        expect(CKPermissionStatus.denied.suggestedAction, contains('settings'));
        expect(CKPermissionStatus.notDetermined.suggestedAction,
            contains('Request'));
        expect(CKPermissionStatus.notSupported.suggestedAction,
            contains('cannot proceed'));
        expect(CKPermissionStatus.unknown.suggestedAction, contains('Attempt'));
      });
    });
  });
}
